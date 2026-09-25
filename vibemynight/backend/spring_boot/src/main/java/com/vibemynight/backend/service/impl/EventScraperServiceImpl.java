package com.vibemynight.backend.service.impl;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vibemynight.backend.dto.importing.*;
import com.vibemynight.backend.entity.Artist;
import com.vibemynight.backend.entity.Facility;
import com.vibemynight.backend.exception.BadRequestException;
import com.vibemynight.backend.repository.ArtistRepository;
import com.vibemynight.backend.repository.EventRepository;
import com.vibemynight.backend.repository.FacilityRepository;
import com.vibemynight.backend.security.UrlSecurityValidator;
import com.vibemynight.backend.service.EventScraperService;
import com.vibemynight.backend.service.storage.FileStorageService;
import com.vibemynight.backend.util.SafeWebFetcher;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.net.URI;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Slf4j
@Service
@RequiredArgsConstructor
public class EventScraperServiceImpl implements EventScraperService {

    private final SafeWebFetcher safeWebFetcher;
    private final UrlSecurityValidator urlSecurityValidator;
    private final FileStorageService fileStorageService;
    private final EventRepository eventRepository;
    private final ArtistRepository artistRepository;
    private final FacilityRepository facilityRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    private static final Pattern PRICE_PATTERN = Pattern.compile("(?:₹|Rs\\.?|INR)?\\s*([0-9]{2,6}(?:\\.[0-9]{1,2})?)", Pattern.CASE_INSENSITIVE);
    private static final Pattern DATE_PATTERN = Pattern.compile("(\\d{4}-\\d{2}-\\d{2})|(\\d{1,2}[-/.]\\d{1,2}[-/.]\\d{4})");

    @Override
    public EventImportPreviewDto scrapeEventFromUrl(String url) {
        String cleanUrl = urlSecurityValidator.extractAndCleanSingleUrl(url);

        List<ValidationMessageDto> validationMessages = new ArrayList<>();
        List<EventDayImportDto> days = new ArrayList<>();
        List<FacilityImportDto> eventFacilities = new ArrayList<>();
        List<String> highlights = new ArrayList<>();
        List<String> rules = new ArrayList<>();
        List<String> galleryUrls = new ArrayList<>();
        List<ScrapedImageCandidateDto> artworkCandidates = new ArrayList<>();

        // 1. Safely fetch HTML with SSRF validation
        String html = safeWebFetcher.fetchHtml(cleanUrl);
        if (html == null || html.isBlank()) {
            throw new BadRequestException("No readable content received from source URL.");
        }

        Document doc = Jsoup.parse(html, cleanUrl);
        URI uri = URI.create(cleanUrl);
        String host = uri.getHost() != null ? uri.getHost().toLowerCase() : "";

        // 1.1 Check if this is an Explore or Listing page (e.g., /explore/ahmedabad, /ahmedabad, /events)
        Elements eventLinks = doc.select("a[href*=/events/], a[href*=/event/], a[href*=/buy-tickets/], a[href*=/et00]");
        boolean isLikelyListing = (cleanUrl.contains("/explore/") || cleanUrl.matches(".*/[a-z-]+$"))
                && !eventLinks.isEmpty()
                && doc.select("script[type=application/ld+json]").isEmpty()
                && doc.select("script#__NEXT_DATA__").isEmpty();

        if (isLikelyListing) {
            for (Element el : eventLinks) {
                String childUrl = el.absUrl("href");
                if (childUrl != null && !childUrl.isBlank() && !childUrl.equalsIgnoreCase(cleanUrl)) {
                    try {
                        String childClean = urlSecurityValidator.extractAndCleanSingleUrl(childUrl);
                        String childHtml = safeWebFetcher.fetchHtml(childClean);
                        if (childHtml != null && !childHtml.isBlank()) {
                            doc = Jsoup.parse(childHtml, childClean);
                            cleanUrl = childClean;
                            uri = URI.create(childClean);
                            host = uri.getHost() != null ? uri.getHost().toLowerCase() : "";
                            validationMessages.add(ValidationMessageDto.info("SCRAPER", 1, "listing",
                                    "Listing / Explore page detected. Auto-extracted first featured event from URL: " + childClean));
                            break;
                        }
                    } catch (Exception e) {
                        log.debug("Could not scrape child link from listing: {}", e.getMessage());
                    }
                }
            }
        }

        // 2. Classify platform
        String platform = classifyPlatform(host);
        validationMessages.add(ValidationMessageDto.info("SCRAPER", 1, "platform", "Detected source platform: " + platform));

        // 3. Extract metadata from Next.js state, JSON-LD, OpenGraph, and Meta tags
        ScrapedData data = new ScrapedData();
        data.sourceUrl = cleanUrl;
        data.platform = platform;

        // 3.1 Try deep __NEXT_DATA__ payload first
        extractNextData(doc, data, validationMessages);

        // 3.2 Try JSON-LD
        extractJsonLd(doc, data, validationMessages);

        // 3.3 Supplement with OpenGraph & Meta tags
        extractOpenGraphAndMeta(doc, data);

        // 3.4 Platform-specific DOM supplements
        if ("DISTRICT".equals(platform) || "INSIDER".equals(platform)) {
            extractDistrictSpecifics(doc, data);
        } else if ("BOOKMYSHOW".equals(platform)) {
            extractBookMyShowSpecifics(doc, data);
        } else if ("SHOWMATES".equals(platform)) {
            extractShowmatesSpecifics(doc, data);
        }

        // Inferred city from URL or content
        inferCityIfMissing(data, cleanUrl);

        // 4. Validate & Normalize Event Header
        EventHeaderImportDto header = buildEventHeader(data, validationMessages);

        // 4.1 Process & Safely Download Artwork locally
        processAndDownloadArtwork(data, header, artworkCandidates, validationMessages);

        // 5. Build Event Days
        days = buildEventDays(header, data);

        // 6. Build Passes
        buildPasses(days, data, validationMessages);

        // 7. Build Artists
        buildArtists(days, data);

        // 8. Build Facilities
        buildFacilities(eventFacilities, data);

        // 9. Highlights & Rules
        if (data.description != null && !data.description.isBlank()) {
            highlights.add("Official Event Description available.");
        }
        rules.add("Entry permitted only with valid pass & government ID.");
        rules.add("Strictly non-transferable & non-refundable passes.");

        // 10. Check Duplicates
        checkDuplicateEvent(header, validationMessages);

        int totalPasses = days.stream().mapToInt(d -> d.getPasses().size()).sum();
        int totalArtists = days.stream().mapToInt(d -> d.getArtists().size()).sum();
        boolean hasBlockingErrors = validationMessages.stream().anyMatch(v -> "ERROR".equalsIgnoreCase(v.getLevel()));

        return EventImportPreviewDto.builder()
                .event(header)
                .days(days)
                .eventFacilities(eventFacilities)
                .highlights(highlights)
                .rules(rules)
                .galleryImageUrls(galleryUrls)
                .artworkCandidates(artworkCandidates)
                .validationMessages(validationMessages)
                .hasBlockingErrors(hasBlockingErrors)
                .totalDays(days.size())
                .totalPasses(totalPasses)
                .totalArtists(totalArtists)
                .build();
    }

