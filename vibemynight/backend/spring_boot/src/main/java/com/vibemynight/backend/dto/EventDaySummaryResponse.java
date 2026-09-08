package com.vibemynight.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;

/** Lightweight day entry nested inside EventDetailResponse's day selector. */
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EventDaySummaryResponse {
    private Long id;
    private Integer dayNumber;
    private LocalDate date;
    private String dayName;
    private String programName;
    private Long primaryArtistId;
    private String primaryArtistName;
    private String primaryArtistPhotoUrl;
    private LocalTime startTime;
    private LocalTime endTime;
    private String venue;
    private String location;
    private BigDecimal startingPrice;
    private String status;
}
