package com.vibemynight.backend.service.impl;

import com.vibemynight.backend.dto.EventDetailDto;
import com.vibemynight.backend.dto.importing.*;
import com.vibemynight.backend.entity.*;
import com.vibemynight.backend.exception.BadRequestException;
import com.vibemynight.backend.mapper.EventMapper;
import com.vibemynight.backend.repository.*;
import com.vibemynight.backend.service.EventImportService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFCellStyle;
import org.apache.poi.xssf.usermodel.XSSFColor;
import org.apache.poi.xssf.usermodel.XSSFFont;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class EventImportServiceImpl implements EventImportService {

    private final EventRepository eventRepository;
    private final EventDayRepository eventDayRepository;
    private final TicketCategoryRepository ticketCategoryRepository;
    private final ArtistRepository artistRepository;
    private final EventDayArtistRepository eventDayArtistRepository;
    private final FacilityRepository facilityRepository;
    private final EventFacilityRepository eventFacilityRepository;
    private final EventDayFacilityRepository eventDayFacilityRepository;
    private final EventHighlightRepository eventHighlightRepository;
    private final EventRuleRepository eventRuleRepository;
    private final EventGalleryRepository eventGalleryRepository;
    private final EventMapper eventMapper;

    @Override
    @Transactional(readOnly = true)
    public EventImportPreviewDto parseAndValidate(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BadRequestException("Uploaded file is empty");
        }

        List<ValidationMessageDto> validationMessages = new ArrayList<>();
        EventHeaderImportDto eventHeader = null;
        List<EventDayImportDto> days = new ArrayList<>();
        List<FacilityImportDto> eventFacilities = new ArrayList<>();
        List<String> highlights = new ArrayList<>();
        List<String> rules = new ArrayList<>();
        List<String> galleryUrls = new ArrayList<>();

        try (InputStream is = file.getInputStream(); Workbook workbook = WorkbookFactory.create(is)) {

            // 1. Sheet: EVENT
            Sheet eventSheet = findSheet(workbook, "EVENT", "EVENTS", "EVENT_INFO");
            if (eventSheet == null) {
                validationMessages.add(ValidationMessageDto.error("WORKBOOK", 1, "EVENT", "Sheet 'EVENT' is missing in workbook."));
            } else {
                eventHeader = parseEventSheet(eventSheet, validationMessages);
            }

            // 2. Sheet: DAYS
            Sheet daysSheet = findSheet(workbook, "DAYS", "EVENT_DAYS", "SCHEDULE");
            if (daysSheet == null) {
                validationMessages.add(ValidationMessageDto.error("WORKBOOK", 1, "DAYS", "Sheet 'DAYS' is missing in workbook."));
            } else {
                days = parseDaysSheet(daysSheet, validationMessages, eventHeader);
            }

            // 3. Sheet: PASSES
            Sheet passesSheet = findSheet(workbook, "PASSES", "TICKETS", "PASS_CATEGORIES");
            if (passesSheet != null) {
                parsePassesSheet(passesSheet, days, validationMessages);
            } else {
                validationMessages.add(ValidationMessageDto.warning("WORKBOOK", 1, "PASSES", "Sheet 'PASSES' not found. Event will have no passes created by default."));
            }

            // 4. Sheet: ARTISTS
            Sheet artistsSheet = findSheet(workbook, "ARTISTS", "DAY_ARTISTS", "LINEUP");
            if (artistsSheet != null) {
                parseArtistsSheet(artistsSheet, days, validationMessages);
            }

            // 5. Sheet: FACILITIES
            Sheet facilitiesSheet = findSheet(workbook, "FACILITIES", "EVENT_FACILITIES", "AMENITIES");
            if (facilitiesSheet != null) {
                parseFacilitiesSheet(facilitiesSheet, days, eventFacilities, validationMessages);
            }

            // 6. Sheet: HIGHLIGHTS_AND_RULES
            Sheet hrSheet = findSheet(workbook, "HIGHLIGHTS_AND_RULES", "HIGHLIGHTS", "RULES");
            if (hrSheet != null) {
                parseHighlightsAndRulesSheet(hrSheet, highlights, rules, galleryUrls, validationMessages);
            }

        } catch (Exception e) {
            log.error("Failed to parse Excel workbook", e);
            throw new BadRequestException("Invalid Excel file format or corrupted structure: " + e.getMessage());
        }

        // Global Validation Checks
        if (eventHeader != null) {
            if (eventHeader.getName() == null || eventHeader.getName().isBlank()) {
                validationMessages.add(ValidationMessageDto.error("EVENT", 2, "name", "Event name is required."));
            }
            if (eventHeader.getStartDate() == null) {
                validationMessages.add(ValidationMessageDto.error("EVENT", 2, "start_date", "Event start date is required."));
            }
            if (eventHeader.getEndDate() == null) {
                validationMessages.add(ValidationMessageDto.error("EVENT", 2, "end_date", "Event end date is required."));
            }
            if (eventHeader.getStartDate() != null && eventHeader.getEndDate() != null && eventHeader.getStartDate().isAfter(eventHeader.getEndDate())) {
                validationMessages.add(ValidationMessageDto.error("EVENT", 2, "date_range", "Event start date cannot be after end date."));
            }
            if (eventHeader.getCity() == null || eventHeader.getCity().isBlank()) {
                validationMessages.add(ValidationMessageDto.error("EVENT", 2, "city", "Event city is required."));
            }

            // Check slug collision
            if (eventHeader.getSlug() != null && !eventHeader.getSlug().isBlank()) {
                if (eventRepository.existsBySlug(eventHeader.getSlug())) {
                    validationMessages.add(ValidationMessageDto.warning("EVENT", 2, "slug", "An event with slug '" + eventHeader.getSlug() + "' already exists. A unique suffix will be appended if imported."));
                }
            }
        }

        if (days.isEmpty()) {
            validationMessages.add(ValidationMessageDto.error("DAYS", 1, "days", "Event must have at least one day defined in 'DAYS' sheet."));
        }

        int totalPasses = days.stream().mapToInt(d -> d.getPasses().size()).sum();
        int totalArtists = days.stream().mapToInt(d -> d.getArtists().size()).sum();
        boolean hasBlockingErrors = validationMessages.stream().anyMatch(v -> "ERROR".equalsIgnoreCase(v.getLevel()));

        return EventImportPreviewDto.builder()
                .event(eventHeader)
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

    @Override
    @Transactional(rollbackFor = Exception.class)
    @CacheEvict(value = {"events", "event_details"}, allEntries = true)
    public EventDetailDto confirmAndCreate(EventImportPreviewDto preview) {
        if (preview == null || preview.getEvent() == null) {
            throw new BadRequestException("Import preview payload is missing or empty");
        }
        if (preview.isHasBlockingErrors()) {
            throw new BadRequestException("Cannot create event with blocking validation errors. Please resolve them first.");
        }

        EventHeaderImportDto header = preview.getEvent();

        // 1. Generate safe unique slug
        String baseSlug = (header.getSlug() != null && !header.getSlug().isBlank())
                ? header.getSlug().toLowerCase().replaceAll("[^a-z0-9-]+", "-")
                : header.getName().toLowerCase().replaceAll("[^a-z0-9-]+", "-");
        baseSlug = baseSlug.replaceAll("^-+|-+$", "");
        if (baseSlug.isBlank()) baseSlug = "event-" + System.currentTimeMillis();

        String finalSlug = baseSlug;
        int suffix = 1;
        while (eventRepository.existsBySlug(finalSlug)) {
            finalSlug = baseSlug + "-" + (++suffix);
        }

        EventStatus status = EventStatus.DRAFT;
        if (header.getStatus() != null) {
            try {
                status = EventStatus.valueOf(header.getStatus().toUpperCase());
            } catch (Exception ignored) {}
        }

        String resolvedMainImage = resolveDurableUrl(header.getMainImage(), preview.getArtworkCandidates(), "POSTER_3_4");
        String resolvedBanner = resolveDurableUrl(header.getBanner(), preview.getArtworkCandidates(), "BANNER_16_9");
        String resolvedThumbnail = resolveDurableUrl(header.getThumbnail(), preview.getArtworkCandidates(), "THUMBNAIL_1_1");
        if (resolvedThumbnail == null || resolvedThumbnail.isBlank()) resolvedThumbnail = resolvedMainImage;
        if (resolvedBanner == null || resolvedBanner.isBlank()) resolvedBanner = resolvedMainImage;

        // 2. Persist Event Header
        Event event = Event.builder()
                .name(header.getName())
                .slug(finalSlug)
                .startDate(header.getStartDate())
                .endDate(header.getEndDate())
                .venue(header.getVenue())
                .address(header.getAddress())
                .city(header.getCity())
                .location(header.getLocation())
                .googleMapsUrl(header.getGoogleMapsUrl())
                .organizer(header.getOrganizer())
                .contactNumber(header.getContactNumber())
                .email(header.getEmail())
                .description(header.getDescription())
                .featured(header.isFeatured())
                .status(status)
                .mainImage(resolvedMainImage)
                .banner(resolvedBanner)
                .thumbnail(resolvedThumbnail)
                .build();

        Event savedEvent = eventRepository.save(event);

        // 3. Persist Event Days, Passes, and Day Artists
        for (EventDayImportDto dayDto : preview.getDays()) {
            EventDay day = EventDay.builder()
                    .event(savedEvent)
                    .dayNumber(dayDto.getDayNumber())
                    .date(dayDto.getDate())
                    .dayName(dayDto.getDayName())
                    .programName(dayDto.getProgramName())
                    .startTime(dayDto.getStartTime())
                    .endTime(dayDto.getEndTime())
                    .venue(dayDto.getVenue() != null && !dayDto.getVenue().isBlank() ? dayDto.getVenue() : savedEvent.getVenue())
                    .address(dayDto.getAddress() != null && !dayDto.getAddress().isBlank() ? dayDto.getAddress() : savedEvent.getAddress())
                    .location(dayDto.getLocation() != null && !dayDto.getLocation().isBlank() ? dayDto.getLocation() : savedEvent.getLocation())
                    .googleMapsUrl(dayDto.getGoogleMapsUrl() != null && !dayDto.getGoogleMapsUrl().isBlank() ? dayDto.getGoogleMapsUrl() : savedEvent.getGoogleMapsUrl())
                    .description(dayDto.getDescription())
                    .status(ActiveStatus.ACTIVE)
                    .build();

            EventDay savedDay = eventDayRepository.save(day);

            // Passes for this day
            if (dayDto.getPasses() != null) {
                for (PassImportDto passDto : dayDto.getPasses()) {
                    TicketType type = TicketType.REGULAR;
                    if (passDto.getType() != null) {
                        try {
                            type = TicketType.valueOf(passDto.getType().toUpperCase());
                        } catch (Exception ignored) {}
                    }

                    TicketCategory ticket = TicketCategory.builder()
                            .eventDay(savedDay)
                            .name(passDto.getName())
                            .type(type)
                            .price(passDto.getPrice() != null ? passDto.getPrice() : BigDecimal.ZERO)
                            .availableQuantity(passDto.getAvailableQuantity() != null ? passDto.getAvailableQuantity() : 100)
                            .maxPerCustomer(passDto.getMaxPerCustomer() != null ? passDto.getMaxPerCustomer() : 10)
                            .description(passDto.getDescription())
                            .benefits(passDto.getBenefits() != null ? new ArrayList<>(passDto.getBenefits()) : new ArrayList<>())
                            .status(ActiveStatus.ACTIVE)
                            .build();

                    ticketCategoryRepository.save(ticket);
                }
            }

            // Artists for this day
            if (dayDto.getArtists() != null) {
                Set<Long> processedArtistIds = new HashSet<>();
                for (DayArtistImportDto artistDto : dayDto.getArtists()) {
                    Artist artist = resolveOrCreateArtist(artistDto);
                    if (artist == null || processedArtistIds.contains(artist.getId())) {
                        continue;
                    }
                    processedArtistIds.add(artist.getId());

                    if (!eventDayArtistRepository.existsByEventDayIdAndArtistId(savedDay.getId(), artist.getId())) {
                        EventDayArtist dayArtist = EventDayArtist.builder()
                                .eventDay(savedDay)
                                .artist(artist)
                                .isPrimary(artistDto.isPrimary())
                                .performanceOrder(artistDto.getPerformanceOrder() != null ? artistDto.getPerformanceOrder() : 1)
                                .performanceStartTime(artistDto.getPerformanceStartTime())
                                .performanceEndTime(artistDto.getPerformanceEndTime())
                                .build();
                        eventDayArtistRepository.save(dayArtist);
                    }
                }
            }

            // Day-level facilities
            if (dayDto.getFacilities() != null) {
                for (FacilityImportDto facDto : dayDto.getFacilities()) {
                    Facility fac = resolveOrCreateFacility(facDto);
                    if (!eventDayFacilityRepository.existsByEventDayIdAndFacilityId(savedDay.getId(), fac.getId())) {
                        eventDayFacilityRepository.save(EventDayFacility.builder().eventDay(savedDay).facility(fac).build());
                    }
                }
            }
        }

        // 4. Persist Event-level Facilities
        if (preview.getEventFacilities() != null) {
            for (FacilityImportDto facDto : preview.getEventFacilities()) {
                Facility fac = resolveOrCreateFacility(facDto);
                if (!eventFacilityRepository.existsByEventIdAndFacilityId(savedEvent.getId(), fac.getId())) {
                    eventFacilityRepository.save(EventFacility.builder().event(savedEvent).facility(fac).build());
                }
            }
        }

        // 5. Highlights
        if (preview.getHighlights() != null) {
            int order = 0;
            for (String hl : preview.getHighlights()) {
                if (hl != null && !hl.isBlank()) {
                    eventHighlightRepository.save(EventHighlight.builder().event(savedEvent).text(hl.trim()).sortOrder(++order).build());
                }
            }
        }

        // 6. Rules
        if (preview.getRules() != null) {
            int order = 0;
            for (String r : preview.getRules()) {
                if (r != null && !r.isBlank()) {
                    eventRuleRepository.save(EventRule.builder().event(savedEvent).text(r.trim()).sortOrder(++order).build());
                }
            }
        }

        // 7. Gallery
        if (preview.getGalleryImageUrls() != null) {
            int order = 0;
            for (String url : preview.getGalleryImageUrls()) {
                if (url != null && !url.isBlank()) {
                    eventGalleryRepository.save(EventGallery.builder().event(savedEvent).imageUrl(url.trim()).sortOrder(++order).build());
                }
            }
        }

        // Return mapped event detail DTO
        Event reloaded = eventRepository.findById(savedEvent.getId()).orElse(savedEvent);
        List<Facility> allFacs = eventFacilityRepository.findByEventId(reloaded.getId()).stream().map(EventFacility::getFacility).toList();
        return eventMapper.toDetailDto(reloaded, allFacs);
    }

    private Artist resolveOrCreateArtist(DayArtistImportDto artistDto) {
        String name = artistDto.getArtistName() != null ? artistDto.getArtistName().trim() : "Artist";
        String slug = name.toLowerCase().replaceAll("[^a-z0-9-]+", "-").replaceAll("^-+|-+$", "");
        if (slug.isBlank()) slug = "artist-" + System.currentTimeMillis();

        Optional<Artist> existing = artistRepository.findBySlug(slug);
        if (existing.isPresent()) {
            return existing.get();
        }

        ArtistType type = ArtistType.SINGER;
        if (artistDto.getArtistType() != null) {
            try {
                type = ArtistType.valueOf(artistDto.getArtistType().toUpperCase());
            } catch (Exception ignored) {}
        }

        Artist newArtist = Artist.builder()
                .name(name)
                .slug(slug)
                .type(type)
                .photoUrl(artistDto.getPhotoUrl())
                .instagramUrl(artistDto.getInstagramUrl())
                .status(ActiveStatus.ACTIVE)
                .build();
        return artistRepository.save(newArtist);
    }

    private Facility resolveOrCreateFacility(FacilityImportDto facDto) {
        String name = facDto.getName() != null ? facDto.getName().trim() : "Facility";
        Optional<Facility> existing = facilityRepository.findByNameIgnoreCase(name);
        if (existing.isPresent()) {
            return existing.get();
        }

        Facility newFac = Facility.builder()
                .name(name)
                .icon(facDto.getIcon() != null ? facDto.getIcon() : "star")
                .description(facDto.getDescription())
                .status(ActiveStatus.ACTIVE)
                .build();
        return facilityRepository.save(newFac);
    }

    // ==========================================
    // EXCEL PARSING LOGIC
    // ==========================================

    private Sheet findSheet(Workbook wb, String... names) {
        for (String name : names) {
            Sheet sheet = wb.getSheet(name);
            if (sheet != null) return sheet;
        }
        for (int i = 0; i < wb.getNumberOfSheets(); i++) {
            String sheetName = wb.getSheetName(i).toUpperCase().trim();
            for (String target : names) {
                if (sheetName.contains(target.toUpperCase())) {
                    return wb.getSheetAt(i);
                }
            }
        }
        return null;
    }

    private EventHeaderImportDto parseEventSheet(Sheet sheet, List<ValidationMessageDto> messages) {
        Row row = sheet.getRow(1); // Row 0 is header, Row 1 is data
        if (row == null) {
            messages.add(ValidationMessageDto.error("EVENT", 2, "EVENT", "Sheet 'EVENT' has no data row (expected on row 2)."));
            return EventHeaderImportDto.builder().build();
        }

        String name = getCellString(row, 0);
        String slug = getCellString(row, 1);
        LocalDate startDate = getCellDate(row, 2);
        LocalDate endDate = getCellDate(row, 3);
        String venue = getCellString(row, 4);
        String address = getCellString(row, 5);
        String city = getCellString(row, 6);
        String location = getCellString(row, 7);
        String mapsUrl = getCellString(row, 8);
        String organizer = getCellString(row, 9);
        String contact = getCellString(row, 10);
        String email = getCellString(row, 11);
        String description = getCellString(row, 12);
        boolean featured = "TRUE".equalsIgnoreCase(getCellString(row, 13));
        String status = getCellString(row, 14);
        String mainImage = getCellString(row, 15);
        String banner = getCellString(row, 16);
        String thumb = getCellString(row, 17);

        return EventHeaderImportDto.builder()
                .name(name)
                .slug(slug)
                .startDate(startDate)
                .endDate(endDate)
                .venue(venue)
                .address(address)
                .city(city)
                .location(location)
                .googleMapsUrl(mapsUrl)
                .organizer(organizer)
                .contactNumber(contact)
                .email(email)
                .description(description)
                .featured(featured)
                .status(status != null && !status.isBlank() ? status : "DRAFT")
                .mainImage(mainImage)
                .banner(banner)
                .thumbnail(thumb)
                .build();
    }

    private List<EventDayImportDto> parseDaysSheet(Sheet sheet, List<ValidationMessageDto> messages, EventHeaderImportDto header) {
        List<EventDayImportDto> days = new ArrayList<>();
        Set<Integer> seenDays = new HashSet<>();

        for (int r = 1; r <= sheet.getLastRowNum(); r++) {
            Row row = sheet.getRow(r);
            if (row == null || isRowEmpty(row)) continue;

            Integer dayNum = getCellInteger(row, 0);
            if (dayNum == null) {
                messages.add(ValidationMessageDto.error("DAYS", r + 1, "day_number", "Day number is missing or invalid on row " + (r + 1)));
                continue;
            }
            if (seenDays.contains(dayNum)) {
                messages.add(ValidationMessageDto.error("DAYS", r + 1, "day_number", "Duplicate day number " + dayNum + " on row " + (r + 1)));
                continue;
            }
            seenDays.add(dayNum);

            LocalDate date = getCellDate(row, 1);
            if (date == null) {
                messages.add(ValidationMessageDto.error("DAYS", r + 1, "date", "Date is required for Day " + dayNum));
            } else if (header != null && header.getStartDate() != null && header.getEndDate() != null) {
                if (date.isBefore(header.getStartDate()) || date.isAfter(header.getEndDate())) {
                    messages.add(ValidationMessageDto.warning("DAYS", r + 1, "date", "Day " + dayNum + " date (" + date + ") is outside event date window (" + header.getStartDate() + " to " + header.getEndDate() + ")"));
                }
            }

            String dayName = getCellString(row, 2);
            String progName = getCellString(row, 3);
            LocalTime startTime = getCellTime(row, 4);
            LocalTime endTime = getCellTime(row, 5);
            String venue = getCellString(row, 6);
            String desc = getCellString(row, 7);

            days.add(EventDayImportDto.builder()
                    .dayNumber(dayNum)
                    .date(date)
                    .dayName(dayName)
                    .programName(progName)
                    .startTime(startTime)
                    .endTime(endTime)
                    .venue(venue)
                    .description(desc)
                    .passes(new ArrayList<>())
                    .artists(new ArrayList<>())
                    .facilities(new ArrayList<>())
                    .build());
        }

        days.sort(Comparator.comparing(EventDayImportDto::getDayNumber));
        return days;
    }

    private void parsePassesSheet(Sheet sheet, List<EventDayImportDto> days, List<ValidationMessageDto> messages) {
        for (int r = 1; r <= sheet.getLastRowNum(); r++) {
            Row row = sheet.getRow(r);
            if (row == null || isRowEmpty(row)) continue;

            String dayNumStr = getCellString(row, 0);
            if (dayNumStr == null || dayNumStr.isBlank()) {
                messages.add(ValidationMessageDto.error("PASSES", r + 1, "day_number", "Pass row " + (r + 1) + " must specify a day_number (e.g. 1, 2 or ALL)"));
                continue;
            }

            String passName = getCellString(row, 1);
            if (passName == null || passName.isBlank()) {
                messages.add(ValidationMessageDto.error("PASSES", r + 1, "pass_name", "Pass name is missing on row " + (r + 1)));
                continue;
            }

            String passType = getCellString(row, 2);
            BigDecimal price = getCellBigDecimal(row, 3);
            if (price == null || price.compareTo(BigDecimal.ZERO) < 0) {
                messages.add(ValidationMessageDto.error("PASSES", r + 1, "price", "Invalid price for pass '" + passName + "' on row " + (r + 1)));
                price = BigDecimal.ZERO;
            }

            Integer qty = getCellInteger(row, 4);
            if (qty == null || qty < 0) {
                qty = 100;
            }

            Integer maxPerCust = getCellInteger(row, 5);
            if (maxPerCust == null || maxPerCust <= 0) {
                maxPerCust = 10;
            }

            String benefitsStr = getCellString(row, 6);
            List<String> benefits = new ArrayList<>();
            if (benefitsStr != null && !benefitsStr.isBlank()) {
                for (String b : benefitsStr.split("[;,\n]")) {
                    if (!b.trim().isEmpty()) benefits.add(b.trim());
                }
            }

            String desc = getCellString(row, 7);

            PassImportDto passDto = PassImportDto.builder()
                    .dayNumber(dayNumStr.trim())
                    .name(passName.trim())
                    .type(passType != null && !passType.isBlank() ? passType.toUpperCase().trim() : "REGULAR")
                    .price(price)
                    .availableQuantity(qty)
                    .maxPerCustomer(maxPerCust)
                    .benefits(benefits)
                    .description(desc)
                    .build();

            if ("ALL".equalsIgnoreCase(dayNumStr.trim())) {
                for (EventDayImportDto day : days) {
                    day.getPasses().add(passDto);
                }
            } else {
                try {
                    int dNum = Integer.parseInt(dayNumStr.replaceAll("[^0-9]", ""));
                    Optional<EventDayImportDto> targetDay = days.stream().filter(d -> d.getDayNumber() == dNum).findFirst();
                    if (targetDay.isPresent()) {
                        targetDay.get().getPasses().add(passDto);
                    } else {
                        messages.add(ValidationMessageDto.warning("PASSES", r + 1, "day_number", "Pass '" + passName + "' references Day " + dNum + " which does not exist in DAYS sheet."));
                    }
                } catch (Exception e) {
                    messages.add(ValidationMessageDto.error("PASSES", r + 1, "day_number", "Invalid day_number '" + dayNumStr + "' on row " + (r + 1)));
                }
            }
        }
    }

    private void parseArtistsSheet(Sheet sheet, List<EventDayImportDto> days, List<ValidationMessageDto> messages) {
        for (int r = 1; r <= sheet.getLastRowNum(); r++) {
            Row row = sheet.getRow(r);
            if (row == null || isRowEmpty(row)) continue;

            Integer dayNum = getCellInteger(row, 0);
            String artistName = getCellString(row, 1);
            if (artistName == null || artistName.isBlank()) continue;

            String artistType = getCellString(row, 2);
            boolean isPrimary = "TRUE".equalsIgnoreCase(getCellString(row, 3));
            Integer order = getCellInteger(row, 4);
            LocalTime startTime = getCellTime(row, 5);
            LocalTime endTime = getCellTime(row, 6);
            String photo = getCellString(row, 7);
            String ig = getCellString(row, 8);

            String slug = artistName.toLowerCase().replaceAll("[^a-z0-9-]+", "-");
            Optional<Artist> existing = artistRepository.findBySlug(slug);

            DayArtistImportDto artistDto = DayArtistImportDto.builder()
                    .dayNumber(dayNum != null ? dayNum : 1)
                    .artistName(artistName.trim())
                    .artistType(artistType != null && !artistType.isBlank() ? artistType.toUpperCase().trim() : "SINGER")
                    .isPrimary(isPrimary)
                    .performanceOrder(order != null ? order : 1)
                    .performanceStartTime(startTime)
                    .performanceEndTime(endTime)
                    .photoUrl(photo)
                    .instagramUrl(ig)
                    .isExistingArtist(existing.isPresent())
                    .matchedArtistId(existing.map(Artist::getId).orElse(null))
                    .build();

            if (dayNum == null) {
                // If no day specified, attach to Day 1
                if (!days.isEmpty()) days.get(0).getArtists().add(artistDto);
            } else {
                Optional<EventDayImportDto> targetDay = days.stream().filter(d -> d.getDayNumber().equals(dayNum)).findFirst();
                if (targetDay.isPresent()) {
                    targetDay.get().getArtists().add(artistDto);
                } else {
                    messages.add(ValidationMessageDto.warning("ARTISTS", r + 1, "day_number", "Artist '" + artistName + "' assigned to Day " + dayNum + " which does not exist in DAYS sheet."));
                }
            }
        }
    }

    private void parseFacilitiesSheet(Sheet sheet, List<EventDayImportDto> days, List<FacilityImportDto> eventFacilities, List<ValidationMessageDto> messages) {
        for (int r = 1; r <= sheet.getLastRowNum(); r++) {
            Row row = sheet.getRow(r);
            if (row == null || isRowEmpty(row)) continue;

            String facName = getCellString(row, 0);
            if (facName == null || facName.isBlank()) continue;

            String scope = getCellString(row, 1);
            String icon = getCellString(row, 2);
            String desc = getCellString(row, 3);

            Optional<Facility> existing = facilityRepository.findByNameIgnoreCase(facName.trim());

            FacilityImportDto facDto = FacilityImportDto.builder()
                    .name(facName.trim())
                    .scope(scope != null && !scope.isBlank() ? scope.trim().toUpperCase() : "EVENT")
                    .icon(icon)
                    .description(desc)
                    .isExistingFacility(existing.isPresent())
                    .matchedFacilityId(existing.map(Facility::getId).orElse(null))
                    .build();

            if (facDto.getScope().equalsIgnoreCase("EVENT") || facDto.getScope().equalsIgnoreCase("ALL")) {
                eventFacilities.add(facDto);
            } else {
                try {
                    int dNum = Integer.parseInt(facDto.getScope().replaceAll("[^0-9]", ""));
                    Optional<EventDayImportDto> targetDay = days.stream().filter(d -> d.getDayNumber() == dNum).findFirst();
                    if (targetDay.isPresent()) {
                        targetDay.get().getFacilities().add(facDto);
                    }
                } catch (Exception ignored) {
                    eventFacilities.add(facDto);
                }
            }
        }
    }

    private void parseHighlightsAndRulesSheet(Sheet sheet, List<String> highlights, List<String> rules, List<String> galleryUrls, List<ValidationMessageDto> messages) {
        for (int r = 1; r <= sheet.getLastRowNum(); r++) {
            Row row = sheet.getRow(r);
            if (row == null || isRowEmpty(row)) continue;

            String type = getCellString(row, 0);
            String text = getCellString(row, 1);
            if (text == null || text.isBlank()) continue;

            if ("HIGHLIGHT".equalsIgnoreCase(type)) {
                highlights.add(text.trim());
            } else if ("RULE".equalsIgnoreCase(type)) {
                rules.add(text.trim());
            } else if ("GALLERY".equalsIgnoreCase(type) || "IMAGE".equalsIgnoreCase(type)) {
                galleryUrls.add(text.trim());
            } else {
                highlights.add(text.trim());
            }
        }
    }

    // ==========================================
    // EXCEL TEMPLATE GENERATOR
    // ==========================================

    @Override
    public byte[] generateExcelTemplate() {
        try (XSSFWorkbook wb = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {

            XSSFCellStyle headerStyle = wb.createCellStyle();
            XSSFFont font = wb.createFont();
            font.setBold(true);
            font.setColor(IndexedColors.WHITE.getIndex());
            headerStyle.setFont(font);
            headerStyle.setFillForegroundColor(new XSSFColor(new byte[]{(byte) 0x7C, (byte) 0x3A, (byte) 0xED}, null)); // Neon Purple #7C3AED
            headerStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);

            // Sheet 1: EVENT
            Sheet sEvent = wb.createSheet("EVENT");
            Row er0 = sEvent.createRow(0);
            String[] eHeaders = {"name*", "slug", "start_date* (YYYY-MM-DD)", "end_date* (YYYY-MM-DD)", "venue", "address", "city*", "location", "google_maps_url", "organizer", "contact_number", "email", "description", "featured (TRUE/FALSE)", "status (PUBLISHED/DRAFT)", "main_image_url", "banner_url", "thumbnail_url"};
            for (int i = 0; i < eHeaders.length; i++) {
                Cell c = er0.createCell(i);
                c.setCellValue(eHeaders[i]);
                c.setCellStyle(headerStyle);
            }
            Row er1 = sEvent.createRow(1);
            er1.createCell(0).setCellValue("Navratri Grand Mahotsav 2026");
            er1.createCell(1).setCellValue("navratri-grand-mahotsav-2026");
            er1.createCell(2).setCellValue("2026-10-15");
            er1.createCell(3).setCellValue("2026-10-17");
            er1.createCell(4).setCellValue("Grand Arena");
            er1.createCell(5).setCellValue("Near SG Highway, Bodakdev");
            er1.createCell(6).setCellValue("Ahmedabad");
            er1.createCell(7).setCellValue("Bodakdev");
            er1.createCell(8).setCellValue("https://maps.google.com/?q=Ahmedabad");
            er1.createCell(9).setCellValue("VibeMyNight Entertainment");
            er1.createCell(10).setCellValue("+91 70416 15131");
            er1.createCell(11).setCellValue("events@vibemynight.com");
            er1.createCell(12).setCellValue("Grand 3-night Navratri Garba festival featuring celebrity singers and live orchestra.");
            er1.createCell(13).setCellValue("TRUE");
            er1.createCell(14).setCellValue("PUBLISHED");

            // Sheet 2: DAYS
            Sheet sDays = wb.createSheet("DAYS");
            Row dr0 = sDays.createRow(0);
            String[] dHeaders = {"day_number*", "date* (YYYY-MM-DD)", "day_name", "program_name", "start_time (HH:MM)", "end_time (HH:MM)", "venue", "description"};
            for (int i = 0; i < dHeaders.length; i++) {
                Cell c = dr0.createCell(i);
                c.setCellValue(dHeaders[i]);
                c.setCellStyle(headerStyle);
            }
            createDayRow(sDays, 1, 1, "2026-10-15", "Day 1 - Opening Night", "Grand Opening Garba", "20:00", "01:00", "Grand Arena Dome A", "Opening night with live orchestra");
            createDayRow(sDays, 2, 2, "2026-10-16", "Day 2 - Celebrity Night", "Garba with Stars", "20:00", "01:00", "Grand Arena Dome A", "Celebrity singer performance");
            createDayRow(sDays, 3, 3, "2026-10-17", "Day 3 - Grand Finale", "Maha Garba Night", "20:00", "02:00", "Grand Arena Dome A", "Grand mega finale night");

            // Sheet 3: PASSES
            Sheet sPasses = wb.createSheet("PASSES");
            Row pr0 = sPasses.createRow(0);
            String[] pHeaders = {"day_number* (1, 2 or ALL)", "pass_name*", "pass_type* (REGULAR/VIP/COUPLE/GROUP/EARLY_BIRD)", "price*", "available_quantity*", "max_per_customer", "benefits (semicolon-separated)", "description"};
            for (int i = 0; i < pHeaders.length; i++) {
                Cell c = pr0.createCell(i);
                c.setCellValue(pHeaders[i]);
                c.setCellStyle(headerStyle);
            }
            createPassRow(sPasses, 1, "ALL", "Regular Pass", "REGULAR", 499, 500, 10, "General Entry; Food Court Access", "Standard ground entry");
            createPassRow(sPasses, 2, "ALL", "VIP Pass", "VIP", 1299, 150, 5, "VIP Arena; Fast-track Entry; Complimentary Drinks", "Dedicated air-conditioned VIP lounge");
            createPassRow(sPasses, 3, "1", "Early Bird Couple Pass", "COUPLE", 799, 100, 2, "Couple Entry for 2; Complimentary Dandiya Sticks", "Special opening night discount");

            // Sheet 4: ARTISTS
            Sheet sArtists = wb.createSheet("ARTISTS");
            Row ar0 = sArtists.createRow(0);
            String[] aHeaders = {"day_number* (1, 2, 3)", "artist_name*", "artist_type (SINGER/DJ/BAND/CELEBRITY)", "is_primary (TRUE/FALSE)", "performance_order", "start_time", "end_time", "photo_url", "instagram_url"};
            for (int i = 0; i < aHeaders.length; i++) {
                Cell c = ar0.createCell(i);
                c.setCellValue(aHeaders[i]);
                c.setCellStyle(headerStyle);
            }
            createArtistRow(sArtists, 1, 1, "Falguni Pathak", "SINGER", "TRUE", 1, "21:00", "00:30", "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7", "https://instagram.com/falgunipathak");
            createArtistRow(sArtists, 2, 2, "Kinjal Dave", "SINGER", "TRUE", 1, "21:00", "00:30", "https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad", "https://instagram.com/kinjaldave");
            createArtistRow(sArtists, 3, 3, "Atul Purohit", "SINGER", "TRUE", 1, "20:30", "01:30", "https://images.unsplash.com/photo-1470225620780-dba8ba36b745", "https://instagram.com/atulpurohit");

            // Sheet 5: FACILITIES
            Sheet sFac = wb.createSheet("FACILITIES");
            Row fr0 = sFac.createRow(0);
            String[] fHeaders = {"facility_name*", "scope (EVENT or Day number 1, 2)", "icon", "description"};
            for (int i = 0; i < fHeaders.length; i++) {
                Cell c = fr0.createCell(i);
                c.setCellValue(fHeaders[i]);
                c.setCellStyle(headerStyle);
            }
            createFacRow(sFac, 1, "Free Valet Parking", "EVENT", "local_parking", "Spacious parking for over 1500 cars");
            createFacRow(sFac, 2, "Gourmet Food Court", "EVENT", "restaurant", "Over 25 vegetarian food & snack stalls");
            createFacRow(sFac, 3, "Doctor & First Aid on Site", "EVENT", "medical_services", "Emergency ambulance and first-aid center");

            // Sheet 6: HIGHLIGHTS_AND_RULES
            Sheet sHR = wb.createSheet("HIGHLIGHTS_AND_RULES");
            Row hrr0 = sHR.createRow(0);
            String[] hrHeaders = {"type (HIGHLIGHT / RULE / GALLERY)", "content*"};
            for (int i = 0; i < hrHeaders.length; i++) {
                Cell c = hrr0.createCell(i);
                c.setCellValue(hrHeaders[i]);
                c.setCellStyle(headerStyle);
            }
            createHRRow(sHR, 1, "HIGHLIGHT", "Air-conditioned 10,000 sq ft wooden Garba arena");
            createHRRow(sHR, 2, "HIGHLIGHT", "Over 500kW state-of-the-art Line Array concert sound system");
            createHRRow(sHR, 3, "RULE", "Traditional Indian attire is mandatory for arena entry");
            createHRRow(sHR, 4, "RULE", "No outside food, beverages, or sharp objects permitted");

            for (int i = 0; i < wb.getNumberOfSheets(); i++) {
                Sheet s = wb.getSheetAt(i);
                for (int col = 0; col < 10; col++) {
                    s.autoSizeColumn(col);
                }
            }

            wb.write(out);
            return out.toByteArray();
        } catch (Exception e) {
            log.error("Failed to generate Excel template", e);
            throw new RuntimeException("Failed to generate Excel template: " + e.getMessage(), e);
        }
    }

    private void createDayRow(Sheet s, int rowIdx, int dayNum, String date, String dayName, String progName, String start, String end, String venue, String desc) {
        Row r = s.createRow(rowIdx);
        r.createCell(0).setCellValue(dayNum);
        r.createCell(1).setCellValue(date);
        r.createCell(2).setCellValue(dayName);
        r.createCell(3).setCellValue(progName);
        r.createCell(4).setCellValue(start);
        r.createCell(5).setCellValue(end);
        r.createCell(6).setCellValue(venue);
        r.createCell(7).setCellValue(desc);
    }

    private void createPassRow(Sheet s, int rowIdx, String dayNum, String name, String type, double price, int qty, int maxPer, String benefits, String desc) {
        Row r = s.createRow(rowIdx);
        r.createCell(0).setCellValue(dayNum);
        r.createCell(1).setCellValue(name);
        r.createCell(2).setCellValue(type);
        r.createCell(3).setCellValue(price);
        r.createCell(4).setCellValue(qty);
        r.createCell(5).setCellValue(maxPer);
        r.createCell(6).setCellValue(benefits);
        r.createCell(7).setCellValue(desc);
    }

    private void createArtistRow(Sheet s, int rowIdx, int dayNum, String name, String type, String primary, int order, String start, String end, String photo, String ig) {
        Row r = s.createRow(rowIdx);
        r.createCell(0).setCellValue(dayNum);
        r.createCell(1).setCellValue(name);
        r.createCell(2).setCellValue(type);
        r.createCell(3).setCellValue(primary);
        r.createCell(4).setCellValue(order);
        r.createCell(5).setCellValue(start);
        r.createCell(6).setCellValue(end);
        r.createCell(7).setCellValue(photo);
        r.createCell(8).setCellValue(ig);
    }

    private void createFacRow(Sheet s, int rowIdx, String name, String scope, String icon, String desc) {
        Row r = s.createRow(rowIdx);
        r.createCell(0).setCellValue(name);
        r.createCell(1).setCellValue(scope);
        r.createCell(2).setCellValue(icon);
        r.createCell(3).setCellValue(desc);
    }

    private void createHRRow(Sheet s, int rowIdx, String type, String content) {
        Row r = s.createRow(rowIdx);
        r.createCell(0).setCellValue(type);
        r.createCell(1).setCellValue(content);
    }

    // ==========================================
    // CELL EXTRACTION UTILITIES
    // ==========================================

    private String getCellString(Row row, int col) {
        Cell cell = row.getCell(col);
        if (cell == null) return null;
        if (cell.getCellType() == CellType.STRING) {
            return cell.getStringCellValue().trim();
        } else if (cell.getCellType() == CellType.NUMERIC) {
            if (DateUtil.isCellDateFormatted(cell)) {
                return DateTimeFormatter.ISO_LOCAL_DATE.format(cell.getLocalDateTimeCellValue().toLocalDate());
            }
            double val = cell.getNumericCellValue();
            if (val == (long) val) {
                return String.valueOf((long) val);
            }
            return String.valueOf(val);
        } else if (cell.getCellType() == CellType.BOOLEAN) {
            return String.valueOf(cell.getBooleanCellValue());
        }
        return null;
    }

    private Integer getCellInteger(Row row, int col) {
        Cell cell = row.getCell(col);
        if (cell == null) return null;
        if (cell.getCellType() == CellType.NUMERIC) {
            return (int) cell.getNumericCellValue();
        } else if (cell.getCellType() == CellType.STRING) {
            try {
                return Integer.parseInt(cell.getStringCellValue().trim().replaceAll("[^0-9]", ""));
            } catch (Exception ignored) {}
        }
        return null;
    }

    private BigDecimal getCellBigDecimal(Row row, int col) {
        Cell cell = row.getCell(col);
        if (cell == null) return null;
        if (cell.getCellType() == CellType.NUMERIC) {
            return BigDecimal.valueOf(cell.getNumericCellValue());
        } else if (cell.getCellType() == CellType.STRING) {
            try {
                return new BigDecimal(cell.getStringCellValue().trim().replaceAll("[^0-9.]", ""));
            } catch (Exception ignored) {}
        }
        return null;
    }

    private LocalDate getCellDate(Row row, int col) {
        Cell cell = row.getCell(col);
        if (cell == null) return null;
        if (cell.getCellType() == CellType.NUMERIC && DateUtil.isCellDateFormatted(cell)) {
            return cell.getLocalDateTimeCellValue().toLocalDate();
        } else if (cell.getCellType() == CellType.STRING) {
            String str = cell.getStringCellValue().trim();
            try {
                return LocalDate.parse(str, DateTimeFormatter.ISO_LOCAL_DATE);
            } catch (DateTimeParseException ignored) {}
            try {
                return LocalDate.parse(str, DateTimeFormatter.ofPattern("dd-MM-yyyy"));
            } catch (DateTimeParseException ignored) {}
            try {
                return LocalDate.parse(str, DateTimeFormatter.ofPattern("dd/MM/yyyy"));
            } catch (DateTimeParseException ignored) {}
        }
        return null;
    }

    private LocalTime getCellTime(Row row, int col) {
        Cell cell = row.getCell(col);
        if (cell == null) return null;
        if (cell.getCellType() == CellType.NUMERIC && DateUtil.isCellDateFormatted(cell)) {
            return cell.getLocalDateTimeCellValue().toLocalTime();
        } else if (cell.getCellType() == CellType.STRING) {
            String str = cell.getStringCellValue().trim().toUpperCase();
            try {
                if (str.contains("AM") || str.contains("PM")) {
                    return LocalTime.parse(str, DateTimeFormatter.ofPattern("hh:mm a", Locale.ENGLISH));
                }
                return LocalTime.parse(str, DateTimeFormatter.ofPattern("HH:mm"));
            } catch (Exception ignored) {}
        }
        return null;
    }

    private boolean isRowEmpty(Row row) {
        for (int c = row.getFirstCellNum(); c < row.getLastCellNum(); c++) {
            Cell cell = row.getCell(c);
            if (cell != null && cell.getCellType() != CellType.BLANK) {
                return false;
            }
        }
        return true;
    }

    private String resolveDurableUrl(String candidateUrl, List<ScrapedImageCandidateDto> candidates, String preferredRole) {
        if (candidateUrl != null && candidateUrl.startsWith("http")) {
            return candidateUrl;
        }
        if (candidates != null && !candidates.isEmpty()) {
            if (candidateUrl != null && !candidateUrl.isBlank()) {
                for (ScrapedImageCandidateDto c : candidates) {
                    if (candidateUrl.equals(c.getLocalUrl()) && c.getUrl() != null && c.getUrl().startsWith("http")) {
                        return c.getUrl();
                    }
                }
            }
            for (ScrapedImageCandidateDto c : candidates) {
                if (preferredRole.equals(c.getSuggestedRole()) && c.getUrl() != null && c.getUrl().startsWith("http")) {
                    return c.getUrl();
                }
            }
            for (ScrapedImageCandidateDto c : candidates) {
                if (c.getUrl() != null && c.getUrl().startsWith("http")) {
                    return c.getUrl();
                }
            }
        }
        return candidateUrl;
    }
}
