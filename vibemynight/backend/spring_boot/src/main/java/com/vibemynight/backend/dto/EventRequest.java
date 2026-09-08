package com.vibemynight.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Getter
@Setter
public class EventRequest {

    @NotBlank(message = "Event name is required")
    private String name;

    @NotBlank(message = "Slug is required")
    private String slug;

    private String mainImage;
    private String banner;
    private String thumbnail;
    private String description;

    @NotNull(message = "Start date is required")
    private LocalDate startDate;

    @NotNull(message = "End date is required")
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

    /** Optional at creation time - managed via dedicated event-highlight/rule/gallery admin calls. */
    private java.util.List<String> highlights;
    private java.util.List<String> rules;
    private java.util.List<Long> facilityIds;
}
