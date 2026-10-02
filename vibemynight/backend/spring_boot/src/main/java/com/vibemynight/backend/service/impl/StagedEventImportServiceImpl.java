package com.vibemynight.backend.service.impl;

import com.vibemynight.backend.dto.importing.*;
import com.vibemynight.backend.entity.*;
import com.vibemynight.backend.repository.EventRepository;
import com.vibemynight.backend.service.StagedEventImportService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.temporal.ChronoUnit;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class StagedEventImportServiceImpl implements StagedEventImportService {

    private final EventRepository eventRepository;

    @Value("${app.staging.api-url:http://localhost:8000}")
    private String stagingApiUrl;

    @Value("${app.staging.api-key:}")
    private String stagingApiKey;

    private RestTemplate getRestTemplate() {
        return new RestTemplateBuilder()
                .setConnectTimeout(Duration.ofSeconds(5))
                .setReadTimeout(Duration.ofSeconds(10))
                .build();
    }

    private HttpHeaders createAuthHeaders() {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setAccept(List.of(MediaType.APPLICATION_JSON));
        if (stagingApiKey != null && !stagingApiKey.isBlank()) {
            headers.set("Authorization", "Bearer " + stagingApiKey);
        }
        return headers;
    }

    private String generateSlug(String title) {
        if (title == null || title.isBlank()) {
            return "event-" + System.currentTimeMillis();
        }
        String slug = title.toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9]+", "-")
                .replaceAll("^-+|-+$", "");
        return slug.isBlank() ? "event-" + System.currentTimeMillis() : slug;
    }

    private LocalDate parseDateOrDefault(String dateStr, LocalDate defaultDate) {
        if (dateStr == null || dateStr.isBlank()) {
            return defaultDate;
        }
        try {
            return LocalDate.parse(dateStr.trim());
        } catch (Exception e) {
            log.debug("Could not parse date string '{}': {}", dateStr, e.getMessage());
            return defaultDate;
        }
    }

    private LocalTime parseTimeOrDefault(String timeStr, LocalTime defaultTime) {
        if (timeStr == null || timeStr.isBlank()) {
            return defaultTime;
        }
        try {
            String trimmed = timeStr.trim();
            if (trimmed.length() == 5) {
                return LocalTime.parse(trimmed);
            }
            return defaultTime;
        } catch (Exception e) {
            return defaultTime;
        }
    }

    @Override
    public StagedImportBatchResultDto importStagedEvents(StagedEventImportRequest request, String adminUsername) {
        List<Integer> ids = request.getStagedEventIds();
        log.info("Admin '{}' requested import for {} staged event IDs", adminUsername, ids.size());

        List<StagedEventImportResultItemDto> results = new ArrayList<>();
        int importedCount = 0;
        int alreadyImportedCount = 0;
        int conflictCount = 0;
        int failedCount = 0;

        // Deduplicate IDs in request
        Set<Integer> uniqueIds = new LinkedHashSet<>(ids);
        RestTemplate restTemplate = getRestTemplate();

        for (Integer stagedId : uniqueIds) {
            try {
                // 1. Fetch staged event details from Staging API
                String fetchUrl = stagingApiUrl + "/api/v1/sync/events/" + stagedId;
                HttpEntity<Void> reqEntity = new HttpEntity<>(createAuthHeaders());
                ResponseEntity<StagedEventDto> response = restTemplate.exchange(
                        fetchUrl,
                        HttpMethod.GET,
                        reqEntity,
                        StagedEventDto.class
                );

                StagedEventDto stagedEvent = response.getBody();
                if (stagedEvent == null) {
                    failedCount++;
                    results.add(StagedEventImportResultItemDto.builder()
                            .stagedEventId(stagedId)
                            .status("FAILED")
                            .reason("EMPTY_STAGING_RESPONSE")
                            .build());
                    continue;
                }

                // 2. Perform single event atomic import
                StagedEventImportResultItemDto itemResult = importSingleStagedEvent(stagedEvent, adminUsername);
                results.add(itemResult);

                if ("IMPORTED".equals(itemResult.getStatus())) {
                    importedCount++;
                    // 3. Notify Staging API that this event is now IMPORTED
                    updateStagingStatusToImported(stagedId, itemResult.getProductionEventId());
                } else if ("ALREADY_IMPORTED".equals(itemResult.getStatus())) {
                    alreadyImportedCount++;
                } else if ("CONFLICT".equals(itemResult.getStatus())) {
                    conflictCount++;
                } else {
                    failedCount++;
                }

            } catch (Exception e) {
                log.error("Failed to process staged event #{}: {}", stagedId, e.getMessage());
                failedCount++;
                results.add(StagedEventImportResultItemDto.builder()
                        .stagedEventId(stagedId)
                        .status("FAILED")
                        .reason("FETCH_OR_IMPORT_EXCEPTION: " + e.getMessage())
                        .build());
            }
        }

        return StagedImportBatchResultDto.builder()
                .success(failedCount == 0 && conflictCount == 0)
                .totalRequested(uniqueIds.size())
                .imported(importedCount)
                .alreadyImported(alreadyImportedCount)
                .conflicts(conflictCount)
                .failed(failedCount)
                .results(results)
                .build();
    }

    @Override
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public StagedEventImportResultItemDto importSingleStagedEvent(StagedEventDto stagedEvent, String adminUsername) {
        Integer stagedId = stagedEvent.getId();
        String rawTitle = stagedEvent.getTitle();
        String effectiveTitle = (stagedEvent.getEnhanced_title() != null && !stagedEvent.getEnhanced_title().isBlank())
                ? stagedEvent.getEnhanced_title()
                : rawTitle;

        if (effectiveTitle == null || effectiveTitle.isBlank()) {
            return StagedEventImportResultItemDto.builder()
                    .stagedEventId(stagedId)
                    .status("REJECTED")
                    .reason("TITLE_REQUIRED")
                    .build();
        }

        // Status validation: Reject duplicate or failed items
        String stagedStatus = stagedEvent.getStatus();
        if ("DUPLICATE".equalsIgnoreCase(stagedStatus)) {
            return StagedEventImportResultItemDto.builder()
                    .stagedEventId(stagedId)
                    .status("REJECTED")
                    .reason("EVENT_FLAGGED_AS_DUPLICATE_IN_STAGING")
                    .build();
        }
        if ("IMPORTED".equalsIgnoreCase(stagedStatus)) {
            return StagedEventImportResultItemDto.builder()
                    .stagedEventId(stagedId)
                    .status("ALREADY_IMPORTED")
                    .reason("ALREADY_MARKED_IMPORTED_IN_STAGING")
                    .build();
        }

        // Slug uniqueness check
        String baseSlug = generateSlug(effectiveTitle);
        Optional<Event> existingBySlug = eventRepository.findBySlug(baseSlug);
        if (existingBySlug.isPresent()) {
            log.warn("Production event with slug '{}' already exists. Rejecting import to protect existing data.", baseSlug);
            return StagedEventImportResultItemDto.builder()
                    .stagedEventId(stagedId)
                    .status("CONFLICT")
                    .productionEventId(existingBySlug.get().getId())
                    .eventName(existingBySlug.get().getName())
                    .slug(baseSlug)
                    .reason("EVENT_SLUG_ALREADY_EXISTS")
                    .build();
        }

        // Parse dates
        LocalDate startDate = parseDateOrDefault(stagedEvent.getEvent_start_date(), LocalDate.now().plusDays(7));
        LocalDate endDate = parseDateOrDefault(stagedEvent.getEvent_end_date(), startDate);
        if (endDate.isBefore(startDate)) {
            endDate = startDate;
        }

        // Parse images
        String mainImg = stagedEvent.getPoster_url() != null ? stagedEvent.getPoster_url() : stagedEvent.getBanner_url();
        String bannerImg = stagedEvent.getBanner_url() != null ? stagedEvent.getBanner_url() : stagedEvent.getPoster_url();
        String thumbImg = mainImg;

        // Build Event entity
        Event event = Event.builder()
                .name(effectiveTitle)
                .slug(baseSlug)
                .mainImage(mainImg)
                .banner(bannerImg)
                .thumbnail(thumbImg)
                .description(stagedEvent.getCatchy_description() != null ? stagedEvent.getCatchy_description() : stagedEvent.getDescription())
                .startDate(startDate)
                .endDate(endDate)
                .venue(stagedEvent.getVenue_name())
                .address(stagedEvent.getVenue_address())
                .city(stagedEvent.getCity() != null ? stagedEvent.getCity() : "Ahmedabad")
                .location(stagedEvent.getCity() != null ? stagedEvent.getCity() : "Gujarat")
                .status(EventStatus.PUBLISHED)
                .featured(Boolean.FALSE)
                .showInHero(Boolean.FALSE)
                .build();

        // Add Highlights
        if (stagedEvent.getHighlights() != null && !stagedEvent.getHighlights().isEmpty()) {
            int order = 0;
            for (String hl : stagedEvent.getHighlights()) {
                if (hl != null && !hl.isBlank()) {
                    EventHighlight highlight = EventHighlight.builder()
                            .event(event)
                            .text(hl.trim())
                            .sortOrder(order++)
                            .build();
                    event.getHighlights().add(highlight);
                }
            }
        }

        // Add Default Rules
        List<String> defaultRules = List.of(
                "Entry allowed only with a valid digital QR pass.",
                "Passes are non-refundable and non-transferable.",
                "Management reserves the right of admission."
        );
        int ruleOrder = 0;
        for (String r : defaultRules) {
            EventRule rule = EventRule.builder()
                    .event(event)
                    .text(r)
                    .sortOrder(ruleOrder++)
                    .build();
            event.getRules().add(rule);
        }

        // Construct EventDays hierarchy
        long totalDays = ChronoUnit.DAYS.between(startDate, endDate) + 1;
        if (totalDays < 1) totalDays = 1;
        if (totalDays > 30) totalDays = 30; // Guard against crazy intervals

        LocalTime startTime = parseTimeOrDefault(stagedEvent.getStart_time(), LocalTime.of(19, 30));
        LocalTime endTime = parseTimeOrDefault(stagedEvent.getEnd_time(), LocalTime.of(23, 59));

        double minPrice = (stagedEvent.getMin_ticket_price() != null && stagedEvent.getMin_ticket_price() > 0)
                ? stagedEvent.getMin_ticket_price()
                : 499.0;
        double maxPrice = (stagedEvent.getMax_ticket_price() != null && stagedEvent.getMax_ticket_price() >= minPrice)
                ? stagedEvent.getMax_ticket_price()
                : minPrice;

        for (int i = 0; i < totalDays; i++) {
            LocalDate currentDayDate = startDate.plusDays(i);
            EventDay eventDay = EventDay.builder()
                    .event(event)
                    .dayNumber(i + 1)
                    .date(currentDayDate)
                    .dayName("Day " + (i + 1))
                    .programName(effectiveTitle + " - Day " + (i + 1))
                    .startTime(startTime)
                    .endTime(endTime)
                    .venue(stagedEvent.getVenue_name())
                    .address(stagedEvent.getVenue_address())
                    .status(ActiveStatus.ACTIVE)
                    .build();

            // Create Standard Pass
            TicketCategory generalPass = TicketCategory.builder()
                    .eventDay(eventDay)
                    .name("General Entry Pass")
                    .type(TicketType.REGULAR)
                    .price(BigDecimal.valueOf(minPrice))
                    .availableQuantity(500)
                    .maxPerCustomer(10)
                    .description("Full event access for Day " + (i + 1))
                    .status(ActiveStatus.ACTIVE)
                    .build();
            eventDay.getTicketCategories().add(generalPass);

            // If max price is significantly higher, add VIP Category
            if (maxPrice > minPrice) {
                TicketCategory vipPass = TicketCategory.builder()
                        .eventDay(eventDay)
                        .name("VIP Pass")
                        .type(TicketType.VIP)
                        .price(BigDecimal.valueOf(maxPrice))
                        .availableQuantity(100)
                        .maxPerCustomer(10)
                        .description("Priority VIP entry, lounge access & refreshments")
                        .status(ActiveStatus.ACTIVE)
                        .build();
                eventDay.getTicketCategories().add(vipPass);
            }

            event.getEventDays().add(eventDay);
        }

        // Persist complete entity graph inside transactional boundary
        Event savedEvent = eventRepository.save(event);
        log.info("Successfully imported staged event #{} into production Event ID #{}", stagedId, savedEvent.getId());

        return StagedEventImportResultItemDto.builder()
                .stagedEventId(stagedId)
                .status("IMPORTED")
                .productionEventId(savedEvent.getId())
                .eventName(savedEvent.getName())
                .slug(savedEvent.getSlug())
                .build();
    }

    private void updateStagingStatusToImported(Integer stagedId, Long prodEventId) {
        try {
            String updateUrl = stagingApiUrl + "/api/v1/sync/events/" + stagedId;
            RestTemplate restTemplate = getRestTemplate();
            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(
                    Map.of("status", "IMPORTED"),
                    createAuthHeaders()
            );
            restTemplate.exchange(updateUrl, HttpMethod.PUT, entity, Void.class);
            log.info("Updated staging event #{} status to 'IMPORTED'", stagedId);
        } catch (Exception e) {
            log.warn("Could not notify staging service of import for event #{}: {}", stagedId, e.getMessage());
        }
    }
}
