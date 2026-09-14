package com.vibemynight.backend.dto.importing;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PassImportDto {
    private String dayNumber; // "1", "2", "ALL"
    private String name;
    @Builder.Default
    private String type = "REGULAR"; // REGULAR, VIP, COUPLE, GROUP, EARLY_BIRD, PREMIUM, CUSTOM
    private BigDecimal price;
    private Integer availableQuantity;
    @Builder.Default
    private Integer maxPerCustomer = 10;
    private String description;
    @Builder.Default
    private List<String> benefits = new ArrayList<>();
}
