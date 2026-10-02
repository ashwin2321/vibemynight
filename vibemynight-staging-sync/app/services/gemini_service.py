import json
import logging
import re
from abc import ABC, abstractmethod
from typing import Optional, Dict, Any, Tuple, List
import httpx
from app.config import settings
from app.schemas.staging_event import AIEnhancedPayload

logger = logging.getLogger(__name__)


SYSTEM_PROMPT = """You are an elite event marketing and nightlife copywriter for 'VibeMyNight' (https://vibemynight.in), Gujarat's premier event discovery and pass ticketing platform.

Your task is to take raw event details and enhance them into high-converting, engaging marketing copy, tags, and WhatsApp teasers while maintaining STRICT FACTUAL INTEGRITY.

STRICT FACTUAL RULES:
1. Emphasize the STAR ARTISTS, HEADLINERS, VENUE, and authentic Navratri Garba / Dandiya experience.
2. DO NOT invent facts or artists not present in the input.
3. If artists are present in additional context, feature them prominently in the enhanced title (e.g., 'United Way of Baroda Garba ft. Atul Purohit') and description.
4. Keep all marketing claims grounded in authentic Gujarati festival culture.
5. Return ONLY a valid JSON object matching the exact schema below. Do not wrap in markdown or explain your reasoning.

TARGET JSON SCHEMA:
{
  "enhancedTitle": "Catchy, polished event title with artist/headliner name",
  "catchyDescription": "High-energy 2-3 paragraph marketing description highlighting artists, atmosphere, facilities, and why attendees must not miss it.",
  "highlights": ["Key feature 1", "Key feature 2", "Key feature 3", "Key feature 4"],
  "genreTags": ["Genre/Vibe tag 1", "Genre/Vibe tag 2"],
  "whatsAppTeaser": "🔥 Punchy 1-line WhatsApp share teaser with artist mention and call to action",
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
            fallback = FallbackRuleBasedProvider()
            return await fallback.enhance_event(title, description, venue, city, start_date, raw_info)

        user_content = (
            f"Event Title: {title}\n"
            f"Description: {description or 'N/A'}\n"
            f"Venue: {venue or 'N/A'}\n"
            f"City: {city or 'N/A'}\n"
            f"Date: {start_date or 'N/A'}\n"
        )
        if raw_info:
            user_content += f"Additional Details & Artists: {json.dumps(raw_info, default=str)[:1000]}\n"

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
                
                if response.status_code != 200:
                    logger.warning(
                        f"Gemini API returned HTTP {response.status_code} ({response.text[:200]}). Falling back to rule-based engine."
                    )
                    fallback = FallbackRuleBasedProvider()
                    return await fallback.enhance_event(
                        title=title,
                        description=description,
                        venue=venue,
                        city=city,
                        start_date=start_date,
                        raw_info=raw_info,
                    )

                res_json = response.json()
                candidates = res_json.get("candidates", [])
                if not candidates:
                    fallback = FallbackRuleBasedProvider()
                    return await fallback.enhance_event(title, description, venue, city, start_date, raw_info)

                parts = candidates[0].get("content", {}).get("parts", [])
                if not parts:
                    fallback = FallbackRuleBasedProvider()
                    return await fallback.enhance_event(title, description, venue, city, start_date, raw_info)

                raw_text = parts[0].get("text", "")
                parsed_dict = self._extract_json_from_text(raw_text)
                if not parsed_dict:
                    fallback = FallbackRuleBasedProvider()
                    return await fallback.enhance_event(title, description, venue, city, start_date, raw_info)

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
    """Deterministic fallback provider that generates rich structured tags, artist highlights and teasers."""

    async def enhance_event(
        self,
        title: str,
        description: Optional[str] = None,
        venue: Optional[str] = None,
        city: Optional[str] = None,
        start_date: Optional[str] = None,
        raw_info: Optional[Dict[str, Any]] = None
    ) -> Tuple[Optional[AIEnhancedPayload], Optional[str]]:
        raw_info = raw_info or {}
        artists: List[Dict[str, Any]] = raw_info.get("artists") or []
        artist_names = [a.get("name") for a in artists if isinstance(a, dict) and a.get("name")]
        
        enhanced_title = title
        if artist_names:
            enhanced_title = f"{title} ft. {', '.join(artist_names)}"

        genres = ["Navratri Garba", "Traditional Folk"]
        lower_t = (title + " " + (description or "")).lower()
        if "ac dome" in lower_t or "dome" in lower_t:
            genres.append("AC Dome Experience")
        if "resort" in lower_t or "luxury" in lower_t:
            genres.append("Luxury Experience")
        if "concert" in lower_t or "dhol" in lower_t:
            genres.append("Live Dhol & Percussion")

        highlights: List[str] = []
        if artist_names:
            highlights.append(f"⭐ Star Headliner: {', '.join(artist_names)}")
        if venue:
            highlights.append(f"📍 Premier Venue: {venue}")
        if city:
            highlights.append(f"🌆 City: {city}, Gujarat")
        
        facilities = raw_info.get("facilities") or []
        if facilities and isinstance(facilities, list):
            highlights.append(f"✨ Features: {', '.join(facilities[:3])}")
        else:
            highlights.append("✨ Instant QR Pass & WhatsApp Confirmation")
        
        highlights.append("🛡️ 100% Verified Entry on VibeMyNight")

        artist_mention = f" featuring {', '.join(artist_names)}" if artist_names else ""
        whats_app = f"🔥 {title}{artist_mention} | Official Passes now live on VibeMyNight! Book instantly on WhatsApp 👇"
        
        seo = [f"{title} passes", f"{city or 'Gujarat'} Navratri 2026", "VibeMyNight passes"]
        if artist_names:
            for an in artist_names:
                seo.append(f"{an} Garba passes 2026")

        desc = description or f"Join the grand celebration at {title}{artist_mention}. Experience non-stop authentic Garba, world-class sound, vibrant atmosphere, and hassle-free pass booking on VibeMyNight."

        payload = AIEnhancedPayload(
            enhancedTitle=enhanced_title,
            catchyDescription=desc,
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
