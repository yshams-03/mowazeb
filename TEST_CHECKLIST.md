# Phase 1 + 2 Manual Test Checklist

## Environment
- [ ] flutter analyze → 0 errors, 0 warnings
- [ ] flutter build apk --debug → succeeds
- [ ] flutter run → app launches on device/emulator
- [ ] Firebase console shows the app connecting (Auth + Firestore activity)

## Auth
- [ ] Register new account → lands on onboarding
- [ ] Register with existing email → shows error (no crash)
- [ ] Login with correct credentials → lands on home
- [ ] Login with wrong password → shows error
- [ ] Kill app and reopen → stays logged in
- [ ] Sign out → returns to login

## Onboarding
- [ ] Step 1 shows location explanation + allow button
- [ ] Step 2 shows all 5 calculation methods, each selectable
- [ ] Step 3 shows Standard + Hanafi, each selectable
- [ ] Completing writes to Firestore (check Firebase console)
- [ ] Completing again does NOT re-show onboarding

## Prayer times
- [ ] Home screen shows 5 correct prayers (verify against islamicfinder.org)
- [ ] Next prayer card highlights correct upcoming prayer
- [ ] Countdown ticks every second (watch 10 sec)
- [ ] Post-Isha → next prayer shown as tomorrow's Fajr
- [ ] Pull-to-refresh works without crash
- [ ] Moving 500m+ triggers recalculation (or test by mocking location)

## My Places — Add Place flow (THE CORE FIX)
- [ ] Tap "Add Place" FAB → bottom sheet opens with **Pick on Map** and **Search by Name** buttons
- [ ] Tap "Pick on Map" → full-screen map opens at GPS location (or Cairo fallback)
- [ ] Drag the map → pin lifts, address shimmer shows
- [ ] Stop dragging → pin drops, address appears within ~1 second
- [ ] Tap "Confirm Location" → returns to sheet with label pre-filled
- [ ] Edit label if needed, pick kind, tap "Save Place"
- [ ] Sheet closes, new place appears in list immediately
- [ ] Tap "Search by Name" → focuses Nominatim search field (text search still works)
- [ ] Type "aast" → suggestions appear within 1 second
- [ ] Suggestions show shortName (bold) + address (muted)
- [ ] Tap a suggestion → suggestion list collapses, label field appears
- [ ] Label field is pre-filled with shortName
- [ ] Label can be edited freely (e.g. change to "University")
- [ ] Home / Work / Other chips are visible and tappable
- [ ] "Save Place" is disabled until both location and label are set
- [ ] Tap "Save Place" → sheet closes, new place appears in list immediately
- [ ] Saved place persists after app restart (check Firestore)
- [ ] Deleting a place shows confirm dialog → confirmed → place disappears

## Smart Day Planner
- [ ] Planner tab loads without crash
- [ ] "Add Block" opens a sheet
- [ ] Saved places appear in the location picker inside Add Block
- [ ] Block is created and appears on the calendar
- [ ] Today's Prayer Plan section shows prayer tags
- [ ] Dhuhr during a "University" 08:00–14:00 block is tagged "Pray at University"
- [ ] A prayer outside all blocks is tagged "Pray at home"
- [ ] Wudu nudge notification fires 10 min before a transition prayer
  (test by creating a block ending 15 min from now and waiting)
- [ ] Blocks not applicable today show "No blocks today" banner
- [ ] Deleting a block removes it from the calendar

## Navigation
- [ ] All 5 bottom tabs tap without crash
- [ ] Back button is sensible throughout

## Dark mode
- [ ] All screens look correct in dark mode
- [ ] No invisible text or white boxes on dark background

---

# Phase 3 Manual Test Checklist — Smart Commute Advisor

## Environment
- [ ] `ORS_API_KEY` set in `.env` (free key from openrouteservice.org)
- [ ] Home location saved in My Places (kind: Home) or Profile home address

## Commute tab — route setup
- [ ] Commute tab loads without crash
- [ ] **From** card shows "Current location" (read-only)
- [ ] **To** card shows saved Home name/address (read-only)
- [ ] "My Places" link navigates to Places tab
- [ ] Warning card appears when home is not configured
- [ ] "Can I Make It?" button disabled until home is set

