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
public class StagedImportBatchResultDto {

    private boolean success;
    private int totalRequested;
    private int imported;
    private int alreadyImported;
    private int conflicts;
    private int failed;
    @Builder.Default
    private List<StagedEventImportResultItemDto> results = new ArrayList<>();
}
