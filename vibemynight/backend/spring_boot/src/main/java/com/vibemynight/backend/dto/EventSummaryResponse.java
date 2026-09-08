package com.vibemynight.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

/** Card-view shape for GET /api/v1/events. */
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EventSummaryResponse {
    private Long id;
    private String name;
    private String slug;
    private String mainImage;
    private String thumbnail;
    private String city;
    private String location;
    private LocalDate startDate;
    private LocalDate endDate;
    private Integer daysCount;
    private boolean featured;
    private String status;
    /** Lowest active pass price across all days, null if none configured yet. */
    private BigDecimal startingPrice;
    private String featuredArtistName;
}
