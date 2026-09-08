package com.vibemynight.backend.mapper;

import com.vibemynight.backend.dto.InquiryAdminSummaryDto;
import com.vibemynight.backend.entity.Inquiry;
import org.springframework.stereotype.Component;

@Component
public class InquiryMapper {

    public InquiryAdminSummaryDto toSummaryDto(Inquiry inquiry) {
        return InquiryAdminSummaryDto.builder()
                .id(inquiry.getId())
                .inquiryNumber(inquiry.getInquiryNumber())
                .customerName(inquiry.getCustomerName())
                .customerMobile(inquiry.getCustomerMobile())
                .eventName(inquiry.getEvent().getName())
                .dayNumber(inquiry.getEventDay().getDayNumber())
                .date(inquiry.getEventDay().getDate())
                .artistName(inquiry.getArtist() != null ? inquiry.getArtist().getName() : null)
                .ticketCategoryName(inquiry.getTicketCategory().getName())
                .price(inquiry.getPrice())
                .quantity(inquiry.getQuantity())
                .estimatedTotal(inquiry.getEstimatedTotal())
                .status(inquiry.getStatus().name())
                .createdAt(inquiry.getCreatedAt())
                .build();
    }
}
