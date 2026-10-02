import json
import logging
import re
from abc import ABC, abstractmethod
from typing import Optional, Dict, Any, Tuple
import httpx
from app.config import settings
from app.schemas.staging_event import AIEnhancedPayload

logger = logging.getLogger(__name__)


SYSTEM_PROMPT = """You are an elite event marketing and nightlife copywriter for 'VibeMyNight' (https://vibemynight.in), Gujarat's premier event discovery and pass ticketing platform.

Your task is to take raw event details and enhance them into high-converting, engaging marketing copy, tags, and WhatsApp teasers while maintaining STRICT FACTUAL INTEGRITY.

STRICT FACTUAL RULES:
1. DO NOT invent or fabricate facts, artists, dates, venues, or ticket prices not provided in the raw input.
2. DO NOT change dates or timings unless explicitly provided.
3. Keep all marketing claims grounded in the actual event theme (e.g. Navratri Garba, Bollywood Concert, DJ Night, Techno/EDM).
4. Return ONLY a valid JSON object matching the exact schema below. Do not wrap in markdown or explain your reasoning.

TARGET JSON SCHEMA:
{
  "enhancedTitle": "Catchy, polished event title (e.g., 'SACHI NAVRATRI 2026 ft. Jigardan Gadhavi')",
  "catchyDescription": "High-energy 2-3 paragraph marketing description with bullet points highlighting why attendees must not miss this event.",
  "highlights": ["Key feature 1", "Key feature 2", "Key feature 3"],
  "genreTags": ["Genre/Vibe tag 1", "Genre/Vibe tag 2"],
  "whatsAppTeaser": "🔥 Punchy 1-line WhatsApp share teaser with emojis and call to action",
  "seoKeywords": ["keyword 1", "keyword 2", "keyword 3"]
}
"""


class AIService(ABC):
    """Abstract base class for AI enrichment providers."""
    
    @abstractmethod
    async def enhance_event(
        self,
        title: str,
        description: Optional[str] = None,
        venue: Optional[str] = None,
        city: Optional[str] = None,
        start_date: Optional[str] = None,
        raw_info: Optional[Dict[str, Any]] = None
    ) -> Tuple[Optional[AIEnhancedPayload], Optional[str]]:
        """Enhances raw event information and returns (Payload, ErrorString)."""
        pass