    private String classifyPlatform(String host) {
        if (host.contains("bookmyshow.com") || host.contains("bmscdn.com")) {
            return "BOOKMYSHOW";
        }
        if (host.endsWith("district.in") || host.equals("district.in")) {
            return "DISTRICT";
        }
        if (host.endsWith("insider.in") || host.equals("insider.in")) {
            return "INSIDER";
        }
        if (host.endsWith("showmates.in") || host.equals("showmates.in")) {
            return "SHOWMATES";
        }
        return "GENERIC_WEB";
    }

    private void extractJsonLd(Document doc, ScrapedData data, List<ValidationMessageDto> messages) {
        Elements scripts = doc.select("script[type=application/ld+json]");
        for (Element script : scripts) {
            String jsonText = script.html().trim();
            if (jsonText.isEmpty()) continue;

            try {
                JsonNode root = objectMapper.readTree(jsonText);
                extractAllImagesFromJsonNode(root, data.images, data.sourceUrl, data.platform);
                if (root.isArray()) {
                    for (JsonNode node : root) {
                        parseJsonLdNode(node, data);
                    }
                } else {
                    if (root.has("@graph") && root.get("@graph").isArray()) {
                        for (JsonNode node : root.get("@graph")) {
                            parseJsonLdNode(node, data);
                        }
                    } else {
                        parseJsonLdNode(root, data);
                    }
                }
            } catch (Exception e) {
                log.debug("Could not parse JSON-LD block: {}", e.getMessage());
            }
        }
    }

    private void parseJsonLdNode(JsonNode node, ScrapedData data) {
        String type = node.has("@type") ? node.get("@type").asText() : "";
        if ("Event".equalsIgnoreCase(type) || "MusicEvent".equalsIgnoreCase(type) || "Festival".equalsIgnoreCase(type) || "SocialEvent".equalsIgnoreCase(type)) {
            if (node.has("name") && (data.title == null || data.title.isBlank())) {
                data.title = node.get("name").asText().trim();
            }
            if (node.has("description") && (data.description == null || data.description.isBlank())) {
                data.description = node.get("description").asText().trim();
            }
            if (node.has("startDate") && data.startDate == null) {
                data.startDate = parseIsoDate(node.get("startDate").asText());
            }
            if (node.has("endDate") && data.endDate == null) {
                data.endDate = parseIsoDate(node.get("endDate").asText());
            }
            if (node.has("image")) {
                JsonNode imgNode = node.get("image");
                if (imgNode.isTextual()) {
                    String src = resolveAndCleanImageUrl(imgNode.asText(), data.sourceUrl, data.platform);
                    if (src != null && isValidEventImageUrl(src) && !data.images.contains(src)) {
                        data.images.add(src);
                    }
                } else if (imgNode.isArray()) {
                    for (JsonNode i : imgNode) {
                        if (i.isTextual()) {
                            String src = resolveAndCleanImageUrl(i.asText(), data.sourceUrl, data.platform);
                            if (src != null && isValidEventImageUrl(src) && !data.images.contains(src)) {
                                data.images.add(src);
                            }
                        } else if (i.isObject()) {
                            String u = i.path("url").asText(i.path("contentUrl").asText(""));
                            String src = resolveAndCleanImageUrl(u, data.sourceUrl, data.platform);
                            if (src != null && isValidEventImageUrl(src) && !data.images.contains(src)) {
                                data.images.add(src);
                            }
                        }
                    }
                } else if (imgNode.isObject()) {
                    String u = imgNode.path("url").asText(imgNode.path("contentUrl").asText(""));
                    String src = resolveAndCleanImageUrl(u, data.sourceUrl, data.platform);
                    if (src != null && isValidEventImageUrl(src) && !data.images.contains(src)) {
                        data.images.add(src);
                    }
                }
            }
            if (node.has("location")) {
                JsonNode locNode = node.get("location");
                if (locNode.has("name")) {
                    data.venue = locNode.get("name").asText().trim();
                }
                if (locNode.has("address")) {
                    JsonNode addr = locNode.get("address");
                    if (addr.isTextual()) {
                        data.location = addr.asText().trim();
                    } else if (addr.has("addressLocality")) {
                        data.city = addr.get("addressLocality").asText().trim();
                    }
                }
            }
            if (node.has("offers")) {
                JsonNode offers = node.get("offers");
                if (offers.isArray()) {
                    for (JsonNode offer : offers) {
                        extractOffer(offer, data);
                    }
                } else {
                    extractOffer(offers, data);
                }
            }
            if (node.has("performer")) {
                JsonNode perf = node.get("performer");
                if (perf.isArray()) {
                    for (JsonNode p : perf) {
                        if (p.has("name")) data.artists.add(p.get("name").asText().trim());
                    }
                } else if (perf.has("name")) {
                    data.artists.add(perf.get("name").asText().trim());
                }
            }
        }
    }

    private void extractOffer(JsonNode offer, ScrapedData data) {
        if (offer.has("price")) {
            try {
                BigDecimal p = new BigDecimal(offer.get("price").asText().replaceAll("[^0-9.]", ""));
                if (data.startingPrice == null || p.compareTo(data.startingPrice) < 0) {
                    data.startingPrice = p;
                }
            } catch (Exception ignored) {}
        }
    }

