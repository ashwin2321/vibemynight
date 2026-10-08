package com.vibemynight.backend.service.impl;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vibemynight.backend.entity.*;
import com.vibemynight.backend.repository.ArtistRepository;
import com.vibemynight.backend.repository.EventRepository;
import jakarta.servlet.http.HttpServletRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpHeaders;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SeoServiceTest {

    @Mock
    private EventRepository eventRepository;

    @Mock
    private ArtistRepository artistRepository;

    @Spy
    private ObjectMapper objectMapper = new ObjectMapper();

    @InjectMocks
    private SeoServiceImpl seoService;

    @Mock
    private HttpServletRequest request;

    private Event mockEvent;
    private Artist mockArtist;

    @BeforeEach
    void setUp() {
        mockArtist = Artist.builder()
                .name("DJ Chetas")
                .slug("dj-chetas")
                .type(ArtistType.DJ)
                .shortBio("India's #1 Bollywood DJ")
                .photoUrl("https://assets.vibemynight.in/chetas.jpg")
                .featured(true)
                .build();
        mockArtist.setId(10L);

        TicketCategory tc = TicketCategory.builder()
                .name("Early Bird Pass")
                .type(TicketType.EARLY_BIRD)
                .price(new BigDecimal("499.00"))
                .availableQuantity(100)
                .status(ActiveStatus.ACTIVE)
                .build();

        EventDayArtist eda = EventDayArtist.builder()
                .artist(mockArtist)
                .isPrimary(true)
                .build();

        EventDay day = EventDay.builder()
                .dayNumber(1)
                .date(LocalDate.of(2026, 10, 12))
                .venue("YMCA Club")
                .ticketCategories(List.of(tc))
                .eventDayArtists(List.of(eda))
                .build();

        mockEvent = Event.builder()
                .name("Rangeelo Garba 2026")
                .slug("rangeelo-garba-2026")
                .mainImage("https://assets.vibemynight.in/rangeelo.jpg")
                .description("The premier heritage garba celebration in Ahmedabad.")
                .startDate(LocalDate.of(2026, 10, 12))
                .endDate(LocalDate.of(2026, 10, 21))
                .venue("YMCA International Club")
                .address("SG Highway")
                .city("Ahmedabad")
                .organizer("VibeMyNight Presents")
                .status(EventStatus.PUBLISHED)
                .eventDays(List.of(day))
                .highlights(List.of(EventHighlight.builder().text("Live Orchestra").build()))
                .rules(List.of(EventRule.builder().text("Traditional attire required").build()))
                .build();
        mockEvent.setId(1L);
    }

    @Test
    @DisplayName("isCrawler detects Googlebot, PerplexityBot, ChatGPT, WhatsApp and filters normal browsers")
    void testCrawlerDetection() {
        when(request.getHeader(HttpHeaders.USER_AGENT)).thenReturn("Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)");
        assertThat(seoService.isCrawler(request)).isTrue();

        when(request.getHeader(HttpHeaders.USER_AGENT)).thenReturn("PerplexityBot/1.0 (+https://www.perplexity.ai/bot)");
        assertThat(seoService.isCrawler(request)).isTrue();

        when(request.getHeader(HttpHeaders.USER_AGENT)).thenReturn("ChatGPT-User/1.0");
        assertThat(seoService.isCrawler(request)).isTrue();

        when(request.getHeader(HttpHeaders.USER_AGENT)).thenReturn("WhatsApp/2.21.12.21 A");
        assertThat(seoService.isCrawler(request)).isTrue();

        when(request.getHeader(HttpHeaders.USER_AGENT)).thenReturn("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36");
        assertThat(seoService.isCrawler(request)).isFalse();
    }

    @Test
    @DisplayName("generateEventHtml produces rich Schema.org JSON-LD, OpenGraph tags, and AI GEO summary block")
    void testGenerateEventHtml() {
        when(eventRepository.findBySlug("rangeelo-garba-2026")).thenReturn(Optional.of(mockEvent));

        String html = seoService.generateEventHtml("rangeelo-garba-2026", request);

        assertThat(html).contains("Rangeelo Garba 2026");
        assertThat(html).contains("https://www.vibemynight.in/events/rangeelo-garba-2026");
        assertThat(html).contains("application/ld+json");
        assertThat(html).contains("\"@type\" : \"MusicEvent\"");
        assertThat(html).contains("\"DJ Chetas\"");
        assertThat(html).contains("\"499\"");
        assertThat(html).contains("og:image");
        assertThat(html).contains("vmn-ai-geo-summary");
        assertThat(html).contains("Live Orchestra");
        assertThat(html).contains("Traditional attire required");
    }

    @Test
    @DisplayName("generateMainSitemapXml references all child sitemaps")
    void testMainSitemapXml() {
        String xml = seoService.generateMainSitemapXml();

        assertThat(xml).contains("<sitemapindex");
        assertThat(xml).contains("/sitemap-events.xml");
        assertThat(xml).contains("/sitemap-artists.xml");
        assertThat(xml).contains("/sitemap-cities.xml");
    }

    @Test
    @DisplayName("generateEventsSitemapXml lists published events and core routes")
    void testEventsSitemapXml() {
        when(eventRepository.findByStatus(EventStatus.PUBLISHED)).thenReturn(List.of(mockEvent));

        String xml = seoService.generateEventsSitemapXml();

        assertThat(xml).contains("<urlset");
        assertThat(xml).contains("https://www.vibemynight.in/");
        assertThat(xml).contains("https://www.vibemynight.in/events");
        assertThat(xml).contains("https://www.vibemynight.in/events/rangeelo-garba-2026");
        assertThat(xml).contains("<priority>0.9</priority>");
    }

    @Test
    @DisplayName("generateRobotsTxt allows search engines and disallows admin and auth")
    void testRobotsTxt() {
        String robots = seoService.generateRobotsTxt();

        assertThat(robots).contains("User-agent: *");
        assertThat(robots).contains("Allow: /events");
        assertThat(robots).contains("Disallow: /admin");
        assertThat(robots).contains("Disallow: /api/v1/admin");
        assertThat(robots).contains("Disallow: /api/v1/auth");
        assertThat(robots).contains("Sitemap: https://www.vibemynight.in/sitemap.xml");
    }

    @Test
    @DisplayName("getSeoHealth returns accurate stats")
    void testSeoHealth() {
        when(eventRepository.findByStatus(EventStatus.PUBLISHED)).thenReturn(List.of(mockEvent));
        when(artistRepository.findByStatus(ActiveStatus.ACTIVE)).thenReturn(List.of(mockArtist));

        Map<String, Object> health = seoService.getSeoHealth();

        assertThat(health.get("status")).isEqualTo("UP");
        assertThat(health.get("publishedEventsCount")).isEqualTo(1L);
        assertThat(health.get("activeArtistsCount")).isEqualTo(1L);
    }
}
