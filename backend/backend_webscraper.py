#!/usr/bin/env python3

import asyncio
import aiohttp
import aio_pika
import json
import os
from datetime import datetime
import logging
from typing import Dict, List
from config import RMQ_CONFIG, SCRAPING_CONFIG, APPLIANCE_PROBLEMS, APPLIANCE_FILTERS, DB_CONFIG, TEST_CONFIG
from retail_scraper import RetailScraper
from parts_scraper import PartsScraper
from pathlib import Path

logging.basicConfig(
  level=logging.INFO,
  format='%(asctime)s - %(levelname)s - %(message)s'
)

class ApplianceWebScraper:
  def __init__(self, test_mode=False):
    self.test_mode = test_mode
    self.connection = None
    self.channel = None
    self.exchange = None
    if not test_mode:
      self.setup_rmq()
    else:
      self.test_queries = []
      logging.info("Running in test mode - no database updates will be made")
    self.retail_scrapers = {
      site: RetailScraper(
        SCRAPING_CONFIG['headers'],
        SCRAPING_CONFIG['rate_limit'],
        site
      )
      for site in SCRAPING_CONFIG['retail_urls']
    }
    self.parts_scrapers = {
      site: PartsScraper(
        SCRAPING_CONFIG['headers'],
        SCRAPING_CONFIG['rate_limit'],
        site
      )
      for site in {**SCRAPING_CONFIG['parts_urls'], **SCRAPING_CONFIG['manufacturer_urls']}
    }
    self.appliances_cache = []

  async def setup_rmq(self):
    if self.test_mode:
      return
    self.connection = await aio_pika.connect(
      f"amqp://admin:{os.environ['rmq_passwd']}@{os.environ['rmq_ip']}/"
    )
    self.channel = await self.connection.channel()
    self.exchange = await self.channel.declare_exchange(
      name='applicare',
      type=aio_pika.ExchangeType.DIRECT,
      durable=True
    )
    self.queue = await self.channel.declare_queue(
      'scraper_queue',
      durable=True,
      arguments={'x-message-ttl': 60000, 'x-queue-type': 'quorum'}
    )
    await self.queue.bind(self.exchange, routing_key='scraper')

  async def run_scraping_cycle(self):
    """Main scraping cycle that runs in phases"""
    await self.setup_rmq()
    try:
      async with aiohttp.ClientSession() as session:
        await self.phase_appliance_collection(session)
        await self.phase_parts_collection(session)
    finally:
      await self.cleanup()

  async def phase_appliance_collection(self, session):
    """Phase 1: Collect appliances from retail sites"""
    logging.info("Starting Phase 1: Appliance Collection")    
    if self.test_mode:
      test_data = {
        'phase': 'appliance_collection',
        'status': 'using_mock_data',
        'mock_appliances': [
          {
            'type': app['type'],
            'brand': app['brand'],
            'model': app['model'],
            'description': f"Common {app['type']} problems and solutions",
            'problems': APPLIANCE_PROBLEMS.get(app['type'].lower(), {})
          }
          for app in TEST_CONFIG['mock_db_response']['results']
        ]
      }
      await self.send_to_database(test_data)
    appliances = await self._gather_appliance_data(session)
    filtered_appliances = self._filter_appliances(appliances)
    for appliance in filtered_appliances:
      await self.store_appliance_data(appliance)
    await self._wait_for_db_response()

  def _filter_appliances(self, appliances: List[Dict]) -> List[Dict]:
    """Filter appliances based on configured types and brands"""
    return [
      app for app in appliances
      if app['type'].lower() in APPLIANCE_FILTERS['types']
      and app['brand'].lower() in APPLIANCE_FILTERS['brands']
    ]

  async def phase_parts_collection(self, session):
    """Phase 2: Collect parts for known appliances"""
    logging.info("Starting Phase 2: Parts Collection")
    appliances = TEST_CONFIG['mock_db_response']['results'] if self.test_mode else []
    if not self.test_mode:
      query = DB_CONFIG['select_appliances']
      params = (
        ','.join([f"'{t}'" for t in APPLIANCE_FILTERS['types']]),
        ','.join([f"'{b}'" for b in APPLIANCE_FILTERS['brands']])
      )
      await self.send_to_database({
        'query': query,
        'params': params,
        'response_required': True
      })
      appliances = await self._wait_for_db_response()
    if self.test_mode:
      await self.send_to_database({
        'phase': 'parts_collection',
        'status': 'using_mock_data',
        'mock_appliances_processed': appliances
      })
    for appliance in appliances:
      await self._gather_parts_for_appliance(session, appliance)

  async def _gather_parts_for_appliance(self, session, appliance: Dict):
    """Gather parts for a specific appliance"""
    problems = APPLIANCE_PROBLEMS.get(appliance['type'].lower(), {})
    sources = self._get_parts_sources(appliance['brand'])
    for problem_area, part_types in problems.items():
      for part_type in part_types:
        parts = await self._search_parts_specific_sources(
          session, 
          appliance['model'],
          part_type,
          problem_area,
          sources
        )
        for part in parts:
          await self.store_part_data(part, appliance['model'])

  def _get_parts_sources(self, brand: str) -> List[str]:
    """Determine which parts sources to use based on brand"""
    sources = list(SCRAPING_CONFIG['parts_urls'].keys())  # always include generic parts sites
    brand = brand.lower()
    if brand in SCRAPING_CONFIG['manufacturer_urls']: # include manufacturer parts sites (if available)
      sources.append(brand)
    return sources

  async def _search_parts_specific_sources(self, session, model: str, part_type: str, problem_area: str, sources: List[str]) -> List[Dict]:
    """Search for parts in specific sources only"""
    if self.test_mode:
      return [{
        'part_name': f"{part_type} for {model}",
        'part_image': f"https://example.com/{part_type}.jpg",
        'part_link': f"https://example.com/parts/{part_type}",
        'instructions_video': f"https://example.com/videos/{part_type}",
        'problem_area': problem_area,
        'issue_description': f"Faulty {part_type}",
        'appliance_model': model
      }]
    tasks = []
    for site in sources:
      if site in self.parts_scrapers:
        tasks.append(self.parts_scrapers[site].search_parts(session, model, part_type, problem_area))
    results = await asyncio.gather(*tasks, return_exceptions=True)
    return [part for result in results if isinstance(result, list) for part in result]

  async def _search_parts_all_sources(self, session, model: str, part_type: str, problem_area: str) -> List[Dict]:
    if self.test_mode:
      parts = []
      for source, source_parts in TEST_CONFIG['mock_scraped_data'].items():
        matching_parts = [
          part for part in source_parts
          if part['type'] == part_type and part['problem_area'] == problem_area
        ]
        parts.extend(matching_parts)
      return parts
    tasks = []
    for site, scraper in self.parts_scrapers.items():
      tasks.append(scraper.search_parts(session, model, part_type, problem_area))    
    results = await asyncio.gather(*tasks, return_exceptions=True)
    parts = []
    for result in results:
      if isinstance(result, Exception):
        logging.error(f"Parts scraping error: {result}")
      else:
        parts.extend(result)
    return parts

  async def _gather_appliance_data(self, session) -> List[Dict]:
    tasks = []
    for site, url in SCRAPING_CONFIG['retail_urls'].items():
      scraper = self.retail_scrapers[site]
      tasks.append(scraper.scrape(session, url))    
    results = await asyncio.gather(*tasks, return_exceptions=True)
    appliances = []
    for result in results:
      if isinstance(result, Exception):
        logging.error(f"Scraping error: {result}")
      else:
        appliances.extend(result)
    return appliances

  async def _gather_parts_data(self, session, appliances: List[Dict]):
    for appliance in appliances:
      model = appliance.get('model')
      if not model:
        continue
      problems = APPLIANCE_PROBLEMS.get(appliance['type'].lower(), {})
      appliance['parts'] = []
      for problem_area, part_types in problems.items():
        for part_type in part_types:
          parts = await self._search_parts_all_sources(session, model, part_type, problem_area)
          appliance['parts'].extend(parts)

  async def _process_scraped_data(self, appliances: List[Dict]):
    for appliance in appliances:
      await self.store_appliance_data(appliance)
      if 'parts' in appliance:
        for part in appliance['parts']:
          await self.store_part_data(part, appliance['model'])

  async def store_appliance_data(self, appliance: Dict):
    """Store appliance data and its associated problem areas in correct order"""
    try:
      appliance_query = {
        'query': """
          INSERT IGNORE INTO appliances (appliance_name, description) 
          VALUES (%s, %s)
        """,
        'params': [appliance['type'], appliance.get('description', f"Common {appliance['type']} issues")]
      }
      await self.send_to_database(appliance_query)
      await self._wait_for_db_response() 
      brand_query = {
        'query': """
          INSERT IGNORE INTO brands (appliance_id, name)
          SELECT appliance_id, %s FROM appliances 
          WHERE appliance_name = %s
        """,
        'params': [appliance['brand'], appliance['type']]
      }
      await self.send_to_database(brand_query)
      await self._wait_for_db_response()
      model_query = {
        'query': """
          INSERT IGNORE INTO models (brand_id, name)
          SELECT b.brand_id, %s 
          FROM brands b
          JOIN appliances a ON b.appliance_id = a.appliance_id
          WHERE b.name = %s AND a.appliance_name = %s
        """,
        'params': [appliance['model'], appliance['brand'], appliance['type']]
      }
      await self.send_to_database(model_query)
      await self._wait_for_db_response()
      problems = self.associate_problems_parts(appliance['type'])
      for problem_area, issues in problems.items():
        area_query = {
          'query': """
            INSERT IGNORE INTO problem_areas (appliance_id, area_name)
            SELECT appliance_id, %s FROM appliances 
            WHERE appliance_name = %s
          """,
          'params': [problem_area, appliance['type']]
        }
        await self.send_to_database(area_query)
        await self._wait_for_db_response()
        for issue_desc in issues:
          issue_query = {
            'query': """
              INSERT IGNORE INTO issue_types (area_id, issue_description)
              SELECT pa.area_id, %s 
              FROM problem_areas pa
              JOIN appliances a ON pa.appliance_id = a.appliance_id
              WHERE pa.area_name = %s AND a.appliance_name = %s
            """,
            'params': [issue_desc, problem_area, appliance['type']]
          }
          await self.send_to_database(issue_query)
          await self._wait_for_db_response()
    except Exception as e:
      logging.error(f"Error storing appliance data: {e}")
      logging.debug(f"Problem appliance data: {appliance}")

  async def store_part_data(self, part: Dict, model: str):
    """Store part data and its relationships in correct order"""
    try:
      if not isinstance(part, dict) or 'part_name' not in part:
        logging.error(f"Invalid part data structure: {part}")
        return
      part_data = {
        'part_name': part.get('part_name', 'Unknown Part'),
        'part_image': part.get('part_image', None),
        'part_link': part.get('part_link', None),
        'instructions_video': part.get('instructions_video', None)
      }
      part_query = {
        'query': """
          INSERT IGNORE INTO parts 
          (part_name, part_image, part_link, instructions_video)
          VALUES (%s, %s, %s, %s)
        """,
        'params': list(part_data.values())
      }
      await self.send_to_database(part_query)
      await self._wait_for_db_response()
      if all(k in part for k in ['problem_area', 'issue_description']):
        issue_part_query = {
          'query': """
            INSERT IGNORE INTO issues_parts (issue_id, part_id)
            SELECT i.issue_id, p.part_id
            FROM issue_types i
            JOIN parts p ON p.part_name = %s
            JOIN problem_areas pa ON i.area_id = pa.area_id
            WHERE i.issue_description = %s
            AND pa.area_name = %s
          """,
          'params': [part_data['part_name'], part['issue_description'], part['problem_area']]
        }
        await self.send_to_database(issue_part_query)
        await self._wait_for_db_response()
    except Exception as e:
        logging.error(f"Error storing part data: {e}")
        logging.debug(f"Problem part data: {part}")

  def associate_problems_parts(self, appliance_type: str) -> Dict:
    appliance_type = appliance_type.lower()
    if appliance_type in APPLIANCE_PROBLEMS:
      return APPLIANCE_PROBLEMS[appliance_type]
    return {}

  async def send_to_database(self, data: Dict):
    if self.test_mode:
      query_info = {
        'timestamp': datetime.now().isoformat(),
        'query': data,
        'query_type': 'insert_part' if 'part_name' in str(data) else 'insert_appliance'
      }
      self.test_queries.append(query_info)
      logging.info(f"Test mode: Stored query: {json.dumps(query_info['timestamp'], indent=2)}")
      return
    try:
      message = aio_pika.Message(
        body=json.dumps({'query': data}).encode(),
        delivery_mode=aio_pika.DeliveryMode.PERSISTENT,
        correlation_id=str(datetime.now().timestamp())
      )
      await self.exchange.publish(
        message,
        routing_key='database'
      )
      logging.info("Successfully sent data to database queue")
    except Exception as e:
      logging.error(f"Error sending to RabbitMQ: {e}")

  async def _wait_for_db_response(self):
    if self.test_mode:
      return TEST_CONFIG['mock_db_response']['results']
    response_future = asyncio.Future()
    correlation_id = str(datetime.now().timestamp())
    async def callback(message):
      nonlocal response_future
      if message.correlation_id == correlation_id:
        data = json.loads(message.body)
        if 'error' in data:
          response_future.set_exception(Exception(data['error']))
        else:
          response_future.set_result(data.get('results', []))
    try:
      return await asyncio.wait_for(response_future, timeout=30.0)
    except asyncio.TimeoutError:
      logging.error("Timeout waiting for database response")
      raise
    
  async def cleanup(self):
    if self.test_mode:
      output_path = Path(TEST_CONFIG['output_file'])
      with open(output_path, 'w') as f:
        json.dump(self.test_queries, f, indent=2)
      logging.info(f"Test results written to {output_path}")
      return
    if self.connection and not self.connection.is_closed:
      await self.connection.close()

async def main():
  test_mode = TEST_CONFIG['enabled'] or os.environ.get('test_mode', '').lower() == 'true'
  scraper = ApplianceWebScraper(test_mode=test_mode)
  await scraper.run_scraping_cycle()

if __name__ == "__main__":
  asyncio.run(main())