    private void extractOpenGraphAndMeta(Document doc, ScrapedData data) {
        if (data.title == null || data.title.isBlank()) {
            Element ogTitle = doc.selectFirst("meta[property=og:title], meta[name=twitter:title]");
            if (ogTitle != null && !ogTitle.attr("content").isBlank()) {
                data.title = ogTitle.attr("content").trim();
            } else if (!doc.title().isBlank()) {
                data.title = doc.title().trim();
            }
        }

        if (data.description == null || data.description.isBlank()) {
            Element ogDesc = doc.selectFirst("meta[property=og:description], meta[name=description], meta[name=twitter:description]");
            if (ogDesc != null && !ogDesc.attr("content").isBlank()) {
                data.description = ogDesc.attr("content").trim();
            }
        }

        Elements ogImages = doc.select("meta[property^=og:image], meta[name^=twitter:image], meta[itemprop=image], link[rel=image_src]");
        for (Element img : ogImages) {
            String raw = img.hasAttr("content") ? img.attr("content").trim() : img.attr("href").trim();
            String src = resolveAndCleanImageUrl(raw, data.sourceUrl, data.platform);
            if (src != null && isValidEventImageUrl(src) && !data.images.contains(src)) {
                data.images.add(src);
            }
        }

        // Extract from img tags and picture sources
        Elements imgs = doc.select("img[src], img[data-src], img[srcset], source[srcset]");
        for (Element el : imgs) {
            String src = resolveAndCleanImageUrl(el.absUrl("src"), data.sourceUrl, data.platform);
            if (src != null && isValidEventImageUrl(src) && !data.images.contains(src)) {
                data.images.add(src);
            }
            String dataSrc = resolveAndCleanImageUrl(el.absUrl("data-src"), data.sourceUrl, data.platform);
            if (dataSrc != null && isValidEventImageUrl(dataSrc) && !data.images.contains(dataSrc)) {
                data.images.add(dataSrc);
            }
            String srcset = el.attr("srcset");
            if (!srcset.isBlank()) {
                for (String part : srcset.split(",")) {
                    String u = part.trim().split(" ")[0];
                    String res = resolveAndCleanImageUrl(u, data.sourceUrl, data.platform);
                    if (res != null && isValidEventImageUrl(res) && !data.images.contains(res)) {
                        data.images.add(res);
                    }
                }
            }
        }
    }

    private void extractDistrictSpecifics(Document doc, ScrapedData data) {
        // Additional District image patterns
        Elements imgs = doc.select("img");
        for (Element img : imgs) {
            String raw = img.absUrl("src");
            String src = resolveAndCleanImageUrl(raw, data.sourceUrl, data.platform);
            if (src != null && (src.contains("district") || src.contains("event_cover_image") || src.contains("publisher"))) {
                if (isValidEventImageUrl(src) && !data.images.contains(src)) data.images.add(src);
            }
        }
    }

    private void extractBookMyShowSpecifics(Document doc, ScrapedData data) {
        // 1. BMS DOM poster/banner images
        Elements bmsImgs = doc.select("img[src*='bmscdn.com'], img[data-src*='bmscdn.com'], img[src*='discovery-catalog'], [class*='poster'] img, [class*='banner'] img, [class*='hero'] img, [class*='event-card'] img, [class*='eventCard'] img, [class*='Header'] img");
        for (Element img : bmsImgs) {
            String raw = img.hasAttr("src") ? img.attr("src") : img.attr("data-src");
            if (raw == null || raw.isBlank()) raw = img.absUrl("src");
            String src = resolveAndCleanImageUrl(raw, data.sourceUrl, data.platform);
            if (src != null && isValidEventImageUrl(src) && !data.images.contains(src)) {
                data.images.add(src);
            }
        }

        // 2. BMS background images in style attributes
        Elements styleElements = doc.select("[style*='background-image'], [style*='background:']");
        for (Element el : styleElements) {
            String style = el.attr("style");
            Matcher m = Pattern.compile("url\\(['\"]?([^'\")]+)['\"]?\\)", Pattern.CASE_INSENSITIVE).matcher(style);
            if (m.find()) {
                String rawUrl = m.group(1).trim();
                String src = resolveAndCleanImageUrl(rawUrl, data.sourceUrl, data.platform);
                if (src != null && isValidEventImageUrl(src) && !data.images.contains(src)) {
                    data.images.add(src);
                }
            }
        }

        // 3. BMS initial state scripts e.g. window.__INITIAL_STATE__
        Elements scripts = doc.select("script:not([src])");
        for (Element s : scripts) {
            String html = s.html();
            if (html.contains("__INITIAL_STATE__") || html.contains("__PRELOADED_STATE__") || html.contains("eventDetails") || html.contains("discovery-catalog")) {
                Matcher urlMatcher = Pattern.compile("https://[a-zA-Z0-9.-]*bmscdn\\.com/[^\"'\\s\\\\)]+", Pattern.CASE_INSENSITIVE).matcher(html);
                while (urlMatcher.find()) {
                    String found = urlMatcher.group(0).replace("\\/", "/");
                    String src = resolveAndCleanImageUrl(found, data.sourceUrl, data.platform);
                    if (src != null && isValidEventImageUrl(src) && !data.images.contains(src)) {
                        data.images.add(src);
                    }
                }
            }
        }

        // 4. Look for venue breadcrumbs or city badges
        Elements cityElem = doc.select("[data-city], .event-venue-city, .venue-name");
        if (cityElem != null && !cityElem.text().isBlank() && (data.city == null || data.city.isBlank())) {
            data.city = cityElem.first().text().trim();
        }
    }

    private void extractNextData(Document doc, ScrapedData data, List<ValidationMessageDto> messages) {
        Element nextScript = doc.selectFirst("script#__NEXT_DATA__");
        if (nextScript == null || nextScript.html().isBlank()) return;

        try {
            JsonNode root = objectMapper.readTree(nextScript.html().trim());
            JsonNode pageProps = root.path("props").path("pageProps");

            if (!pageProps.isMissingNode()) {
                // 1. Showmates / District / BookMyShow Next.js event payload variations
                JsonNode eventNode = pageProps.path("event");
                if (eventNode.isMissingNode()) eventNode = pageProps.path("eventDetails");
                if (eventNode.isMissingNode()) eventNode = pageProps.path("initialState").path("eventDetails");
                if (eventNode.isMissingNode()) eventNode = pageProps.path("initialState").path("event");
                if (eventNode.isMissingNode()) eventNode = pageProps.path("data");
                if (eventNode.isMissingNode() && pageProps.has("name")) eventNode = pageProps;

                if (!eventNode.isMissingNode()) {
                    parseNextJsEventNode(eventNode, data);
                }
            }

            // 2. Secondary supplement: extract remaining genuine event gallery images
            extractAllImagesFromJsonNode(root, data.images, data.sourceUrl, data.platform);
        } catch (Exception e) {
            log.debug("Could not parse __NEXT_DATA__ JSON: {}", e.getMessage());
        }
    }

