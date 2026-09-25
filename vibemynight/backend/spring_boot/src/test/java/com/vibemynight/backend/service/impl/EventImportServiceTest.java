package com.vibemynight.backend.service.impl;

import com.vibemynight.backend.dto.EventDetailDto;
import com.vibemynight.backend.dto.importing.EventHeaderImportDto;
import com.vibemynight.backend.dto.importing.EventImportPreviewDto;
import com.vibemynight.backend.entity.Event;
import com.vibemynight.backend.exception.BadRequestException;
import com.vibemynight.backend.mapper.EventMapper;
import com.vibemynight.backend.repository.*;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;

import java.io.ByteArrayInputStream;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class EventImportServiceTest {

    @Mock
    private EventRepository eventRepository;
    @Mock
    private EventDayRepository eventDayRepository;
    @Mock
    private TicketCategoryRepository ticketCategoryRepository;
    @Mock
    private ArtistRepository artistRepository;
    @Mock
    private EventDayArtistRepository eventDayArtistRepository;
    @Mock
    private FacilityRepository facilityRepository;
    @Mock
    private EventFacilityRepository eventFacilityRepository;
    @Mock
    private EventDayFacilityRepository eventDayFacilityRepository;
    @Mock
    private EventHighlightRepository eventHighlightRepository;
    @Mock
    private EventRuleRepository eventRuleRepository;
    @Mock
    private EventGalleryRepository eventGalleryRepository;
    @Mock
    private EventMapper eventMapper;

    private EventImportServiceImpl importService;

    @BeforeEach
    void setUp() {
        importService = new EventImportServiceImpl(
                eventRepository,
                eventDayRepository,
                ticketCategoryRepository,
                artistRepository,
                eventDayArtistRepository,
                facilityRepository,
                eventFacilityRepository,
                eventDayFacilityRepository,
                eventHighlightRepository,
                eventRuleRepository,
                eventGalleryRepository,
                eventMapper
        );
    }

    @Test
    void testGenerateExcelTemplate() throws Exception {
        byte[] templateBytes = importService.generateExcelTemplate();
        assertNotNull(templateBytes);
        assertTrue(templateBytes.length > 0);

        try (Workbook wb = WorkbookFactory.create(new ByteArrayInputStream(templateBytes))) {
            assertEquals(6, wb.getNumberOfSheets());
            assertNotNull(wb.getSheet("EVENT"));
            assertNotNull(wb.getSheet("DAYS"));
            assertNotNull(wb.getSheet("PASSES"));
            assertNotNull(wb.getSheet("ARTISTS"));
            assertNotNull(wb.getSheet("FACILITIES"));
            assertNotNull(wb.getSheet("HIGHLIGHTS_AND_RULES"));
        }
    }

    @Test
    void testParseAndValidateGeneratedTemplate() {
        byte[] templateBytes = importService.generateExcelTemplate();
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "template.xlsx",
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                templateBytes
        );

        when(eventRepository.existsBySlug(anyString())).thenReturn(false);

        EventImportPreviewDto preview = importService.parseAndValidate(file);
        assertNotNull(preview);
        assertNotNull(preview.getEvent());
        assertEquals("Navratri Grand Mahotsav 2026", preview.getEvent().getName());
        assertEquals(3, preview.getTotalDays());
        assertTrue(preview.getTotalPasses() >= 3);
        assertTrue(preview.getTotalArtists() >= 3);
        assertFalse(preview.isHasBlockingErrors());
    }

    @Test
    void testParseEmptyFileThrowsException() {
        MockMultipartFile emptyFile = new MockMultipartFile("file", "empty.xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", new byte[0]);
        assertThrows(BadRequestException.class, () -> importService.parseAndValidate(emptyFile));
    }

    @Test
    void testConfirmAndCreateWithBlockingErrorsThrows() {
        EventImportPreviewDto invalidPreview = EventImportPreviewDto.builder()
                .event(EventHeaderImportDto.builder().name("Test").build())
                .hasBlockingErrors(true)
                .build();

        assertThrows(BadRequestException.class, () -> importService.confirmAndCreate(invalidPreview));
    }

    @Test
    void testConfirmAndCreatePreservesLocalUploadImages() {
        EventHeaderImportDto header = EventHeaderImportDto.builder()
                .name("Test Fest 2026")
                .slug("test-fest-2026")
                .city("Ahmedabad")
                .venue("Test Venue")
                .startDate(java.time.LocalDate.now())
                .endDate(java.time.LocalDate.now().plusDays(1))
                .mainImage("/uploads/events/local-poster.webp")
                .banner("/uploads/events/local-banner.webp")
                .thumbnail("/uploads/events/local-poster.webp")
                .build();

        com.vibemynight.backend.dto.importing.ScrapedImageCandidateDto candidate1 = com.vibemynight.backend.dto.importing.ScrapedImageCandidateDto.builder()
                .url("https://cdn.showmates.in/static/images/poster.webp")
                .localUrl("/uploads/events/local-poster.webp")
                .suggestedRole("POSTER_3_4")
                .build();

        EventImportPreviewDto preview = EventImportPreviewDto.builder()
                .event(header)
                .days(java.util.List.of())
                .eventFacilities(java.util.List.of())
                .highlights(java.util.List.of())
                .rules(java.util.List.of())
                .artworkCandidates(java.util.List.of(candidate1))
                .hasBlockingErrors(false)
                .build();

        when(eventRepository.existsBySlug(anyString())).thenReturn(false);
        when(eventRepository.save(org.mockito.ArgumentMatchers.any(Event.class))).thenAnswer(invocation -> {
            Event saved = invocation.getArgument(0);
            saved.setId(1L);
            return saved;
        });
        when(eventMapper.toDetailDto(org.mockito.ArgumentMatchers.any(Event.class), org.mockito.ArgumentMatchers.anyList()))
                .thenReturn(new EventDetailDto());

        EventDetailDto result = importService.confirmAndCreate(preview);
        assertNotNull(result);

        org.mockito.ArgumentCaptor<Event> eventCaptor = org.mockito.ArgumentCaptor.forClass(Event.class);
        org.mockito.Mockito.verify(eventRepository).save(eventCaptor.capture());
        Event captured = eventCaptor.getValue();
        assertEquals("/uploads/events/local-poster.webp", captured.getMainImage());
        assertEquals("/uploads/events/local-banner.webp", captured.getBanner());
    }
}