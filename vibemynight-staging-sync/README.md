# VibeMyNight — Staging & Sync Service (Phase 1)

> **IMPORTANT PRODUCTION SAFETY NOTICE:**
> This Phase 1 staging service is completely isolated from the VibeMyNight production database (`https://vibemynight.in`). It runs against an independent staging PostgreSQL/SQLite database and performs **ZERO** direct writes or automatic imports into live production.

---

## 1. Project Purpose & Overview
The **VibeMyNight Staging & Sync Service** is an isolated ingestion and AI-enrichment pipeline designed to:
1. Ingest raw event data from external ticketing APIs (e.g., Showmates).
2. Normalize date formats, timings, pricing ranges, and locations.
3. Detect duplicate events deterministically.
4. Enhance event descriptions, category tags, SEO metadata, and WhatsApp share teasers using **Google Gemini AI** (or OpenAI fallback).
5. Store normalized and enriched events in a staging database for administrative preview, review, and editing before future production import.

---

## 2. Architecture Diagram

```
Showmates API / Ingestion Feeds
             │
             ▼
┌─────────────────────────────────────────────────────────┐
│              Railway Staging Sync Service               │
│                                                         │
│  ┌─────────────────┐       ┌────────────────────────┐   │
│  │ Event Fetcher   │ ────► │ Event Normalizer       │   │
│  └─────────────────┘       └────────────────────────┘   │
│                                        │                │
│                                        ▼                │
│  ┌─────────────────┐       ┌────────────────────────┐   │
│  │ Gemini AI       │ ◄──── │ Duplicate Detector     │   │
│  │ Enrichment      │       └────────────────────────┘   │
│  └─────────────────┘                   │                │
│            │                           │                │
│            └─────────────┬─────────────┘                │
│                          ▼                              │
│              Staging PostgreSQL DB                      │
└─────────────────────────────────────────────────────────┘
                           │ (Read-Only Preview)
                           ▼
          Future Admin Import & Sync Hub
```

---

## 3. Technology Stack
* **Runtime:** Python 3.11+
* **Framework:** FastAPI
* **Database:** PostgreSQL / SQLAlchemy ORM / Alembic Migrations
* **AI Engine:** Google Gemini AI (`gemini-1.5-flash` / `gemini-2.0-flash`) via structured JSON generation
* **HTTP Client:** HTTPX (Async)
* **Testing:** Pytest / Pytest-Asyncio / FastAPI TestClient
* **Deployment & Containerization:** Docker, Docker Compose, Railway-compatible specification (`railway.json`)

---

## 4. Environment Configuration (`.env.example`)
Create a local `.env` file from `.env.example`:

```env
APP_ENV=development
APP_NAME=vibemynight-staging-sync
PORT=8000

# Dedicated Staging Database (Independent from Production)
DATABASE_URL=postgresql+psycopg://postgres:postgrespassword@localhost:5432/vibemynight_staging

# AI Enrichment Engine
AI_PROVIDER=gemini
GEMINI_API_KEY=your_gemini_api_key_here
GEMINI_MODEL=gemini-1.5-flash

# Showmates Ingestion Feed
SHOWMATES_API_URL=https://api.showmates.in/v1/events
SHOWMATES_API_KEY=

# Security & CORS
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5000,http://localhost:8000,https://vibemynight.in,https://www.vibemynight.in
LOG_LEVEL=INFO
```

---

## 5. Running Locally

### Option A: Local Python Environment
```bash
cd vibemynight-staging-sync

# 1. Create and activate virtualenv
python -m venv venv
source venv/bin/activate  # Or `venv\Scripts\activate` on Windows

# 2. Install dependencies
pip install -r requirements.txt

# 3. Start FastAPI server
uvicorn app.main:app --reload --port 8000
```

### Option B: Docker Compose (FastAPI + Staging PostgreSQL)
```bash
cd vibemynight-staging-sync
docker-compose up -d
```

---

## 6. API Endpoints Reference

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/health` | System health check (service & database status). |
| `POST` | `/api/v1/sync/fetch` | Triggers Showmates fetch, normalization, duplicate check, and AI staging. |
| `GET` | `/api/v1/sync/events` | Lists staged events with status/city filtering and pagination. |
| `GET` | `/api/v1/sync/events/{id}` | Retrieves full details and AI metadata for a specific staged event. |
| `PUT` | `/api/v1/sync/events/{id}` | Allows admin to safely edit title, description, prices, or status before import. |

---

## 7. Event Status Workflow
* `PENDING_REVIEW`: Newly ingested and AI-enriched event ready for admin inspection.
* `READY_TO_IMPORT`: Admin-approved event ready for Phase 2 production bridge.
* `DUPLICATE`: Flagged as an existing event; references `duplicate_of` ID.
* `AI_PROCESSING_FAILED`: Ingested successfully, but AI processing encountered an error (original data preserved).
* `SYNC_FAILED`: Critical parsing error on raw input.
* `IMPORTED`: Reserved for Phase 2 after production import is approved.

---

## 8. Running the Test Suite
```bash
cd vibemynight-staging-sync
pytest -v
```

---

## 9. Railway Deployment Preparation
This service is pre-configured for **Railway** deployment:
1. Set the Root Directory to `vibemynight-staging-sync/`.
2. Attach a **PostgreSQL** database service on Railway (which populates `DATABASE_URL`).
3. Add the `GEMINI_API_KEY` in Railway Variables.
4. Railway builds using `Dockerfile` and executes the health-checked service defined in `railway.json`.
