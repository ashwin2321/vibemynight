package com.vibemynight.backend.controller;

import com.vibemynight.backend.dto.ApiResponse;
import com.vibemynight.backend.dto.CreateInquiryRequest;
import com.vibemynight.backend.dto.InquiryAdminSummaryDto;
import com.vibemynight.backend.dto.InquiryResponse;
import com.vibemynight.backend.dto.UpdateInquiryStatusRequest;
import com.vibemynight.backend.entity.InquiryStatus;
import com.vibemynight.backend.mapper.InquiryMapper;
import com.vibemynight.backend.service.InquiryService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequiredArgsConstructor
public class InquiryController {

    private final InquiryService inquiryService;
    private final InquiryMapper inquiryMapper;

    // ---------- Public ----------

    /**
     * Customer submits a pass inquiry. Saves it, then returns everything needed
     * to open WhatsApp (pre-built message + wa.me URL) - "inquiry already saved,
     * then WhatsApp opens" ordering matches the spec exactly.
     */
    @PostMapping("/api/v1/inquiries")
    public ApiResponse<InquiryResponse> create(@Valid @RequestBody CreateInquiryRequest request) {
        return ApiResponse.ok(inquiryService.createInquiry(request), "Inquiry submitted");
    }

    /**
     * Fallback lookup for the "your inquiry has been received, OPEN WHATSAPP" screen
     * if WhatsApp couldn't be opened automatically right after submission.
     */
    @GetMapping("/api/v1/inquiries/{inquiryNumber}")
    public ApiResponse<InquiryResponse> getByInquiryNumber(@PathVariable String inquiryNumber) {
        return ApiResponse.ok(inquiryService.getByInquiryNumber(inquiryNumber));
    }

    // ---------- Admin ----------

    @GetMapping("/api/v1/admin/inquiries")
    public ApiResponse<List<InquiryAdminSummaryDto>> list(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) InquiryStatus status,
            @RequestParam(required = false) Long eventId,
            @RequestParam(required = false) Long artistId,
            @RequestParam(required = false) Long ticketCategoryId,
            @RequestParam(required = false) LocalDate date
    ) {
        List<InquiryAdminSummaryDto> inquiries = inquiryService
                .search(search, status, eventId, artistId, ticketCategoryId, date).stream()
                .map(inquiryMapper::toSummaryDto)
                .toList();
        return ApiResponse.ok(inquiries);
    }

    @GetMapping("/api/v1/admin/inquiries/{id}")
    public ApiResponse<InquiryResponse> getById(@PathVariable Long id) {
        return ApiResponse.ok(inquiryService.getDetailById(id));
    }

    /** Body: { "status": "NEW" | "CONTACTED" | "CONFIRMED" | "CANCELLED" | "COMPLETED" } */
    @PatchMapping("/api/v1/admin/inquiries/{id}/status")
    public ApiResponse<InquiryResponse> updateStatus(@PathVariable Long id, @Valid @RequestBody UpdateInquiryStatusRequest request) {
        InquiryStatus status = InquiryStatus.valueOf(request.getStatus().toUpperCase());
        inquiryService.updateStatus(id, status);
        return ApiResponse.ok(inquiryService.getDetailById(id), "Inquiry status updated");
    }

    @DeleteMapping("/api/v1/admin/inquiries/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        inquiryService.delete(id);
        return ApiResponse.ok(null, "Inquiry deleted");
    }
}
