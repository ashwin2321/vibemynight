from typing import List
from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application Settings powered by Pydantic."""
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )

    # Core
    APP_ENV: str = "development"
    APP_NAME: str = "vibemynight-staging-sync"
    PORT: int = 8000
    LOG_LEVEL: str = "INFO"

    # Database (Defaults to SQLite for local development/testing fallback if postgres not configured)
    DATABASE_URL: str = Field(
        default="sqlite+pysqlite:///./staging_local.db",
        description="Database connection URL"
    )

    @field_validator("DATABASE_URL", mode="before")
    @classmethod
    def assemble_db_connection(cls, v: str) -> str:
        if isinstance(v, str) and v.startswith("postgres://"):
            return v.replace("postgres://", "postgresql://", 1)
        return v

    # AI Integration
    AI_PROVIDER: str = "gemini"
    GEMINI_API_KEY: str = Field(default="", description="Google Gemini API Key")
    GEMINI_MODEL: str = "gemini-1.5-flash"
    
    OPENAI_API_KEY: str = Field(default="", description="Optional OpenAI API Key for fallback")
    OPENAI_MODEL: str = "gpt-4o-mini"

    # Showmates API
    SHOWMATES_API_URL: str = "https://api.showmates.in/v1/events"
    SHOWMATES_API_KEY: str = ""
    SHOWMATES_TIMEOUT_SECONDS: float = 15.0

    # CORS
    CORS_ALLOWED_ORIGINS: str = (
        "http://localhost:3000,http://localhost:5000,http://localhost:8000,"
        "https://vibemynight.in,https://www.vibemynight.in,https://vibemynight.vercel.app,https://vibemynight.up.railway.app"
    )

    @property
    def cors_origins_list(self) -> List[str]:
        if not self.CORS_ALLOWED_ORIGINS:
            return ["*"]
        return [origin.strip() for origin in self.CORS_ALLOWED_ORIGINS.split(",") if origin.strip()]


settings = Settings()
