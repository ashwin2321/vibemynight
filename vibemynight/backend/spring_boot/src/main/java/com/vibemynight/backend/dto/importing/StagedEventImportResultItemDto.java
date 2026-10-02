package com.vibemynight.backend.dto.importing;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StagedEventImportResultItemDto {

    private Integer stagedEventId;
    private String status; // "IMPORTED", "ALREADY_IMPORTED", "CONFLICT", "FAILED", "REJECTED"
    private Long productionEventId;
    private String eventName;
    private String slug;
    private String reason;
}
