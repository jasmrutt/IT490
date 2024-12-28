from abc import ABC, abstractmethod
import aiohttp
import asyncio
from typing import Dict, List, Optional
import logging

class BaseScraper(ABC):
  def __init__(self, headers: Dict, rate_limit: int):
    self.headers = headers
    self.rate_limit = rate_limit

  async def fetch_page(self, session: aiohttp.ClientSession, url: str) -> Optional[str]:
    try:
      await asyncio.sleep(self.rate_limit)
      async with session.get(url, headers=self.headers) as response:
        if response.status == 200:
          return await response.text()
        logging.error(f"HTTP {response.status} for URL: {url}")
        return None
    except Exception as e:
      logging.error(f"Error fetching {url}: {e}")
      return None

  @abstractmethod
  async def scrape(self, session: aiohttp.ClientSession, url: str) -> Dict:
    pass
