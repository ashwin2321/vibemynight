# VibeMyNight — Flutter App (Phase 7+)

This folder will contain the Flutter customer + admin app (`lib/core`, `lib/features`,
`lib/models`, `lib/services`), following the clean-architecture layout described in
`/docs/architecture.md`.

## Status: Phase 7 (project scaffold)

The folder structure, networking, state management, routing and data models
are in place. Screen bodies fall into two groups:

- **Wired to real data** — Home, Events, Event Details (with the multi-day
  selector), Event Day detail + pass selection, Inquiry form + submission,
  Inquiry success (opens WhatsApp), Admin Login, Admin Dashboard shell.
  These call the actual backend through `ApiClient` and will work as soon as
  the backend from Phases 1-6 is running and reachable.
- **Placeholders** — the remaining admin CRUD screens (Events table,
  Create/Edit Event, Manage/Create/Edit Days, Artists, Create/Edit Artist,
  Facilities, Create/Edit Pass, Inquiries table, Inquiry Details, Settings).
  Every route for these already exists in `core/router/app_router.dart` and
  is reachable — the screen body is a `PlaceholderScreen` until Phase 9
  builds out the real table/form UI.

## What's here

```
lib/
  core/
    constants/api_constants.dart   All backend endpoint paths in one place
    network/                       ApiClient (Dio), ApiException, TokenStorage
    providers/                     Riverpod providers (services, data reads, auth)
    router/app_router.dart         Every screen route, admin auth guard
    theme/                         AppColors, AppTheme (dark/glass/neon)
    widgets/                       GlassCard, LoadingView, ErrorView, PlaceholderScreen
  features/
    home/ events/ event_details/ artists/ inquiry/   Customer screens
    admin/{auth,dashboard,events,artists,facilities,inquiries,settings}/  Admin screens
  models/     Plain Dart classes mirroring every backend DTO (fromJson/toJson)
  services/   One class per backend resource, calling ApiClient
```

## Status: Phase 8 (customer UI visual pass)

Built on top of the Phase 7 data wiring — no plumbing changed, only what's
rendered:

- **Home** — hero (gradient headline, logo, EXPLORE EVENTS / GET YOUR PASS),
  horizontal Featured Events + Upcoming Events rails, Featured Artists rail,
  Why VibeMyNight / How It Works / FAQ (accordion) / Final CTA sections.
  Event/artist content is all real backend data; Why/How/FAQ copy is static
  marketing text (not "business data" in the spec's sense).
- **Events** — search box (name/artist/location) + All/Featured/Upcoming
  filter chips over the real published-events list, grid of `EventCard`s.
- **Event Details** — banner, info row with GET DIRECTIONS, description,
  gallery with a tap-to-open lightbox (`PageView` + `InteractiveViewer`),
  highlights/facilities/rules as chips, the multi-day "CHOOSE YOUR NIGHT"
  selector, and a sticky bottom GET YOUR PASS CTA that scrolls to it.
- **Event Day** — artist photo + bio line, program/time/venue/GET DIRECTIONS,
  facilities, and pass cards with SOLD OUT / low-stock states and a gradient
  SELECT button.
- **Artist Details** — full bio, photo, Instagram/Facebook/YouTube buttons.
- Shared building blocks added: `GradientButton`, `SectionHeading`,
  `FaqTile`, `StickyCtaBar`, `NetworkImageBox` (graceful fallback for
  missing/broken images), `FadeIn` (subtle staggered entrance animation used
  across every list), `Hero` transitions on event/artist images between list
  and detail screens.

Still placeholders: full responsive breakpoints/polish beyond `AdminShell`'s
sidebar/drawer switch (Phase 11) — this pass targeted mobile/portrait layouts
primarily, per "do not overuse animations" and to keep scope sane for one
phase.

One scope note: Events search/filter is done client-side over the already-
fetched published list, since the Phase 5 backend endpoint doesn't take
query params yet. Fine at this catalog size; worth moving server-side later
if the number of published events grows large.

## Status: Phase 9 (admin UI)

Every admin screen now has real CRUD, not a placeholder — see
`docs/architecture.md` for the full breakdown. Summary: Events (list/create/
edit/status actions), Days (per-event, unlimited count), Passes (per-day),
Artists (searchable, activate/deactivate), Facilities (inline dialog),
Inquiries (search/filter table + detail screen with CALL CUSTOMER/OPEN
WHATSAPP/status actions), Dashboard (stat cards from existing endpoints,
no fake charts), and Settings (the single source of truth the customer app's
WhatsApp number comes from). All wrapped in a shared `AdminShell`
(desktop sidebar / mobile drawer) and backed by one consolidated
`AdminService` covering every admin route.

## Status: Phase 10 (connected to backend for real)

Two real gaps found and fixed once the two sides were checked end-to-end
rather than reviewed in isolation — see `docs/architecture.md` for the full
writeup:

- Backend CORS was never configured, which would have silently broken every
  request from Flutter Web specifically (mobile/desktop wouldn't have shown
  the problem).
- Image upload didn't exist anywhere — admin forms only had raw URL text
  fields. Added a real upload endpoint + local storage on the backend, and
  an `ImageUploadField` widget (pick → upload → fills the URL field → shows
  a preview) wired into the Artist and Event forms.

New dependency: `file_picker` (for picking image bytes on any platform,
including Web).

## Setup (once you have the Flutter SDK)

```bash
cd frontend/flutter_app
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

`API_BASE_URL` defaults to `http://localhost:8080/api/v1` if not passed.
Make sure the backend's `CORS_ALLOWED_ORIGINS` includes wherever this ends
up running (defaults to `http://localhost:*`, which covers most local dev
setups).

## Known gap / honesty note

This sandbox has no Flutter/Dart SDK installed and no network access to
pub.dev, so **`flutter pub get` and `flutter analyze` have not been run** —
this code is unverified the same way the backend was before you compiled it.
I checked brace/parenthesis balance across all 70 Dart files, confirmed every
relative import resolves to a real file, and checked for duplicate top-level
class names — but please run `flutter pub get` and `flutter analyze` locally
and send me anything that surfaces. `file_picker` is the newest dependency
here and the least-verified — platform-specific setup (Android/iOS
permissions, web quirks) is exactly what I can't catch without actually
running it.

One deliberate deviation from the spec: it suggested Freezed/json_serializable
"where useful". Since `build_runner` can't run in this sandbox either, I used
plain Dart classes with hand-written `fromJson`/`toJson` instead of generated
code — functionally equivalent for this size of app, just without the
codegen step. Happy to switch to Freezed later if you'd rather have it once
you can run `build_runner` locally.

