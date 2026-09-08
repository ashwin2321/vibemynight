package com.vibemynight.backend.mapper;

import com.vibemynight.backend.dto.EventDetailDto;
import com.vibemynight.backend.dto.EventSummaryDto;
import com.vibemynight.backend.dto.FacilityDto;
import com.vibemynight.backend.entity.Event;
import com.vibemynight.backend.entity.EventDay;
import com.vibemynight.backend.entity.EventDayArtist;
import com.vibemynight.backend.entity.EventGallery;
import com.vibemynight.backend.entity.EventHighlight;
import com.vibemynight.backend.entity.EventRule;
import com.vibemynight.backend.entity.Facility;
import com.vibemynight.backend.entity.TicketCategory;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.Comparator;
import java.util.List;

/**
 * Callers must invoke this from within a transaction for the given Event,
 * since it walks lazy collections (eventDays, galleryImages, highlights, rules,
 * and each day's own ticketCategories/eventDayArtists).
 */
@Component
@RequiredArgsConstructor
public class EventMapper {

    private final EventDayMapper eventDayMapper;
    private final FacilityMapper facilityMapper;

    public EventSummaryDto toSummaryDto(Event event) {
        BigDecimal startingPrice = event.getEventDays().stream()
                .flatMap(d -> d.getTicketCategories().stream())
                .map(TicketCategory::getPrice)
                .filter(java.util.Objects::nonNull)
                .min(Comparator.naturalOrder())
                .orElse(null);

        String featuredArtistName = event.getEventDays().stream()
                .sorted(Comparator.comparing(EventDay::getDayNumber))
                .flatMap(d -> d.getEventDayArtists().stream())
                .filter(EventDayArtist::isPrimary)
                .map(link -> link.getArtist().getName())
                .findFirst()
                .orElse(null);

        return EventSummaryDto.builder()
                .id(event.getId())
                .name(event.getName())
                .slug(event.getSlug())
                .mainImage(event.getMainImage())
                .thumbnail(event.getThumbnail())
                .city(event.getCity())
                .location(event.getLocation())
                .startDate(event.getStartDate())
                .endDate(event.getEndDate())
                .dayCount(event.getEventDays().size())
                .startingPrice(startingPrice)
                .featuredArtistName(featuredArtistName)
                .featured(event.isFeatured())
                .status(event.getStatus().name())
                .build();
    }

    public EventDetailDto toDetailDto(Event event, List<Facility> eventFacilities) {
        List<String> gallery = event.getGalleryImages().stream()
                .map(EventGallery::getImageUrl)
                .toList();

        List<String> highlights = event.getHighlights().stream()
                .map(EventHighlight::getText)
                .toList();

        List<String> rules = event.getRules().stream()
                .map(EventRule::getText)
                .toList();

        List<FacilityDto> facilities = eventFacilities.stream()
                .map(facilityMapper::toDto)
                .toList();

        var days = event.getEventDays().stream()
                .sorted(Comparator.comparing(EventDay::getDayNumber))
                .map(eventDayMapper::toSummaryDto)
                .toList();

        return EventDetailDto.builder()
                .id(event.getId())
                .name(event.getName())
                .slug(event.getSlug())
                .mainImage(event.getMainImage())
                .banner(event.getBanner())
                .thumbnail(event.getThumbnail())
                .description(event.getDescription())
                .startDate(event.getStartDate())
                .endDate(event.getEndDate())
                .venue(event.getVenue())
                .address(event.getAddress())
                .city(event.getCity())
                .location(event.getLocation())
                .googleMapsUrl(event.getGoogleMapsUrl())
                .organizer(event.getOrganizer())
                .contactNumber(event.getContactNumber())
                .email(event.getEmail())
                .featured(event.isFeatured())
                .status(event.getStatus().name())
                .galleryImageUrls(gallery)
                .highlights(highlights)
                .rules(rules)
                .facilities(facilities)
                .days(days)
                .build();
    }
}
