package com.vibemynight.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;

/**
 * Everything the Flutter app needs to render the confirmation screen and build
 * the WhatsApp message - all values are server-derived, never client-supplied.
 */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InquiryResponse {
    private Long id;
    private String inquiryNumber;
    private String status;

    private String customerName;
    private String customerMobile;
    private String customerEmail;

    private Long eventId;
    private String eventName;

    private Long eventDayId;
    private Integer dayNumber;
    private LocalDate date;
    private String programName;

    private Long artistId;
    private String artistName;

    private LocalTime startTime;
    private LocalTime endTime;
    private String venue;
    private String location;

    private Long ticketCategoryId;
    private String ticketCategoryName;

    private BigDecimal price;
    private Integer quantity;
    private BigDecimal estimatedTotal;

    private String customerMessage;

    /** WhatsApp number to send the inquiry to, e.g. "917041615131" (from Settings, not hardcoded). */
    private String whatsappNumber;

    /** Pre-built plain-text message matching the spec's WhatsApp template. */
    private String whatsappMessage;

    /** Ready-to-open https://wa.me/... URL with the message URL-encoded. */
    private String whatsappUrl;

    private java.time.LocalDateTime createdAt;
}
