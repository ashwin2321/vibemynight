package com.vibemynight.backend.service.impl;

import com.vibemynight.backend.entity.Event;
import com.vibemynight.backend.entity.EventDay;
import com.vibemynight.backend.exception.ConflictException;
import com.vibemynight.backend.exception.ResourceNotFoundException;
import com.vibemynight.backend.repository.EventDayFacilityRepository;
import com.vibemynight.backend.repository.EventFacilityRepository;
import com.vibemynight.backend.repository.EventRepository;
import com.vibemynight.backend.repository.InquiryRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class EventServiceTest {

    @Mock
    private EventRepository eventRepository;
    @Mock
    private EventFacilityRepository eventFacilityRepository;
    @Mock
    private EventDayFacilityRepository eventDayFacilityRepository;
    @Mock
    private InquiryRepository inquiryRepository;

    private EventServiceImpl eventService;

    @BeforeEach
    void setUp() {
        eventService = new EventServiceImpl(
                eventRepository,
                eventFacilityRepository,
                eventDayFacilityRepository,
                inquiryRepository
        );
    }

    @Test
    void testDeleteEventSuccess_CleansUpChildFacilities() {
        Long eventId = 100L;
        EventDay day1 = EventDay.builder().dayNumber(1).build();
        day1.setId(201L);

        Event event = Event.builder()
                .name("Disposable Test Event")
                .eventDays(List.of(day1))
                .build();
        event.setId(eventId);

        when(eventRepository.findById(eventId)).thenReturn(Optional.of(event));
        when(inquiryRepository.existsByEventId(eventId)).thenReturn(false);

        assertDoesNotThrow(() -> eventService.delete(eventId));

        verify(eventFacilityRepository, times(1)).deleteByEventId(eventId);
        verify(eventDayFacilityRepository, times(1)).deleteByEventDayId(201L);
        verify(eventRepository, times(1)).delete(event);
    }

    @Test
    void testDeleteEvent_ThrowsConflictWhenInquiriesExist() {
        Long eventId = 100L;
        Event event = Event.builder().name("Event With Inquiries").build();
        event.setId(eventId);

        when(eventRepository.findById(eventId)).thenReturn(Optional.of(event));
        when(inquiryRepository.existsByEventId(eventId)).thenReturn(true);

        ConflictException ex = assertThrows(ConflictException.class, () -> eventService.delete(eventId));
        assertTrue(ex.getMessage().contains("customer inquiries"));

        verify(eventRepository, never()).delete(any(Event.class));
        verify(eventFacilityRepository, never()).deleteByEventId(anyLong());
    }

    @Test
    void testDeleteNonExistentEventThrowsNotFound() {
        when(eventRepository.findById(999L)).thenReturn(Optional.empty());
        assertThrows(ResourceNotFoundException.class, () -> eventService.delete(999L));
    }
}