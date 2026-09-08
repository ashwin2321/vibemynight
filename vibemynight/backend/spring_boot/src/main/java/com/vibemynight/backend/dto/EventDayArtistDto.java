package com.vibemynight.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalTime;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EventDayArtistDto {
    private Long artistId;
    private String name;
    private String photoUrl;
    private String type;
    private boolean isPrimary;
    private Integer performanceOrder;
    private LocalTime performanceStartTime;
    private LocalTime performanceEndTime;
}
