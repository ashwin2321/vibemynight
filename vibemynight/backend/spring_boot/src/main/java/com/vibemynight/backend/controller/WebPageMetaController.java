package com.vibemynight.backend.controller;

import com.vibemynight.backend.service.SeoService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@Slf4j
@RestController
@RequiredArgsConstructor
public class WebPageMetaController {

    private final SeoService seoService;

    private static final String SPA_FALLBACK_HTML =
            "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><meta http-equiv=\"refresh\" content=\"0; url=/\" /><title>VibeMyNight</title></head><body>Loading VibeMyNight...</body></html>";

    /**
     * Serves dynamic SEO HTML with Schema.org JSON-LD & OpenGraph tags for search engines, AI bots & social previews.
     */
    @GetMapping(value = {"/events/{slug}", "/events/{slug}/book", "/events/{slug}/passes"}, produces = MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> getEventSeoPreview(@PathVariable String slug, HttpServletRequest request) {
        if (!seoService.isCrawler(request)) {
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_TYPE, MediaType.TEXT_HTML_VALUE)
                    .body(SPA_FALLBACK_HTML);
        }

        try {
            String html = seoService.generateEventHtml(slug, request);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_TYPE, MediaType.TEXT_HTML_VALUE)
                    .body(html);
        } catch (Exception e) {
            log.warn("Failed to generate SEO preview for event slug {}: {}", slug, e.getMessage());
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_TYPE, MediaType.TEXT_HTML_VALUE)
                    .body(SPA_FALLBACK_HTML);
        }
    }

    /**
     * Serves dynamic SEO preview for Artist profiles.
     */
    @GetMapping(value = "/artists/{slug}", produces = MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> getArtistSeoPreview(@PathVariable String slug, HttpServletRequest request) {
        if (!seoService.isCrawler(request)) {
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_TYPE, MediaType.TEXT_HTML_VALUE)
                    .body(SPA_FALLBACK_HTML);
        }

        try {
            String html = seoService.generateArtistHtml(slug, request);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_TYPE, MediaType.TEXT_HTML_VALUE)
                    .body(html);
        } catch (Exception e) {
            log.warn("Failed to generate SEO preview for artist slug {}: {}", slug, e.getMessage());
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_TYPE, MediaType.TEXT_HTML_VALUE)
                    .body(SPA_FALLBACK_HTML);
        }
    }

    /**
     * Serves dynamic SEO preview for City landing pages.
     */
    @GetMapping(value = "/city/{city}", produces = MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> getCitySeoPreview(@PathVariable String city, HttpServletRequest request) {
        if (!seoService.isCrawler(request)) {
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_TYPE, MediaType.TEXT_HTML_VALUE)
                    .body(SPA_FALLBACK_HTML);
        }

        try {
            String html = seoService.generateCityHtml(city, request);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_TYPE, MediaType.TEXT_HTML_VALUE)
                    .body(html);
        } catch (Exception e) {
            log.warn("Failed to generate SEO preview for city {}: {}", city, e.getMessage());
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_TYPE, MediaType.TEXT_HTML_VALUE)
                    .body(SPA_FALLBACK_HTML);
        }
    }

    /**
     * Serves dynamic SEO preview for Category pages.
     */
    @GetMapping(value = "/category/{category}", produces = MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> getCategorySeoPreview(@PathVariable String category, HttpServletRequest request) {
        if (!seoService.isCrawler(request)) {
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_TYPE, MediaType.TEXT_HTML_VALUE)
                    .body(SPA_FALLBACK_HTML);
        }

        try {
            String html = seoService.generateCategoryHtml(category, request);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_TYPE, MediaType.TEXT_HTML_VALUE)
                    .body(html);
        } catch (Exception e) {
            log.warn("Failed to generate SEO preview for category {}: {}", category, e.getMessage());
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_TYPE, MediaType.TEXT_HTML_VALUE)
                    .body(SPA_FALLBACK_HTML);
        }
    }

    /**
     * XML Sitemap Index
     */
    @GetMapping(value = "/sitemap.xml", produces = MediaType.APPLICATION_XML_VALUE)
    public ResponseEntity<String> getMainSitemap() {
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_XML_VALUE)
                .body(seoService.generateMainSitemapXml());
    }

    /**
     * XML Sitemap for Events
     */
    @GetMapping(value = "/sitemap-events.xml", produces = MediaType.APPLICATION_XML_VALUE)
    public ResponseEntity<String> getEventsSitemap() {
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_XML_VALUE)
                .body(seoService.generateEventsSitemapXml());
    }

    /**
     * XML Sitemap for Artists
     */
    @GetMapping(value = "/sitemap-artists.xml", produces = MediaType.APPLICATION_XML_VALUE)
    public ResponseEntity<String> getArtistsSitemap() {
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_XML_VALUE)
                .body(seoService.generateArtistsSitemapXml());
    }

    /**
     * XML Sitemap for Cities
     */
    @GetMapping(value = "/sitemap-cities.xml", produces = MediaType.APPLICATION_XML_VALUE)
    public ResponseEntity<String> getCitiesSitemap() {
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_XML_VALUE)
                .body(seoService.generateCitiesSitemapXml());
    }

    /**
     * Dynamic robots.txt
     */
    @GetMapping(value = "/robots.txt", produces = MediaType.TEXT_PLAIN_VALUE)
    public ResponseEntity<String> getRobotsTxt() {
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_TYPE, MediaType.TEXT_PLAIN_VALUE)
                .body(seoService.generateRobotsTxt());
    }

    /**
     * Read-only JSON endpoint for event SEO inspection
     */
    @GetMapping(value = "/api/v1/seo/events/{slug}", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<Map<String, Object>> getEventSeoData(@PathVariable String slug) {
        return ResponseEntity.ok(seoService.getEventSeoData(slug));
    }

    /**
     * Read-only JSON endpoint for SEO engine health & stats
     */
    @GetMapping(value = "/api/v1/seo/health", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<Map<String, Object>> getSeoHealth() {
        return ResponseEntity.ok(seoService.getSeoHealth());
    }
}
