package com.vibemynight.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

/** Full detail for a single selected day, plus its artists, facilities and passes. */
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EventDayDetailDto {
    private Long id;
    private Long eventId;
    private Integer dayNumber;
    private LocalDate date;
    private String dayName;
    private String programName;
    private LocalTime startTime;
    private LocalTime endTime;
    private String venue;
    private String address;
    private String location;
    private String googleMapsUrl;
    private String description;
    private String status;
    private List<EventDayArtistDto> artists;
    private List<FacilityDto> facilities;
    private List<TicketCategoryDto> passes;
}
