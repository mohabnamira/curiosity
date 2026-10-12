from fastapi import FastAPI
from services.sort_source_service import SortSourceService
from pydantic_models.chat_body import ChatBody
from services.search_service import SearchService
from services.llm_service import LLMService
from fastapi.websockets import WebSocket
import asyncio

app = FastAPI()
search_service = SearchService()
sort_service = SortSourceService()
llm_service = LLMService()

@app.websocket("/ws/chat")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()

    try:
        while True:
            data = await websocket.receive_json()
            query = data.get("query")
            if not query:
                continue
            search_results = search_service.web_search(query)
            sorted_results = sort_service.sort_sources(query, search_results)
            await websocket.send_json({"type": 'search_results', "data": sorted_results})
            for chunk in llm_service.generate_response(query, sorted_results):
                await asyncio.sleep(0.02)
                await websocket.send_json({"type": 'content', "data": chunk})

    except Exception as e:
        print("WebSocket disconnected or error occurred:", repr(e))

@app.post("/chat")
def chat_endpoint(body: ChatBody):
    search_results = search_service.web_search(body.query)
    sorted_results = sort_service.sort_sources(body.query, search_results)
    return {"response": llm_service.generate_full_response(body.query, sorted_results)}