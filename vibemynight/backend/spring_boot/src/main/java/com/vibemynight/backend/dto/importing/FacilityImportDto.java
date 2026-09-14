package com.vibemynight.backend.dto.importing;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FacilityImportDto {
    private String name;
    @Builder.Default
    private String scope = "EVENT"; // "EVENT" or a specific day number e.g. "1"
    private String icon;
    private String description;
    @Builder.Default
    private boolean isExistingFacility = false;
    private Long matchedFacilityId;
}
