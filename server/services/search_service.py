import asyncio
import httpx
import trafilatura
from tavily import AsyncTavilyClient
from config import Settings

settings = Settings()
tavily_client = AsyncTavilyClient(api_key=settings.TAVILY_API_KEY)

MAX_CHARS_PER_SOURCE = 1500
SNIPPET_CHARS = 200


def chunk_text(text: str, max_chars: int = MAX_CHARS_PER_SOURCE) -> str:
    paragraphs = [p.strip() for p in text.split("\n") if p.strip()]
    kept, total = [], 0
    for p in paragraphs:
        if total + len(p) > max_chars:
            break
        kept.append(p)
        total += len(p) + 1
    return "\n".join(kept) or text[:max_chars]


class SearchService:
    async def web_search(self, query: str, focus: str = "all", max_results: int = 5):
        include_domains = None
        if focus == "academic":
            include_domains = [
                "arxiv.org",
                "scholar.google.com",
                "researchgate.net",
                "ncbi.nlm.nih.gov",
                "jstor.org",
                "sciencedirect.com",
                "springer.com",
                "ieee.org",
            ]
        elif focus == "youtube":
            include_domains = ["youtube.com", "youtu.be"]

        search_args = {"query": query, "max_results": max_results}
        if include_domains:
            search_args["include_domains"] = include_domains

        response = await tavily_client.search(**search_args)
        items = response.get("results", [])

        async with httpx.AsyncClient(
            timeout=8, follow_redirects=True,
            headers={"User-Agent": "Mozilla/5.0"},
        ) as client:
            pages = await asyncio.gather(
                *(self._scrape(client, item["url"]) for item in items)
            )

        results = []
        for n, (item, page) in enumerate(zip(items, pages), start=1):
            tavily_text = item.get("content", "")
            results.append({
                "index": n,
                "title": item.get("title", ""),
                "url": item["url"],
                "snippet": tavily_text[:SNIPPET_CHARS],
                "content": chunk_text(page) if page else tavily_text,
            })
        return results

    async def _scrape(self, client: httpx.AsyncClient, url: str) -> str:
        try:
            resp = await client.get(url)
            resp.raise_for_status()
            text = await asyncio.to_thread(
                trafilatura.extract, resp.text,
                include_comments=False, include_tables=False,
            )
            return text or ""
        except Exception:
            return ""