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
                && doc.select("script[type=application/ld+json]").isEmpty();

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

        // 3. Extract metadata from JSON-LD, OpenGraph, and Meta tags
        ScrapedData data = new ScrapedData();
        data.sourceUrl = cleanUrl;

        // Try JSON-LD first
        extractJsonLd(doc, data, validationMessages);

        // Supplement with OpenGraph & Meta tags
        extractOpenGraphAndMeta(doc, data);

        // Platform-specific DOM supplements
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
                .validationMessages(validationMessages)
                .hasBlockingErrors(hasBlockingErrors)
                .totalDays(days.size())
                .totalPasses(totalPasses)
                .totalArtists(totalArtists)
                .build();
    }

    private String classifyPlatform(String host) {
        if (host.endsWith("bookmyshow.com") || host.equals("bookmyshow.com")) {
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
                    data.images.add(imgNode.asText());
                } else if (imgNode.isArray()) {
                    for (JsonNode i : imgNode) {
                        if (i.isTextual()) data.images.add(i.asText());
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

        Elements ogImages = doc.select("meta[property=og:image], meta[name=twitter:image], meta[property=og:image:secure_url]");
        for (Element img : ogImages) {
            String src = img.attr("content").trim();
            if (!src.isEmpty() && !data.images.contains(src)) {
                data.images.add(src);
            }
        }
    }

    private void extractDistrictSpecifics(Document doc, ScrapedData data) {
        Elements imgs = doc.select("img");
        for (Element img : imgs) {
            String src = img.absUrl("src");
            if (src.contains("event_cover_image_vertical") || src.contains("event_cover_image_horizontal") || src.contains("publisher")) {
                if (!data.images.contains(src)) data.images.add(src);
            }
        }
    }

    private void extractBookMyShowSpecifics(Document doc, ScrapedData data) {
        // Look for venue breadcrumbs or city badges
        Elements cityElem = doc.select("[data-city], .event-venue-city, .venue-name");
        if (cityElem != null && !cityElem.text().isBlank() && (data.city == null || data.city.isBlank())) {
            data.city = cityElem.first().text().trim();
        }
    }

    private void extractShowmatesSpecifics(Document doc, ScrapedData data) {
        Elements posters = doc.select(".poster img, .event-card img, .hero-poster img");
        for (Element p : posters) {
            String src = p.absUrl("src");
            if (!src.isEmpty() && !data.images.contains(src)) data.images.add(src);
        }
    }

    private void inferCityIfMissing(ScrapedData data, String url) {
        if (data.city != null && !data.city.isBlank()) return;

        List<String> cities = List.of(
                "Ahmedabad", "Gandhinagar", "Vadodara", "Baroda", "Surat", "Rajkot", "Bhavnagar",
                "Mumbai", "Pune", "Delhi", "Bengaluru", "Bangalore", "Goa", "Jaipur", "Hyderabad",
                "Kolkata", "Chennai", "Indore", "Udaipur", "Chandigarh"
        );

        String combined = (url + " " + (data.title != null ? data.title : "") + " " + (data.venue != null ? data.venue : "")).toLowerCase();
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
        if (title == null || title.isBlank() || title.equalsIgnoreCase("Imported Web Event")) {
            // Extract from URL path
            if (data.sourceUrl != null) {
                try {
                    URI u = URI.create(data.sourceUrl);
                    String path = u.getPath();
                    if (path != null && !path.isBlank()) {
                        String[] parts = path.split("/");
                        for (int i = parts.length - 1; i >= 0; i--) {
                            String segment = parts[i].trim();
                            if (!segment.isEmpty() && !segment.matches("^[0-9A-Z]{4,10}$") && !segment.equals("events") && !segment.equals("explore")) {
                                String readable = segment.replace("-", " ").replace("_", " ");
                                title = capitalizeWords(readable);
                                break;
                            }
                        }
                    }
                } catch (Exception ignored) {}
            }
        }
        if (title == null || title.isBlank()) {
            title = "Imported Web Event";
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
                .description(data.description != null ? data.description : "Experience the premier nightlife event with live artist performances.")
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
        if (data.artists.isEmpty()) {
            return; // Zero fabrication rule
        }

        for (int i = 0; i < data.artists.size(); i++) {
            String name = data.artists.get(i);
            String slug = name.toLowerCase().replaceAll("[^a-z0-9-]+", "-");
            Optional<Artist> existing = artistRepository.findBySlug(slug);

            DayArtistImportDto artistDto = DayArtistImportDto.builder()
                    .dayNumber(1)
                    .artistName(name)
                    .artistType("SINGER")
                    .isPrimary(i == 0)
                    .performanceOrder(i + 1)
                    .performanceStartTime(LocalTime.of(20, 30))
                    .performanceEndTime(LocalTime.of(23, 30))
                    .isExistingArtist(existing.isPresent())
                    .matchedArtistId(existing.map(Artist::getId).orElse(null))
                    .build();

            if (!days.isEmpty()) {
                days.get(0).getArtists().add(artistDto);
            }
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
    }
}
