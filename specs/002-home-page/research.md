# Phase 0 Research: Home Page (Prayer Times & Ayah of Today)

## 1. Design source of truth

**Decision**: Pixel-match spec is read directly from the Claude Design project "Sakinah Quran App UI" (`b8146c64-eac6-43d8-bb96-45b29414f5e1`), file `Sakinah Screens.dc.html`, section 02 "Home" (light + dark phone frames) and section 10 "LTR — English UI (secondary)" (English/LTR mirror). Both were read in full during planning.

**Key layout facts extracted** (drive data-model + widget structure):
- Header: two-line block — line 1 is a time-of-day greeting + user's first name ("مساء الخير، عبدالله" / "Good evening, Abdullah"); line 2 is `{day name} · {Hijri day} {Hijri month} {Hijri year} هـ/AH` ("الأربعاء · ٩ صفر ١٤٤٨ هـ" / "Wednesday · 9 Safar 1448 AH"). Arabic renders the Hijri numerals as Arabic-Indic digits; Gregorian/clock digits stay Latin in both locales.
- Prayer card: a teal gradient (`teal-700` → `teal-900`) rounded-16 card containing: small label "Next prayer"/"الصلاة القادمة", large (26px/800) prayer name, a circular settings/gear icon button (top-right, opens Prayers), and below: a big (34px/800, tabular-nums) `h:mm:ss` countdown + "until adhan · {time}" caption.
- 5-prayer strip: one row, 5 equal-width chips (Fajr/Dhuhr/Asr/Maghrib/Isha), each an icon + label + time; the active/next one is filled with `brand-primary` background and bold white text, the rest are `surface` with a `border` outline.
- "Ayah of Today" section: row header ("آية اليوم"/"Verse of the Day") + a "Share" text-button (icon+label, wired control, not decorative). Below: a `surface`-background rounded-16 card, centered text, with: a small decorative quote-mark icon (opacity-reduced `brand-primary-light`), the Arabic verse in the Quran font (26–27px, ~52px line-height, `brand-primary-dark`), the translation below (13px, `text-secondary`), and a reference line ("Surah · ayahNumber", 11px, `text-tertiary`). Verse Arabic text stays RTL even inside the LTR/English mirror.
- Bottom nav is the existing 3-item bar (Home/Quran/Settings) — unaffected by this feature except that Home is now a real page instead of `Container()`.
- Not shown in the mock: offline/cached/unavailable states for either card (mock only shows the happy path) — those are designed by extension using the same tokens/card shapes, following FR-007/008/009/013/014 in spec.md.

**Rationale**: The design project is the authoritative visual reference the user asked to pixel-match; extracting exact structure/values up front avoids guesswork during implementation and lets Phase 1 define a precise UI contract.

**Alternatives considered**: Rely only on the textual feature description for layout — rejected, since "perfect pixel match" was an explicit, testable requirement (SC-008) and the actual mock contains details (greeting line, share control, countdown format) not present in the text description.

## 2. Design tokens vs. existing `lib/utils/style/`

**Decision**: No new colors or typography roles are needed. `lib/utils/style/app_colors.dart` was spot-checked against the design system's `tokens/colors.css` and matches exactly (base palette hexes, light/dark semantic pairs, `success`/`warning`/`error`/`info`). One-off sizes not covered by a named `AppTypography` role (34px countdown, 26px prayer name, 22px greeting, 15px section label, etc.) are composed inline in feature widgets using `AppTypography.uiFontFamily`/`quranFontFamily` + `AppColors` tokens — consistent with how one-off sizes are already handled elsewhere in the app (typography roles are for reused semantic roles, not every literal size).

**Rationale**: Avoids polluting the shared typography scale with screen-specific one-off sizes while still sourcing every color and font-family from the single source of truth (Principle IV).

**Alternatives considered**: Adding new named `AppTypography` roles for each Home-specific size — rejected as premature; none of these sizes are reused by another screen yet.

## 3. New icon asset

**Decision**: Add `assets/icons/quote.svg` (path extracted verbatim from the design mock: `M7 7h4v4c0 3-2 5-4 5V14H7zM15 7h4v4c0 3-2 5-4 5V14h-2z`, 24×24 viewBox) and register `AppIcons.quote = 'quote'`, consumed via the existing `drawSvgIcon()` helper with `iconColor: AppColors.*brandPrimaryLight` and reduced opacity, matching the mock.

