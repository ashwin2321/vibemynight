package com.vibemynight.backend.service.impl;

import com.vibemynight.backend.dto.importing.EventImportPreviewDto;
import com.vibemynight.backend.repository.ArtistRepository;
import com.vibemynight.backend.repository.EventRepository;
import com.vibemynight.backend.repository.FacilityRepository;
import com.vibemynight.backend.security.UrlSecurityValidator;
import com.vibemynight.backend.service.storage.FileStorageService;
import com.vibemynight.backend.util.SafeWebFetcher;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class EventScraperServiceTest {

    @Mock
    private SafeWebFetcher safeWebFetcher;

    @Mock
    private UrlSecurityValidator urlSecurityValidator;

    @Mock
    private EventRepository eventRepository;

    @Mock
    private ArtistRepository artistRepository;

    @Mock
    private FacilityRepository facilityRepository;

    @Mock
    private FileStorageService fileStorageService;

    private EventScraperServiceImpl scraperService;

    @BeforeEach
    void setUp() {
        scraperService = new EventScraperServiceImpl(
                safeWebFetcher,
                urlSecurityValidator,
                fileStorageService,
                eventRepository,
                artistRepository,
                facilityRepository
        );
    }

    @Test
    void testScrapeWithJsonLd() {
        String testUrl = "https://www.district.in/events/garba-night-2026";
        String html = "<!DOCTYPE html><html><head><script type=\"application/ld+json\">" +
                "{\"@context\":\"https://schema.org\",\"@type\":\"Event\"," +
                "\"name\":\"Garba Mahotsav 2026\"," +
                "\"description\":\"Grandest 9-night celebration with top artists in Ahmedabad.\"," +
                "\"startDate\":\"2026-10-15T20:00:00\"," +
                "\"endDate\":\"2026-10-24T02:00:00\"," +
                "\"image\":\"https://assets.district.in/posters/garba_vertical.jpg\"," +
                "\"location\":{\"@type\":\"Place\",\"name\":\"Swarnim Nagari Ground\",\"address\":\"SG Highway, Ahmedabad\"}," +
                "\"offers\":{\"@type\":\"Offer\",\"price\":\"499.00\",\"priceCurrency\":\"INR\"}}" +
                "</script></head><body></body></html>";

        when(urlSecurityValidator.extractAndCleanSingleUrl(anyString())).thenReturn(testUrl);
        when(safeWebFetcher.fetchHtml(testUrl)).thenReturn(html);
        when(eventRepository.existsBySlug(anyString())).thenReturn(false);

        EventImportPreviewDto preview = scraperService.scrapeEventFromUrl(testUrl);

        assertNotNull(preview);
        assertNotNull(preview.getEvent());
        assertEquals("Garba Mahotsav 2026", preview.getEvent().getName());
        assertEquals("Ahmedabad", preview.getEvent().getCity());
        assertEquals("Swarnim Nagari Ground", preview.getEvent().getVenue());
        assertTrue(preview.getTotalDays() >= 1);
        assertFalse(preview.isHasBlockingErrors());
    }

    @Test
    void testScrapeWithNextDataTree() {
        String testUrl = "https://showmates.in/events/swarnim-nagari-ac-dome-garba-2026";
        String html = "<!DOCTYPE html><html><head><script id=\"__NEXT_DATA__\" type=\"application/json\">" +
                "{\"props\":{\"pageProps\":{\"event\":{" +
                "\"title\":\"Swarnim Nagari AC Dome Garba 2026\"," +
                "\"description\":\"Experience non-stop garba beats inside 100% AC Dome.\"," +
                "\"startDate\":\"2026-10-11\"," +
                "\"endDate\":\"2026-10-20\"," +
                "\"venue\":\"Swarnim Nagari AC Dome, Sardar Patel Ring Rd\"," +
                "\"city\":\"Ahmedabad\"," +
                "\"verticalBanner\":\"https://images.showmates.in/dome_poster.webp\"," +
                "\"ticketCategories\":[" +
                "{\"name\":\"Season Pass Regular\",\"price\":\"1499\",\"quantity\":500,\"type\":\"REGULAR\"}," +
                "{\"name\":\"VIP Daily Pass\",\"price\":\"899\",\"quantity\":100,\"type\":\"VIP\"}" +
                "]," +
                "\"artists\":[" +
                "{\"name\":\"Aditya Gadhvi\"}," +
                "{\"name\":\"Geeta Rabari\"}" +
                "]}}}}</script></head><body></body></html>";

        when(urlSecurityValidator.extractAndCleanSingleUrl(anyString())).thenReturn(testUrl);
        when(safeWebFetcher.fetchHtml(testUrl)).thenReturn(html);
        when(eventRepository.existsBySlug(anyString())).thenReturn(false);

        EventImportPreviewDto preview = scraperService.scrapeEventFromUrl(testUrl);

        assertNotNull(preview);
        assertEquals("Swarnim Nagari AC Dome Garba 2026", preview.getEvent().getName());
        assertEquals("Ahmedabad", preview.getEvent().getCity());
        assertTrue(preview.getTotalPasses() >= 2);
        assertTrue(preview.getTotalArtists() >= 2);
    }

    @Test
    void testScrapeOpenGraphFallback() {
        String testUrl = "https://example.com/events/dj-night";
        String html = "<!DOCTYPE html><html><head>" +
                "<meta property=\"og:title\" content=\"Electric Neon Music Fest 2026\" />" +
                "<meta property=\"og:description\" content=\"Electrifying EDM party in Gandhinagar.\" />" +
                "<meta property=\"og:image\" content=\"https://example.com/images/edm_banner.jpg\" />" +
                "</head><body></body></html>";

        when(urlSecurityValidator.extractAndCleanSingleUrl(anyString())).thenReturn(testUrl);
        when(safeWebFetcher.fetchHtml(testUrl)).thenReturn(html);
        when(eventRepository.existsBySlug(anyString())).thenReturn(false);

        EventImportPreviewDto preview = scraperService.scrapeEventFromUrl(testUrl);

        assertNotNull(preview);
        assertEquals("Electric Neon Music Fest 2026", preview.getEvent().getName());
        assertEquals("Gandhinagar", preview.getEvent().getCity());
    }

    @Test
    void testScrapeMalformedHtmlNeverCrashes() {
        String testUrl = "https://example.com/events/empty";
        String html = "<html><body><!-- no meta tags --></body></html>";

        when(urlSecurityValidator.extractAndCleanSingleUrl(anyString())).thenReturn(testUrl);
        when(safeWebFetcher.fetchHtml(testUrl)).thenReturn(html);
        when(eventRepository.existsBySlug(anyString())).thenReturn(false);

        EventImportPreviewDto preview = scraperService.scrapeEventFromUrl(testUrl);

        assertNotNull(preview);
        assertNotNull(preview.getEvent());
        assertTrue(preview.getEvent().getName().length() > 0);
        assertTrue(preview.getTotalDays() >= 1);
    }
}