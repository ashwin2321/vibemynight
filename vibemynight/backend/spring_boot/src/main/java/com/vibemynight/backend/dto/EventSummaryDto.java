package com.vibemynight.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

/** Event card shape for the events listing screen. */
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EventSummaryDto {
    private Long id;
    private String name;
    private String slug;
    private String mainImage;
    private String thumbnail;
    private String city;
    private String location;
    private LocalDate startDate;
    private LocalDate endDate;
    private int dayCount;
    private BigDecimal startingPrice;
    private String featuredArtistName;
    private boolean featured;
    private String status;
}