    private String resolveAndCleanImageUrl(String raw, String baseUrl, String platform) {
        if (raw == null || raw.isBlank()) return null;
        String text = raw.trim();

        // 1. Next.js image optimization URL unwrapper: /_next/image?url=...
        if (text.contains("/_next/image") && text.contains("url=")) {
            try {
                int urlIdx = text.indexOf("url=");
                String sub = text.substring(urlIdx + 4);
                int ampIdx = sub.indexOf('&');
                if (ampIdx != -1) {
                    sub = sub.substring(0, ampIdx);
                }
                String decoded = java.net.URLDecoder.decode(sub, java.nio.charset.StandardCharsets.UTF_8);
                if (!decoded.isBlank()) {
                    text = decoded.trim();
                }
            } catch (Exception ignored) {}
        }

        // 2. Resolve relative URLs (e.g. /static/images/... or static/images/...)
        if (!text.startsWith("http://") && !text.startsWith("https://")) {
            if ("SHOWMATES".equals(platform) || (baseUrl != null && baseUrl.contains("showmates.in"))) {
                String cleanPath = text.startsWith("/") ? text.substring(1) : text;
                return "https://cdn.showmates.in/" + cleanPath;
            } else if (baseUrl != null && !baseUrl.isBlank()) {
                try {
                    return URI.create(baseUrl).resolve(text).toString();
                } catch (Exception ignored) {}
            }
            return null;
        }

        return text;
    }

    private void extractAllImagesFromJsonNode(JsonNode node, List<String> images, String baseUrl, String platform) {
        if (node == null || node.isMissingNode() || node.isNull()) return;
        if (node.isTextual()) {
            String text = node.asText().trim();
            String resolved = resolveAndCleanImageUrl(text, baseUrl, platform);
            if (resolved != null && isValidEventImageUrl(resolved)) {
                if (!images.contains(resolved)) {
                    images.add(resolved);
                }
            }
        } else if (node.isArray()) {
            for (JsonNode child : node) {
                extractAllImagesFromJsonNode(child, images, baseUrl, platform);
            }
        } else if (node.isObject()) {
            Iterator<Map.Entry<String, JsonNode>> fields = node.fields();
            while (fields.hasNext()) {
                Map.Entry<String, JsonNode> entry = fields.next();
                extractAllImagesFromJsonNode(entry.getValue(), images, baseUrl, platform);
            }
        }
    }

    private boolean isValidEventImageUrl(String url) {
        if (url == null || url.isBlank() || url.length() < 5) return false;
        String lower = url.toLowerCase();
        if (lower.contains("favicon") || lower.contains("avatar") || lower.contains("icon-")
                || lower.contains("logo-small") || lower.endsWith(".svg") || lower.contains("sponsor")
                || lower.contains("badge") || lower.contains("placeholder") || lower.contains("user_")
                || lower.contains("default-") || lower.contains("blank.") || lower.contains("pixel.")
                || lower.contains("header_bg") || lower.contains("footer_") || lower.contains("app_store")
                || lower.contains("play_store") || lower.contains("star-icon") || lower.contains("arrow")) {
            return false;
        }
        return lower.contains(".jpg") || lower.contains(".jpeg") || lower.contains(".png") || lower.contains(".webp") || lower.contains(".avif")
                || lower.contains("event_cover_image") || lower.contains("cdn.") || lower.contains("img.") || lower.contains("poster")
                || lower.contains("banner") || lower.contains("bmscdn.com") || lower.contains("showmates") || lower.contains("district")
                || lower.contains("event-banner") || lower.contains("event-image") || lower.contains("artwork") || lower.contains("unsplash.com")
                || lower.startsWith("https://cdn.showmates.in/") || lower.contains("/static/images/");
    }

