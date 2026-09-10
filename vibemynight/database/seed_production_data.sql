-- Clean up previous test seed data if needed (keeping schema intact)
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE inquiries;
TRUNCATE TABLE ticket_category_benefits;
TRUNCATE TABLE ticket_categories;
TRUNCATE TABLE event_day_artists;
TRUNCATE TABLE event_day_facilities;
TRUNCATE TABLE event_days;
TRUNCATE TABLE event_highlights;
TRUNCATE TABLE event_rules;
TRUNCATE TABLE event_facilities;
TRUNCATE TABLE event_gallery;
TRUNCATE TABLE events;
TRUNCATE TABLE artists;
TRUNCATE TABLE facilities;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Insert Facilities
INSERT INTO facilities (id, created_at, updated_at, name, icon, description, status) VALUES
(1, NOW(), NOW(), 'VIP Air-Conditioned Lounge', 'chair', 'Dedicated air-conditioned luxury seating lounge with refreshments and exclusive stage view.', 'ACTIVE'),
(2, NOW(), NOW(), 'Valet & Dedicated Parking', 'local_parking', 'Spacious and secured parking zone with professional valet assistance for hassle-free entry.', 'ACTIVE'),
(3, NOW(), NOW(), 'Gourmet Food & Beverages Court', 'restaurant', 'Multi-cuisine vegetarian food stalls, live mocktail counters, and traditional Gujarati snacks.', 'ACTIVE'),
(4, NOW(), NOW(), '24/7 Medical & First Aid Station', 'medical_services', 'On-site paramedical team and fully equipped emergency ambulance standby.', 'ACTIVE'),
(5, NOW(), NOW(), 'High-Tech Security & CCTV', 'security', '3-tier security checking, metal detectors, and 360-degree round-the-clock CCTV surveillance.', 'ACTIVE'),
(6, NOW(), NOW(), 'Dandiya Sticks & Costume Booth', 'sports_kabaddi', 'Complimentary wooden dandiya sticks and instant costume touch-up stalls.', 'ACTIVE'),
(7, NOW(), NOW(), '360 Selfie & Photo Experience Zone', 'camera_alt', 'Interactive photo booths with neon aesthetic backdrops and instant digital printouts.', 'ACTIVE');

