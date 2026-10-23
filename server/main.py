import asyncio
import logging
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import ValidationError

from config import Settings
from pydantic_models.chat_body import ChatBody
from services.search_service import SearchService
from services.llm_service import LLMService

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("curiosity")

settings = Settings()

app = FastAPI(
    title="Curiosity Backend",
    version="1.0.0",
    description="Perplexity-style real-time conversational search backend powered by Gemini & Tavily",
)

# CORS configuration
allowed_origins_raw = settings.ALLOWED_ORIGINS.strip()
if allowed_origins_raw == "*" or not allowed_origins_raw:
    cors_origins = ["*"]
else:
    cors_origins = [o.strip() for o in allowed_origins_raw.split(",") if o.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

search_service = SearchService()
llm_service = LLMService()


async def send(ws: WebSocket, type_: str, id_: str | None, data=None):
    try:
        await ws.send_json({"type": type_, "id": id_, "data": data})
    except Exception as e:
        logger.debug(f"Failed to send message over websocket: {e}")


async def handle_chat(ws: WebSocket, body: ChatBody):
    try:
        logger.info(f"[{body.id}] Starting chat turn with focus={body.focus}")
        standalone_query = await llm_service.rewrite_query(body.query, body.history)
        logger.info(f"[{body.id}] Query rewritten: '{body.query}' -> '{standalone_query}'")

        sources = await search_service.web_search(
            standalone_query,
            focus=body.focus,
            max_results=body.max_results,
        )
        logger.info(f"[{body.id}] Found {len(sources)} sources")

        await send(ws, "search_results", body.id, [
            {k: s[k] for k in ("index", "title", "url", "snippet")}
            for s in sources
        ])

        if not sources:
            hint = "Try switching Focus to All." if body.focus != "all" else "Try rephrasing your question."
            await send(ws, "content", body.id, f"No sources found. {hint}")
            await send(ws, "done", body.id)
            return

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
            logger.warning(f"[{body.id}] Related questions generation failed or timed out")

        await send(ws, "done", body.id)
        logger.info(f"[{body.id}] Completed turn successfully")
    except WebSocketDisconnect:
        logger.info(f"[{body.id}] WebSocket disconnected during response generation")
        raise
    except asyncio.CancelledError:
        logger.info(f"[{body.id}] Turn generation was cancelled by client")
    except Exception:
        logger.exception(f"[{body.id}] Unexpected error in handle_chat")
        await send(ws, "error", body.id, "Something went wrong. Please try again.")


@app.websocket("/ws/chat")
async def chat_socket(ws: WebSocket):
    # Optional token verification if APP_TOKEN is set
    if settings.APP_TOKEN:
        token = ws.query_params.get("token")
        if token != settings.APP_TOKEN:
            logger.warning("Rejected unauthorized WebSocket connection attempt")
            await ws.close(code=status.WS_1008_POLICY_VIOLATION)
            return

    await ws.accept()
    client_host = ws.client.host if ws.client else "unknown"
    logger.info(f"WebSocket client connected from {client_host}")

    tasks: dict[str, asyncio.Task] = {}
    query_timestamps: list[float] = []
    try:
        while True:
            try:
                raw = await ws.receive_json()
            except (ValueError, TypeError):
                continue

            msg_type = raw.get("type")
            msg_id = raw.get("id")

            if msg_type == "cancel" and msg_id:
                existing_task = tasks.get(msg_id)
                if existing_task and not existing_task.done():
                    logger.info(f"Cancelling active task {msg_id}")
                    existing_task.cancel()
                continue

            try:
                body = ChatBody(**raw)
            except (ValueError, ValidationError, TypeError) as err:
                logger.warning(f"Invalid request payload received: {err}")
                await send(ws, "error", None, "Invalid request")
                continue

            # Per-connection rate limiting: max 10 queries per 60 seconds
            now = asyncio.get_event_loop().time()
            query_timestamps = [t for t in query_timestamps if now - t < 60.0]
            if len(query_timestamps) >= 10:
                logger.warning(f"Rate limit exceeded for {client_host}")
                await send(ws, "error", body.id, "Too many requests, please wait a minute")
                continue
            query_timestamps.append(now)

            task = asyncio.create_task(handle_chat(ws, body))
            if body.id:
                tasks[body.id] = task
                task.add_done_callback(lambda t, bid=body.id: tasks.pop(bid, None))
    except WebSocketDisconnect:
        logger.info(f"WebSocket client disconnected ({client_host})")
        for t in tasks.values():
            t.cancel()


@app.get("/")
def read_root():
    return {
        "message": "Curiosity Search Server is running",
        "health": "/health",
        "websocket": "/ws/chat",
    }


@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "service": "curiosity-backend",
        "gemini_model": settings.GEMINI_MODEL,
        "tavily_configured": bool(settings.TAVILY_API_KEY),
        "gemini_configured": bool(settings.GEMINI_API_KEY),
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=True,
    )
