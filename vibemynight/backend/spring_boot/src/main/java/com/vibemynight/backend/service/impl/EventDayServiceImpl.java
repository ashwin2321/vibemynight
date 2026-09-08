package com.vibemynight.backend.service.impl;

import com.vibemynight.backend.entity.Event;
import com.vibemynight.backend.entity.EventDay;
import com.vibemynight.backend.exception.ConflictException;
import com.vibemynight.backend.exception.ResourceNotFoundException;
import com.vibemynight.backend.repository.EventDayRepository;
import com.vibemynight.backend.repository.EventRepository;
import com.vibemynight.backend.service.EventDayService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class EventDayServiceImpl implements EventDayService {

    private final EventDayRepository eventDayRepository;
    private final EventRepository eventRepository;

    @Override
    @Transactional(readOnly = true)
    public List<EventDay> findByEvent(Long eventId) {
        return eventDayRepository.findByEventIdOrderByDayNumberAsc(eventId);
    }

    @Override
    @Transactional(readOnly = true)
    public EventDay getById(Long id) {
        return eventDayRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Event day not found: " + id));
    }

    @Override
    @Transactional
    public EventDay create(Long eventId, EventDay day) {
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Event not found: " + eventId));

        eventDayRepository.findByEventIdAndDayNumber(eventId, day.getDayNumber())
                .ifPresent(d -> {
                    throw new ConflictException("Day number " + day.getDayNumber() + " already exists for this event");
                });

        day.setEvent(event);
        return eventDayRepository.save(day);
    }

    @Override
    @Transactional
    public EventDay update(Long id, EventDay updated) {
        EventDay existing = getById(id);
        existing.setDayNumber(updated.getDayNumber());
        existing.setDate(updated.getDate());
        existing.setDayName(updated.getDayName());
        existing.setProgramName(updated.getProgramName());
        existing.setStartTime(updated.getStartTime());
        existing.setEndTime(updated.getEndTime());
        existing.setVenue(updated.getVenue());
        existing.setAddress(updated.getAddress());
        existing.setLocation(updated.getLocation());
        existing.setGoogleMapsUrl(updated.getGoogleMapsUrl());
        existing.setDescription(updated.getDescription());
        existing.setStatus(updated.getStatus());
        return eventDayRepository.save(existing);
    }

    @Override
    @Transactional
    public void delete(Long id) {
        EventDay day = getById(id);
        eventDayRepository.delete(day);
    }
}
