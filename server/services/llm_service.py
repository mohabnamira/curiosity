from google import genai
from config import Settings

settings = Settings()


class LLMService:
    def __init__(self):
        self.client = genai.Client(api_key=settings.GEMINI_API_KEY)
        self.model = "gemini-3.1-flash-lite"

    def generate_response(self, query: str, search_results: list[dict]):
        context = "\n\n".join(
            f"[{i + 1}] {result['title']} ({result['url']})\n{result['content'][:2000]}"
            for i, result in enumerate(search_results)
            if result.get("content")
        )

        full_prompt = f"""You are given the following web search context:

{context}

Please provide a comprehensive, detailed, well-cited, accurate response to the user's query.
Think and reason deeply. Ensure it answers the query the user is asking.
Do not use your knowledge until it is absolutely necessary. If you are unsure, say "I don't know."

User query:
{query}
"""

        response = self.client.models.generate_content(
            model=self.model,
            contents=full_prompt,
        )
        return response.text