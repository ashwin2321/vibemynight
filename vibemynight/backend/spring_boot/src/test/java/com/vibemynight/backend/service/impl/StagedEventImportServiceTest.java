package com.vibemynight.backend.service.impl;

import com.vibemynight.backend.dto.importing.StagedEventDto;
import com.vibemynight.backend.dto.importing.StagedEventImportRequest;
import com.vibemynight.backend.dto.importing.StagedEventImportResultItemDto;
import com.vibemynight.backend.dto.importing.StagedImportBatchResultDto;
import com.vibemynight.backend.entity.Event;
import com.vibemynight.backend.entity.EventStatus;
import com.vibemynight.backend.repository.EventRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class StagedEventImportServiceTest {

    @Mock
    private EventRepository eventRepository;

    private StagedEventImportServiceImpl importService;

    @BeforeEach
    void setUp() {
        importService = new StagedEventImportServiceImpl(eventRepository);
        ReflectionTestUtils.setField(importService, "stagingApiUrl", "http://localhost:8000");
    }

    @Test
    void importSingleStagedEvent_Success() {
        StagedEventDto dto = StagedEventDto.builder()
                .id(101)
                .title("Surat Raas Rang 2026")
                .enhanced_title("Surat Raas Rang Mahotsav 2026")
                .description("Celebration in Surat")
                .catchy_description("Join Surat's biggest Garba fest!")
                .event_start_date("2026-10-10")
                .event_end_date("2026-10-12")
                .venue_name("VR Ground")
                .venue_address("Dumas Road")
                .city("Surat")
                .min_ticket_price(499.0)
                .max_ticket_price(1499.0)
                .highlights(List.of("Massive Dome", "Top Artists"))
                .status("READY_TO_IMPORT")
                .build();

        when(eventRepository.findBySlug(any())).thenReturn(Optional.empty());
        when(eventRepository.save(any(Event.class))).thenAnswer(invocation -> {
            Event ev = invocation.getArgument(0);
            ev.setId(5001L);
            return ev;
        });

        StagedEventImportResultItemDto result = importService.importSingleStagedEvent(dto, "adminUser");

        assertNotNull(result);
        assertEquals("IMPORTED", result.getStatus());
        assertEquals(5001L, result.getProductionEventId());
        assertEquals("Surat Raas Rang Mahotsav 2026", result.getEventName());

        verify(eventRepository, times(1)).save(argThat(ev -> {
            assertEquals("Surat Raas Rang Mahotsav 2026", ev.getName());
            assertEquals(EventStatus.PUBLISHED, ev.getStatus());
            assertEquals(3, ev.getEventDays().size()); // 10, 11, 12 Oct = 3 days
            assertEquals(2, ev.getEventDays().get(0).getTicketCategories().size()); // General + VIP
            return true;
        }));
    }

    @Test
    void importSingleStagedEvent_SlugConflict_ProtectsExistingEvent() {
        StagedEventDto dto = StagedEventDto.builder()
                .id(102)
                .title("Existing Festival")
                .enhanced_title("Existing Festival")
                .event_start_date("2026-10-10")
                .event_end_date("2026-10-10")
                .status("READY_TO_IMPORT")
                .build();

        Event existingEvent = Event.builder()
                .name("Existing Festival")
                .slug("existing-festival")
                .build();
        existingEvent.setId(999L);

        when(eventRepository.findBySlug("existing-festival")).thenReturn(Optional.of(existingEvent));

        StagedEventImportResultItemDto result = importService.importSingleStagedEvent(dto, "adminUser");

        assertNotNull(result);
        assertEquals("CONFLICT", result.getStatus());
        assertEquals("EVENT_SLUG_ALREADY_EXISTS", result.getReason());
        assertEquals(999L, result.getProductionEventId());

        // Verify save was NEVER called, protecting existing database event
        verify(eventRepository, never()).save(any());
    }

    @Test
    void importSingleStagedEvent_DuplicateStaged_ReturnsRejected() {
        StagedEventDto dto = StagedEventDto.builder()
                .id(103)
                .title("Duplicate Staged Event")
                .status("DUPLICATE")
                .build();

        StagedEventImportResultItemDto result = importService.importSingleStagedEvent(dto, "adminUser");

        assertNotNull(result);
        assertEquals("REJECTED", result.getStatus());
        assertEquals("EVENT_FLAGGED_AS_DUPLICATE_IN_STAGING", result.getReason());
        verify(eventRepository, never()).save(any());
    }

    @Test
    void importSingleStagedEvent_AlreadyImported_ReturnsAlreadyImported() {
        StagedEventDto dto = StagedEventDto.builder()
                .id(104)
                .title("Previously Imported Event")
                .status("IMPORTED")
                .build();

        StagedEventImportResultItemDto result = importService.importSingleStagedEvent(dto, "adminUser");

        assertNotNull(result);
        assertEquals("ALREADY_IMPORTED", result.getStatus());
        verify(eventRepository, never()).save(any());
    }
}
