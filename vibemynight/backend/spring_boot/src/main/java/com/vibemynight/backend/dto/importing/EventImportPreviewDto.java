package com.vibemynight.backend.dto.importing;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EventImportPreviewDto {
    private EventHeaderImportDto event;

    @Builder.Default
    private List<EventDayImportDto> days = new ArrayList<>();

    @Builder.Default
    private List<FacilityImportDto> eventFacilities = new ArrayList<>();

    @Builder.Default
    private List<String> highlights = new ArrayList<>();

    @Builder.Default
    private List<String> rules = new ArrayList<>();

    @Builder.Default
    private List<String> galleryImageUrls = new ArrayList<>();

    @Builder.Default
    private List<ScrapedImageCandidateDto> artworkCandidates = new ArrayList<>();

    @Builder.Default
    private List<ValidationMessageDto> validationMessages = new ArrayList<>();

    @Builder.Default
    private boolean hasBlockingErrors = false;

    private int totalDays;
    private int totalPasses;
    private int totalArtists;
}