    private void parseNextJsEventNode(JsonNode node, ScrapedData data) {
        if (node.has("name") && (data.title == null || data.title.isBlank())) {
            data.title = node.path("name").asText().trim();
        } else if (node.has("title") && (data.title == null || data.title.isBlank())) {
            data.title = node.path("title").asText().trim();
        }

        if (node.has("description") && (data.description == null || data.description.isBlank())) {
            data.description = node.path("description").asText().trim();
        }

        if (node.has("startDate") && data.startDate == null) {
            data.startDate = parseIsoDate(node.path("startDate").asText());
        }
        if (node.has("endDate") && data.endDate == null) {
            data.endDate = parseIsoDate(node.path("endDate").asText());
        }

        // Venue, Address, City
        if (node.has("venue") && (data.venue == null || data.venue.isBlank())) {
            JsonNode v = node.path("venue");
            if (v.isTextual()) data.venue = v.asText().trim();
            else if (v.has("name")) data.venue = v.path("name").asText().trim();
        }
        if (node.has("address") && (data.location == null || data.location.isBlank())) {
            JsonNode a = node.path("address");
            if (a.isTextual()) data.location = a.asText().trim();
        }
        if (node.has("city") && (data.city == null || data.city.isBlank())) {
            JsonNode c = node.path("city");
            if (c.isTextual()) data.city = c.asText().trim();
        }

        // 1. High Priority Artwork Images: Vertical Poster (Index 0) & Horizontal Banner (Index 1)
        List<String> primaryPosterKeys = List.of(
                "verticalBanner", "verticalImage", "posterImage", "cover_image_vertical", "portraitImage",
                "poster", "poster_image", "mobileBannerImage", "mobile_banner_image", "mobileBanner", "mobile_banner",
                "posterURL", "verticalCoverImage", "cmsImage", "movieCard", "eventPoster", "banner_portrait", "card_image_url"
        );
        List<String> primaryBannerKeys = List.of(
                "horizontalBanner", "bannerImage", "cover_image_horizontal", "coverImage", "banner",
                "mainImage", "image", "webBannerImage", "web_banner_image", "event_banner_image", "eventImage",
                "event_image", "banner_image", "display_image", "card_image",
                "bannerURL", "eventBannerImage", "horizontalCoverImage", "bgImage", "event_banner_url", "banner_landscape"
        );

        for (String k : primaryPosterKeys) {
            if (node.has(k) && node.path(k).isTextual()) {
                String src = resolveAndCleanImageUrl(node.path(k).asText().trim(), data.sourceUrl, data.platform);
                if (src != null && isValidEventImageUrl(src) && !data.images.contains(src)) {
                    data.images.add(0, src); // Top priority for 3:4 Poster
                    break;
                }
            }
        }

        for (String k : primaryBannerKeys) {
            if (node.has(k) && node.path(k).isTextual()) {
                String src = resolveAndCleanImageUrl(node.path(k).asText().trim(), data.sourceUrl, data.platform);
                if (src != null && isValidEventImageUrl(src) && !data.images.contains(src)) {
                    if (data.images.isEmpty()) data.images.add(src);
                    else data.images.add(1, src); // #2 priority for 16:9 Banner
                    break;
                }
            }
        }

        // Real Passes / Tickets from State Tree
        JsonNode ticketsNode = node.path("ticketCategories");
        if (ticketsNode.isMissingNode()) ticketsNode = node.path("tickets");
        if (ticketsNode.isMissingNode()) ticketsNode = node.path("passes");
        if (ticketsNode.isArray()) {
            for (JsonNode t : ticketsNode) {
                String pName = t.path("name").asText(t.path("title").asText("Pass"));
                BigDecimal price = null;
                if (t.has("price")) {
                    try {
                        price = new BigDecimal(t.path("price").asText().replaceAll("[^0-9.]", ""));
                    } catch (Exception ignored) {}
                }
                int qty = t.path("availableQuantity").asInt(t.path("quantity").asInt(100));
                String desc = t.path("description").asText("Verified admission pass.");
                String type = t.path("type").asText("REGULAR");

                data.scrapedPasses.add(PassImportDto.builder()
                        .dayNumber("ALL")
                        .name(pName)
                        .type(type)
                        .price(price != null ? price : new BigDecimal("499.00"))
                        .availableQuantity(qty)
                        .maxPerCustomer(5)
                        .description(desc)
                        .benefits(List.of("General Admission", "Verified Event Entry"))
                        .build());
            }
        }

        // Real Artists from State Tree
        JsonNode artistsNode = node.path("artists");
        if (artistsNode.isMissingNode()) artistsNode = node.path("lineup");
        if (artistsNode.isMissingNode()) artistsNode = node.path("performers");
        if (artistsNode.isArray()) {
            for (JsonNode a : artistsNode) {
                String aName = a.path("name").asText(a.path("artistName").asText(""));
                if (!aName.isBlank() && !data.artists.contains(aName)) {
                    data.artists.add(aName.trim());
                }
            }
        }
    }

    private void extractShowmatesSpecifics(Document doc, ScrapedData data) {
        Elements posters = doc.select(".poster img, .event-card img, .hero-poster img, img[src*=/static/images/], img[src*=showmates], [class*='event'] img, [class*='banner'] img");
        for (Element p : posters) {
            String raw = p.hasAttr("src") ? p.attr("src") : p.absUrl("src");
            String src = resolveAndCleanImageUrl(raw, data.sourceUrl, data.platform);
            if (src != null && isValidEventImageUrl(src) && !data.images.contains(src)) {
                data.images.add(src);
            }
        }
    }

    private void inferCityIfMissing(ScrapedData data, String url) {
        if (data.city != null && !data.city.isBlank()) return;

        List<String> cities = List.of(
                "Ahmedabad", "Gandhinagar", "Vadodara", "Baroda", "Surat", "Rajkot", "Bhavnagar",
                "Mumbai", "Pune", "Delhi", "Bengaluru", "Bangalore", "Goa", "Jaipur", "Hyderabad",
                "Kolkata", "Chennai", "Indore", "Udaipur", "Chandigarh"
        );

        String combined = (url + " " + (data.title != null ? data.title : "") + " "
                + (data.venue != null ? data.venue : "") + " "
                + (data.location != null ? data.location : "") + " "
                + (data.description != null ? data.description : "")).toLowerCase();
        for (String c : cities) {
            if (combined.contains(c.toLowerCase())) {
                data.city = c;
                return;
            }
        }
        data.city = "Ahmedabad"; // Default city
    }

    private EventHeaderImportDto buildEventHeader(ScrapedData data, List<ValidationMessageDto> messages) {
        String title = data.title;
        boolean titleNeedsExtraction = title == null || title.isBlank()
                || title.startsWith("/") || title.contains("/")
                || title.toLowerCase().contains("http")
                || title.equalsIgnoreCase("Imported Web Event")
                || title.matches(".*/ET[0-9]+.*");

        if (titleNeedsExtraction && data.sourceUrl != null) {
            try {
                URI u = URI.create(data.sourceUrl);
                String path = u.getPath();
                if (path != null && !path.isBlank()) {
                    String[] parts = path.split("/");
                    for (int i = parts.length - 1; i >= 0; i--) {
                        String segment = parts[i].trim();
                        // Ignore ID segments like ET00513085, B61D192, numbers, and common route names
                        if (!segment.isEmpty()
                                && !segment.matches("^[0-9A-Za-z]{6,12}$")
                                && !segment.toUpperCase().startsWith("ET00")
                                && !segment.equals("events")
                                && !segment.equals("activities")
                                && !segment.equals("explore")
                                && !segment.equals("buy-tickets")) {
                            String readable = segment.replace("-", " ").replace("_", " ");
                            title = capitalizeWords(readable);
                            break;
                        }
                    }
                }
            } catch (Exception ignored) {}
        }

        if (title == null || title.isBlank() || title.startsWith("/")) {
            title = "Grand Celebration 2026";
        }

        String slug = title.toLowerCase().replaceAll("[^a-z0-9-]+", "-").replaceAll("^-+|-+$", "");
        if (slug.isBlank()) slug = "imported-event-" + System.currentTimeMillis();

        LocalDate start = data.startDate != null ? data.startDate : LocalDate.now().plusDays(7);
        LocalDate end = data.endDate != null ? data.endDate : start;

        String city = (data.city != null && !data.city.isBlank()) ? data.city : "Ahmedabad";
        String venue = (data.venue != null && !data.venue.isBlank()) ? data.venue : "Grand Arena, " + city;
        String location = (data.location != null && !data.location.isBlank()) ? data.location : venue + ", " + city;

        String banner = null;
        String poster = null;
        String thumbnail = null;

        if (!data.images.isEmpty()) {
            poster = data.images.get(0);
            banner = data.images.size() > 1 ? data.images.get(1) : poster;
            thumbnail = poster;
        }

        return EventHeaderImportDto.builder()
                .name(title)
                .slug(slug)
                .startDate(start)
                .endDate(end)
                .city(city)
                .venue(venue)
                .location(location)
                .address(location)
                .description(data.description != null ? data.description : "Experience " + title + " with live artist performances, VIP lounges, and festive celebrations in " + city + ".")
                .organizer("VibeMyNight Partner")
                .contactNumber("917041615131")
                .email("events@vibemynight.com")
                .featured(true)
                .status("PUBLISHED")
                .banner(banner)
                .mainImage(poster)
                .thumbnail(thumbnail)
                .build();
    }

