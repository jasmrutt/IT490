from base_scraper import BaseScraper
from bs4 import BeautifulSoup
from typing import Dict, List, Optional
import logging
import asyncio
from urllib.parse import urljoin

class PartsScraper(BaseScraper):
  def __init__(self, headers: Dict, rate_limit: int, site: str):
    super().__init__(headers, rate_limit)
    self.site = site
    self._scraping_methods = {
      'repairclinic': self._scrape_repairclinic,
      'partselect': self._scrape_partselect,
      'appliancepartspros': self._scrape_appliancepartspros,
      'whirlpool': self._scrape_whirlpool,
      'lg': self._scrape_lg,
      'samsung': self._scrape_samsung,
      'ge': self._scrape_ge
    }

  async def scrape(self, session, url: str) -> Dict:
    """Implementation of abstract scrape method from BaseScraper"""
    html = await self.fetch_page(session, url)
    if not html:
      return {}
    soup = BeautifulSoup(html, 'html.parser')
    return {
      'site': self.site,
      'url': url,
      'parts': await self._scraping_methods[self.site](soup, '', '')
    }

  async def search_parts(self, session, model: str, part_type: str, problem_area: str) -> List[Dict]:
    if self.site not in self._scraping_methods:
      logging.error(f"Unsupported site: {self.site}")
      return []
    search_url = self._build_search_url(model, part_type)
    html = await self.fetch_page(session, search_url)
    if not html:
      return []
    soup = BeautifulSoup(html, 'html.parser')
    return await self._scraping_methods[self.site](soup, part_type, problem_area)

  def _build_search_url(self, model: str, part_type: str) -> str:
    base_urls = {
      'repairclinic': f"search?q={model}+{part_type}",
      'partselect': f"search?q={model}+{part_type}",
      'appliancepartspros': f"search.php?model={model}&part={part_type}",
      'whirlpool': f"parts/search?query={model}",
      'lg': f"search?query={model}",
      'samsung': f"search?modelCode={model}",
      'ge': f"parts/search?q={model}"
    }
    return urljoin(self.base_url, base_urls.get(self.site, ''))

  async def _scrape_repairclinic(self, soup: BeautifulSoup, part_type: str, problem_area: str) -> List[Dict]:
    parts = []
    try:
      for item in soup.select('.part-item'):
        part = {
          'name': item.select_one('.part-name').text.strip(),
          'part_number': item.select_one('.part-number').text.strip(),
          'price': item.select_one('.price').text.strip(),
          'compatibility': item.select_one('.compatibility').text.strip(),
          'type': part_type,
          'problem_area': problem_area,
          'source': 'repairclinic',
          'url': item.select_one('a')['href']
        }
        parts.append(part)
    except Exception as e:
      logging.error(f"Error scraping RepairClinic: {e}")
    return parts

  async def _scrape_partselect(self, soup: BeautifulSoup, part_type: str, problem_area: str) -> List[Dict]:
    parts = []
    try:
      for item in soup.select('.product-item'):
        part = {
          'name': item.select_one('.product-title').text.strip(),
          'part_number': item.select_one('.part-number').text.strip(),
          'price': item.select_one('.price').text.strip(),
          'compatibility': item.select_one('.fits-models').text.strip(),
          'type': part_type,
          'problem_area': problem_area,
          'source': 'partselect',
          'url': item.select_one('a')['href']
        }
        parts.append(part)
    except Exception as e:
      logging.error(f"Error scraping PartSelect: {e}")
    return parts

  async def _scrape_appliancepartspros(self, soup: BeautifulSoup, part_type: str, problem_area: str) -> List[Dict]:
    parts = []
    try:
      for item in soup.select('.part-listing'):
        part = {
          'name': item.select_one('.part-desc').text.strip(),
          'part_number': item.select_one('.model-number').text.strip(),
          'price': item.select_one('.price').text.strip(),
          'compatibility': item.select_one('.fits-models').text.strip(),
          'type': part_type,
          'problem_area': problem_area,
          'source': 'appliancepartspros',
          'url': item.select_one('a')['href']
        }
        parts.append(part)
    except Exception as e:
      logging.error(f"Error scraping AppliancePartsPros: {e}")
    return parts

  # Manufacturer-specific scraping methods follow similar patterns
  async def _scrape_whirlpool(self, soup: BeautifulSoup, part_type: str, problem_area: str) -> List[Dict]:
    parts = []
    try:
      for item in soup.select('.part-result'):
        part = {
          'name': item.select_one('.part-name').text.strip(),
          'part_number': item.select_one('.part-number').text.strip(),
          'price': item.select_one('.price').text.strip(),
          'type': part_type,
          'problem_area': problem_area,
          'source': 'whirlpool',
          'url': item.select_one('a')['href']
        }
        parts.append(part)
    except Exception as e:
      logging.error(f"Error scraping Whirlpool: {e}")
    return parts

  # Similar implementations for other manufacturer sites
  async def _scrape_lg(self, soup: BeautifulSoup, part_type: str, problem_area: str) -> List[Dict]:
    #TODO: similar implementation for LG...
    return []

  async def _scrape_samsung(self, soup: BeautifulSoup, part_type: str, problem_area: str) -> List[Dict]:
    #TODO: similar implementation for Samsung...
    return []

  async def _scrape_ge(self, soup: BeautifulSoup, part_type: str, problem_area: str) -> List[Dict]:
    #TODO: similar implementation for GE...
    return []
