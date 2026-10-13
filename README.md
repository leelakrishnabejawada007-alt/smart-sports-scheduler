# Smart Sports Facility Scheduler

Flutter + Dart mini project: browse shared sports facilities, pick a date and
slot, submit a booking request and track its status (Pending / Approved / Rejected).

## Setup
Requires Flutter 3.27+ (Dart 3.6+).

```bash
cd smart_sports_scheduler
flutter create . --platforms=web,android,ios   # generates platform folders (keeps lib/ and test/)
flutter pub get
flutter run -d chrome        # or any emulator/device: flutter run
flutter test                 # run all tests
flutter analyze              # static checks
```

## UI redesign (PrintHub-style design system)
Visual-only redesign; the screens, filters, facility data and booking logic are unchanged.
- **Palette:** navy `#1B2B5B` primary, soft-blue accents, off-white canvas, white cards,
  soft green / orange / red for status. Defined once in `lib/theme/app_theme.dart`.
- **Typography:** Inter via `google_fonts` (fetched at runtime; bundle the font files
  under `assets/google_fonts/` for fully offline use).
- **Layout:** sidebar (full on desktop, icon rail on tablet, hamburger drawer on mobile);
  cards 1 / 2 / 3-4 columns by width.
- **Booking panel:** "Book Now" opens a modal (bottom sheet on phones) with date, slots,
  duration, players, price and Confirm Booking - no separate page.
- **Smart features:** "Recommended for you" (favours sports you booked before, quiet slots)
  and "Best time today" (lowest-demand hour). Can be switched off in Settings.
- **New pages:** Calendar, Favorites, Profile, Settings. My Bookings has table (desktop)
  and card (mobile) views with View / Reschedule / Cancel.
- **Note:** the PrintHub files and screenshot were not attached, so the palette and
  component styling follow the written description. Adjust `AppColors` to match exactly.

## Login & registration
- `AuthGate` (in `main.dart`) shows `screens/auth_screen.dart` until the user is signed in,
  then the app. Log out from the sidebar or Profile page.
- Sign in / Create account share one screen (pill switch). Validation: valid email,
  password >= 8 chars with letters + numbers, matching confirmation, student ID 6-10 digits.
- State: `AuthProvider` (session) next to `SchedulerProvider`; on sign-in the name and
  student ID pre-fill the booking form.
- `AuthService` interface -> `MockAuthService` (in-memory) or `HttpAuthService`
  (`POST /auth/login`, `POST /auth/register`; 401 = bad credentials, 409 = exists).
- **Demo account:** `demo@student.edu` / `Demo@1234`, or register a new one.
- Limitations of the mock: sessions and accounts live in memory (restart = signed out),
  passwords are plain text, and bookings are not separated per user. A real backend should
  hash passwords, return a token, and filter bookings by the signed-in user.

## Demo tips
- Facilities show some pre-booked slots (crossed out) and past slots for today.
- Book a slot -> status is **Pending**; after ~8 s the mock API resolves it
  (My Bookings polls automatically, or pull to refresh).
- Student ID ending in `0` -> **Rejected** (slot is freed). Otherwise **Approved**.
- Widen the window (>= 800 px) to see the side navigation rail and two-column details.

## Structure
```
lib/
  main.dart                    app entry, DI of the API service
  theme/app_theme.dart         Material 3 theme
  models/                      Facility, Booking (+ JSON)
  services/api_service.dart    ApiService interface, MockApiService, HttpApiService
  providers/scheduler_provider.dart   state + availability rules
  utils/                       validators, formatting, sport icons, page route
  widgets/                     FacilityCard, SlotChip, StatusChip, MessageView, dialog
  screens/                     shell, facilities, detail, my bookings, calendar,
                               favorites, profile, settings
  widgets/                     + booking_modal, sidebar_nav, page_header, smart_cards,
                               filter_pill, skeleton, availability_badge
test/                          auth + validators, provider/booking logic, booking modal test
```

## State management: Provider + ChangeNotifier
One `SchedulerProvider` owns facilities and bookings. Slot availability is
*derived* from bookings (pending/approved hold a slot, rejected frees it), so
the list, details and booking screens can never disagree. Provider is
lightweight, officially recommended for apps this size, easy to test without
widgets, and needs no code generation. Bloc/Riverpod would be overkill here.

## REST API
`ApiService` is the only backend contract. `MockApiService` simulates latency,
sample data, conflicts and status changes. To go live, change one line in
`main.dart` to `HttpApiService(baseUrl: ...)` which expects:
`GET /facilities`, `GET /bookings`, `POST /bookings` (409 = slot taken),
`PATCH /bookings/{id}` with `{status: cancelled}`.

