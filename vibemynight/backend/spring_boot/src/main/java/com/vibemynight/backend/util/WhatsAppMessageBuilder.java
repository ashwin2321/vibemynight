package com.vibemynight.backend.util;

import com.vibemynight.backend.dto.InquiryResponse;
import org.springframework.stereotype.Component;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.format.DateTimeFormatter;

/**
 * Builds the exact WhatsApp inquiry message text/URL described in the spec.
 * Backend builds this (not just raw data) so every client (Flutter web/iOS/Android,
 * or a future confirmation-page-only fallback) sends an identical, correctly
 * URL-encoded message without re-implementing the formatting.
 */
@Component
public class WhatsAppMessageBuilder {

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("d MMMM yyyy");
    private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("h:mm a");

    public String buildMessage(InquiryResponse inquiry) {
        StringBuilder sb = new StringBuilder();
        sb.append("Hello VibeMyNight,\n\n");
        sb.append("I want to inquire about a pass.\n\n");
        sb.append("Inquiry ID:\n").append(inquiry.getInquiryNumber()).append("\n\n");
        sb.append("Name:\n").append(inquiry.getCustomerName()).append("\n\n");
        sb.append("Mobile:\n").append(inquiry.getCustomerMobile()).append("\n\n");
        sb.append("Event:\n").append(inquiry.getEventName()).append("\n\n");
        if (inquiry.getDayNumber() != null) {
            sb.append("Day:\nDay ").append(inquiry.getDayNumber()).append("\n\n");
        }
        if (inquiry.getDate() != null) {
            sb.append("Date:\n").append(inquiry.getDate().format(DATE_FMT)).append("\n\n");
        }
        if (inquiry.getProgramName() != null && !inquiry.getProgramName().isBlank()) {
            sb.append("Program:\n").append(inquiry.getProgramName()).append("\n\n");
        }
        if (inquiry.getArtistName() != null && !inquiry.getArtistName().isBlank()) {
            sb.append("Artist:\n").append(inquiry.getArtistName()).append("\n\n");
        }
        if (inquiry.getStartTime() != null && inquiry.getEndTime() != null) {
            sb.append("Time:\n")
                    .append(inquiry.getStartTime().format(TIME_FMT))
                    .append(" - ")
                    .append(inquiry.getEndTime().format(TIME_FMT))
                    .append("\n\n");
        }
        if (inquiry.getVenue() != null && !inquiry.getVenue().isBlank()) {
            sb.append("Venue:\n").append(inquiry.getVenue()).append("\n\n");
        }
        if (inquiry.getLocation() != null && !inquiry.getLocation().isBlank()) {
            sb.append("Location:\n").append(inquiry.getLocation()).append("\n\n");
        }
        sb.append("Pass:\n").append(inquiry.getTicketCategoryName()).append("\n\n");
        sb.append("Price:\n\u20b9").append(formatAmount(inquiry.getPrice())).append("\n\n");
        sb.append("Quantity:\n").append(inquiry.getQuantity()).append("\n\n");
        sb.append("Estimated Total:\n\u20b9").append(formatAmount(inquiry.getEstimatedTotal())).append("\n\n");
        sb.append("Please confirm availability and booking details.\n\n");
        sb.append("Thank you,\nVibeMyNight Customer");
        return sb.toString();
    }

    public String buildWhatsAppUrl(String whatsappNumber, String message) {
        String encoded = URLEncoder.encode(message, StandardCharsets.UTF_8).replace("+", "%20");
        return "https://wa.me/" + whatsappNumber + "?text=" + encoded;
    }

    private String formatAmount(java.math.BigDecimal amount) {
        if (amount == null) return "0";
        // Simple thousands-separated formatting, e.g. 2198 -> 2,198 (Indian grouping
        // for lakhs/crores can be added later if needed - plain grouping is enough for v1).
        java.text.DecimalFormat df = new java.text.DecimalFormat("#,##0");
        return df.format(amount);
    }
}
