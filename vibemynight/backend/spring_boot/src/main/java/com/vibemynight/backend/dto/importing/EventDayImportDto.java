package com.vibemynight.backend.dto.importing;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EventDayImportDto {
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

    @Builder.Default
    private List<PassImportDto> passes = new ArrayList<>();

    @Builder.Default
    private List<DayArtistImportDto> artists = new ArrayList<>();

    @Builder.Default
    private List<FacilityImportDto> facilities = new ArrayList<>();
}
