from concurrent.futures import ThreadPoolExecutor, wait
from config import Settings
from tavily import TavilyClient

import trafilatura
settings = Settings()
tavily_client = TavilyClient(api_key=settings.TAVILY_API_KEY)

class SearchService:
    def web_search(self, query: str):
        response = tavily_client.search(query, max_results=10)
        search_results = response.get("results", [])

        executor = ThreadPoolExecutor(max_workers=10)
        futures = [executor.submit(self._fetch_item, item) for item in search_results]

        done, _ = wait(futures, timeout=5)
        executor.shutdown(wait=False, cancel_futures=True)

        return [f.result() for f in futures if f in done]

    def _fetch_item(self, item):
        content = None
        try:
            downloaded = trafilatura.fetch_url(item.get("url"))
            if downloaded:
                content = trafilatura.extract(
                    downloaded,
                    include_comments=False,
                    include_tables=False,
                    include_formatting=False
                )
        except Exception:
            pass

        return {
            "title": item.get("title", ""),
            "url": item.get("url"),
            "content": content
        }