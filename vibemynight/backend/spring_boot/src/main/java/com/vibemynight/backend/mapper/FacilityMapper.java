package com.vibemynight.backend.mapper;

import com.vibemynight.backend.dto.FacilityDto;
import com.vibemynight.backend.entity.Facility;
import org.springframework.stereotype.Component;

@Component
public class FacilityMapper {

    public FacilityDto toDto(Facility facility) {
        if (facility == null) return null;
        return FacilityDto.builder()
                .id(facility.getId())
                .name(facility.getName())
                .icon(facility.getIcon())
                .description(facility.getDescription())
                .status(facility.getStatus().name())
                .build();
    }
}
