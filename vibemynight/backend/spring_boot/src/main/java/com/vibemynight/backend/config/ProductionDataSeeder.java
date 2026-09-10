package com.vibemynight.backend.config;

import com.vibemynight.backend.entity.*;
import com.vibemynight.backend.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

@Slf4j
@Component
@Order(2)
@RequiredArgsConstructor
public class ProductionDataSeeder implements CommandLineRunner {

    private final EventRepository eventRepository;
    private final ArtistRepository artistRepository;
    private final FacilityRepository facilityRepository;
    private final SettingsRepository settingsRepository;
    private final EventDayRepository eventDayRepository;
    private final EventDayArtistRepository eventDayArtistRepository;
    private final TicketCategoryRepository ticketCategoryRepository;
    private final EventHighlightRepository eventHighlightRepository;
    private final EventRuleRepository eventRuleRepository;

    @Override
    @Transactional
    public void run(String... args) {
        if (eventRepository.count() > 0) {
            log.info("Events already exist in database (count: {}). Skipping initial data seed.", eventRepository.count());
            return;
        }

        log.info("Seeding production and sample data for VibeMyNight...");

        // 1. Settings
        if (settingsRepository.count() == 0) {
            Settings settings = Settings.builder()
                    .whatsappNumber("917041615131")
                    .heroBannerUrl("https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=1600")
                    .announcementText("🔥 Navratri 2026 Passes Live! Flat 0% Booking Fee.")
                    .build();
            settingsRepository.save(settings);
        }

        // 2. Facilities
        Facility acDome = facilityRepository.save(Facility.builder().name("AC Dome (Air Conditioned)").icon("ac_unit").status(ActiveStatus.ACTIVE).build());
        Facility parking = facilityRepository.save(Facility.builder().name("Valet & Managed Parking").icon("local_parking").status(ActiveStatus.ACTIVE).build());
        Facility food = facilityRepository.save(Facility.builder().name("Food & Refreshments Court").icon("restaurant").status(ActiveStatus.ACTIVE).build());
        Facility vipLounge = facilityRepository.save(Facility.builder().name("VIP Luxury Lounge").icon("chair").status(ActiveStatus.ACTIVE).build());
        Facility security = facilityRepository.save(Facility.builder().name("3-Tier Security & CCTV").icon("security").status(ActiveStatus.ACTIVE).build());

        // 3. Artists
        Artist jigardan = artistRepository.save(Artist.builder()
                .name("Jigardan Gadhavi")
                .slug("jigardan-gadhavi")
                .type(ArtistType.SINGER)
                .photoUrl("https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=800")
                .shortBio("Gujarat sensation and iconic voice of modern Garba & Dayro fusion.")
                .fullBio("Jigardan Gadhavi (Jigrra) is one of the most celebrated youth icons of Gujarat, mesmerizing millions with high-energy Garba anthems.")
                .featured(true)
                .status(ActiveStatus.ACTIVE)
                .build());

        Artist atul = artistRepository.save(Artist.builder()
                .name("Atul Purohit")
                .slug("atul-purohit")
                .type(ArtistType.SINGER)
                .photoUrl("https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800")
                .shortBio("The classical Garba maestro of Gujarat with over 3 decades of soulful music.")
                .featured(true)
                .status(ActiveStatus.ACTIVE)
                .build());

        Artist kirtidan = artistRepository.save(Artist.builder()
                .name("Kirtidan Gadhvi")
                .slug("kirtidan-gadhvi")
                .type(ArtistType.SINGER)
                .photoUrl("https://images.unsplash.com/photo-1520523839898-507128080356?w=800")
                .shortBio("Folk & Dayro King celebrated globally for energetic Gujarati Raas Garba.")
                .featured(true)
                .status(ActiveStatus.ACTIVE)
                .build());

        Artist djChetas = artistRepository.save(Artist.builder()
                .name("DJ Chetas")
                .slug("dj-chetas")
                .type(ArtistType.DJ)
                .photoUrl("https://images.unsplash.com/photo-1571266028243-3716f02d2d2e?w=800")
                .shortBio("India #1 Bollywood DJ producing chart-topping arena mashups.")
                .featured(true)
                .status(ActiveStatus.ACTIVE)
                .build());

        // 4. EVENT 1: Sachi Navratri AC Dome Garba 2026
        Event sachiEvent = Event.builder()
                .name("SACHI NAVRATRI AC DOME GARBA 2026")
                .slug("sachi-navaratri-ac-dome-garaba-2026-buy-tickets")
                .mainImage("https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=1200")
                .thumbnail("https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400")
                .banner("https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=1600")
                .city("Ahmedabad")
                .venue("Sachi AC Dome Stadium Arena")
                .address("Near SG Highway, Bodakdev, Ahmedabad, Gujarat 380054")
                .location("SG Highway Hub")
                .googleMapsUrl("https://maps.google.com/?q=Bodakdev+Ahmedabad")
                .organizer("Sachi Entertainment & Cultural Trust")
                .contactNumber("+91 70416 15131")
                .email("passes@sachigarba.com")
                .startDate(LocalDate.of(2026, 10, 10))
                .endDate(LocalDate.of(2026, 10, 19))
                .description("Experience Gujarat's largest luxury AC Dome Garba featuring Jigardan Gadhavi and top folk artists. Fully air-conditioned 3D stadium layout with Fanpit, Diamond, and Gold standing & seating arenas. 0% convenience fees and instant WhatsApp delivery.")
                .featured(true)
                .status(EventStatus.PUBLISHED)
                .build();
        sachiEvent = eventRepository.save(sachiEvent);

        // Highlights for Sachi
        eventHighlightRepository.save(EventHighlight.builder().event(sachiEvent).text("Fully Air Conditioned 100,000+ sq.ft Giant Luxury AC Dome").sortOrder(1).build());
        eventHighlightRepository.save(EventHighlight.builder().event(sachiEvent).text("Live Musical Showdown by Jigardan Gadhavi (Jigrra)").sortOrder(2).build());
        eventHighlightRepository.save(EventHighlight.builder().event(sachiEvent).text("3D Arena Layout with Fanpit, Diamond & Gold Seating Wings").sortOrder(3).build());
        eventHighlightRepository.save(EventHighlight.builder().event(sachiEvent).text("Valet Parking, Food Boulevard & 100% Genuine QR Passes").sortOrder(4).build());

        // Rules for Sachi
        eventRuleRepository.save(EventRule.builder().event(sachiEvent).text("Traditional Garba attire (Chaniya Choli / Kurta Dhoti) is recommended.").sortOrder(1).build());
        eventRuleRepository.save(EventRule.builder().event(sachiEvent).text("Digital QR Pass or physical wristband required for gate check-in.").sortOrder(2).build());
        eventRuleRepository.save(EventRule.builder().event(sachiEvent).text("Outside food, alcohol, and sharp items are strictly prohibited.").sortOrder(3).build());

        // Event Days for Sachi Event (10 Days of Navratri)
        for (int i = 1; i <= 9; i++) {
            LocalDate dayDate = LocalDate.of(2026, 10, 9 + i);
            EventDay day = eventDayRepository.save(EventDay.builder()
                    .event(sachiEvent)
                    .dayNumber(i)
                    .dayName("Day " + i + " - Grand Raas Night")
                    .programName(i == 1 ? "Inaugural Night ft. Jigardan Gadhavi" : "Night " + i + " Mega Garba")
                    .date(dayDate)
                    .startTime(LocalTime.of(19, 30))
                    .endTime(LocalTime.of(23, 59))
                    .venue("Sachi AC Dome Stadium Arena")
                    .address("Near SG Highway, Bodakdev, Ahmedabad")
                    .location("Ahmedabad")
                    .status(ActiveStatus.ACTIVE)
                    .build());

            // Link Headliner
            eventDayArtistRepository.save(EventDayArtist.builder()
                    .eventDay(day)
                    .artist(jigardan)
                    .isPrimary(true)
                    .performanceOrder(1)
                    .build());

            // Add Passes with exact names, tiers, and prices
            ticketCategoryRepository.save(TicketCategory.builder()
                    .eventDay(day)
                    .name("FANPIT - STAGE FRONT PASS")
                    .type(TicketType.EARLY_BIRD)
                    .price(new BigDecimal("2499.00"))
                    .availableQuantity(150)
                    .maxPerCustomer(4)
                    .description("Exclusive front-of-stage standing pit with express check-in.")
                    .benefits(List.of("Front Stage Access", "Express Entry Queue", "Free Dandiya Sticks"))
                    .status(ActiveStatus.ACTIVE)
                    .build());

            ticketCategoryRepository.save(TicketCategory.builder()
                    .eventDay(day)
                    .name("DIAMOND ARENA PASS")
                    .type(TicketType.VIP)
                    .price(new BigDecimal("1599.00"))
                    .availableQuantity(400)
                    .maxPerCustomer(6)
                    .description("Center standing arena with elevated side seating wings.")
                    .benefits(List.of("Center Arena View", "Side Seating Wing Access", "Food Coupon Included"))
                    .status(ActiveStatus.ACTIVE)
                    .build());

            ticketCategoryRepository.save(TicketCategory.builder()
                    .eventDay(day)
                    .name("GOLD ARENA PASS")
                    .type(TicketType.REGULAR)
                    .price(new BigDecimal("450.00"))
                    .availableQuantity(800)
                    .maxPerCustomer(10)
                    .description("Grand standing arena with full dome sound & light experience.")
                    .benefits(List.of("Full AC Dome Entry", "Food Court Access", "Instant QR WhatsApp Pass"))
                    .status(ActiveStatus.ACTIVE)
                    .build());
        }

        // 5. EVENT 2: United Way Grand Navratri Mahotsav
        Event unitedWay = eventRepository.save(Event.builder()
                .name("United Way Grand Navratri Mahotsav 2026")
                .slug("united-way-grand-navratri-2026")
                .mainImage("https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=1200")
                .thumbnail("https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=400")
                .banner("https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=1600")
                .city("Vadodara")
                .venue("Navlakhi Palace Ground")
                .address("Rajmahal Road, Navlakhi Compound, Vadodara, Gujarat 390001")
                .location("Vadodara Center")
                .organizer("United Way Heritage Trust")
                .contactNumber("+91 98765 43210")
                .email("info@unitedwaynavratri.org")
                .startDate(LocalDate.of(2026, 10, 10))
                .endDate(LocalDate.of(2026, 10, 18))
                .description("Experience the divine grandeur of world-famous Navratri with legendary vocalist Shri Atul Purohit.")
                .featured(true)
                .status(EventStatus.PUBLISHED)
                .build());

        for (int i = 1; i <= 3; i++) {
            EventDay day = eventDayRepository.save(EventDay.builder()
                    .event(unitedWay)
                    .dayNumber(i)
                    .dayName("Day " + i + " - Swar Sandhya")
                    .date(LocalDate.of(2026, 10, 9 + i))
                    .startTime(LocalTime.of(19, 30))
                    .endTime(LocalTime.of(23, 59))
                    .venue("Navlakhi Palace Ground")
                    .address("Vadodara")
                    .status(ActiveStatus.ACTIVE)
                    .build());

            eventDayArtistRepository.save(EventDayArtist.builder()
                    .eventDay(day)
                    .artist(atul)
                    .isPrimary(true)
                    .performanceOrder(1)
                    .build());

            ticketCategoryRepository.save(TicketCategory.builder()
                    .eventDay(day)
                    .name("General Ground Pass")
                    .type(TicketType.REGULAR)
                    .price(new BigDecimal("499.00"))
                    .availableQuantity(500)
                    .status(ActiveStatus.ACTIVE)
                    .build());

            ticketCategoryRepository.save(TicketCategory.builder()
                    .eventDay(day)
                    .name("VIP Golden Lounge Pass")
                    .type(TicketType.VIP)
                    .price(new BigDecimal("2499.00"))
                    .availableQuantity(100)
                    .status(ActiveStatus.ACTIVE)
                    .build());
        }

        log.info("Production and sample data seeded successfully into database!");
    }
}
