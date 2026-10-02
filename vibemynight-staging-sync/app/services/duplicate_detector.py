import logging
import re
from typing import Optional, Tuple
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_, func
from app.models.staging_event import StagingEvent, StagingEventStatus

logger = logging.getLogger(__name__)


class DuplicateDetector:
    """Detects duplicate events in the staging database deterministically."""

    @staticmethod
    def _clean_str_for_matching(text: Optional[str]) -> str:
        """Strips special characters and lowercases text for fuzzy-safe exact token matching."""
        if not text:
            return ""
        return re.sub(r'[^a-zA-Z0-9]', '', str(text)).lower()

    @classmethod
    def check_duplicate(
        cls,
        db: Session,
        source: str,
        source_event_id: str,
        title: str,
        venue_name: Optional[str] = None,
        event_start_date: Optional[str] = None,
        city: Optional[str] = None,
        exclude_id: Optional[int] = None
    ) -> Tuple[bool, Optional[int]]:
        """
        Evaluates whether an incoming event is a duplicate of an existing record.
        Returns (is_duplicate: bool, existing_event_id: Optional[int]).
        """
        # Rule 1: Exact Source + Source Event ID Match (Absolute priority)
        query1 = db.query(StagingEvent).filter(
            StagingEvent.source == source,
            StagingEvent.source_event_id == str(source_event_id)
        )
        if exclude_id:
            query1 = query1.filter(StagingEvent.id != exclude_id)
        
        match1 = query1.first()
        if match1:
            logger.info(f"Duplicate detected by source ID: {source}:{source_event_id} -> Matches ID {match1.id}")
            return True, match1.id

        # Rule 2: Multi-attribute composite match (Title + Date + Venue/City)
        if title and (event_start_date or venue_name or city):
            clean_title = cls._clean_str_for_matching(title)
            
            candidates_query = db.query(StagingEvent)
            if event_start_date:
                candidates_query = candidates_query.filter(StagingEvent.event_start_date == event_start_date)
            if city:
                candidates_query = candidates_query.filter(func.lower(StagingEvent.city) == city.lower())
            if exclude_id:
                candidates_query = candidates_query.filter(StagingEvent.id != exclude_id)

            candidates = candidates_query.all()
            for cand in candidates:
                cand_clean_title = cls._clean_str_for_matching(cand.title)
                # If titles match closely on the same date and city
                if clean_title and cand_clean_title and (clean_title in cand_clean_title or cand_clean_title in clean_title):
                    # Check venue if both have venues
                    if venue_name and cand.venue_name:
                        v1 = cls._clean_str_for_matching(venue_name)
                        v2 = cls._clean_str_for_matching(cand.venue_name)
                        if v1 in v2 or v2 in v1 or not v1 or not v2:
                            logger.info(f"Duplicate detected by composite metadata: '{title}' on {event_start_date} in {city} -> Matches ID {cand.id}")
                            return True, cand.id
                    else:
                        logger.info(f"Duplicate detected by title+date+city: '{title}' on {event_start_date} in {city} -> Matches ID {cand.id}")
                        return True, cand.id

        return False, None
