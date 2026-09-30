package com.vibemynight.backend.service.impl;

import com.vibemynight.backend.config.CacheConfig;
import com.vibemynight.backend.controller.PaymentController;
import com.vibemynight.backend.dto.ApiResponse;
import com.vibemynight.backend.dto.InitiateUpiPaymentRequest;
import com.vibemynight.backend.dto.InitiateUpiPaymentResponse;
import com.vibemynight.backend.entity.Event;
import com.vibemynight.backend.entity.EventDay;
import com.vibemynight.backend.entity.Settings;
import com.vibemynight.backend.entity.TicketCategory;
import com.vibemynight.backend.exception.BadRequestException;
import com.vibemynight.backend.repository.EventDayRepository;
import com.vibemynight.backend.repository.EventRepository;
import com.vibemynight.backend.repository.SettingsRepository;
import com.vibemynight.backend.repository.TicketCategoryRepository;
import com.vibemynight.backend.service.SettingsService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.junit.jupiter.SpringJUnitConfig;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@SpringJUnitConfig(SettingsServiceTest.TestConfig.class)
class SettingsServiceTest {

    @Configuration
    @Import(CacheConfig.class)
    static class TestConfig {
        @Bean
        public SettingsRepository settingsRepository() {
            return mock(SettingsRepository.class);
        }

        @Bean
        public EventRepository eventRepository() {
            return mock(EventRepository.class);
        }

        @Bean
        public EventDayRepository eventDayRepository() {
            return mock(EventDayRepository.class);
        }

        @Bean
        public TicketCategoryRepository ticketCategoryRepository() {
            return mock(TicketCategoryRepository.class);
        }

        @Bean
        public SettingsService settingsService(SettingsRepository settingsRepository) {
            return new SettingsServiceImpl(settingsRepository);
        }
    }

    @Autowired
    private SettingsRepository settingsRepository;

    @Autowired
    private EventRepository eventRepository;

    @Autowired
    private EventDayRepository eventDayRepository;

    @Autowired
    private TicketCategoryRepository ticketCategoryRepository;

    @Autowired
    private SettingsService settingsService;

    @Autowired
    private CacheManager cacheManager;

    @BeforeEach
    void setUp() {
        reset(settingsRepository, eventRepository, eventDayRepository, ticketCategoryRepository);
        Cache settingsCache = cacheManager.getCache("settings");
        if (settingsCache != null) {
            settingsCache.clear();
        }
    }