-- 2. Insert Artists
INSERT INTO artists (id, created_at, updated_at, name, slug, type, photo_url, short_bio, full_bio, instagram_url, youtube_url, facebook_url, featured, status) VALUES
(1, NOW(), NOW(), 'Atul Purohit', 'atul-purohit', 'SINGER', 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=800&auto=format&fit=crop&q=80', 'The iconic classical Garba maestro of Gujarat with over 3 decades of soulful music.', 'Shri Atul Purohit is a world-renowned devotional and Garba vocalist whose voice has defined Gujarat Navratri celebrations for over 30 years. Millions gather to sway to his traditional divine renditions.', 'https://instagram.com/atulpurohit_official', 'https://youtube.com', 'https://facebook.com', 1, 'ACTIVE'),
(2, NOW(), NOW(), 'Kirtidan Gadhvi', 'kirtidan-gadhvi', 'SINGER', 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800&auto=format&fit=crop&q=80', 'The versatile Folk and Dayro King known for thunderous energy and classical fusion.', 'Kirtidan Gadhvi is an Indian folk and Sufi singer celebrated globally for his vibrant Dayro, dynamic Garba, and folk-rock performances that electrify arenas worldwide.', 'https://instagram.com/kirtidangadhviofficial', 'https://youtube.com', 'https://facebook.com', 1, 'ACTIVE'),
(3, NOW(), NOW(), 'DJ Chetas', 'dj-chetas', 'DJ', 'https://images.unsplash.com/photo-1571266028243-3716f02d2d2e?w=800&auto=format&fit=crop&q=80', 'India #1 Bollywood DJ & Music Producer producing chart-topping arena mashups.', 'DJ Chetas is India most famous electronic music artist ranked in the world Top 100 DJs by DJ Mag, known for his high-energy Bollywood mashups and massive stadium live shows.', 'https://instagram.com/djchetas', 'https://youtube.com', 'https://facebook.com', 1, 'ACTIVE'),
(4, NOW(), NOW(), 'Kinjal Dave', 'kinjal-dave', 'SINGER', 'https://images.unsplash.com/photo-1520523839898-507128080356?w=800&auto=format&fit=crop&q=80', 'The young sensation of modern Gujarati folk-pop and non-stop raas garba.', 'Kinjal Dave is a sensational youth icon whose viral folk songs and high-tempo Dandiya rhythms have won millions of fans across the globe.', 'https://instagram.com/thekinjaldave', 'https://youtube.com', 'https://facebook.com', 1, 'ACTIVE'),
(5, NOW(), NOW(), 'Lost Stories', 'lost-stories', 'BAND', 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=800&auto=format&fit=crop&q=80', 'Critically acclaimed Indian EDM and acoustic fusion pioneer duo.', 'Lost Stories (Prayag Mehta & Rishab Joshi) are pioneers of Indian electronic dance music with performances at Tomorrowland, Mysteryland, and global concert tours.', 'https://instagram.com/loststoriesmusic', 'https://youtube.com', 'https://facebook.com', 0, 'ACTIVE');

-- 3. Insert Events
INSERT INTO events (id, created_at, updated_at, name, slug, description, main_image, thumbnail, banner, city, venue, address, location, google_maps_url, contact_number, email, organizer, start_date, end_date, featured, status) VALUES
(1, NOW(), NOW(), 
'United Way Grand Navratri Mahotsav 2026', 
'united-way-grand-navratri-2026',
'Experience the divine grandeur of world-famous Navratri with legendary vocalist Shri Atul Purohit. Over 50,000 players gather every evening under mesmerizing stage lighting, traditional beats, and sacred spiritual energy. Premium facilities, VIP fast-track access, and full security assure a majestic family celebration.',
'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=1200&auto=format&fit=crop&q=80',
'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400&auto=format&fit=crop&q=80',
'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=1600&auto=format&fit=crop&q=80',
'Vadodara', 'Navlakhi Palace Ground', 'Rajmahal Road, Navlakhi Compound, Vadodara, Gujarat 390001', 'Vadodara City Center',
'https://maps.google.com/?q=Navlakhi+Ground+Vadodara', '+91 98765 43210', 'info@unitedwaynavratri.org', 'United Way Heritage Trust',
'2026-10-10', '2026-10-18', 1, 'PUBLISHED'),

(2, NOW(), NOW(),
'Suvarna Navratri Utsav 2026 ft. Kirtidan Gadhvi',
'suvarna-navratri-utsav-2026',
'Surat biggest and most luxurious Navratri extravaganza featuring the Folk King Kirtidan Gadhvi! Enjoy pristine wooden dance flooring, dynamic 4K LED concert visuals, laser spectacles, and royal hospitality with unmatched festive fervor.',
'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=1200&auto=format&fit=crop&q=80',
'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=400&auto=format&fit=crop&q=80',
'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=1600&auto=format&fit=crop&q=80',
'Surat', 'SIECC Dome Arena', 'Surat International Exhibition and Convention Centre, Sarsana, Surat, Gujarat 395007', 'Sarsana International Hub',
'https://maps.google.com/?q=SIECC+Surat', '+91 99887 76655', 'vip@suvarnanavratri.com', 'Suvarna Events & Entertainment',
'2026-10-10', '2026-10-18', 1, 'PUBLISHED'),

(3, NOW(), NOW(),
'Neon Bollywood EDM Arena ft. DJ Chetas',
'neon-bollywood-edm-arena-dj-chetas',
'Get ready for the ultimate Bollywood EDM concert spectacle with DJ Chetas! Featuring cutting-edge lasers, CO2 jets, confetti cannons, top-tier international acoustics, and a star-studded party vibe. Dress in neon glam and dance till midnight.',
'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1200&auto=format&fit=crop&q=80',
'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=400&auto=format&fit=crop&q=80',
'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1600&auto=format&fit=crop&q=80',
'Ahmedabad', 'Riverfront Open Ground Arena', 'Sabarmati Riverfront Promenade, West Bank, Ahmedabad, Gujarat 380009', 'Sabarmati Riverfront',
'https://maps.google.com/?q=Sabarmati+Riverfront+Ahmedabad', '+91 98250 12345', 'beats@bollynation.in', 'VibeNation Nightlife',
'2026-11-14', '2026-11-15', 1, 'PUBLISHED'),

(4, NOW(), NOW(),
'Raas Rang Dandiya Night with Kinjal Dave',
'raas-rang-dandiya-night-kinjal-dave',
'Dance to the electric beats of Kinjal Dave at Saurashtra premier Navratri celebration. Traditional attire mandatory, lush manicured grass grounds, ample seating, family-friendly security, and non-stop euphoric Garba till midnight.',
'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=1200&auto=format&fit=crop&q=80',
'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=400&auto=format&fit=crop&q=80',
'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=1600&auto=format&fit=crop&q=80',
'Rajkot', 'Race Course Grounds', 'Race Course Ring Road, Sadar, Rajkot, Gujarat 360001', 'Race Course Ring',
'https://maps.google.com/?q=Race+Course+Rajkot', '+91 97230 45678', 'contact@raasrang.com', 'Saurashtra Youth Cultural Forum',
'2026-10-12', '2026-10-16', 0, 'PUBLISHED');

-- 4. Insert Event Highlights
INSERT INTO event_highlights (created_at, updated_at, event_id, text, sort_order) VALUES
(NOW(), NOW(), 1, 'Live Vocal Performance by Classical Legend Shri Atul Purohit', 1),
(NOW(), NOW(), 1, 'Grand 50,000+ Dancers Authentic Circle Ground', 2),
(NOW(), NOW(), 1, 'High-fidelity Line Array Acoustics with Acoustic Tuning', 3),
(NOW(), NOW(), 1, 'Dedicated Luxury AC VIP Lounge and Valet Parking', 4),

(NOW(), NOW(), 2, 'High Energy Folk & Sufi Fusion with Kirtidan Gadhvi', 1),
(NOW(), NOW(), 2, 'Air-Cooled Giant Dome with Premium Wooden Floor', 2),
(NOW(), NOW(), 2, 'Multi-Cuisine Traditional & Modern Food Street', 3),
(NOW(), NOW(), 2, 'Celebrity Guest Appearances every single night', 4),

(NOW(), NOW(), 3, 'Massive 3-Hour Continuous DJ Set by DJ Chetas', 1),
(NOW(), NOW(), 3, 'Laser & SFX Fireworks Synchronized Visual Display', 2),
(NOW(), NOW(), 3, 'Exclusive VIP Table Service & Premium Refreshments', 3),

(NOW(), NOW(), 4, 'Chartbuster Garba Grooves by Kinjal Dave', 1),
(NOW(), NOW(), 4, 'Best Traditional Costume & Best Garba Dancer Daily Awards', 2),
(NOW(), NOW(), 4, 'Safe & Monitored Family Friendly Atmosphere', 3);

-- 5. Insert Event Rules
INSERT INTO event_rules (created_at, updated_at, event_id, text, sort_order) VALUES
(NOW(), NOW(), 1, 'Traditional Indian attire (Chaniya Choli / Kurta Dhoti) is mandatory for garba arena entry.', 1),
(NOW(), NOW(), 1, 'Physical or digital QR Pass must be presented at the gate with a valid photo ID.', 2),
(NOW(), NOW(), 1, 'Outside food, beverages, alcohol, and sharp objects are strictly prohibited.', 3),
(NOW(), NOW(), 1, 'Pass is non-transferable and non-refundable once verified.', 4),

(NOW(), NOW(), 2, 'Entry gates open strictly at 7:00 PM; performances start promptly at 8:30 PM.', 1),
(NOW(), NOW(), 2, 'Dandiya sticks made of metal are prohibited; wooden sticks are permitted and provided.', 2),
(NOW(), NOW(), 2, 'Security screening and metal detection checks are mandatory for all attendees.', 3),

(NOW(), NOW(), 3, 'Age limit 18+ only. Valid Government photo ID required at the gate.', 1),
(NOW(), NOW(), 3, 'Stag entry rules apply as per venue guidelines; re-entry is not permitted.', 2),

(NOW(), NOW(), 4, 'Family passes require at least one female attendee in the group.', 1),
(NOW(), NOW(), 4, 'Children under 5 years enjoy free entry with parent ticket holder.', 2);

-- 6. Insert Event Days (Multi-day schedules)
-- Event 1: United Way (Days 1 to 3)
INSERT INTO event_days (id, created_at, updated_at, event_id, day_number, day_name, program_name, date, start_time, end_time, venue, address, location, status) VALUES
(1, NOW(), NOW(), 1, 1, 'Day 1 - Grand Opening & Aarti', 'Pratham Raas Mahotsav', '2026-10-10', '19:30:00', '23:59:00', 'Navlakhi Palace Ground', 'Rajmahal Road, Vadodara', 'Vadodara Center', 'ACTIVE'),
(2, NOW(), NOW(), 1, 2, 'Day 2 - Royal Garba Night', 'Dwitiya Swar Sandhya', '2026-10-11', '19:30:00', '23:59:00', 'Navlakhi Palace Ground', 'Rajmahal Road, Vadodara', 'Vadodara Center', 'ACTIVE'),
(3, NOW(), NOW(), 1, 3, 'Day 3 - Divine Classical Night', 'Tritiya Bhakti Rang', '2026-10-12', '19:30:00', '23:59:00', 'Navlakhi Palace Ground', 'Rajmahal Road, Vadodara', 'Vadodara Center', 'ACTIVE'),

-- Event 2: Suvarna Navratri (Days 1 to 2)
(4, NOW(), NOW(), 2, 1, 'Day 1 - Surat Mega Inauguration', 'Shree Ganesha Vandana & Raas', '2026-10-10', '20:00:00', '00:30:00', 'SIECC Dome Arena', 'Sarsana, Surat', 'Sarsana Arena', 'ACTIVE'),
(5, NOW(), NOW(), 2, 2, 'Day 2 - Folk Fusion Extravaganza', 'Kirtidan Live Arena Night', '2026-10-11', '20:00:00', '00:30:00', 'SIECC Dome Arena', 'Sarsana, Surat', 'Sarsana Arena', 'ACTIVE'),

-- Event 3: Bollywood EDM (Day 1)
(6, NOW(), NOW(), 3, 1, 'Main Night - Mega Concert', 'DJ Chetas Live in Concert', '2026-11-14', '18:00:00', '23:30:00', 'Riverfront Open Ground', 'Sabarmati Promenade, Ahmedabad', 'Sabarmati Riverfront', 'ACTIVE'),

-- Event 4: Raas Rang (Day 1)
(7, NOW(), NOW(), 4, 1, 'Day 1 - Saurashtra Utsav', 'Kinjal Dave Live Dandiya', '2026-10-12', '19:30:00', '23:45:00', 'Race Course Grounds', 'Race Course Ring Road, Rajkot', 'Race Course', 'ACTIVE');

-- 7. Link Event Day Artists & Facilities
INSERT INTO event_day_artists (created_at, updated_at, event_day_id, artist_id, is_primary, performance_order) VALUES
(NOW(), NOW(), 1, 1, 1, 1),
(NOW(), NOW(), 2, 1, 1, 1),
(NOW(), NOW(), 3, 1, 1, 1),
(NOW(), NOW(), 4, 2, 1, 1),
(NOW(), NOW(), 5, 2, 1, 1),
(NOW(), NOW(), 6, 3, 1, 1),
(NOW(), NOW(), 6, 5, 0, 2),
(NOW(), NOW(), 7, 4, 1, 1);

INSERT INTO event_day_facilities (created_at, updated_at, event_day_id, facility_id) VALUES
(NOW(), NOW(), 1, 1), (NOW(), NOW(), 1, 2), (NOW(), NOW(), 1, 3), (NOW(), NOW(), 1, 4), (NOW(), NOW(), 1, 5), (NOW(), NOW(), 1, 6), (NOW(), NOW(), 1, 7),
(NOW(), NOW(), 2, 1), (NOW(), NOW(), 2, 2), (NOW(), NOW(), 2, 3), (NOW(), NOW(), 2, 4), (NOW(), NOW(), 2, 5), (NOW(), NOW(), 2, 6), (NOW(), NOW(), 2, 7),
(NOW(), NOW(), 3, 1), (NOW(), NOW(), 3, 2), (NOW(), NOW(), 3, 3), (NOW(), NOW(), 3, 4), (NOW(), NOW(), 3, 5), (NOW(), NOW(), 3, 6), (NOW(), NOW(), 3, 7),
(NOW(), NOW(), 4, 1), (NOW(), NOW(), 4, 2), (NOW(), NOW(), 4, 3), (NOW(), NOW(), 4, 5), (NOW(), NOW(), 4, 7),
(NOW(), NOW(), 5, 1), (NOW(), NOW(), 5, 2), (NOW(), NOW(), 5, 3), (NOW(), NOW(), 5, 5), (NOW(), NOW(), 5, 7),
(NOW(), NOW(), 6, 1), (NOW(), NOW(), 6, 2), (NOW(), NOW(), 6, 3), (NOW(), NOW(), 6, 5), (NOW(), NOW(), 6, 7),
(NOW(), NOW(), 7, 2), (NOW(), NOW(), 7, 3), (NOW(), NOW(), 7, 5), (NOW(), NOW(), 7, 6);

-- 8. Insert Ticket Categories & Passes
INSERT INTO ticket_categories (id, created_at, updated_at, event_day_id, name, type, price, available_quantity, max_per_customer, description, status) VALUES
-- Event 1 Day 1 Passes
(1, NOW(), NOW(), 1, 'Early Bird Single Pass', 'EARLY_BIRD', 499.00, 500, 4, 'Standard single-day entry pass to the arena with free dandiya sticks.', 'ACTIVE'),
(2, NOW(), NOW(), 1, 'Couple Delight Pass', 'COUPLE', 999.00, 350, 2, 'Entry for 1 male & 1 female couple with reserved express check-in counter.', 'ACTIVE'),
(3, NOW(), NOW(), 1, 'VIP Golden Lounge Pass', 'VIP', 2499.00, 100, 5, 'Elevated AC lounge access, front-row view, complimentary mocktails & snacks.', 'ACTIVE'),
(4, NOW(), NOW(), 1, 'Group Platinum (5 Pax)', 'GROUP', 3999.00, 50, 2, 'All-access pass for a group of 5 friends or family members with VIP parking.', 'ACTIVE'),

-- Event 1 Day 2 Passes
(5, NOW(), NOW(), 2, 'Regular Single Entry', 'REGULAR', 599.00, 600, 4, 'Single player standard entry pass for Day 2 celebrations.', 'ACTIVE'),
(6, NOW(), NOW(), 2, 'Couple Delight Pass', 'COUPLE', 1099.00, 300, 2, 'Express couple entry for Day 2.', 'ACTIVE'),
(7, NOW(), NOW(), 2, 'VIP Golden Lounge Pass', 'VIP', 2499.00, 100, 5, 'Full luxury VIP lounge access for Day 2.', 'ACTIVE'),

-- Event 2 Day 1 Passes (Suvarna ft. Kirtidan)
(8, NOW(), NOW(), 4, 'Early Bird Garba Pass', 'EARLY_BIRD', 699.00, 400, 4, 'Single entry to the air-cooled indoor dome arena.', 'ACTIVE'),
(9, NOW(), NOW(), 4, 'Couple Royal Entry', 'COUPLE', 1299.00, 250, 2, 'Couple access with fast-track RFID wristband.', 'ACTIVE'),
(10, NOW(), NOW(), 4, 'Royal VIP Stage Pass', 'VIP', 2999.00, 80, 4, 'Stage-side VIP arena, gourmet dinner buffet voucher included.', 'ACTIVE'),

-- Event 3 Day 1 Passes (DJ Chetas EDM)
(11, NOW(), NOW(), 6, 'General Access GA Pass', 'REGULAR', 799.00, 1000, 6, 'Standard ground entry to Bollywood EDM concert arena.', 'ACTIVE'),
(12, NOW(), NOW(), 6, 'VIP Front Stage Pit', 'VIP', 1999.00, 300, 4, 'Front-of-stage fan pit access with express bar queue.', 'ACTIVE'),
(13, NOW(), NOW(), 6, 'VVIP Table for 6', 'PREMIUM', 14999.00, 20, 1, 'Dedicated high table for 6 people with dedicated butler, unlimited mocktails & snacks.', 'ACTIVE'),

-- Event 4 Day 1 Passes (Kinjal Dave)
(14, NOW(), NOW(), 7, 'Single Player Pass', 'REGULAR', 450.00, 500, 5, 'Entry to main ground dandiya arena.', 'ACTIVE'),
(15, NOW(), NOW(), 7, 'Family Package (4 Pax)', 'GROUP', 1599.00, 150, 2, 'Entry package for family of 4 with free parking pass.', 'ACTIVE');

-- 9. Insert Ticket Category Benefits
INSERT INTO ticket_category_benefits (ticket_category_id, benefit) VALUES
(1, 'Single Arena Entry'),
(1, 'Complimentary Wooden Dandiya'),
(1, 'Access to Food Court'),

(2, 'Express Fast-Track Queue'),
(2, 'Couple Entry for 1 Male + 1 Female'),
(2, '2 Complimentary Beverage Vouchers'),

(3, 'Air-Conditioned VIP Golden Lounge'),
(3, 'Stage-Facing Elevated Deck'),
(3, 'Unlimited Premium Mocktails & Starters'),
(3, 'Complimentary Valet Parking Pass'),

(4, 'Entry for 5 Attendees'),
(4, 'Reserved Parking Bay'),
(4, 'Express Wristband Counter'),

(8, 'Access to Giant Air-Cooled Dome'),
(8, 'Complimentary Mineral Water'),

(9, 'RFID Smart Wristband Access'),
(9, '2 Mocktail Drink Coupons'),

(10, 'Stage-Side Royal Lounge Access'),
(10, 'Full Multi-Cuisine Gourmet Buffet Included'),
(10, 'Dedicated Valet & Escort Assistance'),

(11, 'General Concert Ground Access'),
(11, 'Full Audio-Visual Experience'),

(12, 'Front Stage Exclusive Pit Area'),
(12, 'Express Bar Counter Service'),
(12, 'Limited Edition Glow Bands'),

(13, 'Elevated Private High Table for 6'),
(13, 'Dedicated Butler & Beverage Service'),
(13, 'Exclusive Backstage Tour Chance'),
(13, '2 Dedicated VIP Car Parking Slots');

-- 10. Insert Realistic Inquiries for Admin CRM Testing
INSERT INTO inquiries (id, created_at, updated_at, inquiry_number, customer_name, customer_email, customer_mobile, customer_message, quantity, price, estimated_total, status, event_id, event_day_id, ticket_category_id, artist_id) VALUES
(1, NOW() - INTERVAL 2 HOUR, NOW() - INTERVAL 2 HOUR, 'INQ-2026-0001', 'Rahul Sharma', 'rahul.sharma@example.com', '9825123456', 'Looking for 4 VIP passes for Day 1 with valet parking assistance for family.', 4, 2499.00, 9996.00, 'NEW', 1, 1, 3, 1),
(2, NOW() - INTERVAL 5 HOUR, NOW() - INTERVAL 4 HOUR, 'INQ-2026-0002', 'Pooja Patel', 'pooja.patel@example.com', '9909012345', 'Need couple pass for Atul Purohit Garba Night. Please confirm WhatsApp booking.', 2, 999.00, 1998.00, 'CONTACTED', 1, 1, 2, 1),
(3, NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 12 HOUR, 'INQ-2026-0003', 'Aman Verma', 'aman.verma@example.com', '9712345678', 'Interested in VVIP Table of 6 for DJ Chetas Bollywood EDM Arena in Ahmedabad.', 1, 14999.00, 14999.00, 'CONFIRMED', 3, 6, 13, 3),
(4, NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 1 DAY, 'INQ-2026-0004', 'Dharmesh Mehta', 'dharmesh.m@example.com', '9898011223', 'Inquiry for Suvarna Navratri Kirtidan Gadhvi VIP Passes for group of 10.', 10, 2999.00, 29990.00, 'COMPLETED', 2, 4, 10, 2);
