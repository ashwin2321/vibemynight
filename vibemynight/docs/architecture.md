# VibeMyNight — Architecture Notes (Phase 1-3 snapshot)

## Repository layout

```
/vibemynight
    /frontend/flutter_app      Flutter customer + admin app (Phase 7+)
    /backend/spring_boot       Spring Boot 3 / Java 21 backend  <- built in this phase
    /docs
    README.md
```

## Backend package structure (com.vibemynight.backend)

- `config`      — Spring config (JPA auditing, security placeholder)
- `controller`  — REST controllers (Phase 5+, not yet added)
- `dto`         — request/response payloads (ApiResponse envelope, CreateInquiryRequest, InquiryResponse)
- `entity`      — JPA entities (see Entities below)
- `repository`  — Spring Data JPA repositories
- `service` / `service.impl` — business logic
- `security`    — JWT filter/provider (Phase 4, not yet added)
- `exception`   — custom exceptions + @RestControllerAdvice global handler
- `mapper`      — entity<->DTO mappers (added alongside controllers in Phase 5)
- `specification` — JPA Specifications for admin search/filter (Phase 5)
- `util`        — shared helpers

## Entities implemented (Phase 3)

`User` (admin), `Event`, `EventDay`, `Artist`, `EventDayArtist` (join),
`TicketCategory` (+ `ticket_category_benefits` element collection),
`Facility`, `EventFacility`, `EventDayFacility`, `EventHighlight`, `EventRule`,
`EventGallery`, `Inquiry`, `Settings`.

Relationships match the spec exactly:
Event 1→N EventDay; EventDay N↔N Artist (via EventDayArtist, with isPrimary +
performanceOrder); EventDay 1→N TicketCategory; Event N↔N Facility and
EventDay N↔N Facility (two separate join tables); Event 1→N Gallery/Highlights/Rules/Inquiries.

`spring.jpa.hibernate.ddl-auto=update` is used for local dev so the schema is
generated from these entities automatically. Swap to `validate` once
`db/migration` SQL (Flyway/Liquibase) becomes the source of truth for a
non-dev environment.

## Business rules already enforced in the service layer

- `InquiryServiceImpl.createInquiry` re-fetches the `TicketCategory` from the
  DB with a pessimistic write lock, checks `ActiveStatus`, `maxPerCustomer`,
  and `availableQuantity`, computes `price × quantity` itself, decrements
  stock, and only then saves — the price/total sent from the client (if any)
  is never used.
- Inquiry numbers are sequential: `VMN-000001`, `VMN-000123`, ...
- `SettingsServiceImpl` seeds a single settings row from `WHATSAPP_NUMBER` env
  var on first read, so the frontend always fetches the WhatsApp number from
  `GET /api/v1/settings/public` rather than hardcoding it.

## Known gap / honesty note

