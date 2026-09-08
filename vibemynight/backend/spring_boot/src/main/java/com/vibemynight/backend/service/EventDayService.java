package com.vibemynight.backend.service;

import com.vibemynight.backend.entity.EventDay;

import java.util.List;

public interface EventDayService {
    List<EventDay> findByEvent(Long eventId);
    EventDay getById(Long id);
    EventDay create(Long eventId, EventDay day);
    EventDay update(Long id, EventDay day);
    void delete(Long id);
}
