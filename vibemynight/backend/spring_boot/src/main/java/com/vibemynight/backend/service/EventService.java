package com.vibemynight.backend.service;

import com.vibemynight.backend.entity.Event;
import com.vibemynight.backend.entity.EventStatus;

import java.util.List;

public interface EventService {
    List<Event> findPublished();
    Event getBySlug(String slug);
    Event getById(Long id);
    List<Event> findAllForAdmin();
    Event create(Event event);
    Event update(Long id, Event event);
    void delete(Long id);
    Event changeStatus(Long id, EventStatus status);
}
