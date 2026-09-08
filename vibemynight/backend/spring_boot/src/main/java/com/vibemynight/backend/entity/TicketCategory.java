package com.vibemynight.backend.entity;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

/**
 * A pass/ticket belonging to a single EventDay. Prices and availability are always
 * day-specific and are the authoritative source used by the backend during inquiry
 * creation - the frontend price is never trusted.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(callSuper = false)
@Entity
@Table(name = "ticket_categories")
public class TicketCategory extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "event_day_id", nullable = false)
    private EventDay eventDay;

    @Column(nullable = false)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TicketType type;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;

    @Column(name = "available_quantity", nullable = false)
    private Integer availableQuantity;

    @Column(name = "max_per_customer", nullable = false)
    @Builder.Default
    private Integer maxPerCustomer = 10;

    @Column(length = 2000)
    private String description;

    @Builder.Default
    @ElementCollection
    @CollectionTable(name = "ticket_category_benefits", joinColumns = @JoinColumn(name = "ticket_category_id"))
    @Column(name = "benefit")
    private List<String> benefits = new ArrayList<>();

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private ActiveStatus status = ActiveStatus.ACTIVE;
}
