# VibeMyNight

Event discovery and Navratri pass-inquiry platform — Flutter (customer + admin)
frontend, Spring Boot 3 / Java 21 backend, MySQL 8. No payment gateway in v1;
customers submit an inquiry and are handed off to WhatsApp
(`wa.me/<WHATSAPP_NUMBER>`) for manual confirmation by the VibeMyNight team.

## Status: Phase 1-10 of 14

- [x] Phase 1 — repo structure
- [x] Phase 2 — Spring Boot backend skeleton (Maven, Java 21, config)
- [x] Phase 3 — MySQL schema as JPA entities, repositories, core services
- [x] Phase 4 — Spring Security + JWT auth
- [x] Phase 5 — Event/Day/Artist/Pass/Facility REST APIs
- [x] Phase 6 — Inquiry API + WhatsApp message flow (+ gallery/highlights/rules admin CRUD)
- [x] Phase 7 — Flutter project scaffold (structure, networking, state, routing, models)
- [x] Phase 8 — Flutter customer UI visual pass (Home, Events, Event Details, Event Day, Artists)
- [x] Phase 9 — Flutter admin UI (CRUD tables/forms for Events/Days/Passes/Artists/Facilities/Inquiries, Dashboard, Settings)
- [x] Phase 10 — Connect Flutter to backend (CORS enabled + real image upload wired end-to-end)
- [ ] Phase 11 — Responsive design polish
- [ ] Phase 12-14 — testing, fixes, docs

See `/docs/architecture.md` for what's implemented so far and an important
note on why this hasn't been compiled in this sandbox.

## Layout

```
/vibemynight
    /frontend/flutter_app
    /backend/spring_boot
    /docs
```

## Backend quick start (once you have MySQL 8 running locally)

```bash
cd backend/spring_boot
cp ../.env.example ../.env   # then edit values
export $(grep -v '^#' ../.env | xargs)   # or use your IDE's env-var support
mvn spring-boot:run
```

The app starts on `http://localhost:8080`. With `ddl-auto: update`, Hibernate
creates the schema on first run against the `vibemynight` database.

## Auth (Phase 4)

- `POST /api/v1/auth/login` — public, body `{ "email": "...", "password": "..." }`,
  returns a JWT `accessToken` (24h expiry by default, `JWT_EXPIRATION_MS`).
- Send it back as `Authorization: Bearer <token>` on every `/api/v1/admin/**` call.
- The **first** admin account is bootstrapped automatically from
  `ADMIN_SEED_EMAIL` / `ADMIN_SEED_PASSWORD` (see `.env.example`) the first
  time the app starts against an empty `users` table — nothing is hardcoded
  or committed. Change the password after first login (endpoint for that
  comes with the rest of admin settings management in Phase 5).
- Route rules (see `SecurityConfig`): `GET` on events/artists/facilities/event-days
  and `GET /api/v1/settings/public` are public; `POST /api/v1/inquiries` is public;
  everything under `/api/v1/admin/**` requires a valid JWT with the `ADMIN` role.

## API endpoints (Phase 5)

Public:
```
GET  /api/v1/events
GET  /api/v1/events/{slug}
GET  /api/v1/events/{eventId}/days
GET  /api/v1/event-days/{id}
GET  /api/v1/event-days/{dayId}/passes
GET  /api/v1/artists
GET  /api/v1/artists/{id}
GET  /api/v1/facilities
GET  /api/v1/settings/public
```

Admin (require `Authorization: Bearer <token>` with ADMIN role):
```
GET/POST/PUT/DELETE  /api/v1/admin/events, /admin/events/{id}
PATCH                /api/v1/admin/events/{id}/status
GET                  /api/v1/admin/events/{id}          (full detail)
POST/PUT/DELETE      /api/v1/admin/events/{eventId}/days, /admin/event-days/{id}
POST/DELETE          /api/v1/admin/event-days/{dayId}/artists[/{artistId}]
GET/POST/PUT/DELETE  /api/v1/admin/artists, /admin/artists/{id}
PATCH                /api/v1/admin/artists/{id}/status
GET/POST/PUT/DELETE  /api/v1/admin/facilities, /admin/facilities/{id}
PATCH                /api/v1/admin/facilities/{id}/status
POST/DELETE          /api/v1/admin/events/{eventId}/facilities/{facilityId}
POST/DELETE          /api/v1/admin/event-days/{dayId}/facilities/{facilityId}
POST                 /api/v1/admin/event-days/{dayId}/passes
PUT/DELETE           /api/v1/admin/passes/{id}
POST/DELETE          /api/v1/admin/events/{eventId}/gallery, /admin/gallery/{id}
POST/DELETE          /api/v1/admin/events/{eventId}/highlights, /admin/highlights/{id}
POST/DELETE          /api/v1/admin/events/{eventId}/rules, /admin/rules/{id}
GET/PUT              /api/v1/admin/settings
GET                  /api/v1/admin/inquiries?search=&status=&eventId=&artistId=&ticketCategoryId=&date=
GET                  /api/v1/admin/inquiries/{id}
PATCH                /api/v1/admin/inquiries/{id}/status
DELETE               /api/v1/admin/inquiries/{id}
```

Public inquiry flow:
```
POST /api/v1/inquiries               -> saves inquiry, returns InquiryResponse
                                         (includes whatsappMessage + ready whatsappUrl)
GET  /api/v1/inquiries/{inquiryNumber}  -> fallback lookup if WhatsApp didn't open automatically
```

Every response uses the `{ success, data, message, errors }` envelope
(`ApiResponse`). That's the full backend API surface through Phase 6.

## Uploads + CORS (Phase 10)

```
POST /api/v1/admin/uploads   multipart "file" (+ optional "folder"), ADMIN-only
                              -> { "url": "http://.../uploads/<folder>/<uuid>.<ext>" }
GET  /uploads/**              serves whatever was uploaded (public, static)
```

`CORS_ALLOWED_ORIGINS` (see `.env.example`) controls which origins the
Flutter Web app can call this API from — without it, the browser blocks
every request at the CORS preflight before it reaches a controller. Defaults
to `http://localhost:*` for local dev; set it explicitly for any real
deployment.

## Frontend quick start (once you have Flutter installed)

```bash
cd frontend/flutter_app
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

See `frontend/flutter_app/README.md` for what's wired to real data vs still
a placeholder, and an honesty note on what hasn't been verified here.

## WhatsApp number

Configured via `WHATSAPP_NUMBER` (see `.env.example`), served publicly via
`GET /api/v1/settings/public` — never hardcoded in the frontend.
