# Curiosity Backend Server

High-performance real-time search backend powered by FastAPI, Tavily Search, and Google Gemini.

## Features
- **WebSocket Streaming:** Real-time token streaming and incremental citation mapping over `/ws/chat`.
- **Query Rewriting:** Automatically synthesizes multi-turn conversation context into an optimal search query.
- **Deep Web Scraping:** Parallel snippet and full-text extraction via `trafilatura` and `httpx`.
- **Focus Modes:** Scoped search filtering across `all`, `academic` (ArXiv, Nature, PubMed, Google Scholar), and `youtube`.
- **Related Questions:** Proactive generation of 3 contextual follow-up inquiries.
- **Production Hardened:** Configurable CORS, `/health` diagnostic probe, connection lifecycle tracking, and graceful task cancellation.

---

## Local Setup (LAN & Mobile Testing)

1. **Activate Virtual Environment:**
   ```bash
   cd server
   python -m venv venv
   # Windows:
   venv\Scripts\activate
   # macOS/Linux:
   source venv/bin/activate
   ```

2. **Install Dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Configure Environment:**
   Copy `.env.example` to `.env` and fill in your API credentials:
   ```env
   TAVILY_API_KEY=tvly-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   GEMINI_API_KEY=AIzaxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   GEMINI_MODEL=gemini-3.1-flash-lite
   HOST=0.0.0.0
   PORT=8000
   ALLOWED_ORIGINS=*
   ```

4. **Run Server:**
   ```bash
   python main.py
   ```
   > **Note for Mobile Testing:** Running `python main.py` automatically binds to `0.0.0.0:8000`, making it reachable from your phone on the same Wi-Fi network (e.g., `ws://192.168.x.x:8000/ws/chat`).

---

## Health Check
Verify your backend is operating normally:
```bash
curl http://localhost:8000/health
```
Response:
```json
{
  "status": "ok",
  "service": "curiosity-backend",
  "gemini_model": "gemini-3.1-flash-lite",
  "tavily_configured": true,
  "gemini_configured": true
}
```

---

## Docker Deployment

Build the container image:
```bash
docker build -t curiosity-backend .
```

Run the container locally:
```bash
docker run -d \
  -p 8000:8000 \
  --env-file .env \
  --name curiosity \
  curiosity-backend
```

---

## Production Cloud Deployment

### 1. Render / Railway / Fly.io
- Simply point the provider to the repository's `server/` directory or Dockerfile.
- Expose port `8000` (or let `$PORT` dynamically bind).
- Set `GEMINI_API_KEY`, `TAVILY_API_KEY`, and `ALLOWED_ORIGINS` in your platform's environment variables.
- Ensure WebSocket support is enabled (standard on Railway, Render, and Fly.io).

### 2. Google Cloud Run
```bash
gcloud run deploy curiosity-backend \
  --source . \
  --port 8000 \
  --allow-unauthenticated \
  --set-env-vars GEMINI_API_KEY=...,TAVILY_API_KEY=...
```
