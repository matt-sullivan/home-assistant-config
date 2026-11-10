# Tasks: Kitchen family dashboard

## 1. Local HTTPS

- [ ] 1.1 Add a DHCP reservation in UniFi for HA at 192.168.3.5 (manual); verify: reservation listed in UniFi
- [ ] 1.2 Add AAAA record `ha.mattnet.xyz` → Caddy's IPv6 in Route 53 (manual); verify: `getent ahosts ha.mattnet.xyz` returns Caddy's IPv6
- [ ] 1.3 Add `ha.mattnet.xyz` site to Caddy on frigate-srv3 proxying to `192.168.3.5:8123` (manual); verify: Caddy logs show a certificate issued
- [ ] 1.4 Add `http:` with `use_x_forwarded_for: true` and `trusted_proxies: [192.168.3.9]` to `configuration.yaml`, then restart HA; verify: `ha core check` passes and HA starts
- [ ] 1.5 Group check: `https://ha.mattnet.xyz` loads and logs in with no certificate warning from an IPv6 device; `http://homeassistant:8123` and Nabu Casa still work; TTS to `media_player.kitchen_speaker_2` plays (manual)

## 2. Tablet OS and kiosk app

- [ ] 2.1 Create the `kitchen` HA user (non-admin, local only) and its long-lived token; verify: user logs in at `https://ha.mattnet.xyz`
- [ ] 2.2 Flash LineageOS 24.0 and MindTheGapps for Android 17 on the SM-T580 per the repo's `docs/INSTALL.md`, update Android System WebView from Play (manual); verify: WebView version is current
- [ ] 2.3 Check front camera, microphone and two-way video on a WebRTC test page (manual); verify: all work, otherwise fall back per design
- [ ] 2.4 Set charging to stop at ~80% (charging control, or the kernel charge threshold at boot) (manual); verify: battery holds at ~80% on charge, otherwise fall back per design
- [ ] 2.5 Install Kiosk Satellite, start URL `https://ha.mattnet.xyz/kitchen-display/home`, sign in as `kitchen`, set admin PIN, boot start and lockdown (manual); verify: tablet reboots straight into the start URL
- [ ] 2.6 Add the Kiosk Satellite device in HA; verify: its screen and battery entities appear
- [ ] 2.7 Install Browser Mod (HACS), register the tablet's browser as `kitchen`; verify: `browser_mod.navigate` from Developer Tools changes the tablet's page
- [ ] 2.8 Spike: on the tablet, a test view with `voip-stack-card` (Kitchen phone) makes a video call to the Videophone while Kiosk Satellite's wake word is on (manual); verify: two-way audio/video and the wake word still responds after the call. If not, switch to Fully Kiosk PLUS + Voice Satellite card and repeat

## 3. Calendars

