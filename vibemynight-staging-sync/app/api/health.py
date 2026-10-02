from fastapi import APIRouter
from app.config import settings
from app.database import check_db_health

router = APIRouter(tags=["Health"])


@router.get("/health")
def health_check():
    """System health check endpoint providing service and database status."""
    db_ok = check_db_health()
    return {
        "status": "UP" if db_ok else "DEGRADED",
        "service": settings.APP_NAME,
        "database": "UP" if db_ok else "DOWN",
        "environment": settings.APP_ENV,
        "ai_provider": settings.AI_PROVIDER
    }