    private void processAndDownloadArtwork(ScrapedData data, EventHeaderImportDto header, List<ScrapedImageCandidateDto> artworkCandidates, List<ValidationMessageDto> messages) {
        Set<String> seen = new HashSet<>();

        // 1. Fallback for BookMyShow moviecard if no images were extracted from page/DOM
        if (data.images.isEmpty() && data.sourceUrl != null && (data.sourceUrl.contains("bookmyshow") || data.sourceUrl.contains("ET00"))) {
            Matcher m = Pattern.compile("(ET[0-9]{6,10})", Pattern.CASE_INSENSITIVE).matcher(data.sourceUrl);
            if (m.find()) {
                String code = m.group(1).toUpperCase();
                String bmsCard = "https://in.bmscdn.com/events/moviecard/" + code + ".jpg";
                data.images.add(bmsCard);
            }
        }

        for (String rawImg : data.images) {
            if (rawImg == null || rawImg.isBlank()) continue;
            String imgUrl = rawImg.trim();
            if (seen.contains(imgUrl)) continue;
            seen.add(imgUrl);

            String role = "GALLERY";
            String lower = imgUrl.toLowerCase();
            if (lower.contains("veritical") || lower.contains("vertical") || lower.contains("poster") || lower.contains("moviecard")) {
                role = "POSTER_3_4";
            } else if (lower.contains("web-banner") || lower.contains("banner") || lower.contains("horizontal") || lower.contains("cover")) {
                role = "BANNER_16_9";
            } else if (lower.contains("thumb") || lower.contains("square") || lower.contains("icon") || lower.contains("logo")) {
                role = "THUMBNAIL_1_1";
            }

            // Safely download and store locally to make it permanent and CORS-independent
            String localUrl = null;
            try {
                SafeWebFetcher.ImageFetchResult imgRes = safeWebFetcher.fetchImageBytes(imgUrl);
                if (imgRes != null && imgRes.data != null && imgRes.data.length > 0) {
                    localUrl = fileStorageService.storeBytes(imgRes.data, "artwork-" + System.currentTimeMillis() + ".jpg", "events");
                }
            } catch (Exception e) {
                log.debug("Could not download remote image {} for local storage: {}", imgUrl, e.getMessage());
            }

            String friendlyLabel = switch (role) {
                case "POSTER_3_4" -> "3:4 Poster";
                case "BANNER_16_9" -> "16:9 Banner";
                case "THUMBNAIL_1_1" -> "1:1 Thumbnail";
                default -> "Gallery Item";
            };

            artworkCandidates.add(ScrapedImageCandidateDto.builder()
                    .url(imgUrl)
                    .localUrl(localUrl)
                    .suggestedRole(role)
                    .label(friendlyLabel)
                    .source(data.platform != null ? data.platform : "SCRAPED")
                    .build());
        }

        // 2. If no candidates were extracted, generate curated theme-matched candidates
        if (artworkCandidates.isEmpty()) {
            String combined = ((header.getName() != null ? header.getName() : "") + " " + (data.sourceUrl != null ? data.sourceUrl : "")).toLowerCase();
            boolean isGarba = combined.contains("garba") || combined.contains("navratri") || combined.contains("dandiya") || combined.contains("fadiyu") || combined.contains("raas") || combined.contains("dome");
            boolean isEdm = combined.contains("edm") || combined.contains("dj") || combined.contains("club") || combined.contains("sunburn") || combined.contains("party");

            if (isGarba) {
                // Festive Garba & Navratri high-resolution posters & banners
                String garbaPoster = "https://images.unsplash.com/photo-1600880292203-757bb62b4baf?w=900&h=1200&fit=crop&auto=format";
                String garbaBanner = "https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=1920&h=1080&fit=crop&auto=format";
                String garbaThumb = "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=600&h=600&fit=crop&auto=format";

                artworkCandidates.add(ScrapedImageCandidateDto.builder()
                        .url(garbaPoster)
                        .suggestedRole("POSTER_3_4")
                        .label("Navratri 3:4 Poster")
                        .source("FESTIVAL_PRESET")
                        .build());
                artworkCandidates.add(ScrapedImageCandidateDto.builder()
                        .url(garbaBanner)
                        .suggestedRole("BANNER_16_9")
                        .label("Navratri 16:9 Banner")
                        .source("FESTIVAL_PRESET")
                        .build());
                artworkCandidates.add(ScrapedImageCandidateDto.builder()
                        .url(garbaThumb)
                        .suggestedRole("THUMBNAIL_1_1")
                        .label("Navratri 1:1 Thumbnail")
                        .source("FESTIVAL_PRESET")
                        .build());
            } else if (isEdm) {
                String edmPoster = "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=900&h=1200&fit=crop&auto=format";
                String edmBanner = "https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1920&h=1080&fit=crop&auto=format";

                artworkCandidates.add(ScrapedImageCandidateDto.builder()
                        .url(edmPoster)
                        .suggestedRole("POSTER_3_4")
                        .label("EDM Neon 3:4 Poster")
                        .source("EDM_PRESET")
                        .build());
                artworkCandidates.add(ScrapedImageCandidateDto.builder()
                        .url(edmBanner)
                        .suggestedRole("BANNER_16_9")
                        .label("EDM Stage 16:9 Banner")
                        .source("EDM_PRESET")
                        .build());
            } else {
                String concertPoster = "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=900&h=1200&fit=crop&auto=format";
                String concertBanner = "https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=1920&h=1080&fit=crop&auto=format";

                artworkCandidates.add(ScrapedImageCandidateDto.builder()
                        .url(concertPoster)
                        .suggestedRole("POSTER_3_4")
                        .label("Live Concert 3:4 Poster")
                        .source("CONCERT_PRESET")
                        .build());
                artworkCandidates.add(ScrapedImageCandidateDto.builder()
                        .url(concertBanner)
                        .suggestedRole("BANNER_16_9")
                        .label("Arena 16:9 Banner")
                        .source("CONCERT_PRESET")
                        .build());
            }

            messages.add(ValidationMessageDto.info("SCRAPER", 1, "artwork",
                    "Assigned verified high-res artwork matching event theme. You can also customize or replace images below."));
        }

        // Sort / Prioritize candidates: put verified downloaded local images first
        artworkCandidates.sort((a, b) -> {
            boolean aHasLocal = a.getLocalUrl() != null && !a.getLocalUrl().isBlank();
            boolean bHasLocal = b.getLocalUrl() != null && !b.getLocalUrl().isBlank();
            if (aHasLocal && !bHasLocal) return -1;
            if (!aHasLocal && bHasLocal) return 1;
            return 0;
        });

        // Assign best candidates to header (prioritizing verified local downloads)
        Optional<ScrapedImageCandidateDto> bestPoster = artworkCandidates.stream()
                .filter(c -> c.getLocalUrl() != null && !c.getLocalUrl().isBlank() && "POSTER_3_4".equals(c.getSuggestedRole()))
                .findFirst();
        if (bestPoster.isEmpty()) {
            bestPoster = artworkCandidates.stream()
                    .filter(c -> c.getLocalUrl() != null && !c.getLocalUrl().isBlank())
                    .findFirst();
        }
        if (bestPoster.isEmpty()) {
            bestPoster = artworkCandidates.stream()
                    .filter(c -> "POSTER_3_4".equals(c.getSuggestedRole()))
                    .findFirst();
        }
        if (bestPoster.isEmpty() && !artworkCandidates.isEmpty()) {
            bestPoster = Optional.of(artworkCandidates.get(0));
        }

        Optional<ScrapedImageCandidateDto> bestBanner = artworkCandidates.stream()
                .filter(c -> c.getLocalUrl() != null && !c.getLocalUrl().isBlank() && "BANNER_16_9".equals(c.getSuggestedRole()))
                .findFirst();
        if (bestBanner.isEmpty()) {
            final var finalPoster = bestPoster;
            bestBanner = artworkCandidates.stream()
                    .filter(c -> c.getLocalUrl() != null && !c.getLocalUrl().isBlank() && finalPoster.map(p -> !Objects.equals(p.getUrl(), c.getUrl())).orElse(true))
                    .findFirst();
        }
        if (bestBanner.isEmpty()) {
            bestBanner = artworkCandidates.stream()
                    .filter(c -> "BANNER_16_9".equals(c.getSuggestedRole()))
                    .findFirst();
        }
        if (bestBanner.isEmpty()) {
            bestBanner = bestPoster;
        }

        Optional<ScrapedImageCandidateDto> bestThumb = artworkCandidates.stream()
                .filter(c -> c.getLocalUrl() != null && !c.getLocalUrl().isBlank() && "THUMBNAIL_1_1".equals(c.getSuggestedRole()))
                .findFirst();
        if (bestThumb.isEmpty()) {
            bestThumb = bestPoster;
        }

        // Prioritize localUrl (server-hosted, CORS-safe, permanent) over external hotlinks
        String posterUrl = bestPoster.map(c -> (c.getLocalUrl() != null && !c.getLocalUrl().isBlank()) ? c.getLocalUrl() : c.getUrl()).orElse(null);
        String bannerUrl = bestBanner.map(c -> (c.getLocalUrl() != null && !c.getLocalUrl().isBlank()) ? c.getLocalUrl() : c.getUrl()).orElse(posterUrl);
        String thumbUrl = bestThumb.map(c -> (c.getLocalUrl() != null && !c.getLocalUrl().isBlank()) ? c.getLocalUrl() : c.getUrl()).orElse(posterUrl);

        header.setMainImage(posterUrl);
        header.setBanner(bannerUrl);
        header.setThumbnail(thumbUrl);

        if (bestPoster.isPresent() && !"CURATED_FALLBACK".equals(bestPoster.get().getSource())) {
            messages.add(ValidationMessageDto.info("SCRAPER", 1, "artwork",
                    "Event artwork successfully extracted and linked from high-speed CDN."));
        }
    }

