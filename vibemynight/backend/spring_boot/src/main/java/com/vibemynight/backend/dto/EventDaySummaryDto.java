package com.vibemynight.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalTime;

/** Lightweight shape for the "CHOOSE YOUR NIGHT" day selector strip. */
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EventDaySummaryDto {
    private Long id;
    private Integer dayNumber;
    private LocalDate date;
    private String dayName;
    private String programName;
    private LocalTime startTime;
    private LocalTime endTime;
    private String primaryArtistName;
    private String primaryArtistPhotoUrl;
    private java.math.BigDecimal startingPrice;
}
