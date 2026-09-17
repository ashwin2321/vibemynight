package com.vibemynight.backend.service.impl;

import com.vibemynight.backend.dto.CreateInquiryRequest;
import com.vibemynight.backend.dto.InquiryResponse;
import com.vibemynight.backend.entity.ActiveStatus;
import com.vibemynight.backend.entity.EventDay;
import com.vibemynight.backend.entity.EventDayArtist;
import com.vibemynight.backend.entity.Inquiry;
import com.vibemynight.backend.entity.InquiryStatus;
import com.vibemynight.backend.entity.Settings;
import com.vibemynight.backend.entity.TicketCategory;
import com.vibemynight.backend.exception.BadRequestException;
import com.vibemynight.backend.exception.ResourceNotFoundException;
import com.vibemynight.backend.repository.EventDayArtistRepository;
import com.vibemynight.backend.repository.EventDayRepository;
import com.vibemynight.backend.repository.InquiryRepository;
import com.vibemynight.backend.repository.SettingsRepository;
import com.vibemynight.backend.repository.TicketCategoryRepository;
import com.vibemynight.backend.service.InquiryService;
import com.vibemynight.backend.util.WhatsAppMessageBuilder;
import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;
import jakarta.persistence.PersistenceContext;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Service
@RequiredArgsConstructor
public class InquiryServiceImpl implements InquiryService {

    private final InquiryRepository inquiryRepository;
    private final EventDayRepository eventDayRepository;
    private final TicketCategoryRepository ticketCategoryRepository;
    private final EventDayArtistRepository eventDayArtistRepository;
    private final SettingsRepository settingsRepository;
    private final WhatsAppMessageBuilder whatsAppMessageBuilder;

    @PersistenceContext
    private EntityManager entityManager;

    @Override
    @Transactional
    public InquiryResponse createInquiry(CreateInquiryRequest request) {

        EventDay eventDay = eventDayRepository.findById(request.getEventDayId())
                .orElseThrow(() -> new ResourceNotFoundException("Event day not found"));

        if (eventDay.getStatus() != ActiveStatus.ACTIVE) {
            throw new BadRequestException("This day is not available for booking");
        }

        // Lock the pass row so concurrent inquiries can't oversell availableQuantity.
        TicketCategory ticket = entityManager.find(
                TicketCategory.class, request.getTicketCategoryId(), LockModeType.PESSIMISTIC_WRITE);
        if (ticket == null) {
            throw new ResourceNotFoundException("Pass not found");
        }

        if (!ticket.getEventDay().getId().equals(eventDay.getId())) {
            throw new BadRequestException("Selected pass does not belong to the selected day");
        }
        if (ticket.getStatus() != ActiveStatus.ACTIVE) {
            throw new BadRequestException("This pass is not currently available");
        }

        int quantity = request.getQuantity();
        if (quantity < 1) {
            throw new BadRequestException("Quantity must be at least 1");
        }
        int maxAllowed = (ticket.getMaxPerCustomer() != null && ticket.getMaxPerCustomer() > 10) ? ticket.getMaxPerCustomer() : 100;
        if (quantity > maxAllowed) {
            throw new BadRequestException("Maximum " + maxAllowed + " passes allowed per inquiry");
        }
        if (ticket.getAvailableQuantity() < quantity) {
            throw new BadRequestException("Only " + ticket.getAvailableQuantity() + " passes left");
        }

        // Price is always taken from the current DB record - never trusted from the client.
        BigDecimal price = ticket.getPrice();
        BigDecimal total = price.multiply(BigDecimal.valueOf(quantity));

        ticket.setAvailableQuantity(ticket.getAvailableQuantity() - quantity);
        ticketCategoryRepository.save(ticket);

        String primaryArtistName = null;
        Long primaryArtistId = null;
        var primaryArtistLink = eventDayArtistRepository.findByEventDayIdAndIsPrimaryTrue(eventDay.getId());
        if (primaryArtistLink.isPresent()) {
            EventDayArtist link = primaryArtistLink.get();
            primaryArtistId = link.getArtist().getId();
            primaryArtistName = link.getArtist().getName();
        }

        Inquiry inquiry = Inquiry.builder()
                .inquiryNumber(generateInquiryNumber())
                .customerName(request.getCustomerName())
                .customerMobile(request.getCustomerMobile())
                .customerEmail(request.getCustomerEmail())
                .event(eventDay.getEvent())
                .eventDay(eventDay)
                .artist(primaryArtistLink.map(EventDayArtist::getArtist).orElse(null))
                .ticketCategory(ticket)
                .price(price)
                .quantity(quantity)
                .estimatedTotal(total)
                .customerMessage(request.getMessage())
                .status(InquiryStatus.NEW)
                .build();

        inquiry = inquiryRepository.save(inquiry);

        String whatsappNumber = settingsRepository.findAll().stream()
                .findFirst()
                .map(Settings::getWhatsappNumber)
                .orElse(null);

        return toResponse(inquiry, primaryArtistId, primaryArtistName, whatsappNumber);
    }

    @Override
    @Transactional(readOnly = true)
    public InquiryResponse getByInquiryNumber(String inquiryNumber) {
        Inquiry inquiry = inquiryRepository.findByInquiryNumber(inquiryNumber)
                .orElseThrow(() -> new ResourceNotFoundException("Inquiry not found"));

        String artistName = inquiry.getArtist() != null ? inquiry.getArtist().getName() : null;
        Long artistId = inquiry.getArtist() != null ? inquiry.getArtist().getId() : null;
        String whatsappNumber = settingsRepository.findAll().stream()
                .findFirst().map(Settings::getWhatsappNumber).orElse(null);

        // Mask PII on public unauthenticated lookup to prevent enumeration attacks
        return toMaskedResponse(inquiry, artistId, artistName, whatsappNumber);
    }

