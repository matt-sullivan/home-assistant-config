# Design: Kitchen family dashboard

## Technical context

- The Kitchen tablet is already a VoIP Stack (esphome-intercom, `custom_components/voip_stack`) softphone device "Kitchen", with `sensor.home_call_state` (`idle`, `ringing`, `in_call`, …) and `event.home_call`. Auto-answer and camera sending are per-phone settings (`voip_stack.set_ha_softphone_settings`); auto-answer only works when an attached browser has microphone permission. The `voip-stack-card` must be loaded in the page to attach the browser to the phone, and takes `device_id` to pick the phone.
- Dashboards are YAML-mode, registered in `packages/common/dashboard.yaml` with resources listed there (`resource_mode: yaml`). `kiosk-mode` (hides header and sidebar), `advanced-camera-card` and `button-card` are already installed through HACS.
- Cameras come from the Frigate integration (`camera.downstairs`, `camera.footpath`, `camera.frontyard`, `camera.upstairs`), served by frigate-srv3 (192.168.3.9), which also runs Caddy in Docker.
- Entities used on the home view: `cover.garage_door`, `input_select.downstairs_mode`, `script.leaving_home` (turns everything off and opens the garage).
- Google Keep Sync (HACS, `watkins-matt/home-assistant-google-keep-sync`) authenticates with a Google master token whose scope can't be limited, creates a `todo` entity per selected list, pushes HA edits to Keep immediately per item, and pulls from Keep every 15 minutes by default (configurable). If an item is edited in both places between pulls, the HA edit wins.
- The Google Calendar integration refreshes events from Google about every 15 minutes; it isn't push.
- Browser Mod 3.x (requires HA 2026.10, installed is 2026.10.2) can target a registered browser with `browser_mod.navigate`, `browser_mod.popup` and `browser_mod.javascript`.
- `week-planner-card` (HACS) shows N day columns with per-calendar colours, a legend, an event detail popup, and refreshes from HA every 60 s by default.
- SM-T580 custom ROMs (codename `gtaxlwifi`, all unofficial):
  - LineageOS 24.0 / Android 17 (GitHub `alessandro-fontana/gtaxlwifi-lineageos`, 2026-10-16, 2026-10-01 patch level): mainline Linux 7.2 kernel; both cameras, internal mic, Wi-Fi and hardware H.264/HEVC/VP8 encode and decode work; wired-headset mic doesn't. No charge limit documented. Single developer, releases since early Oct 2026; updates are sideloaded from recovery (the built-in Updater only sees official builds); MindTheGapps for Android 17 installs from recovery. Install repartitions the tablet.
  - LineageOS 19.1 / Android 12L (XDA, long-running): reportedly has LineageOS charging control; last update date unconfirmed.
  - /e/OS Android 14 (community, build 2026-08).
- HA currently has no `http:` section and a YAML `route53:` integration updating the `ha` A record in `matt-sullivan.id.au`; its AWS keys are in `secrets.yaml`.

## Decisions

### Flash LineageOS 24.0 with Google Play services
The tablet runs the unofficial LineageOS 24.0 with MindTheGapps, so Android System WebView and the kiosk app update from the Play Store. It's the only build with the camera, internal mic and hardware video encoding all documented as working, which video calls need, and it's current. Straight after flashing, check camera, mic, a WebRTC test page and whether a charge limit is available (see the battery decision). ROM updates are sideloaded by hand every few months.
- **Alternative:** stay on stock Android 8.1 — rejected because the WebView no longer updates.
- **Alternative:** LineageOS 19.1 — fallback if 24.0 is unstable or can't limit charging; not first choice because its camera, mic and video encoding status isn't confirmed and it's an older base.
- **Alternative:** /e/OS Android 14 — rejected because it ships microG instead of Play, so the WebView needs side-loading, and it has no advantage for this use.
- **Alternative:** no Play services — rejected because the system WebView would only update with ROM builds.