**Rationale**: All other icons the Home screen needs (fajr/dhuhr/asr/maghrib/isha/clock/settings/notifications/share) already exist in `assets/icons/` + `AppIcons`; only the decorative quote mark is missing.

## 4. Location resolution for Prayer Times (no Prayers settings screen exists yet)

**Context**: The integration reference assumes a `user_preferences.location_lat/lng`/`location_city` already exists (owned by a Prayers settings screen). Neither that screen nor any preferences model exists in this codebase yet — spec.md's Assumptions section explicitly defers it as "an existing or separately-specified screen."

**Decision**: The shared `prayer_times` module owns minimal location bootstrapping itself, so Home is usable standalone:
1. On first need, `PrayerTimesRepositoryImpl` checks `SharedPrefHandler` for a previously stored lat/lng.
2. If none, it asks `PermissionHandler.checkLocationPermission()` (existing handler); on grant, a new `LocationHandler` (`lib/handlers/location_handler.dart`, wrapping `geolocator`) fetches the device's current position once and it is persisted.
3. If permission is denied or detection fails and no cached location exists either, `PrayerTimesCubit` emits `PrayerTimesLocationRequiredState` — Home shows FR-009's explicit guidance with a "Retry"/"Enable location" action that re-runs step 2.
4. Calculation method defaults to `umm_al_qura` (AlAdhan id `4`) when nothing is stored yet — a reasonable default for the app's Arabic-first audience; stored the same way as location so a future Prayers screen can override it through the same repository/Cubit.

**Rationale**: Keeps Home fully functional end-to-end without inventing a full manual-city-picker UI (explicitly out of scope — that belongs to the future Prayers feature), while still satisfying FR-003/FR-009 and the "one repository, one global Cubit, reused later" requirement from the integration reference.

**Alternatives considered**: Hardcode a fallback city — rejected, spec.md FR-008/FR-009 explicitly forbid fabricating/defaulting location data; Block Home entirely until a Prayers screen is built — rejected, out of scope creep and contradicts "Home is the first screen" requirement (FR-001).

## 5. Manual-city fallback endpoint (`/timingsByCity`)

**Decision**: Not implemented in this feature. The integration reference's Endpoint B (`/timingsByCity`) depends on `user_preferences.location_city`, which requires the not-yet-built manual-city picker (Prayers screen). `PrayerTimesRepository.getPrayerTimes` is still designed to accept a `PrayerLocation` union (`Coordinates | City`) per the integration reference's contract, so the future Prayers feature can pass a `City` value with zero repository changes — but nothing in this feature ever constructs a `City` value today.

**Rationale**: Matches "one repository method regardless of source" from the integration reference (forward-compatible signature) without building UI that has no way to be reached yet.

## 6. Prayers screen navigation target (FR-006/SC-007)

**Decision**: Add `AppRoutes.prayers` and a minimal placeholder route (a bare scaffold, no real settings UI) in `route_generator.dart`, and wire the prayer card's gear icon to `Navigator.pushNamed(context, AppRoutes.prayers)`. This satisfies "reach prayer settings in a single tap" (FR-006/SC-007) without building the full Prayers screen, which is explicitly out of scope (spec.md Assumptions: "an existing or separately-specified screen").

**Rationale**: Avoids both a broken/no-op edit icon and unplanned full-screen scope creep; the placeholder is a clearly temporary seam the future Prayers-screen feature replaces.

**Alternatives considered**: Disable/hide the edit icon until the Prayers screen exists — rejected, contradicts the explicit user story (Story 3) and FR-006.

## 7. Hijri date calculation

**Decision**: Compute the Hijri date client-side using the `hijri` pub package (pure Dart, no network dependency), driven off the device's local Gregorian date — independent of `PrayerTimesCubit`/AlAdhan entirely. This matches the integration reference's explicit instruction to ignore the `hijri` field in the AlAdhan timings response.

**Rationale**: Decouples the header's Hijri date from prayer-times network/cache state (FR-002 must work even if prayer times are in an "unable to load" state), and from the AlAdhan response.

**Alternatives considered**: Derive Hijri date from the (ignored) AlAdhan response field — rejected, contradicts the explicit "ignore hijri" instruction and couples an unrelated header element to prayer-times fetch success/failure.

