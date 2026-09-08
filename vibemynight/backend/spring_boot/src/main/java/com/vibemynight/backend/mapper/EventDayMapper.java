package com.vibemynight.backend.mapper;

import com.vibemynight.backend.dto.EventDayArtistDto;
import com.vibemynight.backend.dto.EventDayDetailDto;
import com.vibemynight.backend.dto.EventDaySummaryDto;
import com.vibemynight.backend.dto.FacilityDto;
import com.vibemynight.backend.dto.TicketCategoryDto;
import com.vibemynight.backend.entity.EventDay;
import com.vibemynight.backend.entity.EventDayArtist;
import com.vibemynight.backend.entity.Facility;
import com.vibemynight.backend.entity.TicketCategory;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.Comparator;
import java.util.List;

/**
 * Callers must invoke this from within a transaction/read session for a given
 * EventDay, since it walks lazy collections (eventDayArtists, ticketCategories).
 */
@Component
@RequiredArgsConstructor
public class EventDayMapper {

    private final FacilityMapper facilityMapper;
    private final TicketCategoryMapper ticketCategoryMapper;

    public EventDayArtistDto toArtistDto(EventDayArtist link) {
        return EventDayArtistDto.builder()
                .artistId(link.getArtist().getId())
                .name(link.getArtist().getName())
                .photoUrl(link.getArtist().getPhotoUrl())
                .type(link.getArtist().getType().name())
                .isPrimary(link.isPrimary())
                .performanceOrder(link.getPerformanceOrder())
                .performanceStartTime(link.getPerformanceStartTime())
                .performanceEndTime(link.getPerformanceEndTime())
                .build();
    }

    public EventDaySummaryDto toSummaryDto(EventDay day) {
        EventDayArtist primary = day.getEventDayArtists().stream()
                .filter(EventDayArtist::isPrimary)
                .findFirst()
                .orElse(day.getEventDayArtists().stream().findFirst().orElse(null));

        BigDecimal startingPrice = day.getTicketCategories().stream()
                .map(TicketCategory::getPrice)
                .filter(java.util.Objects::nonNull)
                .min(Comparator.naturalOrder())
                .orElse(null);

        return EventDaySummaryDto.builder()
                .id(day.getId())
                .dayNumber(day.getDayNumber())
                .date(day.getDate())
                .dayName(day.getDayName())
                .programName(day.getProgramName())
                .startTime(day.getStartTime())
                .endTime(day.getEndTime())
                .primaryArtistName(primary != null ? primary.getArtist().getName() : null)
                .primaryArtistPhotoUrl(primary != null ? primary.getArtist().getPhotoUrl() : null)
                .startingPrice(startingPrice)
                .build();
    }

    public EventDayDetailDto toDetailDto(EventDay day, List<Facility> dayFacilities) {
        List<EventDayArtistDto> artists = day.getEventDayArtists().stream()
                .map(this::toArtistDto)
                .toList();

        List<FacilityDto> facilities = dayFacilities.stream()
                .map(facilityMapper::toDto)
                .toList();

        List<TicketCategoryDto> passes = day.getTicketCategories().stream()
                .map(ticketCategoryMapper::toDto)
                .toList();

        return EventDayDetailDto.builder()
                .id(day.getId())
                .eventId(day.getEvent().getId())
                .dayNumber(day.getDayNumber())
                .date(day.getDate())
                .dayName(day.getDayName())
                .programName(day.getProgramName())
                .startTime(day.getStartTime())
                .endTime(day.getEndTime())
                .venue(day.getVenue())
                .address(day.getAddress())
                .location(day.getLocation())
                .googleMapsUrl(day.getGoogleMapsUrl())
                .description(day.getDescription())
                .status(day.getStatus().name())
                .artists(artists)
                .facilities(facilities)
                .passes(passes)
                .build();
    }
}
