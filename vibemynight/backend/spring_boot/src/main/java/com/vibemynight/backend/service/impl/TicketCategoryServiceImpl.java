package com.vibemynight.backend.service.impl;

import com.vibemynight.backend.entity.EventDay;
import com.vibemynight.backend.entity.TicketCategory;
import com.vibemynight.backend.exception.ResourceNotFoundException;
import com.vibemynight.backend.repository.EventDayRepository;
import com.vibemynight.backend.repository.TicketCategoryRepository;
import com.vibemynight.backend.service.TicketCategoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class TicketCategoryServiceImpl implements TicketCategoryService {

    private final TicketCategoryRepository ticketCategoryRepository;
    private final EventDayRepository eventDayRepository;

    @Override
    @Transactional(readOnly = true)
    public List<TicketCategory> findByEventDay(Long eventDayId) {
        return ticketCategoryRepository.findByEventDayId(eventDayId);
    }

    @Override
    @Transactional(readOnly = true)
    public TicketCategory getById(Long id) {
        return ticketCategoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Pass not found: " + id));
    }

    @Override
    @Transactional
    public TicketCategory create(Long eventDayId, TicketCategory ticket) {
        EventDay day = eventDayRepository.findById(eventDayId)
                .orElseThrow(() -> new ResourceNotFoundException("Event day not found: " + eventDayId));
        ticket.setEventDay(day);
        return ticketCategoryRepository.save(ticket);
    }

    @Override
    @Transactional
    public TicketCategory update(Long id, TicketCategory updated) {
        TicketCategory existing = getById(id);
        existing.setName(updated.getName());
        existing.setType(updated.getType());
        existing.setPrice(updated.getPrice());
        existing.setAvailableQuantity(updated.getAvailableQuantity());
        existing.setMaxPerCustomer(updated.getMaxPerCustomer());
        existing.setDescription(updated.getDescription());
        existing.setBenefits(updated.getBenefits());
        existing.setStatus(updated.getStatus());
        return ticketCategoryRepository.save(existing);
    }

    @Override
    @Transactional
    public void delete(Long id) {
        ticketCategoryRepository.delete(getById(id));
    }
}
