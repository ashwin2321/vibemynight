package com.vibemynight.backend.controller;

import com.vibemynight.backend.dto.ApiResponse;
import com.vibemynight.backend.dto.CreateEventGalleryRequest;
import com.vibemynight.backend.dto.CreateEventHighlightRequest;
import com.vibemynight.backend.dto.CreateEventRuleRequest;
import com.vibemynight.backend.dto.EventGalleryDto;
import com.vibemynight.backend.dto.EventHighlightDto;
import com.vibemynight.backend.dto.EventRuleDto;
import com.vibemynight.backend.entity.Event;
import com.vibemynight.backend.entity.EventGallery;
import com.vibemynight.backend.entity.EventHighlight;
import com.vibemynight.backend.entity.EventRule;
import com.vibemynight.backend.exception.ResourceNotFoundException;
import com.vibemynight.backend.repository.EventGalleryRepository;
import com.vibemynight.backend.repository.EventHighlightRepository;
import com.vibemynight.backend.repository.EventRuleRepository;
import com.vibemynight.backend.service.EventService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/**
 * Admin CRUD for the three Event sub-content types that don't warrant their own
 * top-level service: gallery images, highlights, rules. All are read publicly
 * via EventDetailDto (see EventController/EventMapper) - this controller only
 * covers the admin write side.
 */
@RestController
@RequiredArgsConstructor
public class EventContentController {

    private final EventService eventService;
    private final EventGalleryRepository eventGalleryRepository;
    private final EventHighlightRepository eventHighlightRepository;
    private final EventRuleRepository eventRuleRepository;

    // ---------- Gallery ----------

    @PostMapping("/api/v1/admin/events/{eventId}/gallery")
    public ApiResponse<EventGalleryDto> addGalleryImage(@PathVariable Long eventId, @Valid @RequestBody CreateEventGalleryRequest request) {
        Event event = eventService.getById(eventId);
        EventGallery image = EventGallery.builder()
                .event(event)
                .imageUrl(request.getImageUrl())
                .caption(request.getCaption())
                .sortOrder(request.getSortOrder() != null ? request.getSortOrder() : 0)
                .build();
        image = eventGalleryRepository.save(image);
        return ApiResponse.ok(toDto(image), "Gallery image added");
    }

    @DeleteMapping("/api/v1/admin/gallery/{id}")
    public ApiResponse<Void> deleteGalleryImage(@PathVariable Long id) {
        EventGallery image = eventGalleryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Gallery image not found: " + id));
        eventGalleryRepository.delete(image);
        return ApiResponse.ok(null, "Gallery image deleted");
    }

    // ---------- Highlights ----------

    @PostMapping("/api/v1/admin/events/{eventId}/highlights")
    public ApiResponse<EventHighlightDto> addHighlight(@PathVariable Long eventId, @Valid @RequestBody CreateEventHighlightRequest request) {
        Event event = eventService.getById(eventId);
        EventHighlight highlight = EventHighlight.builder()
                .event(event)
                .text(request.getText())
                .sortOrder(request.getSortOrder() != null ? request.getSortOrder() : 0)
                .build();
        highlight = eventHighlightRepository.save(highlight);
        return ApiResponse.ok(toDto(highlight), "Highlight added");
    }

    @DeleteMapping("/api/v1/admin/highlights/{id}")
    public ApiResponse<Void> deleteHighlight(@PathVariable Long id) {
        EventHighlight highlight = eventHighlightRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Highlight not found: " + id));
        eventHighlightRepository.delete(highlight);
        return ApiResponse.ok(null, "Highlight deleted");
    }

    // ---------- Rules ----------

    @PostMapping("/api/v1/admin/events/{eventId}/rules")
    public ApiResponse<EventRuleDto> addRule(@PathVariable Long eventId, @Valid @RequestBody CreateEventRuleRequest request) {
        Event event = eventService.getById(eventId);
        EventRule rule = EventRule.builder()
                .event(event)
                .text(request.getText())
                .sortOrder(request.getSortOrder() != null ? request.getSortOrder() : 0)
                .build();
        rule = eventRuleRepository.save(rule);
        return ApiResponse.ok(toDto(rule), "Rule added");
    }

    @DeleteMapping("/api/v1/admin/rules/{id}")
    public ApiResponse<Void> deleteRule(@PathVariable Long id) {
        EventRule rule = eventRuleRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Rule not found: " + id));
        eventRuleRepository.delete(rule);
        return ApiResponse.ok(null, "Rule deleted");
    }

    // ---------- mapping helpers ----------

    private EventGalleryDto toDto(EventGallery g) {
        return EventGalleryDto.builder().id(g.getId()).imageUrl(g.getImageUrl()).caption(g.getCaption()).sortOrder(g.getSortOrder()).build();
    }

    private EventHighlightDto toDto(EventHighlight h) {
        return EventHighlightDto.builder().id(h.getId()).text(h.getText()).sortOrder(h.getSortOrder()).build();
    }

    private EventRuleDto toDto(EventRule r) {
        return EventRuleDto.builder().id(r.getId()).text(r.getText()).sortOrder(r.getSortOrder()).build();
    }
}
