package com.vibemynight.backend.service.impl;

import com.vibemynight.backend.entity.EventDay;
import com.vibemynight.backend.exception.ConflictException;
import com.vibemynight.backend.exception.ResourceNotFoundException;
import com.vibemynight.backend.repository.EventDayFacilityRepository;
import com.vibemynight.backend.repository.EventDayRepository;
import com.vibemynight.backend.repository.EventRepository;
import com.vibemynight.backend.repository.InquiryRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class EventDayServiceTest {

    @Mock
    private EventDayRepository eventDayRepository;
    @Mock
    private EventRepository eventRepository;
    @Mock
    private EventDayFacilityRepository eventDayFacilityRepository;
    @Mock
    private InquiryRepository inquiryRepository;

    private EventDayServiceImpl eventDayService;

    @BeforeEach
    void setUp() {
        eventDayService = new EventDayServiceImpl(
                eventDayRepository,
                eventRepository,
                eventDayFacilityRepository,
                inquiryRepository
        );
    }

    @Test
    void testDeleteEventDaySuccess_CleansUpDayFacilities() {
        Long dayId = 201L;
        EventDay day = EventDay.builder().dayNumber(1).build();
        day.setId(dayId);

        when(eventDayRepository.findById(dayId)).thenReturn(Optional.of(day));
        when(inquiryRepository.existsByEventDayId(dayId)).thenReturn(false);

        assertDoesNotThrow(() -> eventDayService.delete(dayId));

        verify(eventDayFacilityRepository, times(1)).deleteByEventDayId(dayId);
        verify(eventDayRepository, times(1)).delete(day);
    }

    @Test
    void testDeleteEventDay_ThrowsConflictWhenInquiriesExist() {
        Long dayId = 201L;
        EventDay day = EventDay.builder().dayNumber(1).build();
        day.setId(dayId);

        when(eventDayRepository.findById(dayId)).thenReturn(Optional.of(day));
        when(inquiryRepository.existsByEventDayId(dayId)).thenReturn(true);

        ConflictException ex = assertThrows(ConflictException.class, () -> eventDayService.delete(dayId));
        assertTrue(ex.getMessage().contains("customer inquiries"));

        verify(eventDayRepository, never()).delete(any(EventDay.class));
        verify(eventDayFacilityRepository, never()).deleteByEventDayId(anyLong());
    }

    @Test
    void testDeleteNonExistentEventDayThrowsNotFound() {
        when(eventDayRepository.findById(999L)).thenReturn(Optional.empty());
        assertThrows(ResourceNotFoundException.class, () -> eventDayService.delete(999L));
    }
}
