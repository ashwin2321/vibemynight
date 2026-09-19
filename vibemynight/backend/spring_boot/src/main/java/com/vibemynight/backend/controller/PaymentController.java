package com.vibemynight.backend.controller;

import com.vibemynight.backend.dto.ApiResponse;
import com.vibemynight.backend.dto.InitiateUpiPaymentRequest;
import com.vibemynight.backend.dto.InitiateUpiPaymentResponse;
import com.vibemynight.backend.entity.Event;
import com.vibemynight.backend.entity.EventDay;
import com.vibemynight.backend.entity.Settings;
import com.vibemynight.backend.entity.TicketCategory;
import com.vibemynight.backend.exception.BadRequestException;
import com.vibemynight.backend.exception.ResourceNotFoundException;
import com.vibemynight.backend.repository.EventDayRepository;
import com.vibemynight.backend.repository.EventRepository;
import com.vibemynight.backend.repository.TicketCategoryRepository;
import com.vibemynight.backend.service.SettingsService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/v1/payments")
@RequiredArgsConstructor
public class PaymentController {

    private final SettingsService settingsService;
    private final EventRepository eventRepository;
    private final EventDayRepository eventDayRepository;
    private final TicketCategoryRepository ticketCategoryRepository;

    @PostMapping("/upi/initiate")
    public ApiResponse<InitiateUpiPaymentResponse> initiateUpiPayment(@Valid @RequestBody InitiateUpiPaymentRequest request) {
        Settings settings = settingsService.getSettings();

        // 1. Check feature flag
        if (!Boolean.TRUE.equals(settings.getUpiEnabled())) {
            throw new BadRequestException("Online UPI Payment is currently disabled by administrator");
        }

        String vpa = settings.getUpiVpa();
        if (vpa == null || vpa.trim().isEmpty()) {
            throw new BadRequestException("Merchant UPI VPA is not configured");
        }
        vpa = vpa.trim();

        String merchantName = settings.getUpiMerchantName() != null && !settings.getUpiMerchantName().isBlank()
                ? settings.getUpiMerchantName().trim()
                : (settings.getWebsiteName() != null ? settings.getWebsiteName() : "VibeMyNight");

        // 2. Validate Event & Day
        Event event = eventRepository.findById(request.getEventId())
                .orElseThrow(() -> new ResourceNotFoundException("Event not found: " + request.getEventId()));

        EventDay eventDay = eventDayRepository.findById(request.getEventDayId())
                .orElseThrow(() -> new ResourceNotFoundException("EventDay not found: " + request.getEventDayId()));

        if (!eventDay.getEvent().getId().equals(event.getId())) {
            throw new BadRequestException("EventDay does not belong to the specified Event");
        }

        // 3. Calculate server-side total amount securely (never trust client amounts)
        BigDecimal totalAmount = BigDecimal.ZERO;
        List<String> breakdown = new ArrayList<>();
        int totalTickets = 0;

        for (Map.Entry<Long, Integer> entry : request.getSelectedQuantities().entrySet()) {
            Long passId = entry.getKey();
            Integer qty = entry.getValue();

            if (qty == null || qty <= 0) continue;

            TicketCategory pass = ticketCategoryRepository.findById(passId)
                    .orElseThrow(() -> new ResourceNotFoundException("Ticket pass category not found: " + passId));

            if (!pass.getEventDay().getId().equals(eventDay.getId())) {
                throw new BadRequestException("Pass " + pass.getName() + " does not belong to the selected day");
            }

            if (pass.getPrice() == null) {
                throw new BadRequestException("Pass " + pass.getName() + " does not have a valid price configured");
            }

            BigDecimal itemTotal = pass.getPrice().multiply(BigDecimal.valueOf(qty));
            totalAmount = totalAmount.add(itemTotal);
            totalTickets += qty;
            breakdown.add(pass.getName() + " x " + qty + " = INR " + itemTotal.toPlainString());
        }

        if (totalTickets == 0 || totalAmount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new BadRequestException("Total quantity must be at least 1 and amount must be greater than 0");
        }

        // 4. Generate unique transaction reference
        String txnRef = "VMN-" + System.currentTimeMillis() + "-" + UUID.randomUUID().toString().substring(0, 6).toUpperCase();
        String note = "Passes for " + event.getName() + " (" + totalTickets + " passes)";
        if (note.length() > 50) {
            note = note.substring(0, 47) + "...";
        }

        // 5. Construct secure UPI URL (RFC 3986 / NPCI UPI Deeplink standard)
        String encodedMerchantName = URLEncoder.encode(merchantName, StandardCharsets.UTF_8);
        String encodedNote = URLEncoder.encode(note, StandardCharsets.UTF_8);
        String formattedAmount = totalAmount.setScale(2, java.math.RoundingMode.HALF_UP).toPlainString();

        String upiUrl = String.format(
                "upi://pay?pa=%s&pn=%s&am=%s&cu=INR&tn=%s&tr=%s",
                vpa,
                encodedMerchantName,
                formattedAmount,
                encodedNote,
                txnRef
        );

        InitiateUpiPaymentResponse response = InitiateUpiPaymentResponse.builder()
                .transactionReference(txnRef)
                .totalAmount(totalAmount)
                .upiUrl(upiUrl)
                .upiVpa(vpa)
                .merchantName(merchantName)
                .status("INITIATED")
                .itemizedBreakdown(breakdown)
                .note(note)
                .build();

        log.info("UPI payment initiated: txnRef={}, event={}, amount={}", txnRef, event.getSlug(), totalAmount);
        return ApiResponse.ok(response, "UPI payment initiated successfully");
    }
}
