package com.vibemynight.backend.controller;

import com.vibemynight.backend.dto.ApiResponse;
import com.vibemynight.backend.dto.CreateEventRequest;
import com.vibemynight.backend.dto.EventDetailDto;
import com.vibemynight.backend.dto.EventSummaryDto;
import com.vibemynight.backend.entity.Event;
import com.vibemynight.backend.entity.EventStatus;
import com.vibemynight.backend.entity.Facility;
import com.vibemynight.backend.mapper.EventMapper;
import com.vibemynight.backend.repository.EventFacilityRepository;
import com.vibemynight.backend.service.EventService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequiredArgsConstructor
public class EventController {

    private final EventService eventService;
    private final EventMapper eventMapper;
    private final EventFacilityRepository eventFacilityRepository;

    // ---------- Public ----------

    @GetMapping("/api/v1/events")
    public ApiResponse<List<EventSummaryDto>> listPublished() {
        List<EventSummaryDto> events = eventService.findPublished().stream()
                .map(eventMapper::toSummaryDto)
                .toList();
        return ApiResponse.ok(events);
    }

    @GetMapping("/api/v1/events/{slug}")
    public ApiResponse<EventDetailDto> getBySlug(@PathVariable String slug) {
        Event event = eventService.getBySlug(slug);
        List<Facility> facilities = eventFacilityRepository.findByEventId(event.getId()).stream()
                .map(ef -> ef.getFacility())
                .toList();
        return ApiResponse.ok(eventMapper.toDetailDto(event, facilities));
    }

    // ---------- Admin ----------

    @GetMapping("/api/v1/admin/events")
    public ApiResponse<List<EventSummaryDto>> listAllForAdmin() {
        List<EventSummaryDto> events = eventService.findAllForAdmin().stream()
                .map(eventMapper::toSummaryDto)
                .toList();
        return ApiResponse.ok(events);
    }

    @GetMapping("/api/v1/admin/events/{id}")
    public ApiResponse<EventDetailDto> getByIdForAdmin(@PathVariable Long id) {
        Event event = eventService.getById(id);
        List<Facility> facilities = eventFacilityRepository.findByEventId(event.getId()).stream()
                .map(ef -> ef.getFacility())
                .toList();
        return ApiResponse.ok(eventMapper.toDetailDto(event, facilities));
    }

    @PostMapping("/api/v1/admin/events")
    public ApiResponse<EventSummaryDto> create(@Valid @RequestBody CreateEventRequest request) {
        Event event = Event.builder()
                .name(request.getName())
                .slug(request.getSlug())
                .mainImage(request.getMainImage())
                .banner(request.getBanner())
                .thumbnail(request.getThumbnail())
                .description(request.getDescription())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .venue(request.getVenue())
                .address(request.getAddress())
                .city(request.getCity())
                .location(request.getLocation())
                .googleMapsUrl(request.getGoogleMapsUrl())
                .organizer(request.getOrganizer())
                .contactNumber(request.getContactNumber())
                .email(request.getEmail())
                .featured(request.isFeatured())
                .status(EventStatus.DRAFT)
                .build();
        Event saved = eventService.create(event);
        return ApiResponse.ok(eventMapper.toSummaryDto(saved), "Event created");
    }

    @PutMapping("/api/v1/admin/events/{id}")
    public ApiResponse<EventSummaryDto> update(@PathVariable Long id, @Valid @RequestBody CreateEventRequest request) {
        Event event = Event.builder()
                .name(request.getName())
                .slug(request.getSlug())
                .mainImage(request.getMainImage())
                .banner(request.getBanner())
                .thumbnail(request.getThumbnail())
                .description(request.getDescription())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .venue(request.getVenue())
                .address(request.getAddress())
                .city(request.getCity())
                .location(request.getLocation())
                .googleMapsUrl(request.getGoogleMapsUrl())
                .organizer(request.getOrganizer())
                .contactNumber(request.getContactNumber())
                .email(request.getEmail())
                .featured(request.isFeatured())
                .build();
        Event saved = eventService.update(id, event);
        return ApiResponse.ok(eventMapper.toSummaryDto(saved), "Event updated");
    }

    @DeleteMapping("/api/v1/admin/events/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        eventService.delete(id);
        return ApiResponse.ok(null, "Event deleted");
    }

    /** Body: { "status": "PUBLISHED" | "UNPUBLISHED" | "COMPLETED" | "CANCELLED" | "DRAFT" } */
    @PatchMapping("/api/v1/admin/events/{id}/status")
    public ApiResponse<EventSummaryDto> changeStatus(@PathVariable Long id, @RequestBody Map<String, String> body) {
        EventStatus status = EventStatus.valueOf(body.get("status").toUpperCase());
        Event saved = eventService.changeStatus(id, status);
        return ApiResponse.ok(eventMapper.toSummaryDto(saved), "Event status updated");
    }
}
