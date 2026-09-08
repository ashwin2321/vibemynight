package com.vibemynight.backend.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateInquiryRequest {

    @NotBlank(message = "Full name is required")
    private String customerName;

    @NotBlank(message = "Mobile number is required")
    @Pattern(regexp = "^[6-9]\\d{9}$", message = "Enter a valid 10-digit Indian mobile number")
    private String customerMobile;

    @Email(message = "Enter a valid email address")
    private String customerEmail;

    @NotNull(message = "eventDayId is required")
    private Long eventDayId;

    @NotNull(message = "ticketCategoryId is required")
    private Long ticketCategoryId;

    @NotNull(message = "quantity is required")
    @Min(value = 1, message = "quantity must be at least 1")
    @Max(value = 50, message = "quantity is too large")
    private Integer quantity;

    private String message;
}
