# Research: Prayers Times Screen

Phase 0 output. Each decision resolves a gap between spec.md's requirements and what already exists in the codebase (per the Explore survey of `lib/shared/prayer_times/`, `lib/features/home/`, `lib/shared/bloc/`, Supabase schema, and `pubspec.yaml`).

## R1. Location display (city + country) for the location card

**Decision**: Add on-device reverse geocoding using the `geocoding` package (`placemarkFromCoordinates`) inside the existing `lib/shared/prayer_times/` module — new method `PrayerTimesRepository.resolveDisplayLocation(PrayerLocation location)` returning a `{city, country}` pair (or `null` if it cannot be resolved), cached alongside the existing lat/lng Hive entry so it isn't re-geocoded on every screen open.

**Rationale**: `PrayerLocation.Coordinates` (the only variant ever constructed today — see R2) carries lat/lng only; nothing in the codebase currently turns that into a human-readable city/country, yet FR-001 requires showing both. Placing this on `PrayerTimesRepository` (rather than inside the new `prayers` feature) follows Constitution Principle I: location is already state owned by `lib/shared/prayer_times/`, so a location-derived capability belongs there too, not duplicated locally. `geocoding` is the standard Flutter plugin for this exact job, uses the OS's native geocoder (no new API key, no new backend dependency), and matches the existing `geolocator` dependency's device-capability style.

**Alternatives considered**:
- Parse AlAdhan's `/timings` response `meta` block — rejected, it exposes only a timezone string (e.g. `Africa/Cairo`), not a reliable city/country name for arbitrary coordinates.
- Call a REST reverse-geocoding API (e.g. Nominatim) through `DioClient` — rejected for v1: adds a third external prayer-adjacent HTTP dependency and a new failure surface, where an on-device plugin is simpler and works offline once cached.

## R2. Manual city selection UI

**Decision**: Out of scope for this feature, per spec.md's own Assumptions. `PrayerLocation.City` stays exactly as-is (defined, never constructed). This screen only *displays* whatever location is currently resolved (GPS via R1, or a future manual selection once that capability exists) and shows the "configure a location" guidance (FR-011) when none is resolved yet.

**Rationale**: spec.md explicitly assumes location resolution — including manual city search and the location-permanently-denied help flow — is owned by shared functionality "already used by the Home screen." The Explore survey confirms `City` was pre-built in the 002 feature specifically for "a future Prayers screen," but building the manual-city-search *UI* itself was never claimed by 002 and isn't in this feature's Requirements (FR-001–019 only ask this screen to *show* the resolved location). Treating it as a pre-existing gap in the shared location capability — not something 003 must close — keeps this feature's scope matched to what spec.md actually committed to.

## R3. Local reminder delivery mechanism (FR-005, FR-015–017)

**Decision**: Use `flutter_local_notifications` with the `timezone` package for `zonedSchedule`, one scheduled local notification per enabled prayer (prayer_time − 10 minutes), with a deterministic notification id per prayer code (1=fajr…5=isha) so scheduling/cancelling is idempotent. Configure Darwin (iOS) presentation options so the same scheduled notification displays as a banner both in foreground and background — no separate custom "in-app banner" widget system is needed to satisfy FR-015's two delivery modes.

**Rationale**: Neither package exists in `pubspec.yaml` today — this is greenfield. A prayer's reminder time is fully known on-device once prayer times are fetched, so client-side scheduling satisfies FR-005/FR-015/FR-016 without needing a server-side scheduler. The Supabase integration notes given for this feature only define upsert/pull/seed operations for settings sync — no scheduled server function — so there is no backend in place to originate a Firebase push at prayer time; building one would be new, unscoped backend infrastructure.

