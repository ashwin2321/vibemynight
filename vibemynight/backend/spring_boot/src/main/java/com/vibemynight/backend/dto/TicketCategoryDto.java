package com.vibemynight.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TicketCategoryDto {
    private Long id;
    private Long eventDayId;
    private String name;
    private String type;
    private BigDecimal price;
    private Integer availableQuantity;
    private Integer maxPerCustomer;
    private String description;
    private List<String> benefits;
    private String status;
    /** Convenience flag for the frontend: true when availableQuantity == 0. */
    private boolean soldOut;
}