## Requirement coverage
| Requirement | Where |
|---|---|
| Facility listings | `facility_list_screen.dart`, `facility_card.dart` (sport filter, placeholders, availability) |
| Facility details + slots | `facility_detail_screen.dart` |
| Booking request | `widgets/booking_modal.dart` |
| Booking status | `my_bookings_screen.dart`, `status_chip.dart` |
| Validation / no double booking | `validators.dart`; `SchedulerProvider.book` + server-side conflict check |
| Navigation | NavigationBar/Rail + `Navigator.push` with custom transition |
| State management | `scheduler_provider.dart` |
| Reusable UI + theme | `widgets/`, `app_theme.dart` |
| Animation | page fade/slide, Hero icon, animated confirmation check, animated status chip |
| REST API | `api_service.dart` |
| Responsive | grid with max tile width, rail vs bottom bar, two-column details |
| Tests | `test/` |

## Contact section
`widgets/contact_section.dart` shows the address and a "Need help" block (phones, email,
opening hours) with no map. It appears at the bottom of Facilities and on Settings. Change the
text in `lib/config/contact_info.dart`. Tapping a number or the email copies it; to open the
dialer / mail app instead, add `url_launcher` and launch `tel:` / `mailto:` links.

## Visual style (FastCopies-inspired)
Same content and features, new look: cool light-grey canvas with a soft blue glow, heavy italic
uppercase headings with the last word in blue (`widgets/section_title.dart`), 24-28px rounded
cards, dark-slate "BOOK NOW" buttons, blue pill buttons, a dark announcement strip at the top
(`widgets/announcement_ticker.dart`, built from live availability and contact data), a dark
gradient "Recommended" banner and a dark footer (`widgets/contact_section.dart`).
All colours and text styles live in `lib/theme/app_theme.dart` (`AppColors`, `AppText`).

## Database, saved login and admin (backend)
**Backend:** `backend/server.py` is a REST API on **SQLite** (`scheduler.db`, created on first run).
It uses only the Python 3 standard library (no installs). Passwords are hashed (PBKDF2),
sessions are random tokens valid for 30 days, and all booking rules are enforced on the server
(no double-booking, opening hours, past slots).

```bash
cd backend
python3 server.py          # http://localhost:8000/api  (keep it running)
python3 test_server.py     # 25 end-to-end checks against a temporary database
```
**Windows:** use `python server.py` (or `py server.py`) instead of `python3`. Check it works by opening
http://localhost:8000/api/facilities in the browser - you should see JSON. If the app says
"Could not reach the server", the backend is not running (or is on a different port).

Then run the app in another terminal: `flutter run -d chrome`
(Android emulator uses `10.0.2.2` automatically; for a real phone use
`--dart-define=API_URL=http://<your-pc-ip>:8000/api`; offline demo without the server:
`--dart-define=USE_MOCK=true`).

**Accounts (seeded on first run):**
| Role | Email | Password |
|---|---|---|
| Admin | admin@sports.edu | Admin@1234 |
| Student | demo@student.edu | Demo@1234 |

**Saved login:** the token and user are stored on the device (`shared_preferences`; browser local
storage on web). On the next launch the app calls `GET /auth/me`, skips the login page if the
session is still valid, and shows login again if it expired or you logged out.

**Admin page** (only visible to admins, opens automatically after admin login):
- stats: pending requests, confirmed bookings, confirmed revenue, facilities, students
- **Bookings:** filter by status; **Approve / Reject** pending requests, cancel confirmed ones.
  Students' "My Bookings" update on their own (it polls while something is pending).
- **Facilities:** add, edit (name, sport, location, description, amenities, price, opening hours)
  and delete.
- **Users:** everyone registered, with role.

With the real backend, requests stay **Pending until an admin approves them** (the 8-second
auto-approval only exists in the offline mock). To make someone an admin:
`sqlite3 backend/scheduler.db "UPDATE users SET role='admin' WHERE email='you@college.edu'"`.
Delete `scheduler.db` to reset all data. For production: serve over HTTPS and restrict CORS in `server.py`.

## The /admin page (admin-only)
Open **http://localhost:4765/admin** (use a fixed port: `flutter run -d chrome --web-port=4765`;
a fixed port also keeps your saved login, because browsers store it per address).
- Not signed in -> a dedicated **Admin sign in** page. Student accounts are rejected there.
- Signed in as a student -> "Admin access only".
- Signed in as admin -> the dashboard (approve/reject bookings, facilities, users) with its own
  top bar, a "Student app" link and Log out.
- The student app has no link to /admin. The server also refuses every admin API call from
  non-admin accounts, so hiding the page is not the only protection.
- Clean URLs (`/admin`, not `/#/admin`) use `flutter_web_plugins`; hosting must send unknown
  paths to `index.html` (the dev server does this already).

**Make yourself the only admin** (do this once):
```bash
cd backend
python server.py set-admin you@college.edu "YourStrongPass1" "Your Name"
python server.py delete-user admin@sports.edu        # remove the default admin
```
Registration in the app can only create students. Five wrong passwords lock that email for
5 minutes. Admin accounts cannot be created over HTTP, only with this terminal command.
Also delete the seeded demo/priya accounts before a real launch.
