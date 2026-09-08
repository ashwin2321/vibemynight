package com.vibemynight.backend.controller;

import com.vibemynight.backend.dto.ApiResponse;
import com.vibemynight.backend.dto.CreateFacilityRequest;
import com.vibemynight.backend.dto.FacilityDto;
import com.vibemynight.backend.entity.ActiveStatus;
import com.vibemynight.backend.entity.Event;
import com.vibemynight.backend.entity.EventDay;
import com.vibemynight.backend.entity.EventDayFacility;
import com.vibemynight.backend.entity.EventFacility;
import com.vibemynight.backend.entity.Facility;
import com.vibemynight.backend.mapper.FacilityMapper;
import com.vibemynight.backend.repository.EventDayFacilityRepository;
import com.vibemynight.backend.repository.EventFacilityRepository;
import com.vibemynight.backend.service.EventDayService;
import com.vibemynight.backend.service.EventService;
import com.vibemynight.backend.service.FacilityService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequiredArgsConstructor
public class FacilityController {

    private final FacilityService facilityService;
    private final FacilityMapper facilityMapper;
    private final EventService eventService;
    private final EventDayService eventDayService;
    private final EventFacilityRepository eventFacilityRepository;
    private final EventDayFacilityRepository eventDayFacilityRepository;

    // ---------- Public ----------

    @GetMapping("/api/v1/facilities")
    public ApiResponse<List<FacilityDto>> list() {
        List<FacilityDto> facilities = facilityService.findByStatus(ActiveStatus.ACTIVE).stream()
                .map(facilityMapper::toDto)
                .toList();
        return ApiResponse.ok(facilities);
    }

    // ---------- Admin: Facility CRUD ----------

    @GetMapping("/api/v1/admin/facilities")
    public ApiResponse<List<FacilityDto>> listAllForAdmin() {
        List<FacilityDto> facilities = facilityService.findAll().stream()
                .map(facilityMapper::toDto)
                .toList();
        return ApiResponse.ok(facilities);
    }

    @PostMapping("/api/v1/admin/facilities")
    public ApiResponse<FacilityDto> create(@Valid @RequestBody CreateFacilityRequest request) {
        Facility facility = Facility.builder()
                .name(request.getName())
                .icon(request.getIcon())
                .description(request.getDescription())
                .status(ActiveStatus.ACTIVE)
                .build();
        return ApiResponse.ok(facilityMapper.toDto(facilityService.create(facility)), "Facility created");
    }

    @PutMapping("/api/v1/admin/facilities/{id}")
    public ApiResponse<FacilityDto> update(@PathVariable Long id, @Valid @RequestBody CreateFacilityRequest request) {
        Facility facility = Facility.builder()
                .name(request.getName())
                .icon(request.getIcon())
                .description(request.getDescription())
                .build();
        return ApiResponse.ok(facilityMapper.toDto(facilityService.update(id, facility)), "Facility updated");
    }

    @DeleteMapping("/api/v1/admin/facilities/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        facilityService.delete(id);
        return ApiResponse.ok(null, "Facility deleted");
    }

    /** Body: { "status": "ACTIVE" | "INACTIVE" } */
    @PatchMapping("/api/v1/admin/facilities/{id}/status")
    public ApiResponse<FacilityDto> changeStatus(@PathVariable Long id, @RequestBody Map<String, String> body) {
        ActiveStatus status = ActiveStatus.valueOf(body.get("status").toUpperCase());
        return ApiResponse.ok(facilityMapper.toDto(facilityService.changeStatus(id, status)), "Facility status updated");
    }

    // ---------- Admin: event-level and day-level facility assignment ----------

    @PostMapping("/api/v1/admin/events/{eventId}/facilities/{facilityId}")
    public ApiResponse<Void> addToEvent(@PathVariable Long eventId, @PathVariable Long facilityId) {
        Event event = eventService.getById(eventId);
        Facility facility = facilityService.getById(facilityId);
        eventFacilityRepository.save(EventFacility.builder().event(event).facility(facility).build());
        return ApiResponse.ok(null, "Facility added to event");
    }

    @DeleteMapping("/api/v1/admin/events/{eventId}/facilities/{facilityId}")
    public ApiResponse<Void> removeFromEvent(@PathVariable Long eventId, @PathVariable Long facilityId) {
        eventFacilityRepository.deleteByEventIdAndFacilityId(eventId, facilityId);
        return ApiResponse.ok(null, "Facility removed from event");
    }

    @PostMapping("/api/v1/admin/event-days/{dayId}/facilities/{facilityId}")
    public ApiResponse<Void> addToDay(@PathVariable Long dayId, @PathVariable Long facilityId) {
        EventDay day = eventDayService.getById(dayId);
        Facility facility = facilityService.getById(facilityId);
        eventDayFacilityRepository.save(EventDayFacility.builder().eventDay(day).facility(facility).build());
        return ApiResponse.ok(null, "Facility added to day");
    }

    @DeleteMapping("/api/v1/admin/event-days/{dayId}/facilities/{facilityId}")
    public ApiResponse<Void> removeFromDay(@PathVariable Long dayId, @PathVariable Long facilityId) {
        eventDayFacilityRepository.deleteByEventDayIdAndFacilityId(dayId, facilityId);
        return ApiResponse.ok(null, "Facility removed from day");
    }
}
