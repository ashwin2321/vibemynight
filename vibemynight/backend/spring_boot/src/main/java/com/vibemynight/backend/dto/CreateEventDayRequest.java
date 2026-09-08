package com.vibemynight.backend.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalTime;

@Getter
@Setter
public class CreateEventDayRequest {

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
}