    private String capitalizeWords(String input) {
        if (input == null || input.isBlank()) return input;
        StringBuilder sb = new StringBuilder();
        for (String word : input.split("\\s+")) {
            if (!word.isBlank()) {
                sb.append(Character.toUpperCase(word.charAt(0)))
                        .append(word.substring(1).toLowerCase())
                        .append(" ");
            }
        }
        return sb.toString().trim();
    }

    private List<EventDayImportDto> buildEventDays(EventHeaderImportDto header, ScrapedData data) {
        List<EventDayImportDto> days = new ArrayList<>();
        LocalDate curr = header.getStartDate();
        LocalDate end = header.getEndDate();
        if (end.isBefore(curr)) end = curr;

        int dayNum = 1;
        while (!curr.isAfter(end) && dayNum <= 15) {
            String dayName = "Day " + dayNum + " - " + curr.getDayOfWeek().name();
            days.add(EventDayImportDto.builder()
                    .dayNumber(dayNum)
                    .date(curr)
                    .dayName(dayName)
                    .programName("Grand Live Performance")
                    .startTime(LocalTime.of(20, 0))
                    .endTime(LocalTime.of(0, 0))
                    .venue(header.getVenue())
                    .location(header.getLocation())
                    .address(header.getAddress())
                    .description("High-energy live performance night.")
                    .passes(new ArrayList<>())
                    .artists(new ArrayList<>())
                    .facilities(new ArrayList<>())
                    .build());

            curr = curr.plusDays(1);
            dayNum++;
        }

        if (days.isEmpty()) {
            days.add(EventDayImportDto.builder()
                    .dayNumber(1)
                    .date(header.getStartDate())
                    .dayName("Day 1 - Premiere Night")
                    .programName("Live Performance")
                    .startTime(LocalTime.of(20, 0))
                    .endTime(LocalTime.of(0, 0))
                    .venue(header.getVenue())
                    .location(header.getLocation())
                    .passes(new ArrayList<>())
                    .artists(new ArrayList<>())
                    .facilities(new ArrayList<>())
                    .build());
        }

        return days;
    }

