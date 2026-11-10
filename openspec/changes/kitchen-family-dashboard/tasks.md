# Tasks: Kitchen family dashboard

## 1. Local HTTPS

- [x] 1.1 Add a DHCP reservation in UniFi for HA at 192.168.3.5 (manual); verify: reservation listed in UniFi
- [x] 1.2 Add AAAA record `ha.mattnet.xyz` → Caddy's IPv6 in Route 53 (manual); verify: `getent ahosts ha.mattnet.xyz` returns Caddy's IPv6 — not needed: covered by existing `*.mattnet.xyz` wildcard
- [x] 1.3 Add `ha.mattnet.xyz` site to Caddy on frigate-srv3 proxying to `192.168.3.5:8123` (manual); verify: Caddy logs show a certificate issued
- [x] 1.4 In Settings → System → Network → HTTP server, enable `use_x_forwarded_for` and add trusted proxy `192.168.3.9`, restart if prompted (manual); verify: no reverse-proxy errors in the HA log when Caddy forwards a request — confirmed 2026-10-24
- [x] 1.5 Group check: `https://ha.mattnet.xyz` loads and logs in with no certificate warning from an IPv6 device; `http://homeassistant:8123` and Nabu Casa still work; TTS to `media_player.kitchen_speaker_2` plays (manual) — HTTPS, HTTP and Nabu Casa pass; TTS **SKIPPED** (user, 2026-10-24): HTTP access unchanged, low risk

## 2. Tablet OS and kiosk app

- [x] 2.1 Create the `kitchen` HA user (non-admin) and its long-lived token; verify: user logs in at `https://ha.mattnet.xyz` — local-only blocked via Caddy (client seen as public IPv6), remote login allowed
- [x] 2.2 Flash LineageOS 24.0 and MindTheGapps for Android 17 on the SM-T580 per the repo's `docs/INSTALL.md` (manual); verify: Developer options → WebView implementation shows a current version — 155.0.8059.39, 2026-10-24
- [x] 2.3 Check front camera, microphone and two-way video on a WebRTC test page (manual); verify: all work, otherwise fall back per design — work; mic needs gain 79 and autoplay must be allowed (session notes)
- [x] 2.4 Set charging to stop at ~80% (charging control, or the kernel charge threshold at boot) (manual); verify: battery holds at ~80% on charge, otherwise fall back per design — LineageOS charging control at 75%; needs a DCP wall charger (a 500 mA SDP port gives no net charge, session notes)
- [x] 2.5 Install Kiosk Satellite, start URL `https://ha.mattnet.xyz/kitchen-display/home`, sign in as `kitchen`, set admin PIN and boot start (manual); verify: tablet reboots straight into the start URL
- [x] 2.6 Add the Kiosk Satellite device in HA; verify: its screen and battery entities appear — "Kitchen Tablet" (ESPHome), entities `*.kitchen_tablet_*`
- [x] 2.7 Spike: on the tablet, a test view with `voip-stack-card` (Kitchen phone) makes a video call to the Videophone while Kiosk Satellite's wake word is on (manual); verify: two-way audio/video and the wake word still responds after the call. If not, switch to Fully Kiosk PLUS + Voice Satellite card and repeat — passed with Kiosk Satellite; auto-answer fails separately (session notes)

## 3. Calendars