## 8. Countdown behavior and "animation"

**Decision**: The countdown renders as ticking `h:mm:ss` text (unpadded hours, zero-padded minutes/seconds — matching the design mock's `1:11:58` format and its `setInterval(tick, 1000)` behavior), computed as `nextPrayerDateTime.difference(DateTime.now())`, recomputed once per second by a dedicated `PrayerTimesCountdown` widget (isolated from the rest of the card so only the digits rebuild each tick). The "animation" the user asked for is an `AnimatedSwitcher`/implicit fade-transition on the digit string each second (a smooth ticking cross-fade), not a progress ring/arc — the design mock has no ring/arc, only ticking numerals. When the countdown reaches zero, the widget's parent (`PrayerTimesCubit`) re-resolves the next prayer (rolling to the following prayer, or to tomorrow's Fajr if Isha just passed) rather than the countdown widget owning that transition logic itself.

**Rationale**: Matches the literal design reference exactly; keeps "which prayer is next" business logic in the Cubit (single source of truth, testable) and "how the digits visually tick" in a small, isolated presentation widget (cheap rebuilds, easy to unit-test the Cubit without a widget pump).

**Alternatives considered**: A circular/radial progress-ring countdown — rejected, not present in the pixel-match reference; would fail SC-008.

## 9. Offline/error detection

**Decision**: Reuse the existing `Failure.handleDioException` mapping — a `ConnectionFailure` (or `TimeoutFailure`) from a repository call is treated as "offline/unreachable" by both Cubits, triggering their respective cache-fallback paths (FR-007/FR-013). No new connectivity-detection package is added.

**Rationale**: The failure taxonomy already exists and is the constitution's mandated single source of truth for network error classification (Principle VI); adding `connectivity_plus` would duplicate it.

## 10. Ayah-of-Today "no cache, offline" fallback asset

**Context**: The integration reference says the deepest fallback (no network, no cache) should pick a random ayah "from the bundled local Quran asset (same asset the Quran Reading feature uses)." No Quran Reading feature or bundled Quran-text asset exists in this codebase yet (`assets/` has no Quran data file).

**Decision**: Implement exactly spec.md's Alternate Flow B / FR-014 as written: show the "Ayah of Today is unavailable. Check your internet connection." message with a manual Retry action. Do **not** attempt to bundle a local Quran dataset in this feature — that asset does not exist yet and creating one is out of scope for a Home Page feature. `AyahRepository`'s fallback chain is written so that swapping in a local-asset lookup later (once the Quran Reading feature ships that asset) is a single, additive change inside `AyahRepositoryImpl`, not a Cubit/state-contract change.

**Rationale**: spec.md was already written to not depend on an asset that doesn't exist (its FR-014 matches the simpler placeholder+retry behavior); this research entry makes explicit why the richer fallback from the integration reference is deferred rather than silently dropped.

## 11. External API base URLs vs. `AppEnv`

**Decision**: AlAdhan and Al Quran Cloud base URLs are added as constants on `AppEndPoints` (`app_end_points.dart`), not on `AppEnv`. `RequestInstructions.url` is built as the full absolute URL for each call; `DioClient.instance` accepts this even though it has its own `baseUrl` configured, because Dio does not prepend `baseUrl` to an already-absolute URL.

**Rationale**: `AppEnv` specifically models the app's own backend per environment (`dev`/`staging`/`production`, security key, Supabase project) — these two APIs are fixed, unauthenticated, environment-independent public hosts, so folding them into `AppEnv`/`.env.*` would be a category error and would force fake per-environment values for a host that never changes.

**Alternatives considered**: A second `Dio`/`DioClient` instance per external API — rejected, Principle VI explicitly forbids a second `Dio` instance; the absolute-URL approach keeps a single client.

## 12. New dependencies summary

| Package | Purpose | Why not already covered |
|---|---|---|
| `geolocator` | One-shot device coordinates for prayer-location auto-detect | `permission_handler` (existing) only handles permission grant/deny, not reading the actual position |
| `hijri` | Gregorian→Hijri conversion for the header date | No calendar-math package in the current stack; AlAdhan's `hijri` field is explicitly out of scope |
| `share_plus` | Native share sheet for the Ayah card's wired "Share" control | No share package in the current stack |

All three are additive (new capability categories), not replacements/duplicates of anything in the constitution's approved stack.
