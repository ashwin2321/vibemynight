import pytest
from unittest.mock import AsyncMock, patch
from app.services.gemini_service import GeminiProvider, FallbackRuleBasedProvider, get_ai_service


@pytest.mark.asyncio
async def test_fallback_rule_based_provider():
    provider = FallbackRuleBasedProvider()
    payload, error = await provider.enhance_event(
        title="Royal Garba Night 2026",
        description="Great cultural garba night",
        venue="Royal Dome",
        city="Ahmedabad",
        start_date="2026-10-10"
    )
    assert error is None
    assert payload is not None
    assert "Garba" in payload.enhancedTitle
    assert any("Garba" in tag for tag in payload.genreTags)
    assert payload.whatsAppTeaser is not None
    assert "VibeMyNight" in payload.whatsAppTeaser


@pytest.mark.asyncio
async def test_gemini_json_extraction_with_markdown_fences():
    provider = GeminiProvider(api_key="mock_key")
    raw_response = """
    ```json
    {
      "enhancedTitle": "SACHI NAVRATRI 2026 | Jigardan Gadhavi",
      "catchyDescription": "Join Gujarat's elite celebration.",
      "highlights": ["AC Dome", "VIP Passes"],
      "genreTags": ["Traditional Garba", "Headliner"],
      "whatsAppTeaser": "🔥 Sachi Navratri passes live!",
      "seoKeywords": ["sachi garba", "ahmedabad garba"]
    }
    ```
    """
    extracted = provider._extract_json_from_text(raw_response)
    assert extracted is not None
    assert extracted["enhancedTitle"] == "SACHI NAVRATRI 2026 | Jigardan Gadhavi"
    assert len(extracted["highlights"]) == 2


@pytest.mark.asyncio
async def test_gemini_api_mock_success(monkeypatch):
    provider = GeminiProvider(api_key="mock_test_key")

    mock_gemini_response = {
        "candidates": [
            {
                "content": {
                    "parts": [
                        {
                            "text": '{"enhancedTitle": "Grand Garba 2026", "catchyDescription": "Awesome event", "highlights": ["VIP"], "genreTags": ["Folk"], "whatsAppTeaser": "Book now!", "seoKeywords": ["garba"]}'
                        }
                    ]
                }
            }
        ]
    }

    import httpx
    mock_resp = httpx.Response(200, json=mock_gemini_response, request=httpx.Request("POST", "https://mock"))

    with patch("httpx.AsyncClient.post", new_callable=AsyncMock) as mock_post:
        mock_post.return_value = mock_resp
        payload, error = await provider.enhance_event(
            title="Raw Garba Title",
            description="Raw desc",
            venue="Venue",
            city="Ahmedabad"
        )
        assert error is None
        assert payload is not None
        assert payload.enhancedTitle == "Grand Garba 2026"
        assert payload.genreTags == ["Folk"]


@pytest.mark.asyncio
async def test_gemini_api_timeout_handling():
    provider = GeminiProvider(api_key="mock_test_key")

    with patch("httpx.AsyncClient.post", side_effect=Exception("Connection timed out")):
        payload, error = await provider.enhance_event(
            title="Raw Garba Title",
            description="Raw desc"
        )
        assert payload is None
        assert error is not None
        assert "timed out" in error.lower() or "error" in error.lower()
