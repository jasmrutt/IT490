from base_scraper import BaseScraper
from bs4 import BeautifulSoup
from typing import Dict, List
import logging

class RetailScraper(BaseScraper):
  def __init__(self, headers: Dict, rate_limit: int, site: str):
    super().__init__(headers, rate_limit)
    self.site = site

  async def scrape(self, session, url: str) -> List[Dict]:
    html = await self.fetch_page(session, url)
    if not html:
      return []

    soup = BeautifulSoup(html, 'html.parser')
    if self.site == 'homedepot':
      return await self._scrape_homedepot(soup)
    elif self.site == 'lowes':
      return await self._scrape_lowes(soup)
    return []

  async def _scrape_homedepot(self, soup: BeautifulSoup) -> List[Dict]:
    appliances = []
    try:
      for item in soup.select('div.product-item'):
        appliance = {
          'brand': item.select_one('.brand').text.strip(),
          'model': item.select_one('.model').text.strip(),
          'type': item.select_one('.type').text.strip(),
          'source': 'homedepot',
          'url': item.select_one('a')['href']
        }
        appliances.append(appliance)
    except Exception as e:
      logging.error(f"Error scraping Home Depot: {e}")
    return appliances

  async def _scrape_lowes(self, soup: BeautifulSoup) -> List[Dict]:
    appliances = []
    try:
      for item in soup.select('div.product-details'):
        appliance = {
          'brand': item.select_one('.brand-name').text.strip(),
          'model': item.select_one('.product-model').text.strip(),
          'type': item.select_one('.product-category').text.strip(),
          'source': 'lowes',
          'url': item.select_one('a.product-link')['href']
        }
        appliances.append(appliance)
    except Exception as e:
      logging.error(f"Error scraping Lowes: {e}")
    return appliances