### Kiosk Satellite as kiosk app, Fully Kiosk PLUS as fallback
Kiosk Satellite provides the full-screen lockdown, boot start, the HA device (screen, battery sensor) and a native Voice Satellite with on-device wake word. It's chosen if, on the tablet, the dashboard's `voip-stack-card` gets camera and microphone access while the wake word is listening. Otherwise use Fully Kiosk Browser with a PLUS licence (~€9) plus the Voice Satellite integration (HACS) for in-page wake word.
- **Alternative:** HA Companion app — rejected because it can't lock the tablet to the dashboard.
- **Alternative:** wake word processed on the HA server (openWakeWord app) — not needed; both options detect on the tablet, and streaming audio continuously costs more. Revisit only if on-device detection is too slow on the tablet.

### Dedicated non-admin HA user for the tablet
A `kitchen` HA user (non-admin, local-only) logs in on the tablet and owns the kiosk app's long-lived token. Kiosk-mode applies by user, so other users keep the normal UI if they open the dashboard.
- **Alternative:** Matt's account — rejected because an unattended wall device would have admin rights.

### One YAML dashboard with a shared navigation bar
New YAML dashboard `kitchen-display` (`ui-lovelace-kitchen.yaml`, not in the sidebar), registered in `packages/common/dashboard.yaml`. Views:
- `home` (`sidebar` type): week planner as main content; side column with `cover.garage_door` tile (`cover-open-close` feature), `input_select.downstairs_mode` tile (`select-options`), a Leaving Home shortcut with confirmation, the `voip-stack-card` (Kitchen phone) and today's weather.
- `garage` (subview): `camera.footpath` and `camera.frontyard` (`advanced-camera-card`) and the garage door tile.
- `cameras`: `advanced-camera-card` with the Frigate cameras.
- `shopping`: built-in to-do list card for the Keep list.
- `call` (`panel`): `voip-stack-card` for the Kitchen phone, full screen for video.

`navbar-card` (HACS) gives the always-visible navigation (side rail on a landscape tablet) with Home, Cameras, Shopping, Call and an Assist action; it's defined once in a YAML file included into each view. Kiosk-mode hides the HA header and sidebar for the `kitchen` user.
- **Alternative:** a storage-mode dashboard — rejected to match the repo's YAML dashboards tracked in git.
- **Alternative:** everything on one view — rejected because a readable 7-day planner needs most of a 10" landscape screen.

