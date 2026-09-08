package com.vibemynight.backend.service;

import com.vibemynight.backend.dto.CreateInquiryRequest;
import com.vibemynight.backend.dto.InquiryResponse;
import com.vibemynight.backend.entity.Inquiry;
import com.vibemynight.backend.entity.InquiryStatus;

import java.time.LocalDate;
import java.util.List;

public interface InquiryService {

    /**
     * Validates and creates an inquiry. Price and total are always computed
     * server-side from the current TicketCategory - client-supplied price is ignored.
     */
    InquiryResponse createInquiry(CreateInquiryRequest request);

    InquiryResponse getByInquiryNumber(String inquiryNumber);

    List<Inquiry> findAll();

    List<Inquiry> search(String search, InquiryStatus status, Long eventId, Long artistId,
                          Long ticketCategoryId, LocalDate date);

    Inquiry getById(Long id);

    /** Full detail (including WhatsApp message/url) for the admin inquiry detail screen. */
    InquiryResponse getDetailById(Long id);

    Inquiry updateStatus(Long id, InquiryStatus status);

    void delete(Long id);
}
