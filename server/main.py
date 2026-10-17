import asyncio
import logging
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from pydantic import ValidationError

from pydantic_models.chat_body import ChatBody
from services.search_service import SearchService
from services.llm_service import LLMService

logger = logging.getLogger("curiosity")
app = FastAPI()
search_service = SearchService()
llm_service = LLMService()


async def send(ws: WebSocket, type_: str, id_: str | None, data=None):
    await ws.send_json({"type": type_, "id": id_, "data": data})


async def handle_chat(ws: WebSocket, body: ChatBody):
    try:
        standalone_query = await llm_service.rewrite_query(body.query, body.history)
        sources = await search_service.web_search(standalone_query)
        await send(ws, "search_results", body.id, [
            {k: s[k] for k in ("index", "title", "url", "snippet")}
            for s in sources
        ])
        full_answer = ""
        async for text in llm_service.stream_answer(standalone_query, sources, body.history):
            full_answer += text
            await send(ws, "content", body.id, text)
        try:
            related = await asyncio.wait_for(
                llm_service.generate_related_questions(standalone_query, full_answer),
                timeout=8,
            )
            if related:
                await send(ws, "related", body.id, related)
        except Exception:
            logger.exception("related questions failed")
        await send(ws, "done", body.id)
    except WebSocketDisconnect:
        raise
    except Exception:
        logger.exception("chat failed")
        await send(ws, "error", body.id, "Something went wrong. Please try again.")


@app.websocket("/ws/chat")
async def chat_socket(ws: WebSocket):
    await ws.accept()
    try:
        while True:
            try:
                raw = await ws.receive_json()
                body = ChatBody(**raw)
            except (ValueError, ValidationError, TypeError):
                await send(ws, "error", None, "Invalid request")
                continue
            await handle_chat(ws, body)
    except WebSocketDisconnect:
        pass


@app.get("/")
def read_root():
    return {"message": "Server is running"}