### Week planner from three Google calendars
The official Google Calendar integration (Matt's account) adds the existing shared family calendar and two new shared calendars, "Kids" and "Meals". `week-planner-card` shows 7 days starting today with a colour per calendar and a legend; tapping an event opens its detail popup. Changes reach the tablet after the integration's next refresh (up to ~15 minutes).
- **Alternative:** built-in calendar card — rejected because its week view is a time grid that doesn't fit all-day items and is hard to read at a distance.
- **Alternative:** `startingDay: monday` — rejected because past days would use half the screen late in the week.

### Keep shopping list through Google Keep Sync with a dedicated Google account
A dedicated Google account is added as a collaborator on the Keep "Shopping" note, and Google Keep Sync logs in as that account with only that list selected. The pull interval is lowered from 15 to 5 minutes. The `todo` entity is named "Shopping List" and exposed to Assist, so the built-in "add X to the shopping list" intent writes to it.
- **Alternative:** Matt's own account — rejected because the master token can't be scoped and would expose his whole Google account.
- **Alternative:** a custom intent or script for adding items — not needed; the built-in list intent targets to-do entities by name.

### Navigation driven by Browser Mod automations
The tablet's browser is registered in Browser Mod as `kitchen`. Automations in a new `packages/common/kitchen_display.yaml`:
- garage starts opening → navigate to `garage`; garage closed → navigate to `home`;
- `sensor.home_call_state` becomes `ringing` or `in_call` → navigate to `call`; becomes `idle` → `browser_mod.javascript` `history.back()` to return to the previous view.

Returning to `home` after inactivity uses the kiosk app's idle "go to start URL" setting (2 minutes).
- **Alternative:** the kiosk app's load-URL action — rejected because it reloads the whole frontend, which is slow on this tablet, and isn't available if the kiosk app changes.
- **Alternative:** conditional cards on every view — rejected because a full-screen video call needs its own view.

### Kitchen phone auto-answers with video
`voip_stack.set_ha_softphone_settings` on the Kitchen phone: `auto_answer: true`, `send_video: true`. The card on the `home` and `call` views keeps the browser attached so calls ring and auto-answer on any view.
- **Alternative:** answer prompt — replaced by the delta spec's auto-answer requirement.

### Local HTTPS through Caddy at `ha.mattnet.xyz`
Caddy on frigate-srv3 serves `ha.mattnet.xyz` with its existing Route 53 DNS-01 certificate setup and proxies to `http://192.168.3.5:8123` (websockets pass through). `ha.mattnet.xyz` gets an AAAA record pointing at Caddy's IPv6 address. HA gets an `http:` section in `configuration.yaml` (root-level, required there): `use_x_forwarded_for: true`, `trusted_proxies: [192.168.3.9]`. HA's internal URL stays `http://homeassistant.local:8123`; only the tablet uses the HTTPS name. HA's IP gets a DHCP reservation in UniFi (frigate-srv3's is already fixed).
- **Alternative:** HA serving HTTPS itself — rejected because 8123 would become HTTPS-only, breaking HTTP access and TTS casting, and every renewal needs an HA restart.
- **Alternative:** NGINX SSL proxy and Let's Encrypt apps on HA — rejected as two more apps to maintain when Caddy already does this.
- **Alternative:** IPv6 upstream and IPv6 trusted proxy — rejected because the ISP prefix can change, and IPv4 avoids Docker IPv6 setup.

### Remove the Route 53 IPv4 updater
Delete the `route53:` block and its `logger` entry from `configuration.yaml` and its secrets from `secrets.yaml`; delete the `ha` A record in Route 53; revoke the IAM key if unused elsewhere.

### Charge limit set on the tablet
The tablet stops charging at about 80% using LineageOS charging control (Settings → Battery) if 24.0 offers it, otherwise by writing the kernel's charge-limit setting (`charge_control_end_threshold`) at boot if the mainline kernel exposes it for this battery. The kiosk app's battery sensor in HA shows it holding.
- **Alternative:** smart plug switched by an HA automation — rejected to avoid another device and an HA dependency for charging.
- **Alternative:** permanent charging to 100% — rejected because of battery swelling.

## Risks

- **LineageOS 24.0 unstable, or its single developer stops** → it keeps working as installed; LineageOS 19.1 is the fallback, then stock with Odin and cut video.
- **No charge limit on 24.0** → try LineageOS 19.1's charging control; if neither works, decide then between a smart plug and accepting the swelling risk.
- **Tablet too slow for planner, video and wake word together** → cut video first, then hands-free voice (tap-to-talk remains), per the proposal.
- **Kiosk Satellite's wake word and the call card can't share the microphone** → fall back to Fully Kiosk PLUS with the Voice Satellite card; if the same conflict appears there, pause the wake word during calls.
- **Keep edit lost when edited in Keep and on the tablet between pulls** → 5-minute pull interval makes it rare. Accepted.
- **Google master token revoked or expires** → the integration raises a repair; the list keeps working in Keep and Google Home.
- **`history.back()` lands on an unexpected view after a call** → acceptable; the idle timer returns to `home`.
- **ISP changes the IPv6 prefix** → the tablet loses HTTPS until the AAAA record is updated; Nabu Casa URL works as a temporary start URL.
- **VoIP Stack and Kiosk Satellite are fast-moving** → pin known-good versions and check release notes before updating.

