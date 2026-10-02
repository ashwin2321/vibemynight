import re
import ipaddress
import urllib.parse
import logging
from typing import Optional, Tuple, Any
from dateutil import parser as date_parser

logger = logging.getLogger(__name__)

# Blocked hostnames for SSRF protection
BLOCKED_HOSTNAMES = {
    "localhost",
    "127.0.0.1",
    "0.0.0.0",
    "::1",
    "169.254.169.254",  # AWS/GCP/Cloud instance metadata
    "metadata.google.internal",
    "instance-data",
}


class EventNormalizer:
    """Utilities to clean, normalize, format, and secure external event data consistently."""

    @staticmethod
    def normalize_date(raw_date: Optional[str]) -> Optional[str]:
        """Converts varied date strings into ISO format (YYYY-MM-DD), supporting DD-MM-YYYY Indian formats."""
        if not raw_date or not str(raw_date).strip():
            return None
        
        raw = str(raw_date).strip()
        try:
            # Check ISO format first YYYY-MM-DD
            match_iso = re.match(r'^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})', raw)
            if match_iso:
                y, m, d = match_iso.groups()
                return f"{int(y):04d}-{int(m):02d}-{int(d):02d}"
            
            # Check DD-MM-YYYY format
            match_dmy = re.match(r'^(\d{1,2})[-/.](\d{1,2})[-/.](\d{4})', raw)
            if match_dmy:
                d, m, y = match_dmy.groups()
                return f"{int(y):04d}-{int(m):02d}-{int(d):02d}"

            parsed = date_parser.parse(raw, fuzzy=True, dayfirst=True)
            return parsed.strftime("%Y-%m-%d")
        except Exception as e:
            logger.debug(f"Could not parse date string '{raw}': {e}")
            return None

    @staticmethod
    def normalize_time(raw_time: Optional[str]) -> Optional[str]:
        """Normalizes varied time strings into 24-hour HH:MM format."""
        if not raw_time or not str(raw_time).strip():
            return None
        
        raw = str(raw_time).strip().upper()
        try:
            parsed = date_parser.parse(raw, fuzzy=True)
            return parsed.strftime("%H:%M")
        except Exception:
            # Match formats like 7:00 PM or 19:30
            match = re.search(r'(\d{1,2}):?(\d{2})?\s*(AM|PM)?', raw)
            if match:
                hour = int(match.group(1))
                minute = int(match.group(2)) if match.group(2) else 0
                meridiem = match.group(3)
                if meridiem == "PM" and hour < 12:
                    hour += 12
                elif meridiem == "AM" and hour == 12:
                    hour = 0
                return f"{hour:02d}:{minute:02d}"
            return None

    @staticmethod
    def normalize_string(text: Optional[str], title_case: bool = False) -> Optional[str]:
        """Cleans whitespace and optionally title-cases string fields."""
        if not text:
            return None
        cleaned = " ".join(str(text).split()).strip()
        if not cleaned:
            return None
        if title_case:
            return cleaned.title()
        return cleaned

    @staticmethod
    def normalize_city(city: Optional[str]) -> Optional[str]:
        """Normalizes city names standardizing common Gujarat/India cities without inventing defaults."""
        if not city:
            return None
        cleaned = " ".join(str(city).split()).strip()
        if not cleaned:
            return None
        canonical_map = {
            "ahmedabad": "Ahmedabad",
            "amd": "Ahmedabad",
            "surat": "Surat",
            "vadodara": "Vadodara",
            "baroda": "Vadodara",
            "rajkot": "Rajkot",
            "gandhinagar": "Gandhinagar",
            "mumbai": "Mumbai",
            "goa": "Goa",
            "pune": "Pune",
            "delhi": "Delhi",
            "delhi-ncr": "Delhi",
        }
        return canonical_map.get(cleaned.lower(), cleaned.title())

    @staticmethod
    def normalize_prices(
        raw_min: Any,
        raw_max: Any = None,
        default_currency: str = "INR"
    ) -> Tuple[Optional[float], Optional[float], str]:
        """Extracts and validates numeric minimum and maximum ticket prices without fabricating defaults."""
        def parse_price(val: Any) -> Optional[float]:
            if val is None:
                return None
            if isinstance(val, (int, float)):
                return float(val) if val >= 0 else None
            # Extract numeric from string e.g. "₹499 onwards"
            cleaned = re.sub(r'[^\d.]', '', str(val))
            if cleaned:
                try:
                    num = float(cleaned)
                    return num if num >= 0 else None
                except ValueError:
                    return None
            return None

        p_min = parse_price(raw_min)
        p_max = parse_price(raw_max) if raw_max is not None else p_min

        # Ensure min <= max if both are present
        if p_min is not None and p_max is not None and p_min > p_max:
            p_min, p_max = p_max, p_min

        currency = default_currency.upper().strip() if default_currency else "INR"
        return p_min, p_max, currency

    @staticmethod
    def validate_url(url: Optional[str]) -> Optional[str]:
        """
        Validates that a given URL is a syntactically valid and secure HTTP/HTTPS URL.
        Enforces SSRF Protection:
        - Blocks localhost, loopback (127.0.0.1, ::1), cloud metadata (169.254.169.254),
          and private IP addresses (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16).
        - Blocks non-HTTP protocols (file://, ftp://, gopher://).
        """
        if not url or not str(url).strip():
            return None
        trimmed = str(url).strip()
        
        try:
            parsed = urllib.parse.urlparse(trimmed)
            # Only allow http and https protocols
            if parsed.scheme.lower() not in ("http", "https"):
                logger.warning(f"SSRF Blocked: Invalid scheme '{parsed.scheme}' in URL '{trimmed}'")
                return None
            
            hostname = (parsed.hostname or "").lower().strip()
            if not hostname:
                return None

            # Block known local and metadata hostnames
            if hostname in BLOCKED_HOSTNAMES or hostname.endswith(".local") or hostname.endswith(".internal"):
                logger.warning(f"SSRF Blocked: Hostname '{hostname}' is restricted")
                return None

            # Check if hostname is an IP address and block private/reserved/loopback IPs
            try:
                ip_obj = ipaddress.ip_address(hostname)
                if (
                    ip_obj.is_private
                    or ip_obj.is_loopback
                    or ip_obj.is_link_local
                    or ip_obj.is_reserved
                    or ip_obj.is_multicast
                ):
                    logger.warning(f"SSRF Blocked: Private or restricted IP '{hostname}'")
                    return None
            except ValueError:
                # Not a literal IP address, standard hostname (e.g. showmates.in, cdn.district.in)
                pass

            return trimmed
        except Exception as e:
            logger.debug(f"URL validation error for '{trimmed}': {e}")
            return None
