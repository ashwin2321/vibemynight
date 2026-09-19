package com.vibemynight.backend.controller;

import com.vibemynight.backend.entity.Event;
import com.vibemynight.backend.service.EventService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.util.Locale;

@Slf4j
@RestController
@RequiredArgsConstructor
public class WebPageMetaController {

    private final EventService eventService;

    private static final String[] SOCIAL_CRAWLER_KEYWORDS = {
            "whatsapp", "facebookexternalhit", "facebot", "twitterbot",
            "telegrambot", "linkedinbot", "slackbot", "discordbot",
            "skypeuripreview", "googlebot", "bingbot"
    };

    private boolean isSocialCrawler(HttpServletRequest request) {
        String userAgent = request.getHeader(HttpHeaders.USER_AGENT);
        if (userAgent == null) {
            return false;
        }
        String ua = userAgent.toLowerCase(Locale.ROOT);
        for (String bot : SOCIAL_CRAWLER_KEYWORDS) {
            if (ua.contains(bot)) {
                return true;
            }
        }
        return false;
    }

    private String escapeHtml(String input) {
        if (input == null) return "";
        return input.replace("&", "&amp;")
                .replace("\"", "&quot;")
                .replace("<", "&lt;")
                .replace(">", "&gt;");
    }

    /**
     * Serves dynamic OpenGraph HTML tags for WhatsApp & Social Media link sharing.
     * When requested by a crawler (WhatsApp, Facebook, Twitter, Telegram, etc.),
     * it generates a complete HTML preview payload with og:title, og:description, and og:image.
     */
    @GetMapping(value = {"/events/{slug}", "/events/{slug}/book", "/events/{slug}/passes"}, produces = MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> getEventSocialPreview(@PathVariable String slug, HttpServletRequest request) {
        if (!isSocialCrawler(request)) {
            // Normal browser traffic will be handled by WebSpaConfig / static index.html fallback
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_TYPE, MediaType.TEXT_HTML_VALUE)
                    .body("<!DOCTYPE html><html><head><meta http-equiv=\"refresh\" content=\"0; url=/\" /></head><body>Loading VibeMyNight...</body></html>");
        }

        try {
            Event event = eventService.getBySlug(slug);

            String title = escapeHtml(event.getName() + " | VibeMyNight");
            String venue = event.getVenue() != null ? event.getVenue() : "Ahmedabad";
            String city = event.getCity() != null ? event.getCity() : "Ahmedabad";
            String dateRange = (event.getStartDate() != null ? event.getStartDate().toString() : "")
                    + (event.getEndDate() != null && !event.getEndDate().equals(event.getStartDate()) ? " to " + event.getEndDate().toString() : "");

            String description = escapeHtml(
                    (dateRange.isEmpty() ? "" : dateRange + " • ")
                            + venue + ", " + city
                            + ". Book verified passes with 0% convenience fees on VibeMyNight."
            );

            String imageUrl = event.getMainImage();
            if (imageUrl == null || imageUrl.isBlank()) {
                imageUrl = event.getThumbnail();
            }
            if (imageUrl == null || imageUrl.isBlank()) {
                imageUrl = event.getBanner();
            }
            if (imageUrl != null && imageUrl.startsWith("/")) {
                imageUrl = "https://vibemynight.onrender.com" + imageUrl;
            }
            if (imageUrl == null || imageUrl.isBlank()) {
                imageUrl = "https://vibemynight.com/favicon.png";
            }
            imageUrl = escapeHtml(imageUrl);

            String pageUrl = escapeHtml("https://vibemynight.com/events/" + slug);

            String html = "<!DOCTYPE html>\n" +
                    "<html lang=\"en\">\n" +
                    "<head>\n" +
                    "    <meta charset=\"UTF-8\">\n" +
                    "    <title>" + title + "</title>\n" +
                    "    <meta name=\"description\" content=\"" + description + "\">\n" +
                    "    <!-- OpenGraph / Facebook / WhatsApp -->\n" +
                    "    <meta property=\"og:type\" content=\"website\">\n" +
                    "    <meta property=\"og:url\" content=\"" + pageUrl + "\">\n" +
                    "    <meta property=\"og:title\" content=\"" + title + "\">\n" +
                    "    <meta property=\"og:description\" content=\"" + description + "\">\n" +
                    "    <meta property=\"og:image\" content=\"" + imageUrl + "\">\n" +
                    "    <meta property=\"og:image:secure_url\" content=\"" + imageUrl + "\">\n" +
                    "    <meta property=\"og:image:type\" content=\"image/jpeg\">\n" +
                    "    <meta property=\"og:image:width\" content=\"1200\">\n" +
                    "    <meta property=\"og:image:height\" content=\"630\">\n" +
                    "    <meta property=\"og:site_name\" content=\"VibeMyNight\">\n" +
                    "    <!-- Twitter -->\n" +
                    "    <meta name=\"twitter:card\" content=\"summary_large_image\">\n" +
                    "    <meta name=\"twitter:url\" content=\"" + pageUrl + "\">\n" +
                    "    <meta name=\"twitter:title\" content=\"" + title + "\">\n" +
                    "    <meta name=\"twitter:description\" content=\"" + description + "\">\n" +
                    "    <meta name=\"twitter:image\" content=\"" + imageUrl + "\">\n" +
                    "    <link rel=\"canonical\" href=\"" + pageUrl + "\">\n" +
                    "</head>\n" +
                    "<body>\n" +
                    "    <h1>" + title + "</h1>\n" +
                    "    <p>" + description + "</p>\n" +
                    "    <img src=\"" + imageUrl + "\" alt=\"" + title + "\">\n" +
                    "</body>\n" +
                    "</html>";

            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_TYPE, MediaType.TEXT_HTML_VALUE)
                    .body(html);

        } catch (Exception e) {
            log.warn("Failed to generate OpenGraph preview for slug {}: {}", slug, e.getMessage());
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_TYPE, MediaType.TEXT_HTML_VALUE)
                    .body("<!DOCTYPE html><html><head><title>VibeMyNight</title></head><body>VibeMyNight</body></html>");
        }
    }
}