    @Override
    @Transactional(readOnly = true)
    public List<Inquiry> findAll() {
        return inquiryRepository.findAll();
    }

    @Override
    @Transactional(readOnly = true)
    public List<Inquiry> search(String search, InquiryStatus status, Long eventId, Long artistId,
                                 Long ticketCategoryId, java.time.LocalDate date) {
        return inquiryRepository.findAll(
                com.vibemynight.backend.specification.InquirySpecification.filter(
                        search, status, eventId, artistId, ticketCategoryId, date));
    }

    @Override
    @Transactional(readOnly = true)
    public Inquiry getById(Long id) {
        return inquiryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Inquiry not found"));
    }

    @Override
    @Transactional(readOnly = true)
    public InquiryResponse getDetailById(Long id) {
        Inquiry inquiry = getById(id);
        String artistName = inquiry.getArtist() != null ? inquiry.getArtist().getName() : null;
        Long artistId = inquiry.getArtist() != null ? inquiry.getArtist().getId() : null;
        String whatsappNumber = settingsRepository.findAll().stream()
                .findFirst().map(Settings::getWhatsappNumber).orElse(null);
        return toResponse(inquiry, artistId, artistName, whatsappNumber);
    }

    @Override
    @Transactional
    public Inquiry updateStatus(Long id, InquiryStatus status) {
        Inquiry inquiry = getById(id);
        inquiry.setStatus(status);
        return inquiryRepository.save(inquiry);
    }

    @Override
    @Transactional
    public void delete(Long id) {
        inquiryRepository.delete(getById(id));
    }

    private static final String ALPHANUMERIC = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ";
    private static final java.security.SecureRandom RANDOM = new java.security.SecureRandom();

    /** Concurrency-safe, collision-free inquiry number (e.g. VMN-2609-K8F2P4). */
    private String generateInquiryNumber() {
        java.time.LocalDate now = java.time.LocalDate.now();
        String prefix = String.format("VMN-%02d%02d-", now.getYear() % 100, now.getMonthValue());
        for (int attempt = 0; attempt < 10; attempt++) {
            StringBuilder sb = new StringBuilder(prefix);
            for (int i = 0; i < 6; i++) {
                sb.append(ALPHANUMERIC.charAt(RANDOM.nextInt(ALPHANUMERIC.length())));
            }
            String candidate = sb.toString();
            if (!inquiryRepository.existsByInquiryNumber(candidate)) {
                return candidate;
            }
        }
        return "VMN-" + System.currentTimeMillis();
    }

    private InquiryResponse toMaskedResponse(Inquiry inquiry, Long artistId, String artistName, String whatsappNumber) {
        InquiryResponse resp = toResponse(inquiry, artistId, artistName, whatsappNumber);
        resp.setCustomerName(maskName(inquiry.getCustomerName()));
        resp.setCustomerMobile(maskMobile(inquiry.getCustomerMobile()));
        resp.setCustomerEmail(maskEmail(inquiry.getCustomerEmail()));
        return resp;
    }

    private String maskName(String name) {
        if (name == null || name.isBlank()) return "Customer";
        String[] parts = name.trim().split("\\s+");
        StringBuilder sb = new StringBuilder();
        for (String part : parts) {
            if (part.length() <= 1) {
                sb.append(part).append(" ");
            } else {
                sb.append(part.charAt(0)).append("*".repeat(Math.max(1, part.length() - 1))).append(" ");
            }
        }
        return sb.toString().trim();
    }

    private String maskMobile(String mobile) {
        if (mobile == null || mobile.length() < 4) return "****";
        return mobile.substring(0, 2) + "******" + mobile.substring(mobile.length() - 2);
    }

    private String maskEmail(String email) {
        if (email == null || !email.contains("@")) return null;
        int atIdx = email.indexOf("@");
        if (atIdx <= 2) return "***" + email.substring(atIdx);
        return email.substring(0, 2) + "***" + email.substring(atIdx);
    }

    private InquiryResponse toResponse(Inquiry inquiry, Long artistId, String artistName, String whatsappNumber) {
        EventDay day = inquiry.getEventDay();
        TicketCategory ticket = inquiry.getTicketCategory();
        InquiryResponse response = InquiryResponse.builder()
                .id(inquiry.getId())
                .inquiryNumber(inquiry.getInquiryNumber())
                .status(inquiry.getStatus().name())
                .customerName(inquiry.getCustomerName())
                .customerMobile(inquiry.getCustomerMobile())
                .customerEmail(inquiry.getCustomerEmail())
                .eventId(inquiry.getEvent().getId())
                .eventName(inquiry.getEvent().getName())
                .eventDayId(day.getId())
                .dayNumber(day.getDayNumber())
                .date(day.getDate())
                .programName(day.getProgramName())
                .artistId(artistId)
                .artistName(artistName)
                .startTime(day.getStartTime())
                .endTime(day.getEndTime())
                .venue(day.getVenue())
                .location(day.getLocation())
                .ticketCategoryId(ticket.getId())
                .ticketCategoryName(ticket.getName())
                .price(inquiry.getPrice())
                .quantity(inquiry.getQuantity())
                .estimatedTotal(inquiry.getEstimatedTotal())
                .customerMessage(inquiry.getCustomerMessage())
                .whatsappNumber(whatsappNumber)
                .createdAt(inquiry.getCreatedAt())
                .build();

        String message = whatsAppMessageBuilder.buildMessage(response);
        response.setWhatsappMessage(message);
        if (whatsappNumber != null) {
            response.setWhatsappUrl(whatsAppMessageBuilder.buildWhatsAppUrl(whatsappNumber, message));
        }
        return response;
    }
}
