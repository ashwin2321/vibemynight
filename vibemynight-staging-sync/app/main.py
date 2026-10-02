import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import Base, engine
from app.api.health import router as health_router
from app.api.sync import router as sync_router

# Configure structured logging
logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL.upper(), logging.INFO),
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("vibemynight-staging-sync")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initializes tables on startup if not already created."""
    logger.info(f"Starting {settings.APP_NAME} in {settings.APP_ENV} mode...")
    try:
        Base.metadata.create_all(bind=engine)
        logger.info("Staging database schema verified.")
    except Exception as e:
        logger.error(f"Failed to verify staging database schema: {e}")
    yield
    logger.info(f"Shutting down {settings.APP_NAME}...")


app = FastAPI(
    title="VibeMyNight Staging & Sync API",
    description="Dedicated staging and AI sync service for external events ingestion (Showmates / Gemini AI).",
    version="1.0.0",
    lifespan=lifespan
)

# CORS Middleware Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount Routes
app.include_router(health_router)
app.include_router(sync_router)


@app.get("/")
def root():
    return {
        "service": settings.APP_NAME,
        "status": "ONLINE",
        "docs_url": "/docs",
        "health_url": "/health"
    }
