package com.vibemynight.backend.service.impl;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vibemynight.backend.entity.ActiveStatus;
import com.vibemynight.backend.entity.Artist;
import com.vibemynight.backend.entity.Event;
import com.vibemynight.backend.entity.EventDay;
import com.vibemynight.backend.entity.EventDayArtist;
import com.vibemynight.backend.entity.EventHighlight;
import com.vibemynight.backend.entity.EventRule;
import com.vibemynight.backend.entity.EventStatus;
import com.vibemynight.backend.entity.TicketCategory;
import com.vibemynight.backend.exception.ResourceNotFoundException;
import com.vibemynight.backend.repository.ArtistRepository;
import com.vibemynight.backend.repository.EventRepository;
import com.vibemynight.backend.service.SeoService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class SeoServiceImpl implements SeoService {

    private final EventRepository eventRepository;
    private final ArtistRepository artistRepository;
    private final ObjectMapper objectMapper;

    private static final String BASE_URL = "https://www.vibemynight.in";
    private static final String DEFAULT_IMAGE = "https://www.vibemynight.in/favicon.png";
    private static final String DEFAULT_CITY = "Ahmedabad";

    private static final String[] CRAWLER_KEYWORDS = {
            "googlebot", "bingbot", "slurp", "duckduckbot", "baiduspider",
            "yandexbot", "sogou", "ia_archiver", "perplexitybot", "chatgpt-user",
            "gptbot", "claudebot", "amazonbot", "google-inspectiontool", "applebot",
            "whatsapp", "facebookexternalhit", "facebot", "twitterbot",
            "telegrambot", "linkedinbot", "slackbot", "discordbot",
            "skypeuripreview", "pinterestbot", "vkshare", "quora", "outbrain",
            "embedly", "bitlybot"
    };

    @Override
    public boolean isCrawler(HttpServletRequest request) {
        if (request == null) return false;
        String userAgent = request.getHeader(HttpHeaders.USER_AGENT);
        if (userAgent == null || userAgent.isBlank()) return false;
        String ua = userAgent.toLowerCase(Locale.ROOT);
        for (String bot : CRAWLER_KEYWORDS) {
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

    private String resolveImageUrl(String url) {
        if (url == null || url.isBlank()) return DEFAULT_IMAGE;
        if (url.startsWith("/")) {
            return "https://vibemynight.onrender.com" + url;
        }
        return url;
    }

    private String formatDate(LocalDate date) {
        if (date == null) return "";
        return date.format(DateTimeFormatter.ofPattern("d MMMM yyyy"));
    }

    @Override
    @Transactional(readOnly = true)
    public String generateEventHtml(String slug, HttpServletRequest request) {
        Event event = eventRepository.findBySlug(slug)
                .or(() -> {
                    try {
                        Long id = Long.parseLong(slug);
                        return eventRepository.findById(id);
                    } catch (NumberFormatException ignored) {
                        return Optional.empty();
                    }
                })
                .orElseThrow(() -> new ResourceNotFoundException("Event not found for SEO: " + slug));

        // Resolve dates
        LocalDate startDate = event.getStartDate();
        LocalDate endDate = event.getEndDate();
        String dateString = formatDate(startDate);
        if (endDate != null && !endDate.equals(startDate)) {
            dateString += " - " + formatDate(endDate);
        }

        // Venue & Location
        String venue = event.getVenue() != null && !event.getVenue().isBlank() ? event.getVenue() : "VibeMyNight Partner Venue";
        String city = event.getCity() != null && !event.getCity().isBlank() ? event.getCity() : DEFAULT_CITY;
        String address = event.getAddress() != null && !event.getAddress().isBlank() ? event.getAddress() : (event.getLocation() != null ? event.getLocation() : city);

        // Images
        String imageUrl = event.getMainImage();
        if (imageUrl == null || imageUrl.isBlank()) imageUrl = event.getThumbnail();
        if (imageUrl == null || imageUrl.isBlank()) imageUrl = event.getBanner();
        imageUrl = resolveImageUrl(imageUrl);

        // Collect Tickets & Pricing
        List<TicketCategory> allTickets = new ArrayList<>();
        List<Artist> allArtists = new ArrayList<>();
        Set<Long> seenArtistIds = new HashSet<>();

        if (event.getEventDays() != null) {
            for (EventDay day : event.getEventDays()) {
                if (day.getTicketCategories() != null) {
                    for (TicketCategory tc : day.getTicketCategories()) {
                        if (tc.getStatus() == ActiveStatus.ACTIVE) {
                            allTickets.add(tc);
                        }
                    }
                }
                if (day.getEventDayArtists() != null) {
                    for (EventDayArtist eda : day.getEventDayArtists()) {
                        if (eda.getArtist() != null && seenArtistIds.add(eda.getArtist().getId())) {
                            allArtists.add(eda.getArtist());
                        }
                    }
                }
            }
        }

        BigDecimal minPrice = null;
        BigDecimal maxPrice = null;
        for (TicketCategory tc : allTickets) {
            if (tc.getPrice() != null) {
                if (minPrice == null || tc.getPrice().compareTo(minPrice) < 0) {
                    minPrice = tc.getPrice();
                }
                if (maxPrice == null || tc.getPrice().compareTo(maxPrice) > 0) {
                    maxPrice = tc.getPrice();
                }
            }
        }

        String priceSummary = minPrice != null ? "₹" + minPrice.stripTrailingZeros().toPlainString() : "Free / Registration Required";
        if (minPrice != null && maxPrice != null && minPrice.compareTo(maxPrice) < 0) {
            priceSummary = "₹" + minPrice.stripTrailingZeros().toPlainString() + " - ₹" + maxPrice.stripTrailingZeros().toPlainString();
        }

        String artistNames = allArtists.stream().map(Artist::getName).collect(Collectors.joining(", "));

        // SEO Title & Description
        String title = event.getName() + " | Passes, Venue & Schedule | VibeMyNight";
        StringBuilder descBuilder = new StringBuilder();
        descBuilder.append("Book official passes for ").append(event.getName());
        if (!dateString.isBlank()) descBuilder.append(" on ").append(dateString);
        descBuilder.append(" at ").append(venue).append(", ").append(city).append(".");
        if (!artistNames.isBlank()) descBuilder.append(" Featuring ").append(artistNames).append(".");
        if (minPrice != null) descBuilder.append(" Passes from ₹").append(minPrice.stripTrailingZeros().toPlainString()).append(" with 0% booking fee.");
        String description = descBuilder.toString();

        String canonicalUrl = BASE_URL + "/events/" + event.getSlug();

        // Build Schema.org JSON-LD
        Map<String, Object> schemaMap = new LinkedHashMap<>();
        schemaMap.put("@context", "https://schema.org");
        schemaMap.put("@type", allArtists.isEmpty() ? "Event" : "MusicEvent");
        schemaMap.put("name", event.getName());
        schemaMap.put("url", canonicalUrl);
        schemaMap.put("description", event.getDescription() != null && !event.getDescription().isBlank() ? event.getDescription() : description);
        schemaMap.put("image", List.of(imageUrl));
        if (startDate != null) schemaMap.put("startDate", startDate.toString());
        if (endDate != null) schemaMap.put("endDate", endDate.toString());
        schemaMap.put("eventStatus", "https://schema.org/EventScheduled");
        schemaMap.put("eventAttendanceMode", "https://schema.org/OfflineEventAttendanceMode");

        Map<String, Object> placeMap = new LinkedHashMap<>();
        placeMap.put("@type", "Place");
        placeMap.put("name", venue);
        Map<String, Object> addressMap = new LinkedHashMap<>();
        addressMap.put("@type", "PostalAddress");
        addressMap.put("streetAddress", address);
        addressMap.put("addressLocality", city);
        addressMap.put("addressRegion", "Gujarat");
        addressMap.put("addressCountry", "IN");
        placeMap.put("address", addressMap);
        schemaMap.put("location", placeMap);

        Map<String, Object> orgMap = new LinkedHashMap<>();
        orgMap.put("@type", "Organization");
        orgMap.put("name", event.getOrganizer() != null && !event.getOrganizer().isBlank() ? event.getOrganizer() : "VibeMyNight");
        orgMap.put("url", BASE_URL);
        schemaMap.put("organizer", orgMap);

        if (!allArtists.isEmpty()) {
            List<Map<String, Object>> performers = new ArrayList<>();
            for (Artist a : allArtists) {
                Map<String, Object> p = new LinkedHashMap<>();
                p.put("@type", "Person");
                p.put("name", a.getName());
                if (a.getSlug() != null) p.put("url", BASE_URL + "/artists/" + a.getSlug());
                performers.add(p);
            }
            schemaMap.put("performer", performers);
        }

        if (!allTickets.isEmpty()) {
            List<Map<String, Object>> offers = new ArrayList<>();
            for (TicketCategory tc : allTickets) {
                Map<String, Object> offer = new LinkedHashMap<>();
                offer.put("@type", "Offer");
                offer.put("name", tc.getName());
                offer.put("price", tc.getPrice() != null ? tc.getPrice().stripTrailingZeros().toPlainString() : "0.00");
                offer.put("priceCurrency", "INR");
                offer.put("url", canonicalUrl);
                offer.put("availability", (tc.getAvailableQuantity() != null && tc.getAvailableQuantity() > 0)
                        ? "https://schema.org/InStock" : "https://schema.org/SoldOut");
                if (startDate != null) offer.put("validFrom", startDate.toString());
                offers.add(offer);
            }
            schemaMap.put("offers", offers);
        }

        // BreadcrumbList schema
        Map<String, Object> breadcrumbSchema = new LinkedHashMap<>();
        breadcrumbSchema.put("@context", "https://schema.org");
        breadcrumbSchema.put("@type", "BreadcrumbList");
        List<Map<String, Object>> itemList = new ArrayList<>();
        itemList.add(Map.of("@type", "ListItem", "position", 1, "name", "Home", "item", BASE_URL));
        itemList.add(Map.of("@type", "ListItem", "position", 2, "name", "Events", "item", BASE_URL + "/events"));
        itemList.add(Map.of("@type", "ListItem", "position", 3, "name", event.getName(), "item", canonicalUrl));
        breadcrumbSchema.put("itemListElement", itemList);

        String jsonLdString = "";
        String breadcrumbJsonLd = "";
        try {
            jsonLdString = objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(schemaMap);
            breadcrumbJsonLd = objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(breadcrumbSchema);
        } catch (Exception e) {
            log.error("Failed to serialize JSON-LD schema for event {}: {}", slug, e.getMessage());
        }

        // Build Server-Rendered Semantic HTML Body
        StringBuilder html = new StringBuilder();
        html.append("<!DOCTYPE html>\n");
        html.append("<html lang=\"en\">\n");
        html.append("<head>\n");
        html.append("    <meta charset=\"UTF-8\">\n");
        html.append("    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n");
        html.append("    <title>").append(escapeHtml(title)).append("</title>\n");
        html.append("    <meta name=\"description\" content=\"").append(escapeHtml(description)).append("\">\n");
        html.append("    <link rel=\"canonical\" href=\"").append(escapeHtml(canonicalUrl)).append("\">\n");
        html.append("    <meta name=\"robots\" content=\"index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1\">\n");
        html.append("    <!-- OpenGraph / Facebook / WhatsApp -->\n");
        html.append("    <meta property=\"og:type\" content=\"website\">\n");
        html.append("    <meta property=\"og:url\" content=\"").append(escapeHtml(canonicalUrl)).append("\">\n");
        html.append("    <meta property=\"og:title\" content=\"").append(escapeHtml(title)).append("\">\n");
        html.append("    <meta property=\"og:description\" content=\"").append(escapeHtml(description)).append("\">\n");
        html.append("    <meta property=\"og:image\" content=\"").append(escapeHtml(imageUrl)).append("\">\n");
        html.append("    <meta property=\"og:image:secure_url\" content=\"").append(escapeHtml(imageUrl)).append("\">\n");
        html.append("    <meta property=\"og:site_name\" content=\"VibeMyNight\">\n");
        html.append("    <!-- Twitter / X Cards -->\n");
        html.append("    <meta name=\"twitter:card\" content=\"summary_large_image\">\n");
        html.append("    <meta name=\"twitter:url\" content=\"").append(escapeHtml(canonicalUrl)).append("\">\n");
        html.append("    <meta name=\"twitter:title\" content=\"").append(escapeHtml(title)).append("\">\n");
        html.append("    <meta name=\"twitter:description\" content=\"").append(escapeHtml(description)).append("\">\n");
        html.append("    <meta name=\"twitter:image\" content=\"").append(escapeHtml(imageUrl)).append("\">\n");
        html.append("    <!-- JSON-LD Structured Data -->\n");
        html.append("    <script type=\"application/ld+json\">\n").append(jsonLdString).append("\n    </script>\n");
        html.append("    <script type=\"application/ld+json\">\n").append(breadcrumbJsonLd).append("\n    </script>\n");
        html.append("    <style>\n");
        html.append("        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif; line-height: 1.6; color: #1e293b; background: #0f172a; margin: 0; padding: 20px; }\n");
        html.append("        .vmn-container { max-width: 800px; margin: 0 auto; background: #ffffff; border-radius: 16px; padding: 32px; box-shadow: 0 10px 25px rgba(0,0,0,0.3); }\n");
        html.append("        h1 { color: #0f172a; margin-top: 0; font-size: 28px; }\n");
        html.append("        .vmn-meta-badge { display: inline-block; background: #e0e7ff; color: #4338ca; font-weight: 600; padding: 4px 12px; border-radius: 20px; font-size: 14px; margin-bottom: 16px; }\n");
        html.append("        .vmn-hero-img { width: 100%; max-height: 420px; object-fit: cover; border-radius: 12px; margin-bottom: 24px; }\n");
        html.append("        .vmn-info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 24px; }\n");
        html.append("        .vmn-info-card { background: #f8fafc; padding: 16px; border-radius: 8px; border: 1px solid #e2e8f0; }\n");
        html.append("        .vmn-info-card strong { display: block; color: #64748b; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; }\n");
        html.append("        .vmn-info-card span { font-size: 16px; font-weight: 600; color: #0f172a; }\n");
        html.append("        .vmn-btn { display: inline-block; background: #4f46e5; color: #ffffff; font-weight: 700; padding: 14px 28px; border-radius: 8px; text-decoration: none; margin-top: 16px; text-align: center; }\n");
        html.append("        .vmn-btn:hover { background: #4338ca; }\n");
        html.append("        table { width: 100%; border-collapse: collapse; margin-top: 12px; }\n");
        html.append("        th, td { text-align: left; padding: 10px; border-bottom: 1px solid #e2e8f0; }\n");
        html.append("        th { background: #f1f5f9; color: #475569; font-size: 13px; }\n");
        html.append("        .vmn-ai-geo-summary { background: #fdf4ff; border: 1px solid #f0abfc; padding: 20px; border-radius: 8px; margin-top: 32px; }\n");
        html.append("        .vmn-ai-geo-summary h2 { font-size: 18px; color: #86198f; margin-top: 0; }\n");
        html.append("        dl { display: grid; grid-template-columns: 140px 1fr; gap: 8px; margin: 0; font-size: 14px; }\n");
        html.append("        dt { font-weight: 600; color: #701a75; }\n");
        html.append("        dd { margin: 0; color: #3b0764; }\n");
        html.append("    </style>\n");
        html.append("</head>\n");
        html.append("<body>\n");
        html.append("<main class=\"vmn-container\">\n");
        html.append("    <span class=\"vmn-meta-badge\">Verified Event • 0% Convenience Fee</span>\n");
        html.append("    <h1>").append(escapeHtml(event.getName())).append("</h1>\n");
        html.append("    <img class=\"vmn-hero-img\" src=\"").append(escapeHtml(imageUrl)).append("\" alt=\"").append(escapeHtml(event.getName())).append("\">\n");

        html.append("    <div class=\"vmn-info-grid\">\n");
        html.append("        <div class=\"vmn-info-card\">\n");
        html.append("            <strong>Date & Schedule</strong>\n");
        html.append("            <time><span>").append(escapeHtml(dateString.isBlank() ? "To Be Announced" : dateString)).append("</span></time>\n");
        html.append("        </div>\n");
        html.append("        <div class=\"vmn-info-card\">\n");
        html.append("            <strong>Venue & City</strong>\n");
        html.append("            <address><span>").append(escapeHtml(venue)).append(", ").append(escapeHtml(city)).append("</span></address>\n");
        html.append("        </div>\n");
        html.append("        <div class=\"vmn-info-card\">\n");
        html.append("            <strong>Starting Price</strong>\n");
        html.append("            <span>").append(escapeHtml(priceSummary)).append("</span>\n");
        html.append("        </div>\n");
        html.append("        <div class=\"vmn-info-card\">\n");
        html.append("            <strong>Organizer</strong>\n");
        html.append("            <span>").append(escapeHtml(event.getOrganizer() != null ? event.getOrganizer() : "VibeMyNight")).append("</span>\n");
        html.append("        </div>\n");
        html.append("    </div>\n");

        if (event.getDescription() != null && !event.getDescription().isBlank()) {
            html.append("    <section>\n");
            html.append("        <h2>About The Event</h2>\n");
            html.append("        <p>").append(escapeHtml(event.getDescription())).append("</p>\n");
            html.append("    </section>\n");
        }

        if (!allArtists.isEmpty()) {
            html.append("    <section>\n");
            html.append("        <h2>Featured Artists & Lineup</h2>\n");
            html.append("        <p>").append(escapeHtml(artistNames)).append("</p>\n");
            html.append("    </section>\n");
        }

        if (!allTickets.isEmpty()) {
            html.append("    <section>\n");
            html.append("        <h2>Pass Categories & Pricing</h2>\n");
            html.append("        <table>\n");
            html.append("            <thead><tr><th>Category</th><th>Price</th><th>Availability</th></tr></thead>\n");
            html.append("            <tbody>\n");
            for (TicketCategory tc : allTickets) {
                html.append("                <tr>\n");
                html.append("                    <td><strong>").append(escapeHtml(tc.getName())).append("</strong></td>\n");
                html.append("                    <td>₹").append(tc.getPrice() != null ? tc.getPrice().stripTrailingZeros().toPlainString() : "0").append("</td>\n");
                html.append("                    <td>").append((tc.getAvailableQuantity() != null && tc.getAvailableQuantity() > 0) ? "Available" : "Sold Out").append("</td>\n");
                html.append("                </tr>\n");
            }
            html.append("            </tbody>\n");
            html.append("        </table>\n");
            html.append("    </section>\n");
        }

        if (event.getHighlights() != null && !event.getHighlights().isEmpty()) {
            html.append("    <section>\n");
            html.append("        <h2>Event Highlights</h2>\n");
            html.append("        <ul>\n");
            for (EventHighlight h : event.getHighlights()) {
                html.append("            <li>").append(escapeHtml(h.getText())).append("</li>\n");
            }
            html.append("        </ul>\n");
            html.append("    </section>\n");
        }

        if (event.getRules() != null && !event.getRules().isEmpty()) {
            html.append("    <section>\n");
            html.append("        <h2>Guidelines & Rules</h2>\n");
            html.append("        <ul>\n");
            for (EventRule r : event.getRules()) {
                html.append("            <li>").append(escapeHtml(r.getText())).append("</li>\n");
            }
            html.append("        </ul>\n");
            html.append("    </section>\n");
        }

        // Dedicated AI Engine & GEO Knowledge Triples Block
        html.append("    <section class=\"vmn-ai-geo-summary\" aria-label=\"AI Search Fact Summary\">\n");
        html.append("        <h2>AI Answer & Search Overview</h2>\n");
        html.append("        <dl>\n");
        html.append("            <dt>Event Entity</dt><dd>").append(escapeHtml(event.getName())).append("</dd>\n");
        html.append("            <dt>Platform</dt><dd>VibeMyNight (0% Convenience Fee Pass Booking)</dd>\n");
        html.append("            <dt>Location</dt><dd>").append(escapeHtml(venue)).append(", ").append(escapeHtml(address)).append(", ").append(escapeHtml(city)).append(", Gujarat, India</dd>\n");
        html.append("            <dt>Dates</dt><dd>").append(escapeHtml(dateString.isBlank() ? "Scheduled" : dateString)).append("</dd>\n");
        html.append("            <dt>Pricing</dt><dd>").append(escapeHtml(priceSummary)).append("</dd>\n");
        if (!artistNames.isBlank()) {
            html.append("            <dt>Headliners</dt><dd>").append(escapeHtml(artistNames)).append("</dd>\n");
        }
        html.append("            <dt>Official Pass URL</dt><dd><a href=\"").append(escapeHtml(canonicalUrl)).append("\">").append(escapeHtml(canonicalUrl)).append("</a></dd>\n");
        html.append("        </dl>\n");
        html.append("    </section>\n");

        html.append("    <div style=\"text-align: center; margin-top: 24px;\">\n");
        html.append("        <a class=\"vmn-btn\" href=\"").append(escapeHtml(canonicalUrl)).append("\">Book Passes on VibeMyNight</a>\n");
        html.append("    </div>\n");

        html.append("</main>\n");
        html.append("</body>\n");
        html.append("</html>");

        return html.toString();
    }

    @Override
    @Transactional(readOnly = true)
    public String generateArtistHtml(String slug, HttpServletRequest request) {
        Artist artist = artistRepository.findBySlug(slug)
                .or(() -> {
                    try {
                        Long id = Long.parseLong(slug);
                        return artistRepository.findById(id);
                    } catch (NumberFormatException ignored) {
                        return Optional.empty();
                    }
                })
                .orElseThrow(() -> new ResourceNotFoundException("Artist not found for SEO: " + slug));

        String title = artist.getName() + " | Events, Passes & Tour Dates | VibeMyNight";
        String bio = artist.getShortBio() != null && !artist.getShortBio().isBlank()
                ? artist.getShortBio()
                : (artist.getFullBio() != null && !artist.getFullBio().isBlank() ? artist.getFullBio() : "Discover upcoming live events and book passes for " + artist.getName() + " on VibeMyNight.");
        String description = "Book passes to upcoming live events and performances by " + artist.getName() + " on VibeMyNight with 0% booking fees.";
        String imageUrl = resolveImageUrl(artist.getPhotoUrl());
        String canonicalUrl = BASE_URL + "/artists/" + (artist.getSlug() != null ? artist.getSlug() : artist.getId());

        Map<String, Object> schemaMap = new LinkedHashMap<>();
        schemaMap.put("@context", "https://schema.org");
        schemaMap.put("@type", "Person");
        schemaMap.put("name", artist.getName());
        schemaMap.put("url", canonicalUrl);
        schemaMap.put("description", bio);
        schemaMap.put("image", imageUrl);

        String jsonLd = "";
        try {
            jsonLd = objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(schemaMap);
        } catch (Exception ignored) {}

        StringBuilder html = new StringBuilder();
        html.append("<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n");
        html.append("    <meta charset=\"UTF-8\">\n");
        html.append("    <title>").append(escapeHtml(title)).append("</title>\n");
        html.append("    <meta name=\"description\" content=\"").append(escapeHtml(description)).append("\">\n");
        html.append("    <link rel=\"canonical\" href=\"").append(escapeHtml(canonicalUrl)).append("\">\n");
        html.append("    <meta property=\"og:title\" content=\"").append(escapeHtml(title)).append("\">\n");
        html.append("    <meta property=\"og:description\" content=\"").append(escapeHtml(description)).append("\">\n");
        html.append("    <meta property=\"og:image\" content=\"").append(escapeHtml(imageUrl)).append("\">\n");
        html.append("    <meta name=\"twitter:card\" content=\"summary_large_image\">\n");
        html.append("    <script type=\"application/ld+json\">\n").append(jsonLd).append("\n    </script>\n");
        html.append("</head>\n<body>\n");
        html.append("    <h1>").append(escapeHtml(artist.getName())).append("</h1>\n");
        html.append("    <p>").append(escapeHtml(bio)).append("</p>\n");
        html.append("    <a href=\"").append(escapeHtml(canonicalUrl)).append("\">View Artist Events on VibeMyNight</a>\n");
        html.append("</body>\n</html>");
        return html.toString();
    }

    @Override
    @Transactional(readOnly = true)
    public String generateCityHtml(String city, HttpServletRequest request) {
        String capitalizedCity = city.substring(0, 1).toUpperCase() + city.substring(1).toLowerCase();
        List<Event> cityEvents = eventRepository.findByStatus(EventStatus.PUBLISHED).stream()
                .filter(e -> e.getCity() != null && e.getCity().equalsIgnoreCase(city))
                .toList();

        String title = "Events & Nightlife in " + capitalizedCity + " | VibeMyNight";
        String description = "Discover the best upcoming concerts, garba nights, EDM parties, and festivals in " + capitalizedCity + ". Book verified passes with 0% convenience fees on VibeMyNight.";
        String canonicalUrl = BASE_URL + "/city/" + city.toLowerCase();

        StringBuilder html = new StringBuilder();
        html.append("<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n");
        html.append("    <meta charset=\"UTF-8\">\n");
        html.append("    <title>").append(escapeHtml(title)).append("</title>\n");
        html.append("    <meta name=\"description\" content=\"").append(escapeHtml(description)).append("\">\n");
        html.append("    <link rel=\"canonical\" href=\"").append(escapeHtml(canonicalUrl)).append("\">\n");
        html.append("</head>\n<body>\n");
        html.append("    <h1>Upcoming Events in ").append(escapeHtml(capitalizedCity)).append("</h1>\n");
        html.append("    <p>").append(escapeHtml(description)).append("</p>\n");
        html.append("    <ul>\n");
        for (Event e : cityEvents) {
            html.append("        <li><a href=\"").append(BASE_URL).append("/events/").append(escapeHtml(e.getSlug())).append("\">")
                    .append(escapeHtml(e.getName())).append("</a> - ").append(escapeHtml(formatDate(e.getStartDate()))).append("</li>\n");
        }
        html.append("    </ul>\n");
        html.append("</body>\n</html>");
        return html.toString();
    }

    @Override
    @Transactional(readOnly = true)
    public String generateCategoryHtml(String category, HttpServletRequest request) {
        String title = category.toUpperCase() + " Events & Passes | VibeMyNight";
        String description = "Browse top " + category + " events and concerts. Instant pass confirmation and 0% booking fees on VibeMyNight.";
        String canonicalUrl = BASE_URL + "/category/" + category.toLowerCase();

        StringBuilder html = new StringBuilder();
        html.append("<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n");
        html.append("    <meta charset=\"UTF-8\">\n");
        html.append("    <title>").append(escapeHtml(title)).append("</title>\n");
        html.append("    <meta name=\"description\" content=\"").append(escapeHtml(description)).append("\">\n");
        html.append("    <link rel=\"canonical\" href=\"").append(escapeHtml(canonicalUrl)).append("\">\n");
        html.append("</head>\n<body>\n");
        html.append("    <h1>").append(escapeHtml(category.toUpperCase())).append(" Events</h1>\n");
        html.append("    <p>").append(escapeHtml(description)).append("</p>\n");
        html.append("    <a href=\"").append(BASE_URL).append("/events\">Browse All Events</a>\n");
        html.append("</body>\n</html>");
        return html.toString();
    }

    @Override
    @Transactional(readOnly = true)
    public String generateHomeHtml(HttpServletRequest request) {
        List<Event> published = eventRepository.findByStatus(EventStatus.PUBLISHED);
        String title = "VibeMyNight — Nightlife & Cultural Events Pass Booking Platform";
        String description = "Discover and book verified passes for the hottest Garba nights, music festivals, concerts, and nightlife events in Gujarat with 0% convenience fees.";
        String canonicalUrl = BASE_URL;

        Map<String, Object> orgSchema = new LinkedHashMap<>();
        orgSchema.put("@context", "https://schema.org");
        orgSchema.put("@type", "WebSite");
        orgSchema.put("name", "VibeMyNight");
        orgSchema.put("url", BASE_URL);
        Map<String, Object> searchAction = new LinkedHashMap<>();
        searchAction.put("@type", "SearchAction");
        searchAction.put("target", BASE_URL + "/events?q={search_term_string}");
        searchAction.put("query-input", "required name=search_term_string");
        orgSchema.put("potentialAction", searchAction);

        String jsonLd = "";
        try {
            jsonLd = objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(orgSchema);
        } catch (Exception ignored) {}

        StringBuilder html = new StringBuilder();
        html.append("<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n");
        html.append("    <meta charset=\"UTF-8\">\n");
        html.append("    <title>").append(escapeHtml(title)).append("</title>\n");
        html.append("    <meta name=\"description\" content=\"").append(escapeHtml(description)).append("\">\n");
        html.append("    <link rel=\"canonical\" href=\"").append(escapeHtml(canonicalUrl)).append("\">\n");
        html.append("    <meta property=\"og:title\" content=\"").append(escapeHtml(title)).append("\">\n");
        html.append("    <meta property=\"og:description\" content=\"").append(escapeHtml(description)).append("\">\n");
        html.append("    <meta property=\"og:image\" content=\"").append(DEFAULT_IMAGE).append("\">\n");
        html.append("    <script type=\"application/ld+json\">\n").append(jsonLd).append("\n    </script>\n");
        html.append("</head>\n<body>\n");
        html.append("    <h1>VibeMyNight — Verified Events & Passes</h1>\n");
        html.append("    <p>").append(escapeHtml(description)).append("</p>\n");
        html.append("    <h2>Featured Events</h2>\n");
        html.append("    <ul>\n");
        for (Event e : published) {
            html.append("        <li><a href=\"").append(BASE_URL).append("/events/").append(escapeHtml(e.getSlug())).append("\">")
                    .append(escapeHtml(e.getName())).append("</a> (").append(escapeHtml(e.getCity() != null ? e.getCity() : DEFAULT_CITY)).append(")</li>\n");
        }
        html.append("    </ul>\n");
        html.append("</body>\n</html>");
        return html.toString();
    }

    @Override
    public String generateMainSitemapXml() {
        String today = LocalDate.now().toString();
        return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
                "<sitemapindex xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n" +
                "    <sitemap>\n" +
                "        <loc>" + BASE_URL + "/sitemap-events.xml</loc>\n" +
                "        <lastmod>" + today + "</lastmod>\n" +
                "    </sitemap>\n" +
                "    <sitemap>\n" +
                "        <loc>" + BASE_URL + "/sitemap-artists.xml</loc>\n" +
                "        <lastmod>" + today + "</lastmod>\n" +
                "    </sitemap>\n" +
                "    <sitemap>\n" +
                "        <loc>" + BASE_URL + "/sitemap-cities.xml</loc>\n" +
                "        <lastmod>" + today + "</lastmod>\n" +
                "    </sitemap>\n" +
                "</sitemapindex>";
    }

    @Override
    @Transactional(readOnly = true)
    public String generateEventsSitemapXml() {
        List<Event> events = eventRepository.findByStatus(EventStatus.PUBLISHED);
        StringBuilder xml = new StringBuilder();
        xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
        xml.append("<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n");

        // Static core routes
        xml.append("    <url>\n");
        xml.append("        <loc>").append(BASE_URL).append("/</loc>\n");
        xml.append("        <changefreq>daily</changefreq>\n");
        xml.append("        <priority>1.0</priority>\n");
        xml.append("    </url>\n");
        xml.append("    <url>\n");
        xml.append("        <loc>").append(BASE_URL).append("/events</loc>\n");
        xml.append("        <changefreq>daily</changefreq>\n");
        xml.append("        <priority>0.9</priority>\n");
        xml.append("    </url>\n");
        xml.append("    <url>\n");
        xml.append("        <loc>").append(BASE_URL).append("/about</loc>\n");
        xml.append("        <changefreq>monthly</changefreq>\n");
        xml.append("        <priority>0.5</priority>\n");
        xml.append("    </url>\n");
        xml.append("    <url>\n");
        xml.append("        <loc>").append(BASE_URL).append("/contact</loc>\n");
        xml.append("        <changefreq>monthly</changefreq>\n");
        xml.append("        <priority>0.5</priority>\n");
        xml.append("    </url>\n");

        for (Event e : events) {
            String lastmod = e.getUpdatedAt() != null ? e.getUpdatedAt().toLocalDate().toString() : LocalDate.now().toString();
            xml.append("    <url>\n");
            xml.append("        <loc>").append(BASE_URL).append("/events/").append(e.getSlug()).append("</loc>\n");
            xml.append("        <lastmod>").append(lastmod).append("</lastmod>\n");
            xml.append("        <changefreq>daily</changefreq>\n");
            xml.append("        <priority>0.9</priority>\n");
            xml.append("    </url>\n");
        }

        xml.append("</urlset>");
        return xml.toString();
    }

    @Override
    @Transactional(readOnly = true)
    public String generateArtistsSitemapXml() {
        List<Artist> artists = artistRepository.findByStatus(ActiveStatus.ACTIVE);
        StringBuilder xml = new StringBuilder();
        xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
        xml.append("<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n");

        xml.append("    <url>\n");
        xml.append("        <loc>").append(BASE_URL).append("/artists</loc>\n");
        xml.append("        <changefreq>weekly</changefreq>\n");
        xml.append("        <priority>0.7</priority>\n");
        xml.append("    </url>\n");

        for (Artist a : artists) {
            String slug = a.getSlug() != null && !a.getSlug().isBlank() ? a.getSlug() : a.getId().toString();
            String lastmod = a.getUpdatedAt() != null ? a.getUpdatedAt().toLocalDate().toString() : LocalDate.now().toString();
            xml.append("    <url>\n");
            xml.append("        <loc>").append(BASE_URL).append("/artists/").append(slug).append("</loc>\n");
            xml.append("        <lastmod>").append(lastmod).append("</lastmod>\n");
            xml.append("        <changefreq>weekly</changefreq>\n");
            xml.append("        <priority>0.7</priority>\n");
            xml.append("    </url>\n");
        }

        xml.append("</urlset>");
        return xml.toString();
    }

    @Override
    @Transactional(readOnly = true)
    public String generateCitiesSitemapXml() {
        List<Event> events = eventRepository.findByStatus(EventStatus.PUBLISHED);
        Set<String> cities = events.stream()
                .map(Event::getCity)
                .filter(Objects::nonNull)
                .map(String::trim)
                .filter(c -> !c.isEmpty())
                .map(String::toLowerCase)
                .collect(Collectors.toSet());

        if (cities.isEmpty()) {
            cities.add("ahmedabad");
        }

        StringBuilder xml = new StringBuilder();
        xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
        xml.append("<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n");

        for (String c : cities) {
            xml.append("    <url>\n");
            xml.append("        <loc>").append(BASE_URL).append("/city/").append(c).append("</loc>\n");
            xml.append("        <changefreq>daily</changefreq>\n");
            xml.append("        <priority>0.8</priority>\n");
            xml.append("    </url>\n");
        }

        xml.append("</urlset>");
        return xml.toString();
    }

    @Override
    public String generateRobotsTxt() {
        return "User-agent: *\n" +
                "Allow: /\n" +
                "Allow: /events\n" +
                "Allow: /events/*\n" +
                "Allow: /artists\n" +
                "Allow: /artists/*\n" +
                "Allow: /city/*\n" +
                "Allow: /category/*\n" +
                "Allow: /about\n" +
                "Allow: /contact\n" +
                "\n" +
                "# Disallow internal admin, auth, and private checkout states\n" +
                "Disallow: /admin\n" +
                "Disallow: /admin/*\n" +
                "Disallow: /api/v1/admin\n" +
                "Disallow: /api/v1/admin/*\n" +
                "Disallow: /api/v1/auth\n" +
                "Disallow: /api/v1/auth/*\n" +
                "Disallow: /inquiry/success\n" +
                "\n" +
                "# Main Canonical XML Sitemap Index\n" +
                "Sitemap: " + BASE_URL + "/sitemap.xml\n";
    }

    @Override
    @Transactional(readOnly = true)
    public Map<String, Object> getEventSeoData(String slug) {
        Event event = eventRepository.findBySlug(slug)
                .or(() -> {
                    try {
                        Long id = Long.parseLong(slug);
                        return eventRepository.findById(id);
                    } catch (NumberFormatException ignored) {
                        return Optional.empty();
                    }
                })
                .orElseThrow(() -> new ResourceNotFoundException("Event not found for SEO: " + slug));

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", event.getId());
        result.put("name", event.getName());
        result.put("slug", event.getSlug());
        result.put("canonicalUrl", BASE_URL + "/events/" + event.getSlug());
        result.put("startDate", event.getStartDate());
        result.put("endDate", event.getEndDate());
        result.put("venue", event.getVenue());
        result.put("city", event.getCity());
        result.put("status", event.getStatus());

        return result;
    }

    @Override
    @Transactional(readOnly = true)
    public Map<String, Object> getSeoHealth() {
        long publishedCount = eventRepository.findByStatus(EventStatus.PUBLISHED).size();
        long artistCount = artistRepository.findByStatus(ActiveStatus.ACTIVE).size();

        Map<String, Object> health = new LinkedHashMap<>();
        health.put("status", "UP");
        health.put("publishedEventsCount", publishedCount);
        health.put("activeArtistsCount", artistCount);
        health.put("sitemapIndex", BASE_URL + "/sitemap.xml");
        health.put("robotsTxt", BASE_URL + "/robots.txt");
        health.put("timestamp", LocalDateTime.now());
        return health;
    }
}