- [x] 3.1 Create shared Google calendars "Kids" and "Meals" (Matt and Sara) and enter the weekly routine from the printed table as recurring events (manual); verify: visible on Matt's and Sara's phones (verified on Matt's phone; Sara's skipped by choice)
- [x] 3.2 Add the Google Calendar integration (Matt's account) with Matt's, Sara's, Kids and Meals calendars, entity IDs per design; verify: four entities with upcoming events
- [x] 3.3 Group check: an event added on a phone appears in its `calendar.*` entity within ~15 minutes

## 4. Shopping list

- [x] 4.1 Create a dedicated Google account and share the Keep "Shopping" note with it (manual); verify: note visible in that account
- [x] 4.2 Install Google Keep Sync (HACS), log in as the dedicated account, select only "Shopping", set pull interval to 5 minutes, name the entity "Shopping List" with ID `todo.shopping_list` (used by the dashboard); verify: `todo` entity lists current Keep items
- [x] 4.3 Expose the Shopping List entity to Assist; verify: `ha_get_entity_exposure` shows it exposed
- [x] 4.4 Group check: item added in HA appears in Keep on a phone; item ticked in Keep shows done in HA within 5 minutes; "add eggs to the shopping list" typed into Assist adds it to Keep; adding via Google Home still works — passed 2026-10-26 except Google Home, whose adding was already broken; out of scope

## 5. Dashboard

- [x] 5.1 Install `week-planner-card` and `navbar-card` (HACS, manual) and add both to the resources in `packages/common/dashboard.yaml`; verify: `ha core check` passes
- [x] 5.2 Register YAML dashboard `kitchen-display` (`ui-lovelace-kitchen.yaml`, not in sidebar) with kiosk-mode on for the `kitchen` user; verify: dashboard opens with no header or sidebar as `kitchen`
- [x] 5.3 Build the `home` view: full-width week planner (Matt, Sara, Kids, Meals calendars per design); verify: renders on the tablet
- [x] 5.4 Build `controls` (garage tile, downstairs mode, Leaving Home shortcut with confirmation), `garage`, `cameras`, `shopping` and `call` views per design; verify: each renders with live data
- [x] 5.5 Add the shared navbar template (Home, Controls, Garage, Cameras, Shopping, Call, Assist) to every view; verify: one tap reaches each view from each other view
- [x] 5.6 Group check: on the tablet the planner is readable from across the kitchen, scrolling and view changes are responsive (manual)

## 6. Calls and automations

- [x] 6.1 Set the Kitchen phone `auto_answer: true`, `send_video: true` with `voip_stack.set_ha_softphone_settings`; verify: settings shown on the device — on, 2026-11-07
- [x] 6.2 Add `packages/common/kitchen_display.yaml` automations switching views with `select.kitchen_tablet_dashboard_view`: garage opening → `garage`, garage closed → `home`; verify: `ha core check` passes, automations load, and selecting the already-selected view still switches the tablet
- [x] 6.3 Add the idle return-to-home automation to `packages/common/kitchen_display.yaml`; verify: tablet returns to `home` after 2 minutes untouched — controls → home after 2 min, 2026-10-26
- [x] 6.4 Switch to `show_on_ring`: install the fork's `release-test` VoIP Stack into `custom_components/voip_stack` (not through HACS) and bump the resource `?v=`, set `show_on_ring: true` on the `call` card, remove the hidden phone cards and the call-view automation; verify: phone `idle` on every view and `offline` on another dashboard, a ring opens `call` from any view, navigating away during a ring isn't overridden, auto-answer with video works after a kiosk app restart — passed with `768cd16a`, 2026-11-06 (session notes)
- [x] 6.5 Install the `release-test` version with the earlier software-encoder switch the same way and record its commit in `AGENTS.md`; verify: auto-answer after a kiosk app restart, and video from the tablet has no multi-second delay at the start of a call — passed with `f73e2373`, 2026-11-07
- [x] 6.6 Add the screen brightness helpers (`input_number.kitchen_tablet_brightness_day`, `_evening`, `_night`, set to 100/50/1%) and automation to `packages/common/kitchen_display.yaml`; verify: `ha core check` passes and changing a level sets the screen — day level 50% gave screen brightness 128/255, 2026-11-07
- [x] 6.7 Add the night screensaver automation to `packages/common/kitchen_display.yaml` and restore it after the idle return to home; verify: `ha core check` passes, the screensaver starts after 1 minute (backlight 10/255), turning the switch off or switching the view dismisses it, a brightness change doesn't, and the idle return to home leaves it active — passed 2026-11-08

## 7. Assist

- [x] 7.1 Enable the Kiosk Satellite voice satellite with the preferred pipeline and a wake word distinct from the Videophone's "Alexa"; verify: `assist_satellite` entity for the tablet is idle

## 8. Remove Route 53 IPv4 updater

- [x] 8.1 Remove `route53:` and its logger entry from `configuration.yaml`, then restart HA; verify: `ha core check` passes, no `route53` entities or log entries
- [x] 8.2 Delete the `ha` A record in Route 53 (manual); verify: `getent ahosts ha.matt-sullivan.id.au` returns only the IPv6 address
- [x] 8.3 Revoke the IAM key if unused elsewhere and remove its secrets from `secrets.yaml` (manual) — skipped

## 9. Final verification

- [x] 9.1 Always-on dashboard: Normal use (manual)
- [x] 9.2 Unattended recovery: Power restored, Home Assistant restarts (manual) — the tablet started on the dashboard by itself after the 2026-11-08 flat battery and the 2026-11-09 ROM update; with VoIP Stack `184f5f91` the phone returned to `idle` without a reload after two HA restarts (100 s and 7 s), 2026-11-11
- [x] 9.4 Navigation always available: Switch view (manual) — passed in 5.5
- [x] 9.5 Return to home view: Left on another view (manual) — passed in 6.3
- [ ] 9.6 Home controls: Garage open on the controls view, Open the garage; Leaving Home shortcut asks for confirmation (deferred: garage unavailable)
- [x] 9.7 Open Garage View: Garage opens (manual) — garage opened 2026-11-05 16:57, tablet showed `garage` within 0.1 s and `home` when it closed
- [x] 9.8 Home Cameras: Check cameras (manual)
- [x] 9.9 Hands-free Assist: Voice command, Tap to talk (manual)
- [x] 9.10 Week planner: Routine and parent event on the same day, Tonight's dinner (manual)
- [x] 9.11 Calendar edited in Google only: Event added on a phone, Tap an event (manual)
- [x] 9.12 Shopping list: Ask Assist by voice, Add on the tablet, Tick off on a phone (manual) — passed in 4.4 and in use
- [x] 9.13 Keep remains the source of the list: Sync stopped (manual)
- [ ] 9.14 Intercom: Kitchen calls Emily, Emily calls the kitchen, Videophone hangs up (deferred: needs the Videophone)
- [x] 9.15 Existing access unchanged: Existing HTTP URL, TTS to a speaker (manual)
- [ ] 9.16 Certificate renewal: tablet still loads without warning after Caddy's first renewal (deferred to the personal assistant session)
- [ ] 9.17 Battery: battery level in HA stays at or below ~80% over a week on charge (deferred to the personal assistant session)
- [x] 9.18 Screen brightness by time of day: Evening, Bedtime (manual) — light on 02:32 set 50%, off 02:35 set 1%, 2026-11-08
- [x] 9.19 Dark screen at night: Asleep, Wake on touch, Lights on, Call at night (manual); the tablet stays online overnight (`binary_sensor.kitchen_tablet_connectivity`, IPv6 default route) — dark 23:41 after the light went off, dark on `garage`, stayed dark through the idle return to home (lit ~2 s), online overnight, 2026-11-10

## 10. Wrap-up

- [x] 10.1 Update `AGENTS.md` with the kitchen dashboard, `kitchen` user, Kiosk Satellite device (`kitchen_tablet` entities), and the `ha.mattnet.xyz` / Caddy dependency; verify: reviewed
- [x] 10.2 Remove the test view from 2.7; verify: `ha core check` passes

## Workflow follow-up

- Archive the change with `openspec archive kitchen-family-dashboard`
