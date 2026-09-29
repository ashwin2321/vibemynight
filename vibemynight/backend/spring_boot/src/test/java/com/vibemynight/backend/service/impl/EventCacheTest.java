package com.vibemynight.backend.service.impl;

import com.vibemynight.backend.config.CacheConfig;
import com.vibemynight.backend.entity.Event;
import com.vibemynight.backend.entity.EventStatus;
import com.vibemynight.backend.repository.EventDayFacilityRepository;
import com.vibemynight.backend.repository.EventFacilityRepository;
import com.vibemynight.backend.repository.EventRepository;
import com.vibemynight.backend.repository.InquiryRepository;
import com.vibemynight.backend.service.EventService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.junit.jupiter.SpringJUnitConfig;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@SpringJUnitConfig(EventCacheTest.TestConfig.class)
class EventCacheTest {

    @Configuration
    @Import(CacheConfig.class)
    static class TestConfig {
        @Bean
        public EventRepository eventRepository() {
            return mock(EventRepository.class);
        }

        @Bean
        public EventFacilityRepository eventFacilityRepository() {
            return mock(EventFacilityRepository.class);
        }

        @Bean
        public EventDayFacilityRepository eventDayFacilityRepository() {
            return mock(EventDayFacilityRepository.class);
        }

        @Bean
        public InquiryRepository inquiryRepository() {
            return mock(InquiryRepository.class);
        }

        @Bean
        public EventService eventService(
                EventRepository eventRepository,
                EventFacilityRepository eventFacilityRepository,
                EventDayFacilityRepository eventDayFacilityRepository,
                InquiryRepository inquiryRepository) {
            return new EventServiceImpl(
                    eventRepository,
                    eventFacilityRepository,
                    eventDayFacilityRepository,
                    inquiryRepository
            );
        }
    }

    @Autowired
    private EventService eventService;

    @Autowired
    private EventRepository eventRepository;

    @Autowired
    private CacheManager cacheManager;

    @BeforeEach
    void clearAllCaches() {
        reset(eventRepository);
        cacheManager.getCacheNames().forEach(name -> {
            Cache c = cacheManager.getCache(name);
            if (c != null) c.clear();
        });
    }

    @Test
    void testCachePopulation_AndHit_PreventsSubsequentRepositoryCalls() {
        Event event1 = Event.builder().name("Concert 1").slug("concert-1").status(EventStatus.PUBLISHED).build();
        event1.setId(1L);

        when(eventRepository.findByStatus(EventStatus.PUBLISHED)).thenReturn(List.of(event1));

        // 1. First Call: Populates cache (Repository MUST be called once)
        List<Event> firstCall = eventService.findPublished();
        assertEquals(1, firstCall.size());
        assertEquals("Concert 1", firstCall.get(0).getName());
        verify(eventRepository, times(1)).findByStatus(EventStatus.PUBLISHED);

        // 2. Second Call: Cache Hit (Repository MUST NOT be called again)
        List<Event> secondCall = eventService.findPublished();
        assertEquals(1, secondCall.size());
        assertEquals("Concert 1", secondCall.get(0).getName());
        verify(eventRepository, times(1)).findByStatus(EventStatus.PUBLISHED);
    }

    @Test
    void testCacheEviction_OnStatusChange_ForcesFreshDataFetch() {
        Event event1 = Event.builder().name("Concert 1").slug("concert-1").status(EventStatus.DRAFT).build();
        event1.setId(1L);

        when(eventRepository.findByStatus(EventStatus.PUBLISHED)).thenReturn(List.of(event1));
        when(eventRepository.findById(1L)).thenReturn(Optional.of(event1));
        when(eventRepository.save(any(Event.class))).thenAnswer(inv -> inv.getArgument(0));

        // Populate events cache
        eventService.findPublished();
        verify(eventRepository, times(1)).findByStatus(EventStatus.PUBLISHED);

        // Change status (evicts cache)
        eventService.changeStatus(1L, EventStatus.PUBLISHED);

        // Subsequent call must fetch fresh data from repository (Repository called a 2nd time)
        eventService.findPublished();
        verify(eventRepository, times(2)).findByStatus(EventStatus.PUBLISHED);
    }

    @Test
    void testUnrelatedCache_RemainsIntact_WhenEventsAreEvicted() {
        Cache artistsCache = cacheManager.getCache("artists");
        assertNotNull(artistsCache);
        artistsCache.put("all", "cached_artists_list");

        // Evict events by creating new event
        Event newEvent = Event.builder().name("New Event").slug("new-event").build();
        when(eventRepository.existsBySlug("new-event")).thenReturn(false);
        when(eventRepository.save(newEvent)).thenReturn(newEvent);

        eventService.create(newEvent);

        // Unrelated artists cache must still exist and have data
        assertNotNull(artistsCache.get("all"));
        assertEquals("cached_artists_list", artistsCache.get("all").get());
    }
}
