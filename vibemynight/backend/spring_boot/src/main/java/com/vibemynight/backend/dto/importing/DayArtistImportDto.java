package com.vibemynight.backend.dto.importing;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DayArtistImportDto {
    private Integer dayNumber;
    private String artistName;
    @Builder.Default
    private String artistType = "SINGER"; // SINGER, DJ, BAND, CELEBRITY, PERFORMER, LIVE_ARTIST, OTHER
    @Builder.Default
    private boolean isPrimary = false;
    private Integer performanceOrder;
    private LocalTime performanceStartTime;
    private LocalTime performanceEndTime;
    private String photoUrl;
    private String instagramUrl;
    @Builder.Default
    private boolean isExistingArtist = false;
    private Long matchedArtistId;
}
