package com.vibemynight.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

/** Full event detail screen shape: banner, info, gallery, highlights, rules, and the day selector. */
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EventDetailDto {
    private Long id;
    private String name;
    private String slug;
    private String mainImage;
    private String banner;
    private String thumbnail;
    private String description;
    private LocalDate startDate;
    private LocalDate endDate;
    private String venue;
    private String address;
    private String city;
    private String location;
    private String googleMapsUrl;
    private String organizer;
    private String contactNumber;
    private String email;
    private boolean featured;
    private String status;
    private List<String> galleryImageUrls;
    private List<String> highlights;
    private List<String> rules;
    private List<FacilityDto> facilities;
    private List<EventDaySummaryDto> days;
}