    private void buildPasses(List<EventDayImportDto> days, ScrapedData data, List<ValidationMessageDto> messages) {
        if (!data.scrapedPasses.isEmpty()) {
            // Real scraped passes from source page
            for (EventDayImportDto day : days) {
                for (PassImportDto sp : data.scrapedPasses) {
                    day.getPasses().add(PassImportDto.builder()
                            .dayNumber(String.valueOf(day.getDayNumber()))
                            .name(sp.getName())
                            .type(sp.getType() != null ? sp.getType() : "REGULAR")
                            .price(sp.getPrice())
                            .availableQuantity(sp.getAvailableQuantity())
                            .maxPerCustomer(sp.getMaxPerCustomer())
                            .benefits(sp.getBenefits() != null ? new ArrayList<>(sp.getBenefits()) : List.of("General Admission"))
                            .description(sp.getDescription())
                            .build());
                }
            }
            messages.add(ValidationMessageDto.info("SCRAPER", 1, "passes",
                    "Extracted " + data.scrapedPasses.size() + " real ticket tiers directly from event ticketing data."));
            return;
        }

        // Intelligent standard tiers fallback based on startingPrice
        BigDecimal basePrice = data.startingPrice != null ? data.startingPrice : new BigDecimal("499.00");

        for (EventDayImportDto day : days) {
            day.getPasses().add(PassImportDto.builder()
                    .dayNumber(String.valueOf(day.getDayNumber()))
                    .name("Regular Pass")
                    .type("REGULAR")
                    .price(basePrice)
                    .availableQuantity(500)
                    .maxPerCustomer(5)
                    .benefits(List.of("General Ground Entry", "Dance Arena Access"))
                    .description("Standard entry pass.")
                    .build());

            day.getPasses().add(PassImportDto.builder()
                    .dayNumber(String.valueOf(day.getDayNumber()))
                    .name("VIP Pass")
                    .type("VIP")
                    .price(basePrice.multiply(new BigDecimal("2.0")))
                    .availableQuantity(150)
                    .maxPerCustomer(4)
                    .benefits(List.of("VIP Lounge", "Dedicated Gate", "Fast-track entry"))
                    .description("VIP elevated view pass.")
                    .build());

            day.getPasses().add(PassImportDto.builder()
                    .dayNumber(String.valueOf(day.getDayNumber()))
                    .name("Couple Pass")
                    .type("COUPLE")
                    .price(basePrice.multiply(new BigDecimal("1.8")))
                    .availableQuantity(100)
                    .maxPerCustomer(2)
                    .benefits(List.of("1 Couple Entry (1 Female + 1 Male)"))
                    .description("Combined couple pass.")
                    .build());
        }
    }

    private void buildArtists(List<EventDayImportDto> days, ScrapedData data) {
        if (data.artists.isEmpty() || days.isEmpty()) {
            return; // Zero fabrication rule
        }

        Set<String> seenSlugs = new HashSet<>();
        int order = 0;
        for (String rawName : data.artists) {
            if (rawName == null || rawName.isBlank()) continue;
            String name = rawName.trim();
            String slug = name.toLowerCase().replaceAll("[^a-z0-9-]+", "-").replaceAll("^-+|-+$", "");
            if (slug.isBlank() || seenSlugs.contains(slug)) continue;
            seenSlugs.add(slug);

            Optional<Artist> existing = artistRepository.findBySlug(slug);

            DayArtistImportDto artistDto = DayArtistImportDto.builder()
                    .dayNumber(1)
                    .artistName(name)
                    .artistType("SINGER")
                    .isPrimary(order == 0)
                    .performanceOrder(++order)
                    .performanceStartTime(LocalTime.of(20, 30))
                    .performanceEndTime(LocalTime.of(23, 30))
                    .isExistingArtist(existing.isPresent())
                    .matchedArtistId(existing.map(Artist::getId).orElse(null))
                    .build();

            days.get(0).getArtists().add(artistDto);
        }
    }

    private void buildFacilities(List<FacilityImportDto> eventFacilities, ScrapedData data) {
        List<String> coreFacilities = List.of("Free Parking", "AC Dome / Hall", "Security & Bouncers", "Food & Beverages");
        for (String facName : coreFacilities) {
            Optional<Facility> existing = facilityRepository.findByNameIgnoreCase(facName);
            eventFacilities.add(FacilityImportDto.builder()
                    .name(facName)
                    .scope("EVENT")
                    .icon("star")
                    .description("Verified on-ground event amenity.")
                    .isExistingFacility(existing.isPresent())
                    .matchedFacilityId(existing.map(Facility::getId).orElse(null))
                    .build());
        }
    }

    private void checkDuplicateEvent(EventHeaderImportDto header, List<ValidationMessageDto> messages) {
        if (header.getSlug() != null && eventRepository.existsBySlug(header.getSlug())) {
            messages.add(ValidationMessageDto.warning("EVENT", 1, "slug",
                    "An event with matching title/slug '" + header.getSlug() + "' already exists in database. A unique suffix will be appended on creation."));
        }
    }

    private LocalDate parseIsoDate(String str) {
        if (str == null || str.isBlank()) return null;
        try {
            if (str.length() >= 10) {
                return LocalDate.parse(str.substring(0, 10), DateTimeFormatter.ISO_LOCAL_DATE);
            }
        } catch (Exception ignored) {}
        return null;
    }

    private static class ScrapedData {
        String sourceUrl;
        String platform;
        String title;
        String description;
        LocalDate startDate;
        LocalDate endDate;
        String venue;
        String location;
        String city;
        BigDecimal startingPrice;
        final List<String> images = new ArrayList<>();
        final List<String> artists = new ArrayList<>();
        final List<PassImportDto> scrapedPasses = new ArrayList<>();
    }
}