    @Test
    void testUpdateSettings_persistsUpiFieldsCorrectly() {
        Settings existing = Settings.builder()
                .websiteName("VibeMyNight")
                .whatsappNumber("917041615131")
                .currency("INR")
                .upiEnabled(false)
                .upiVpa(null)
                .upiMerchantName(null)
                .build();
        existing.setId(1L);

        when(settingsRepository.findAll()).thenReturn(List.of(existing));
        when(settingsRepository.save(any(Settings.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Settings updatePayload = Settings.builder()
                .websiteName("VibeMyNight Club")
                .whatsappNumber("917041615131")
                .currency("INR")
                .upiEnabled(true)
                .upiVpa("testmerchant@upi")
                .upiMerchantName("VibeMyNight Test Merchant")
                .build();

        Settings saved = settingsService.updateSettings(updatePayload);

        assertNotNull(saved);
        assertEquals("VibeMyNight Club", saved.getWebsiteName());
        assertTrue(saved.getUpiEnabled());
        assertEquals("testmerchant@upi", saved.getUpiVpa());
        assertEquals("VibeMyNight Test Merchant", saved.getUpiMerchantName());

        ArgumentCaptor<Settings> captor = ArgumentCaptor.forClass(Settings.class);
        verify(settingsRepository).save(captor.capture());
        Settings captured = captor.getValue();
        assertTrue(captured.getUpiEnabled());
        assertEquals("testmerchant@upi", captured.getUpiVpa());
        assertEquals("VibeMyNight Test Merchant", captured.getUpiMerchantName());
    }

    @Test
    void testUpdateSettings_disablingUpi_persistsFalseState() {
        Settings existing = Settings.builder()
                .websiteName("VibeMyNight")
                .whatsappNumber("917041615131")
                .currency("INR")
                .upiEnabled(true)
                .upiVpa("testmerchant@upi")
                .upiMerchantName("VibeMyNight Test Merchant")
                .build();
        existing.setId(1L);

        when(settingsRepository.findAll()).thenReturn(List.of(existing));
        when(settingsRepository.save(any(Settings.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Settings updatePayload = Settings.builder()
                .websiteName("VibeMyNight")
                .whatsappNumber("917041615131")
                .currency("INR")
                .upiEnabled(false)
                .upiVpa(null)
                .upiMerchantName(null)
                .build();

        Settings saved = settingsService.updateSettings(updatePayload);

        assertNotNull(saved);
        assertFalse(saved.getUpiEnabled());
        assertNull(saved.getUpiVpa());
    }

    @Test
    void testPaymentController_rejectsWhenUpiDisabled() {
        Settings disabledSettings = Settings.builder()
                .websiteName("VibeMyNight")
                .whatsappNumber("917041615131")
                .currency("INR")
                .upiEnabled(false)
                .build();

        when(settingsRepository.findAll()).thenReturn(List.of(disabledSettings));

        PaymentController controller = new PaymentController(
                settingsService, eventRepository, eventDayRepository, ticketCategoryRepository
        );

        InitiateUpiPaymentRequest request = new InitiateUpiPaymentRequest();
        request.setEventId(10L);
        request.setEventDayId(100L);
        request.setSelectedQuantities(Map.of(1000L, 2));
        request.setCustomerName("Test User");
        request.setCustomerMobile("9876543210");

        BadRequestException ex = assertThrows(BadRequestException.class, () -> controller.initiateUpiPayment(request));
        assertTrue(ex.getMessage().contains("Online UPI Payment is currently disabled"));
    }

    @Test
    void testPaymentController_rejectsWhenUpiVpaMissing() {
        Settings noVpaSettings = Settings.builder()
                .websiteName("VibeMyNight")
                .whatsappNumber("917041615131")
                .currency("INR")
                .upiEnabled(true)
                .upiVpa("   ")
                .build();

        when(settingsRepository.findAll()).thenReturn(List.of(noVpaSettings));

        PaymentController controller = new PaymentController(
                settingsService, eventRepository, eventDayRepository, ticketCategoryRepository
        );

        InitiateUpiPaymentRequest request = new InitiateUpiPaymentRequest();
        request.setEventId(10L);
        request.setEventDayId(100L);
        request.setSelectedQuantities(Map.of(1000L, 2));
        request.setCustomerName("Test User");
        request.setCustomerMobile("9876543210");

        BadRequestException ex = assertThrows(BadRequestException.class, () -> controller.initiateUpiPayment(request));
        assertTrue(ex.getMessage().contains("Merchant UPI VPA is not configured"));
    }

    @Test
    void testPaymentController_calculatesAmountAndBuildsUpiUrlSuccessfully() {
        Settings validSettings = Settings.builder()
                .websiteName("VibeMyNight")
                .whatsappNumber("917041615131")
                .currency("INR")
                .upiEnabled(true)
                .upiVpa("testmerchant@upi")
                .upiMerchantName("VibeMyNight Test Merchant")
                .build();

        when(settingsRepository.findAll()).thenReturn(List.of(validSettings));

        Event event = Event.builder()
                .name("Sunburn Arena 2026")
                .slug("sunburn-arena-2026")
                .build();
        event.setId(10L);

        EventDay day = EventDay.builder()
                .event(event)
                .dayNumber(1)
                .build();
        day.setId(100L);

        TicketCategory pass = TicketCategory.builder()
                .eventDay(day)
                .name("VIP Pass")
                .price(new BigDecimal("1500.00"))
                .build();
        pass.setId(1000L);

        when(eventRepository.findById(10L)).thenReturn(Optional.of(event));
        when(eventDayRepository.findById(100L)).thenReturn(Optional.of(day));
        when(ticketCategoryRepository.findById(1000L)).thenReturn(Optional.of(pass));

        PaymentController controller = new PaymentController(
                settingsService, eventRepository, eventDayRepository, ticketCategoryRepository
        );

        InitiateUpiPaymentRequest request = new InitiateUpiPaymentRequest();
        request.setEventId(10L);
        request.setEventDayId(100L);
        request.setSelectedQuantities(Map.of(1000L, 3));
        request.setCustomerName("Aman Sharma");
        request.setCustomerMobile("9876543210");

        ApiResponse<InitiateUpiPaymentResponse> response = controller.initiateUpiPayment(request);

        assertNotNull(response);
        assertTrue(response.isSuccess());
        InitiateUpiPaymentResponse data = response.getData();
        assertNotNull(data);
        assertEquals(new BigDecimal("4500.00"), data.getTotalAmount());
        assertEquals("testmerchant@upi", data.getUpiVpa());
        assertEquals("VibeMyNight Test Merchant", data.getMerchantName());
        assertEquals("INITIATED", data.getStatus());
        assertTrue(data.getUpiUrl().startsWith("upi://pay?pa=testmerchant@upi"));
        assertTrue(data.getUpiUrl().contains("am=4500.00"));
        assertTrue(data.getTransactionReference().startsWith("VMN-"));
    }
}
