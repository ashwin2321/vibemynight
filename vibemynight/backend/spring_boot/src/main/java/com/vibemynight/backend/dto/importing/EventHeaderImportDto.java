package com.vibemynight.backend.dto.importing;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EventHeaderImportDto {
    private String name;
    private String slug;
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
    private String description;
    @Builder.Default
    private boolean featured = false;
    @Builder.Default
    private String status = "DRAFT";
    private String mainImage;
    private String banner;
    private String thumbnail;
}
