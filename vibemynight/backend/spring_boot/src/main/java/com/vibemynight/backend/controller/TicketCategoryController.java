package com.vibemynight.backend.controller;

import com.vibemynight.backend.dto.ApiResponse;
import com.vibemynight.backend.dto.CreateTicketCategoryRequest;
import com.vibemynight.backend.dto.TicketCategoryDto;
import com.vibemynight.backend.entity.ActiveStatus;
import com.vibemynight.backend.entity.TicketCategory;
import com.vibemynight.backend.entity.TicketType;
import com.vibemynight.backend.mapper.TicketCategoryMapper;
import com.vibemynight.backend.service.TicketCategoryService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class TicketCategoryController {

    private final TicketCategoryService ticketCategoryService;
    private final TicketCategoryMapper ticketCategoryMapper;

    // ---------- Public ----------

    @GetMapping("/api/v1/event-days/{dayId}/passes")
    public ApiResponse<List<TicketCategoryDto>> listForDay(@PathVariable Long dayId) {
        List<TicketCategoryDto> passes = ticketCategoryService.findByEventDay(dayId).stream()
                .filter(t -> t.getStatus() == ActiveStatus.ACTIVE)
                .map(ticketCategoryMapper::toDto)
                .toList();
        return ApiResponse.ok(passes);
    }

    // ---------- Admin ----------

    @PostMapping("/api/v1/admin/event-days/{dayId}/passes")
    public ApiResponse<TicketCategoryDto> create(@PathVariable Long dayId, @Valid @RequestBody CreateTicketCategoryRequest request) {
        TicketCategory ticket = TicketCategory.builder()
                .name(request.getName())
                .type(TicketType.valueOf(request.getType().toUpperCase()))
                .price(request.getPrice())
                .availableQuantity(request.getAvailableQuantity())
                .maxPerCustomer(request.getMaxPerCustomer() != null ? request.getMaxPerCustomer() : 10)
                .description(request.getDescription())
                .benefits(request.getBenefits() != null ? request.getBenefits() : List.of())
                .status(ActiveStatus.ACTIVE)
                .build();
        TicketCategory saved = ticketCategoryService.create(dayId, ticket);
        return ApiResponse.ok(ticketCategoryMapper.toDto(saved), "Pass created");
    }

    @PutMapping("/api/v1/admin/passes/{id}")
    public ApiResponse<TicketCategoryDto> update(@PathVariable Long id, @Valid @RequestBody CreateTicketCategoryRequest request) {
        TicketCategory ticket = TicketCategory.builder()
                .name(request.getName())
                .type(TicketType.valueOf(request.getType().toUpperCase()))
                .price(request.getPrice())
                .availableQuantity(request.getAvailableQuantity())
                .maxPerCustomer(request.getMaxPerCustomer() != null ? request.getMaxPerCustomer() : 10)
                .description(request.getDescription())
                .benefits(request.getBenefits() != null ? request.getBenefits() : List.of())
                .status(ActiveStatus.ACTIVE)
                .build();
        TicketCategory saved = ticketCategoryService.update(id, ticket);
        return ApiResponse.ok(ticketCategoryMapper.toDto(saved), "Pass updated");
    }

    @DeleteMapping("/api/v1/admin/passes/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        ticketCategoryService.delete(id);
        return ApiResponse.ok(null, "Pass deleted");
    }
}
