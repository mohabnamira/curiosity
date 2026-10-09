from fastapi import FastAPI
from services.sort_source_service import SortSourceService
from pydantic_models.chat_body import ChatBody
from services.search_service import SearchService

app = FastAPI()
search_service = SearchService()
sort_service = SortSourceService()

@app.post("/chat")
def chat_endpoint(body: ChatBody):
    search_results = search_service.web_search(body.query)
    sorted_results = sort_service.sort_sources(body.query, search_results)

    return sorted_results

@app.get("/")
def read_root():
    return {"message": "Server is running"}