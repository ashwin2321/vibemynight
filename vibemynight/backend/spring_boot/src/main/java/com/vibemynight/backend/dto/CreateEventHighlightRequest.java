package com.vibemynight.backend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateEventHighlightRequest {

    @NotBlank(message = "text is required")
    private String text;

    private Integer sortOrder;
}
