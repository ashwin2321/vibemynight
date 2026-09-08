package com.vibemynight.backend.service;

import com.vibemynight.backend.entity.TicketCategory;

import java.util.List;

public interface TicketCategoryService {
    List<TicketCategory> findByEventDay(Long eventDayId);
    TicketCategory getById(Long id);
    TicketCategory create(Long eventDayId, TicketCategory ticket);
    TicketCategory update(Long id, TicketCategory ticket);
    void delete(Long id);
}
