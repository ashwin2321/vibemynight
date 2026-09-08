package com.vibemynight.backend.entity;

import jakarta.persistence.Column;
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

/**
 * A customer's pass inquiry. price/estimatedTotal are always computed and stamped
 * by the backend at creation time - never accepted from the client.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(callSuper = false)
@Entity
@Table(name = "inquiries")
public class Inquiry extends BaseEntity {

    @Column(name = "inquiry_number", nullable = false, unique = true)
    private String inquiryNumber;

    @Column(name = "customer_name", nullable = false)
    private String customerName;

    @Column(name = "customer_mobile", nullable = false)
    private String customerMobile;

    @Column(name = "customer_email")
    private String customerEmail;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "event_id", nullable = false)
    private Event event;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "event_day_id", nullable = false)
    private EventDay eventDay;

    /** Primary artist for the selected day at the time of inquiry, if any. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "artist_id")
    private Artist artist;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "ticket_category_id", nullable = false)
    private TicketCategory ticketCategory;

    /** Price per unit at the moment the inquiry was created (server-verified, not client-supplied). */
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;

    @Column(nullable = false)
    private Integer quantity;

    @Column(name = "estimated_total", nullable = false, precision = 10, scale = 2)
    private BigDecimal estimatedTotal;

    @Column(name = "customer_message", length = 2000)
    private String customerMessage;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private InquiryStatus status = InquiryStatus.NEW;
}
