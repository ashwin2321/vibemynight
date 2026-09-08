package com.vibemynight.backend.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalTime;

@Getter
@Setter
public class AssignArtistToDayRequest {

    @NotNull(message = "artistId is required")
    private Long artistId;

    private boolean isPrimary;
    private Integer performanceOrder;
    private LocalTime performanceStartTime;
    private LocalTime performanceEndTime;
}
