package com.vibemynight.backend.dto.importing;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ScrapedImageCandidateDto {
    private String url;
    private String localUrl;
    private String suggestedRole; // "POSTER_3_4", "BANNER_16_9", "THUMBNAIL_1_1", "GALLERY"
    private String label;
    private String source;

    public String getEffectiveUrl() {
        return (localUrl != null && !localUrl.isBlank()) ? localUrl : url;
    }
}
