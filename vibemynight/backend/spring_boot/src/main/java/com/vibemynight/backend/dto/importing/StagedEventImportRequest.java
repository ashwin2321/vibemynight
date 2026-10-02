package com.vibemynight.backend.dto.importing;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StagedEventImportRequest {

    @NotEmpty(message = "stagedEventIds must not be empty")
    @Size(max = 50, message = "Maximum batch size is 50 events per import request")
    private List<Integer> stagedEventIds;
}