**Alternatives considered**:
- `firebase_messaging` server-triggered push (as the original feature brief's "Firebase push" phrasing suggested) — rejected for v1: requires a server-side scheduler/cron hitting FCM at each user's next prayer time, which nothing in the provided Supabase schema/operations implements; `user_devices.fcm_token` exists in the DB but nothing registers a device today. Flagged as a future enhancement, not blocking FR-015/016/017 which are satisfiable entirely client-side.

**Known platform follow-ups** (implementation-phase tasks, not plan blockers): Android 13+ requires the `POST_NOTIFICATIONS` runtime permission (gated via R4); exact-time scheduling needs `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM` on newer Android; scheduled alarms do not survive a device reboot unless rescheduled on next app launch — this feature's cubit already reschedules all enabled reminders on `loadSettings()`, which covers that case adequately for v1.

## R4. Notification permission status (granted / denied / permanently denied)

**Decision**: Add `checkNotificationPermissionStatus()` to `lib/handlers/permission_handler.dart` returning the raw tri-state (`granted` / `denied` / `permanentlyDenied`) from `permission_handler`'s `Permission.notification`, rather than reusing the existing private `_checkPermission()` helper (which collapses denied and permanently-denied to the same `false`).

**Rationale**: FR-012/013/014 require the UI to distinguish "not yet asked," "denied, can retry," and "permanently denied" — three distinct card/interaction states — which the existing boolean-returning helper can't express. `permission_handler`'s `Permission.notification` already unifies iOS/Android notification permission under one check, consistent with `PermissionHandler`'s existing per-capability method pattern (`checkCameraPermission`, `checkLocationPermission`, etc.) — this is an additive method, not a change to existing callers.

## R5. Local persistence shape for per-prayer toggle state

**Decision**: One Hive entry (new key `AppPersistenceDataKeys.prayerNotificationSettings`) holding a JSON-encoded map of `{prayerCode: {isEnabled, updatedAt}}` for all five prayers, following the same "envelope" convention as `CachedPrayerTimes` (serialize the domain shape + a timestamp, `toJson`/`fromJson`). `updatedAt` is the local device timestamp of the last toggle change and is exactly what a last-write-wins comparison diffs against the Supabase row's `updated_at` (FR-007).

**Rationale**: Nothing in the codebase currently stores a per-item "last changed at" timestamp locally (the closest precedent, `CachedPrayerTimes`, only timestamps the whole fetch, not five independent fields) — this is new, but shaped to match the existing envelope pattern in `lib/shared/prayer_times/data/models/prayer_times_model.dart` so it's consistent with how this codebase already persists structured Hive data via `SharedPrefHandler.save`/`get<T>`.

## R6. Supabase table access + failure mapping

**Decision**: Query `prayer_notification_settings` directly via `Supabase.instance.client.from('prayer_notification_settings')` inside the new feature's repository impl (mirroring how `auth_repository_impl.dart` already calls `Supabase.instance.client.auth` directly — no repository-level Supabase wrapper exists in `lib/network/`, and none is needed here). Add the table name as a constant on `lib/configurations/app_end_points.dart` (`AppEndPoints.prayerNotificationSettingsTable`) rather than an inline string literal, consistent with Constitution Principle VII's "no magic strings for API paths." Catch `PostgrestException` and map it to `Failure.unknown(...)` (no existing `handlePostgrestException` helper exists; `Failure.handleAuthException`/`handleDioException` don't apply to table errors) since sync failures are swallowed per FR-006's "fire-and-forget" contract and spec.md's Assumptions ("a failed sync does not roll back the local toggle").

**Rationale**: Matches existing precedent exactly (direct Supabase client calls, no locator, no new network abstraction) while keeping the one new string constant centralized per the constitution rather than inlined.

## R7. Cubit shape and state ownership

**Decision**: New `PrayerNotificationSettingsCubit` (Cubit, not Bloc — matches Constitution Principle II's explicit "settings toggles" example), feature-scoped (provided via `BlocProvider` at `PrayersPage`, **not** a global singleton like `PrayerTimesCubit`/`SessionCubit`, since this state is per-screen). It owns a dedicated sealed state (`PrayerNotificationSettingsState`: Initial / Loading / Loaded(settings, permissionStatus)) rather than the legacy `AppStates` hierarchy, following `PrayerTimesCubit`'s newer, more specific convention. The Prayers screen composes this new cubit alongside the existing, unmodified `PrayerTimesCubit.instance` for times/location — exactly how Home composes `PrayerTimesCubit` alongside its own `AyahOfTodayCubit` today.

**Rationale**: `lib/shared/bloc/` has no existing owner for per-prayer notification-toggle state (checked per Constitution Principle I's required step before adding new state), so this is genuinely new, feature-local state. `PrayerTimesCubit`'s own contract doc already states other features must consume it via `.instance` rather than calling its repository directly — this plan follows that constraint rather than re-fetching prayer times independently.

## R8. Replacing the placeholder screen

**Decision**: Replace the body of `lib/features/prayers/presentation/pages/prayers_page.dart` in place; keep the existing route wiring (`AppRoutes.prayers` → `PrayersPage`, already present in `route_generator.dart`) unchanged.

**Rationale**: The placeholder's own doc comment (`specs/002-home-page/research.md §6`) states it exists specifically as "a clearly temporary seam the future Prayers-screen feature replaces" — this is that feature.
