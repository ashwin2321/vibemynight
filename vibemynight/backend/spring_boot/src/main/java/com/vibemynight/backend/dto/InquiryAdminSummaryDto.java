package com.vibemynight.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/** One row of the admin inquiries table. */
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InquiryAdminSummaryDto {
    private Long id;
    private String inquiryNumber;
    private String customerName;
    private String customerMobile;
    private String eventName;
    private Integer dayNumber;
    private LocalDate date;
    private String artistName;
    private String ticketCategoryName;
    private BigDecimal price;
    private Integer quantity;
    private BigDecimal estimatedTotal;
    private String status;
    private LocalDateTime createdAt;
}
