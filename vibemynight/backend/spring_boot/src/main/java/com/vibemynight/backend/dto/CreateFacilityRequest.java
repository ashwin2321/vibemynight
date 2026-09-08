package com.vibemynight.backend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateFacilityRequest {

    @NotBlank(message = "Facility name is required")
    private String name;

    private String icon;
    private String description;
}