This container has no internet access to Maven Central (only a small
allow-list of domains, which doesn't include `repo.maven.apache.org`), and
Maven itself isn't installed here. That means **this code has not been
compiled or run in this session** — it hasn't been verified end-to-end.
Please run `mvn clean compile` (or open in IntelliJ/VS Code) after copying
`.env.example` to `.env`/exporting the variables and pointing `DATABASE_URL`
at a real MySQL 8 instance. I've been careful with imports, annotations and
entity relationships, but a first local build may still surface a typo or
two — send me the stack trace and I'll fix it immediately.

## Auth (Phase 4)

- `security/JwtService` — issues/validates HS256 JWTs (email as subject, `userId` +
  `role` as claims). `app.jwt.secret` must be a real random 32+ byte value in any
  non-dev environment — the `application.yml` default is dev-only.
- `security/JwtAuthenticationFilter` — reads `Authorization: Bearer <token>`,
  loads the `User` by email, and populates the Spring Security context with a
  `ROLE_ADMIN` authority. No filter chain block on missing/invalid tokens —
  it just leaves the request unauthenticated and lets `authorizeHttpRequests`
  reject with 401/403.
- `security/JwtAuthenticationEntryPoint` — turns unauthenticated 401s into the
  same `ApiResponse` JSON envelope as everything else, instead of Spring's
  default HTML/plain-text 401.
- `config/AdminSeeder` — a `CommandLineRunner` that creates the first admin
  user from `ADMIN_SEED_EMAIL`/`ADMIN_SEED_PASSWORD` env vars the first time
  the app boots against an empty `users` table. Idempotent (no-ops once any
  user exists), so it's safe to leave in place rather than a one-off script.
- `SecurityConfig` — stateless sessions, CSRF disabled (pure JSON API), public
  `GET` on customer-facing read endpoints + public inquiry submission, and
  `hasRole("ADMIN")` on everything under `/api/v1/admin/**`.

## REST layer (Phase 5)

- `dto/` — one response DTO per shape the frontend actually needs
  (`EventSummaryDto` for cards, `EventDetailDto` for the event page,
  `EventDaySummaryDto` for the day-selector strip, `EventDayDetailDto` for
  the selected-day panel, `ArtistDto`, `FacilityDto`, `TicketCategoryDto`,
  `SettingsPublicDto`) plus one request DTO per admin write endpoint
  (`Create*Request`, `AssignArtistToDayRequest`, `UpdateInquiryStatusRequest`).
  Controllers never return JPA entities directly to the customer-facing
  endpoints — this avoids both Jackson infinite-recursion on the bidirectional
  `Event ↔ EventDay ↔ TicketCategory/EventDayArtist` relationships and
  leaking internal fields.
- `mapper/` — `EventMapper`, `EventDayMapper`, `ArtistMapper`,
  `FacilityMapper`, `TicketCategoryMapper` convert entities to DTOs. They
  walk lazy collections (`event.getEventDays()`, `day.getTicketCategories()`,
  etc.), which works because `spring.jpa.open-in-view` is at its Spring Boot
  default (`true`) — the Hibernate session stays open for the whole request,
  so mapping in the controller after the service call is safe. If you switch
  `open-in-view` to `false` later (recommended for production), move the
  mapping calls inside the `@Transactional` service methods instead.
- Multi-day pricing/availability: `EventDayMapper.toSummaryDto` computes each
  day's `startingPrice` as `min(ticketCategories.price)`, and
  `EventMapper.toSummaryDto` computes the event card's `startingPrice` as the
  min across *all* days — so a 9-day and a 1-day event both work with no
  special-casing, matching the "never assume N days" requirement.
- Event/day facility join management is exposed as simple
  `POST/DELETE /admin/events/{id}/facilities/{facilityId}` and the day
  equivalent, backed directly by `EventFacilityRepository` /
  `EventDayFacilityRepository` — no separate service class, since it's a
  pure join-table toggle.
- Not yet added: admin CRUD for gallery images / highlights / rules
  (entities + repos already exist from Phase 3, controllers still to come),
  and the inquiry endpoints (`POST /inquiries`, `/admin/inquiries*`) — both
  land in Phase 6 alongside the WhatsApp message builder.

## Inquiry + WhatsApp flow (Phase 6)

- `InquiryServiceImpl.createInquiry` unchanged from Phase 3 in its core
  guarantee (server re-verifies price/availability/`maxPerCustomer` under a
  pessimistic lock) — this phase adds the WhatsApp piece on top.
- `util/WhatsAppMessageBuilder` renders the exact message template from the
  spec (Inquiry ID, Name, Mobile, Event, Day, Date, Program, Artist, Time,
  Venue, Location, Pass, Price, Quantity, Estimated Total) and URL-encodes it
  into a ready `https://wa.me/<number>?text=...` link. Both the plain
  `whatsappMessage` and the finished `whatsappUrl` come back on every
  `InquiryResponse` — the Flutter app can just launch the URL rather than
  re-implementing the formatting, while still having the raw fields
  available if it wants to build its own UI first.
- `GET /api/v1/inquiries/{inquiryNumber}` is the public fallback the spec
  calls for: "if WhatsApp cannot open, show Inquiry ID + an OPEN WHATSAPP
  button" — the button just re-fetches this endpoint and opens
  `whatsappUrl` again.
- Admin inquiries list supports `search` (matches inquiry number, customer
  name, mobile, or event name) plus `status`/`eventId`/`artistId`/
  `ticketCategoryId`/`date` filters via `InquirySpecification`
  (`JpaSpecificationExecutor`), matching the spec's admin search/filter list.
- Gallery/highlights/rules admin CRUD landed here too (`EventContentController`)
  — simple, so no dedicated service class; it uses the repositories from
  Phase 3 directly plus `EventService.getById` for the parent lookup.

## Flutter scaffold (Phase 7)

See `frontend/flutter_app/README.md` for the full breakdown. Summary:

- `core/network/ApiClient` unwraps the backend's `{success, data, message,
  errors}` envelope into a single `ApiException` type, and attaches the
  admin JWT (from `flutter_secure_storage` via `TokenStorage`) to every
  request automatically — harmless no-op for public calls.
- `core/router/app_router.dart` wires every screen from the spec's Flutter
  Customer/Admin Screens lists to a route, with a redirect guard sending
  unauthenticated `/admin/**` requests to `/admin/login`.
- `models/` mirrors every Phase 5-6 DTO with plain Dart classes
  (`fromJson`/`toJson`, no codegen — see the honesty note in the Flutter
  README on why Freezed/json_serializable weren't used here).
- Home, Events, Event Details (multi-day selector), Event Day + passes,
  Inquiry form + submission, Inquiry success (WhatsApp launch), Admin Login,
  and the Admin Dashboard shell are wired to real backend calls already.
  Everything else under `admin/` is a routed `PlaceholderScreen` pending
  Phase 9's CRUD tables/forms.

## Flutter customer UI (Phase 8)

See `frontend/flutter_app/README.md` for the full breakdown. Summary:

- Home/Events/Event Details/Event Day/Artist Details all got their real
  visual pass on top of the Phase 7 data wiring — no provider/service/model
  changes, purely presentation.
- New shared widgets: `GradientButton`, `SectionHeading`, `FaqTile`,
  `StickyCtaBar`, `NetworkImageBox` (graceful broken/missing-image
  fallback), `FadeIn` (staggered entrance animation), plus `EventCard` and
  `ArtistCard` shared between Home and their respective listing screens
  (avoids duplicating the same card UI twice).
- `Hero` widgets carry the event/artist image from list card to detail
  screen for a smooth shared-element transition.
- Gallery lightbox is a `Dialog` + `PageView` + `InteractiveViewer` — tap a
  thumbnail, swipe between images, pinch to zoom.
- Events search/filter is intentionally client-side over the already-fetched
  published list (documented as a scope note in the Flutter README) since
  the Phase 5 endpoint has no query params yet.

## Flutter admin UI (Phase 9)

Full CRUD for every admin resource, all built on a shared `AdminShell`
(desktop sidebar / mobile drawer, per the spec's responsive requirement) and
one consolidated `AdminService` covering every `/api/v1/admin/**` route from
Phases 5-6 (kept as a single class rather than one per resource, since each
method is a thin uniform pass-through to `ApiClient` — see the class doc
comment in `services/admin_service.dart`):

- **Events** — table with publish/unpublish/complete/cancel actions, edit,
  delete, and a link into Manage Days. Create/Edit share one form.
- **Days** — per-event day list (add/edit/delete) with a note that an event
  can have any number of days — never assumed fixed. Manage Passes links off
  each day.
- **Passes** — per-day list with add/edit/delete; price/availability/type/
  benefits form matches the backend's `TicketCategory` fields exactly.
- **Artists** — searchable table, activate/deactivate, edit, delete;
  create/edit share one form with all bio/social fields.
- **Facilities** — simple enough to manage via an inline dialog rather than
  a separate route.
- **Inquiries** — search (inquiry number/customer/mobile/event) + status
  filter table backed by the Phase 6 `GET /admin/inquiries?search=&status=`
  endpoint, linking to...
- **Inquiry Details** — full record, CALL CUSTOMER (`tel:`) and OPEN
  WHATSAPP (the backend-built `whatsappUrl`) buttons, and status-change
  chips.
- **Dashboard** — stat cards (Total/Published Events, Total Artists, Total/
  New/Confirmed Inquiries, Total Requested Passes, Estimated Inquiry Value)
  computed client-side from the existing list endpoints, since there's no
  dedicated aggregate endpoint yet — documented as worth promoting to a real
  backend endpoint if these lists grow large enough that fetching everything
  just to count it gets expensive. No fake charts; just what the real data
  supports right now.
- **Settings** — the single source of truth `GET /settings/public` serves,
  so changing the WhatsApp number here reaches the customer app without a
  rebuild.

## Connecting Flutter to the backend for real (Phase 10)

Every screen was already calling real endpoints as it was built (Phases
7-9), so this phase's job was auditing for gaps that only show up when the
two sides actually talk to each other rather than when reviewing code in
isolation. Found and fixed two real ones:

- **CORS was completely unconfigured.** Flutter mobile/desktop builds
  wouldn't have noticed (no browser same-origin policy), but Flutter Web —
  explicitly required by the spec — would have failed every single request
  at the browser's CORS preflight, before any controller ever ran. Added
  `config/CorsConfig.java` (configurable via `CORS_ALLOWED_ORIGINS`) and
  wired it into `SecurityConfig`'s filter chain with `.cors(...)` — a bean
  existing isn't enough, Spring Security has to be told to use it.
- **Image upload never actually existed.** `.env.example` had
  `IMAGE_STORAGE_URL`/`IMAGE_STORAGE_LOCAL_PATH` since Phase 2, and the spec
  calls for an admin-uploadable artist photo / event images, but every admin
  form only had a raw "paste a URL" text field — there was no
  `FileStorageService` and no upload endpoint behind those env vars. Added:
  - `service/storage/FileStorageService` (interface) +
    `LocalFileStorageService` (impl) — the abstraction the spec asked for,
    so swapping to S3/GCS later doesn't touch any caller.
  - `UploadController` — `POST /api/v1/admin/uploads` (multipart, ADMIN-only,
    8MB/image-type limit), returns `{url}`.
  - `WebMvcConfig` — serves `/uploads/**` as static files from the same
    local path, so an uploaded file is actually reachable at the URL
    returned.
  - Flutter: `ApiClient.uploadFile` (multipart via bytes, so it works
    identically on Web and mobile/desktop), `AdminService.uploadImage`, and
    a reusable `ImageUploadField` widget (URL field + Upload button + live
    preview) wired into both the Artist form (photo) and Event form (main
    image/banner/thumbnail) as the reference implementation. Gallery upload
    isn't wired to this yet — same pattern applies if you want it there too.

## Next phases

11. Responsive design polish (breakpoint tuning beyond AdminShell's
    sidebar/drawer switch, tablet layouts, customer-side breakpoints)
12-14. Testing, error fixes, README/deployment docs

## Known gap, still true in Phase 10

Backend: same as noted above — no Maven Central access / no Maven installed
in this sandbox, so it still hasn't been compiled here. This phase adds one
new runtime dependency indirectly used (Spring's built-in CORS support, part
of spring-web, already a transitive dependency — no pom.xml change needed).

Flutter: no Flutter/Dart SDK and no pub.dev access in this sandbox either, so
`flutter pub get` / `flutter analyze` have not been run — and this phase adds
a genuinely new dependency (`file_picker`) that has never been fetched here,
so it's the least-verified addition yet. I checked brace/parenthesis balance
across all 70 Dart files, confirmed every relative import resolves, and
checked for duplicate top-level class names — but please run
`flutter pub get && flutter analyze` locally and send me anything that
surfaces, especially around `file_picker` (platform-specific setup like
Android/iOS permissions or web CanvasKit quirks are exactly the kind of
thing I can't catch without actually running it).