class GeminiProvider(AIService):
    """Google Gemini AI implementation using structured REST / SDK calls."""

    def __init__(self, api_key: Optional[str] = None, model: Optional[str] = None):
        self.api_key = api_key or settings.GEMINI_API_KEY
        self.model = model or settings.GEMINI_MODEL or "gemini-1.5-flash"

    def _extract_json_from_text(self, text: str) -> Optional[dict]:
        """Safely parses JSON out of raw model responses, cleaning markdown code blocks if present."""
        if not text:
            return None
        text = text.strip()
        # Remove markdown code fences if model enclosed JSON
        if text.startswith("```json"):
            text = text[7:]
        elif text.startswith("```"):
            text = text[3:]
        if text.endswith("```"):
            text = text[:-3]
        text = text.strip()

        try:
            return json.loads(text)
        except json.JSONDecodeError:
            # Fallback regex search for { ... }
            match = re.search(r'(\{[\s\S]*\})', text)
            if match:
                try:
                    return json.loads(match.group(1))
                except Exception:
                    return None
            return None

    async def enhance_event(
        self,
        title: str,
        description: Optional[str] = None,
        venue: Optional[str] = None,
        city: Optional[str] = None,
        start_date: Optional[str] = None,
        raw_info: Optional[Dict[str, Any]] = None
    ) -> Tuple[Optional[AIEnhancedPayload], Optional[str]]:
        if not self.api_key:
            return None, "GEMINI_API_KEY not configured"

        user_content = (
            f"Event Title: {title}\n"
            f"Description: {description or 'N/A'}\n"
            f"Venue: {venue or 'N/A'}\n"
            f"City: {city or 'N/A'}\n"
            f"Date: {start_date or 'N/A'}\n"
        )
        if raw_info:
            user_content += f"Additional Context: {json.dumps(raw_info, default=str)[:500]}\n"

        url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent?key={self.api_key}"
        
        payload = {
            "contents": [
                {
                    "role": "user",
                    "parts": [{"text": f"{SYSTEM_PROMPT}\n\nRAW EVENT DATA:\n{user_content}"}]
                }
            ],
            "generationConfig": {
                "temperature": 0.4,
                "responseMimeType": "application/json"
            }
        }

        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                response = await client.post(url, json=payload)
                
                if response.status_code == 429:
                    logger.warning("Gemini API rate limited (429)")
                    return None, "Rate limit exceeded (HTTP 429)"
                elif response.status_code == 400 or response.status_code == 403:
                    logger.warning("Gemini API authentication / parameter error")
                    return None, f"Gemini API error (HTTP {response.status_code})"
                elif response.status_code != 200:
                    logger.warning(f"Gemini API returned HTTP {response.status_code}")
                    return None, f"Gemini server error (HTTP {response.status_code})"

                res_json = response.json()
                candidates = res_json.get("candidates", [])
                if not candidates:
                    return None, "No candidates returned by Gemini"

                parts = candidates[0].get("content", {}).get("parts", [])
                if not parts:
                    return None, "Empty text in Gemini response"

                raw_text = parts[0].get("text", "")
                parsed_dict = self._extract_json_from_text(raw_text)
                if not parsed_dict:
                    return None, "Failed to parse structured JSON from Gemini output"

                # Validate with Pydantic
                enhanced = AIEnhancedPayload(
                    enhancedTitle=parsed_dict.get("enhancedTitle") or title,
                    catchyDescription=parsed_dict.get("catchyDescription") or description,
                    highlights=parsed_dict.get("highlights") or [],
                    genreTags=parsed_dict.get("genreTags") or [],
                    whatsAppTeaser=parsed_dict.get("whatsAppTeaser"),
                    seoKeywords=parsed_dict.get("seoKeywords") or []
                )
                return enhanced, None

        except httpx.TimeoutException:
            logger.warning("Gemini API request timed out after 15s")
            return None, "Gemini API request timed out"
        except Exception as e:
            logger.error(f"Unexpected error in Gemini enhancement: {e}")
            return None, f"AI processing error: {str(e)}"


class FallbackRuleBasedProvider(AIService):
    """Deterministic fallback provider that generates clean structured tags and teasers when AI key is absent."""

    async def enhance_event(
        self,
        title: str,
        description: Optional[str] = None,
        venue: Optional[str] = None,
        city: Optional[str] = None,
        start_date: Optional[str] = None,
        raw_info: Optional[Dict[str, Any]] = None
    ) -> Tuple[Optional[AIEnhancedPayload], Optional[str]]:
        enhanced_title = title.title()
        
        # Determine genres from title & description
        genres = []
        lower_t = (title + " " + (description or "")).lower()
        if "garba" in lower_t or "navratri" in lower_t:
            genres.extend(["Navratri Garba", "Traditional Folk"])
        if "dj" in lower_t or "concert" in lower_t or "night" in lower_t:
            genres.extend(["Live DJ Concert", "Nightlife"])
        if "ac dome" in lower_t or "dome" in lower_t:
            genres.append("AC Dome Experience")
        if not genres:
            genres = ["Live Entertainment", "Exclusive Passes"]

        highlights = []
        if venue:
            highlights.append(f"Premier Venue: {venue}")
        if city:
            highlights.append(f"Hosted in {city}")
        highlights.extend(["0% Convenience Fee on VibeMyNight", "Instant WhatsApp Pass Booking"])

        whats_app = f"🔥 {title} | Verified passes available on VibeMyNight! Book directly on WhatsApp 👇"
        seo = [f"{title} passes", f"{city or 'Gujarat'} events", "VibeMyNight passes"]

        payload = AIEnhancedPayload(
            enhancedTitle=enhanced_title,
            catchyDescription=description or f"Join the ultimate celebration at {title}. Experience premier artists, state-of-the-art production, and secure your passes directly on VibeMyNight.",
            highlights=highlights,
            genreTags=genres,
            whatsAppTeaser=whats_app,
            seoKeywords=seo
        )
        return payload, None


def get_ai_service() -> AIService:
    """Factory providing the configured AI enrichment engine."""
    if settings.GEMINI_API_KEY:
        return GeminiProvider()
    return FallbackRuleBasedProvider()