- [ ] 3.1 Create shared Google calendars "Kids" and "Meals" (Matt and Sara) and enter the weekly routine from the printed table as recurring events (manual); verify: visible on Matt's and Sara's phones
- [ ] 3.2 Add the Google Calendar integration (Matt's account) with the family, Kids and Meals calendars; verify: three `calendar.*` entities with upcoming events
- [ ] 3.3 Group check: an event added on a phone appears in its `calendar.*` entity within ~15 minutes

## 4. Shopping list

- [ ] 4.1 Create a dedicated Google account and share the Keep "Shopping" note with it (manual); verify: note visible in that account
- [ ] 4.2 Install Google Keep Sync (HACS), log in as the dedicated account, select only "Shopping", set pull interval to 5 minutes, name the entity "Shopping List"; verify: `todo` entity lists current Keep items
- [ ] 4.3 Expose the Shopping List entity to Assist; verify: `ha_get_entity_exposure` shows it exposed
- [ ] 4.4 Group check: item added in HA appears in Keep on a phone; item ticked in Keep shows done in HA within 5 minutes; "add eggs to the shopping list" typed into Assist adds it to Keep; adding via Google Home still works

## 5. Dashboard

- [ ] 5.1 Install `week-planner-card` and `navbar-card` (HACS) and add both to the resources in `packages/common/dashboard.yaml`; verify: `ha core check` passes
- [ ] 5.2 Register YAML dashboard `kitchen-display` (`ui-lovelace-kitchen.yaml`, not in sidebar) with kiosk-mode on for the `kitchen` user; verify: dashboard opens with no header or sidebar as `kitchen`
- [ ] 5.3 Build the `home` view: week planner (Kids, Meals, family calendars, colours, legend, 7 days from today) and side column (garage tile, downstairs mode, Leaving Home shortcut with confirmation, `voip-stack-card` for the Kitchen phone, weather); verify: renders on the tablet
- [ ] 5.4 Build `garage`, `cameras`, `shopping` and `call` views per design; verify: each renders with live data
- [ ] 5.5 Add the shared navbar include to every view (Home, Cameras, Shopping, Call, Assist); verify: one tap reaches each view from each other view
- [ ] 5.6 Group check: on the tablet the planner is readable from across the kitchen, scrolling and view changes are responsive (manual)

## 6. Calls and automatic navigation

- [ ] 6.1 Set the Kitchen phone `auto_answer: true`, `send_video: true` with `voip_stack.set_ha_softphone_settings`; verify: settings shown on the device
- [ ] 6.2 Add `packages/common/kitchen_display.yaml` automations: garage opening → `garage` view, garage closed → `home`; call ringing/in_call → `call` view, idle → `history.back()`; verify: `ha core check` passes and automations load
- [ ] 6.3 Set the kiosk app's idle timeout to return to the start URL after 2 minutes; verify: tablet returns to `home` after 2 minutes untouched

## 7. Assist

- [ ] 7.1 Enable the Kiosk Satellite voice satellite with the preferred pipeline and a wake word distinct from the Videophone's "Alexa"; verify: `assist_satellite` entity for the tablet is idle

## 8. Remove Route 53 IPv4 updater

- [ ] 8.1 Remove `route53:` and its logger entry from `configuration.yaml` and its secrets from `secrets.yaml`, then restart HA; verify: `ha core check` passes, no `route53` entities or log entries
- [ ] 8.2 Delete the `ha` A record in Route 53 and revoke the IAM key if unused elsewhere (manual); verify: `getent ahosts ha.matt-sullivan.id.au` returns only the IPv6 address

## 9. Final verification

- [ ] 9.1 Always-on dashboard: Normal use (manual)
- [ ] 9.2 Unattended recovery: Power restored, Home Assistant restarts (manual)
- [ ] 9.3 Locked to the dashboard: Kid tries to exit (manual)
- [ ] 9.4 Navigation always available: Switch view (manual)
- [ ] 9.5 Return to home view: Left on another view (manual)
- [ ] 9.6 Home status: Garage open on the home view, Open the garage; Leaving Home shortcut asks for confirmation (manual)
- [ ] 9.7 Open Garage View: Garage opens (manual)
- [ ] 9.8 Home Cameras: Check cameras (manual)
- [ ] 9.9 Hands-free Assist: Voice command, Tap to talk (manual)
- [ ] 9.10 Week planner: Routine and family event on the same day, Tonight's dinner (manual)
- [ ] 9.11 Calendar edited in Google only: Event added on a phone, Tap an event (manual)
- [ ] 9.12 Shopping list: Ask Assist by voice, Add on the tablet, Tick off on a phone (manual)
- [ ] 9.13 Keep remains the source of the list: Sync stopped (manual)
- [ ] 9.14 Intercom: Kitchen calls Emily, Emily calls the kitchen, Videophone hangs up (manual; needs Videophone video firmware, audio only until then)
- [ ] 9.15 Existing access unchanged: Existing HTTP URL, TTS to a speaker (manual)
- [ ] 9.16 Certificate renewal: tablet still loads without warning after Caddy's first renewal (deferred)
- [ ] 9.17 Battery: battery level in HA stays at or below ~80% over a week on charge (deferred)

## 10. Wrap-up

- [ ] 10.1 Update `AGENTS.md` with the kitchen dashboard, `kitchen` user, Browser Mod browser ID, and the `ha.mattnet.xyz` / Caddy dependency; verify: reviewed
- [ ] 10.2 Remove the test view from 2.8; verify: `ha core check` passes

## Workflow follow-up

- Archive the change with `openspec archive kitchen-family-dashboard`
