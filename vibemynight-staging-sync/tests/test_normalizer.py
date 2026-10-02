from app.services.event_normalizer import EventNormalizer


def test_normalize_date_formats():
    assert EventNormalizer.normalize_date("2026/10/05") == "2026-10-05"
    assert EventNormalizer.normalize_date("05-10-2026") == "2026-10-05"
    assert EventNormalizer.normalize_date("October 5, 2026") == "2026-10-05"
    assert EventNormalizer.normalize_date("2026-10-05T19:30:00Z") == "2026-10-05"
    assert EventNormalizer.normalize_date(None) is None
    assert EventNormalizer.normalize_date("invalid-date-string") is None


def test_normalize_time_formats():
    assert EventNormalizer.normalize_time("19:30") == "19:30"
    assert EventNormalizer.normalize_time("7:00 PM") == "19:00"
    assert EventNormalizer.normalize_time("8:30 am") == "08:30"
    assert EventNormalizer.normalize_time("12:00 AM") == "00:00"
    assert EventNormalizer.normalize_time(None) is None


def test_normalize_city_names():
    assert EventNormalizer.normalize_city("ahmedabad") == "Ahmedabad"
    assert EventNormalizer.normalize_city("AMD") == "Ahmedabad"
    assert EventNormalizer.normalize_city("surat") == "Surat"
    assert EventNormalizer.normalize_city("baroda") == "Vadodara"
    assert EventNormalizer.normalize_city("vadodara") == "Vadodara"
    assert EventNormalizer.normalize_city("rajkot") == "Rajkot"
    assert EventNormalizer.normalize_city(None) is None


def test_normalize_prices():
    min_p, max_p, curr = EventNormalizer.normalize_prices("₹499", "1999", "inr")
    assert min_p == 499.0
    assert max_p == 1999.0
    assert curr == "INR"

    # Inverted order auto-fix
    min_p, max_p, _ = EventNormalizer.normalize_prices(2500, 500)
    assert min_p == 500.0
    assert max_p == 2500.0

    # None cases
    min_p, max_p, curr = EventNormalizer.normalize_prices(None, None)
    assert min_p is None
    assert max_p is None
    assert curr == "INR"


def test_validate_url():
    assert EventNormalizer.validate_url("https://cdn.showmates.in/poster.webp") == "https://cdn.showmates.in/poster.webp"
    assert EventNormalizer.validate_url("http://example.com/img.png") == "http://example.com/img.png"
    assert EventNormalizer.validate_url("invalid-url") is None
    assert EventNormalizer.validate_url(None) is None