## Can I Make It? verdict
- [ ] Tap button → loading shimmer appears
- [ ] GREEN verdict when drive time ≤ next-prayer countdown
- [ ] Card shows drive minutes, countdown minutes, and spare buffer
- [ ] RED verdict when drive time exceeds countdown
- [ ] RED card says "Pray before you leave"
- [ ] Missing ORS key shows configuration error (not a crash)
- [ ] Retry button works after a failed calculation

## Mosque finder (RED only)
- [ ] Nearby mosques list appears only on RED verdict
- [ ] Each mosque shows name, distance, and "Open in Maps"
- [ ] "Open in Maps" launches external maps app (OSM link)

## Profile integration
- [ ] Profile icon in Commute app bar opens Profile screen
- [ ] Updating home address in Profile updates Commute "To" card

## Navigation
- [ ] Commute tab in bottom nav (4th item) works
- [ ] Dark mode: verdict cards readable (green/red backgrounds)

---

# Phase 4 Manual Test Checklist — Peer Accountability Circles

## Environment
- [ ] Firestore rules deployed (`firebase deploy --only firestore:rules`)
- [ ] Cloud Functions deployed (`firebase deploy --only functions`)
- [ ] Notification permission granted on device (for FCM reminders)

## Community tab — circle management
- [ ] Community tab loads "Accountability Circles" screen
- [ ] Empty state shows Create + Join options
- [ ] **Create Circle** → enter name → circle saved to Firestore
- [ ] Success screen shows 6-char invite code
- [ ] Copy invite code works
- [ ] **Join Circle** → enter valid code → added to members array
- [ ] Invalid code shows error snackbar
- [ ] Circle list shows name, member count, and group streak

## Circle detail — live feed
- [ ] Tap circle → detail screen opens
- [ ] Group streak and invite code visible in header
- [ ] Share/copy invite code from app bar works
- [ ] Live feed shows each member: avatar | name | 5 prayer icons
- [ ] Feed updates in real time when another member checks off (test with 2 devices)
- [ ] Your row labeled "(You)" and appears first

## Prayer check-off
- [ ] Home screen: tap prayer icon → turns green immediately (optimistic UI)
- [ ] Check-off writes to `users/{uid}/prayer_logs/{date}/prayers/{prayerName}`
- [ ] Circle feed reflects your check-off within ~1 second
- [ ] Cannot check off another member's prayers (icons not tappable)

## Missed prayer alerts (Cloud Function)
- [ ] After prayer window + 10 min without check-off, status becomes `missed` (red icon)
- [ ] Other circle members receive FCM: "[Name] hasn't checked off [Prayer] yet"
- [ ] Tapping notification opens circle detail screen
- [ ] "Send Reminder" action sends reminder to target user

## Security
- [ ] User cannot read circles they are not a member of
- [ ] User cannot read another user's prayer logs unless they share a circle

## Privacy & Dua (Phase 5)
- [ ] Profile shows status toggle (Active / Traveling / Excused / In Exam)
- [ ] Circle detail shows compact status toggle above prayer feed
- [ ] Setting Traveling/Excused/In Exam hides red missed indicators for other members
- [ ] Other members see only status label badge (e.g. "✈️ Traveling") — never a reason
- [ ] Optional expiry auto-resets status to Active
- [ ] Dua Board tab lists requests newest first
- [ ] Post Request FAB opens sheet and saves to Firestore
- [ ] Make Dua adds uid to duaSenders and shows "Dua Sent ✓"
- [ ] Dua author receives private FCM only (not broadcast to circle)
- [ ] Missed-prayer notification has "Send Dua" action
- [ ] Tapping Send Dua creates board entry + private FCM to missed member

## Navigation
- [ ] Community tab in bottom nav (5th item) works
- [ ] `/community/create`, `/community/join`, `/community/circle/:id` routes work
- [ ] Dark mode: feed rows and prayer icons readable

---

# Automated tests (Phase 3 + 4)

Run: `flutter test`

| Suite | Phase 3 (Commute) | Phase 4 (Community) |
|-------|-------------------|---------------------|
| Unit | `commute_calculator_test`, `open_route_service_test`, `reverse_geocode_service_test` | `accountability_circle_test`, `invite_code_generator_test`, `prayer_log_entry_test`, `stream_utils_test` |
| Widget | `commute_screen_test`, `commute_verdict_card_test` | `circles_screen_test`, `member_prayer_row_test` |
| Integration | `commute_integration_test` | `community_integration_test` |

**Total suite: 116 tests** (includes Phase 1 + 2 tests)
