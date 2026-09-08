package com.vibemynight.backend.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateInquiryStatusRequest {

    @NotNull(message = "status is required")
    private String status;
}
