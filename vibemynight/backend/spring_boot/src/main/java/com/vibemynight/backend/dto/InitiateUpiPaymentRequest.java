package com.vibemynight.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.util.Map;

@Getter
@Setter
public class InitiateUpiPaymentRequest {

    @NotNull(message = "eventId is required")
    private Long eventId;

    @NotNull(message = "eventDayId is required")
    private Long eventDayId;

    /** Map of TicketCategoryId (Long) -> Quantity (Integer) */
    @NotEmpty(message = "At least one pass quantity must be selected")
    private Map<Long, Integer> selectedQuantities;

    @NotBlank(message = "Customer name is required")
    private String customerName;

    @NotBlank(message = "Customer mobile is required")
    private String customerMobile;

    private String customerEmail;
}
