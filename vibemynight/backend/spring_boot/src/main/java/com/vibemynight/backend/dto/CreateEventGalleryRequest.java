package com.vibemynight.backend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateEventGalleryRequest {

    @NotBlank(message = "imageUrl is required")
    private String imageUrl;

    private String caption;
    private Integer sortOrder;
}
