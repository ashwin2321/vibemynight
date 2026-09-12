package com.vibemynight.backend.service.impl;

import com.vibemynight.backend.entity.Event;
import com.vibemynight.backend.entity.EventStatus;
import com.vibemynight.backend.exception.ConflictException;
import com.vibemynight.backend.exception.ResourceNotFoundException;
import com.vibemynight.backend.repository.EventRepository;
import com.vibemynight.backend.service.EventService;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class EventServiceImpl implements EventService {

    private final EventRepository eventRepository;

    @Override
    @Transactional(readOnly = true)
    @Cacheable(value = "events")
    public List<Event> findPublished() {
        return eventRepository.findByStatus(EventStatus.PUBLISHED);
    }

    @Override
    @Transactional(readOnly = true)
    @Cacheable(value = "event_details", key = "#slug")
    public Event getBySlug(String slug) {
        return eventRepository.findBySlug(slug)
                .orElseThrow(() -> new ResourceNotFoundException("Event not found: " + slug));
    }

    @Override
    @Transactional(readOnly = true)
    public Event getById(Long id) {
        return eventRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Event not found: " + id));
    }

    @Override
    @Transactional(readOnly = true)
    public List<Event> findAllForAdmin() {
        return eventRepository.findAll();
    }

    @Override
    @Transactional
    @CacheEvict(value = {"events", "event_details"}, allEntries = true)
    public Event create(Event event) {
        if (eventRepository.existsBySlug(event.getSlug())) {
            throw new ConflictException("An event with this slug already exists");
        }
        return eventRepository.save(event);
    }

    @Override
    @Transactional
    @CacheEvict(value = {"events", "event_details"}, allEntries = true)
    public Event update(Long id, Event updated) {
        Event existing = getById(id);
        existing.setName(updated.getName());
        existing.setSlug(updated.getSlug());
        existing.setMainImage(updated.getMainImage());
        existing.setBanner(updated.getBanner());
        existing.setThumbnail(updated.getThumbnail());
        existing.setDescription(updated.getDescription());
        existing.setStartDate(updated.getStartDate());
        existing.setEndDate(updated.getEndDate());
        existing.setVenue(updated.getVenue());
        existing.setAddress(updated.getAddress());
        existing.setCity(updated.getCity());
        existing.setLocation(updated.getLocation());
        existing.setGoogleMapsUrl(updated.getGoogleMapsUrl());
        existing.setOrganizer(updated.getOrganizer());
        existing.setContactNumber(updated.getContactNumber());
        existing.setEmail(updated.getEmail());
        existing.setFeatured(updated.isFeatured());
        return eventRepository.save(existing);
    }

    @Override
    @Transactional
    @CacheEvict(value = {"events", "event_details"}, allEntries = true)
    public void delete(Long id) {
        Event event = getById(id);
        eventRepository.delete(event);
    }

    @Override
    @Transactional
    @CacheEvict(value = {"events", "event_details"}, allEntries = true)
    public Event changeStatus(Long id, EventStatus status) {
        Event event = getById(id);
        event.setStatus(status);
        return eventRepository.save(event);
    }
}
