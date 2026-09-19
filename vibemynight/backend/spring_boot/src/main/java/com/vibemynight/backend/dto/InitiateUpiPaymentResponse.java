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
public class InitiateUpiPaymentResponse {
    private String transactionReference;
    private BigDecimal totalAmount;
    private String upiUrl;
    private String upiVpa;
    private String merchantName;
    private String status;
    private List<String> itemizedBreakdown;
    private String note;
}
