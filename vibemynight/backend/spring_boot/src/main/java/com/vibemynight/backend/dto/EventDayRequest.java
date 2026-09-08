package com.vibemynight.backend.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

@Getter
@Setter
public class EventDayRequest {

    @NotNull(message = "dayNumber is required")
    private Integer dayNumber;

    @NotNull(message = "date is required")
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

    /** Artist assignment - handled via EventDayArtist rows, not stored on EventDay itself. */
    private Long primaryArtistId;
    private List<Long> additionalArtistIds;

    private List<Long> facilityIds;
}
