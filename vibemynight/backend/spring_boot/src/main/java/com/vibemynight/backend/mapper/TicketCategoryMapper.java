package com.vibemynight.backend.mapper;

import com.vibemynight.backend.dto.TicketCategoryDto;
import com.vibemynight.backend.entity.TicketCategory;
import org.springframework.stereotype.Component;

@Component
public class TicketCategoryMapper {

    public TicketCategoryDto toDto(TicketCategory ticket) {
        if (ticket == null) return null;
        return TicketCategoryDto.builder()
                .id(ticket.getId())
                .eventDayId(ticket.getEventDay().getId())
                .name(ticket.getName())
                .type(ticket.getType().name())
                .price(ticket.getPrice())
                .availableQuantity(ticket.getAvailableQuantity())
                .maxPerCustomer(ticket.getMaxPerCustomer())
                .description(ticket.getDescription())
                .benefits(ticket.getBenefits())
                .status(ticket.getStatus().name())
                .soldOut(ticket.getAvailableQuantity() != null && ticket.getAvailableQuantity() <= 0)
                .build();
    }
}
