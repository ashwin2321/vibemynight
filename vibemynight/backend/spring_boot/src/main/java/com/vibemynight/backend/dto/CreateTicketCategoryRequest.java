package com.vibemynight.backend.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.List;

@Getter
@Setter
public class CreateTicketCategoryRequest {

    @NotBlank(message = "Pass name is required")
    private String name;

    @NotNull(message = "Pass type is required")
    private String type;

    @NotNull(message = "Price is required")
    @DecimalMin(value = "0.0", message = "Price cannot be negative")
    private BigDecimal price;

    @NotNull(message = "availableQuantity is required")
    @Min(value = 0, message = "availableQuantity cannot be negative")
    private Integer availableQuantity;

    @Min(value = 1, message = "maxPerCustomer must be at least 1")
    private Integer maxPerCustomer;

    private String description;
    private List<String> benefits;
}
