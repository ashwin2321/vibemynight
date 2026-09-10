package com.vibemynight.backend.util;

import com.vibemynight.backend.dto.InquiryResponse;
import org.springframework.stereotype.Component;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.format.DateTimeFormatter;
import java.util.Locale;

/**
 * Builds the clean, aesthetic WhatsApp inquiry message text/URL matching
 * the requested VibeMyNight standard format.
 */
@Component
public class WhatsAppMessageBuilder {

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("d MMM yyyy", Locale.ENGLISH);
    private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("h:mm a", Locale.ENGLISH);

    public String buildMessage(InquiryResponse inquiry) {
        StringBuilder sb = new StringBuilder();
        sb.append("🎫 *VIBEMYNIGHT INQUIRY*\n");
        sb.append("———————————————\n");
        sb.append("🆔 ").append(inquiry.getInquiryNumber()).append("\n\n");
        sb.append("👤 ").append(inquiry.getCustomerName()).append("\n");
        sb.append("📱 ").append(inquiry.getCustomerMobile()).append("\n");
        sb.append("———————————————\n");
        sb.append("📌 ").append(inquiry.getEventName()).append("\n");

        if (inquiry.getDayNumber() != null && inquiry.getDate() != null) {
            sb.append("📅 Day ").append(inquiry.getDayNumber())
              .append(" · ").append(inquiry.getDate().format(DATE_FMT)).append("\n");
        } else if (inquiry.getDate() != null) {
            sb.append("📅 ").append(inquiry.getDate().format(DATE_FMT)).append("\n");
        } else if (inquiry.getDayNumber() != null) {
            sb.append("📅 Day ").append(inquiry.getDayNumber()).append("\n");
        }

        if (inquiry.getArtistName() != null && !inquiry.getArtistName().isBlank()) {
            sb.append("🎤 ").append(inquiry.getArtistName()).append("\n");
        }

        if (inquiry.getStartTime() != null && inquiry.getEndTime() != null) {
            sb.append("🕗 ")
              .append(inquiry.getStartTime().format(TIME_FMT))
              .append(" – ")
              .append(inquiry.getEndTime().format(TIME_FMT))
              .append("\n");
        } else if (inquiry.getStartTime() != null) {
            sb.append("🕗 ").append(inquiry.getStartTime().format(TIME_FMT)).append("\n");
        }

        String locationStr = buildLocationString(inquiry.getVenue(), inquiry.getLocation());
        if (locationStr != null && !locationStr.isBlank()) {
            sb.append("📍 ").append(locationStr).append("\n");
        }

        sb.append("———————————————\n");
        sb.append("🎟️ ").append(inquiry.getTicketCategoryName())
          .append(" × ").append(inquiry.getQuantity()).append("\n");
        sb.append("💰 *Total: ₹").append(formatAmount(inquiry.getEstimatedTotal())).append("*\n");
        sb.append("———————————————\n");
        sb.append("Please confirm availability. Thank you!");

        return sb.toString();
    }

    public String buildWhatsAppUrl(String whatsappNumber, String message) {
        String cleanPhone = whatsappNumber != null ? whatsappNumber.replaceAll("[^0-9]", "") : "";
        if (!cleanPhone.startsWith("91") && cleanPhone.length() == 10) {
            cleanPhone = "91" + cleanPhone;
        }
        String encoded = URLEncoder.encode(message, StandardCharsets.UTF_8).replace("+", "%20");
        return "https://api.whatsapp.com/send?phone=" + cleanPhone + "&text=" + encoded;
    }

    private String buildLocationString(String venue, String location) {
        boolean hasVenue = venue != null && !venue.isBlank();
        boolean hasLoc = location != null && !location.isBlank();
        if (hasVenue && hasLoc) {
            return venue.equals(location) ? venue : venue + ", " + location;
        } else if (hasVenue) {
            return venue;
        } else if (hasLoc) {
            return location;
        }
        return null;
    }

    private String formatAmount(java.math.BigDecimal amount) {
        if (amount == null) return "0";
        java.text.DecimalFormat df = new java.text.DecimalFormat("#,##0");
        return df.format(amount);
    }
}
