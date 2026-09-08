package com.vibemynight.backend.controller;

import com.vibemynight.backend.dto.ApiResponse;
import com.vibemynight.backend.dto.AssignArtistToDayRequest;
import com.vibemynight.backend.dto.CreateEventDayRequest;
import com.vibemynight.backend.dto.EventDayDetailDto;
import com.vibemynight.backend.dto.EventDaySummaryDto;
import com.vibemynight.backend.entity.ActiveStatus;
import com.vibemynight.backend.entity.Artist;
import com.vibemynight.backend.entity.EventDay;
import com.vibemynight.backend.entity.EventDayArtist;
import com.vibemynight.backend.entity.Facility;
import com.vibemynight.backend.exception.ResourceNotFoundException;
import com.vibemynight.backend.mapper.EventDayMapper;
import com.vibemynight.backend.repository.ArtistRepository;
import com.vibemynight.backend.repository.EventDayArtistRepository;
import com.vibemynight.backend.repository.EventDayFacilityRepository;
import com.vibemynight.backend.service.EventDayService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class EventDayController {

    private final EventDayService eventDayService;
    private final EventDayMapper eventDayMapper;
    private final EventDayArtistRepository eventDayArtistRepository;
    private final EventDayFacilityRepository eventDayFacilityRepository;
    private final ArtistRepository artistRepository;

    // ---------- Public ----------

    @GetMapping("/api/v1/events/{eventId}/days")
    public ApiResponse<List<EventDaySummaryDto>> listDaysForEvent(@PathVariable Long eventId) {
        List<EventDaySummaryDto> days = eventDayService.findByEvent(eventId).stream()
                .map(eventDayMapper::toSummaryDto)
                .toList();
        return ApiResponse.ok(days);
    }

    @GetMapping("/api/v1/event-days/{id}")
    public ApiResponse<EventDayDetailDto> getDayDetail(@PathVariable Long id) {
        EventDay day = eventDayService.getById(id);
        List<Facility> facilities = eventDayFacilityRepository.findByEventDayId(id).stream()
                .map(edf -> edf.getFacility())
                .toList();
        return ApiResponse.ok(eventDayMapper.toDetailDto(day, facilities));
    }

    // ---------- Admin ----------

    @PostMapping("/api/v1/admin/events/{eventId}/days")
    public ApiResponse<EventDayDetailDto> create(@PathVariable Long eventId, @Valid @RequestBody CreateEventDayRequest request) {
        EventDay day = EventDay.builder()
                .dayNumber(request.getDayNumber())
                .date(request.getDate())
                .dayName(request.getDayName())
                .programName(request.getProgramName())
                .startTime(request.getStartTime())
                .endTime(request.getEndTime())
                .venue(request.getVenue())
                .address(request.getAddress())
                .location(request.getLocation())
                .googleMapsUrl(request.getGoogleMapsUrl())
                .description(request.getDescription())
                .status(ActiveStatus.ACTIVE)
                .build();
        EventDay saved = eventDayService.create(eventId, day);
        return ApiResponse.ok(eventDayMapper.toDetailDto(saved, List.of()), "Event day created");
    }

    @PutMapping("/api/v1/admin/event-days/{id}")
    public ApiResponse<EventDayDetailDto> update(@PathVariable Long id, @Valid @RequestBody CreateEventDayRequest request) {
        EventDay day = EventDay.builder()
                .dayNumber(request.getDayNumber())
                .date(request.getDate())
                .dayName(request.getDayName())
                .programName(request.getProgramName())
                .startTime(request.getStartTime())
                .endTime(request.getEndTime())
                .venue(request.getVenue())
                .address(request.getAddress())
                .location(request.getLocation())
                .googleMapsUrl(request.getGoogleMapsUrl())
                .description(request.getDescription())
                .status(ActiveStatus.ACTIVE)
                .build();
        EventDay saved = eventDayService.update(id, day);
        List<Facility> facilities = eventDayFacilityRepository.findByEventDayId(id).stream()
                .map(edf -> edf.getFacility())
                .toList();
        return ApiResponse.ok(eventDayMapper.toDetailDto(saved, facilities), "Event day updated");
    }

    @DeleteMapping("/api/v1/admin/event-days/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        eventDayService.delete(id);
        return ApiResponse.ok(null, "Event day deleted");
    }

    /** Assign (or update the assignment of) an artist to a day - one primary + any number of additional artists. */
    @PostMapping("/api/v1/admin/event-days/{dayId}/artists")
    public ApiResponse<Void> assignArtist(@PathVariable Long dayId, @Valid @RequestBody AssignArtistToDayRequest request) {
        EventDay day = eventDayService.getById(dayId);
        Artist artist = artistRepository.findById(request.getArtistId())
                .orElseThrow(() -> new ResourceNotFoundException("Artist not found: " + request.getArtistId()));

        EventDayArtist link = EventDayArtist.builder()
                .eventDay(day)
                .artist(artist)
                .isPrimary(request.isPrimary())
                .performanceOrder(request.getPerformanceOrder())
                .performanceStartTime(request.getPerformanceStartTime())
                .performanceEndTime(request.getPerformanceEndTime())
                .build();
        eventDayArtistRepository.save(link);
        return ApiResponse.ok(null, "Artist assigned to day");
    }

    @DeleteMapping("/api/v1/admin/event-days/{dayId}/artists/{artistId}")
    public ApiResponse<Void> removeArtist(@PathVariable Long dayId, @PathVariable Long artistId) {
        eventDayArtistRepository.deleteByEventDayIdAndArtistId(dayId, artistId);
        return ApiResponse.ok(null, "Artist removed from day");
    }
}
