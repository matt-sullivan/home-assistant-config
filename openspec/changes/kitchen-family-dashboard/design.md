# Design: Kitchen family dashboard

## Technical context

- The Kitchen tablet is already a VoIP Stack (esphome-intercom, `custom_components/voip_stack`) softphone device "Kitchen", with `sensor.home_call_state` (`idle`, `ringing`, `in_call`, …) and `event.home_call`. Auto-answer and camera sending are per-phone settings (`voip_stack.set_ha_softphone_settings`); auto-answer only works when an attached browser has microphone permission. The `voip-stack-card` attaches the browser to the phone and takes `device_id` to pick the phone. With `show_on_ring: true` (one card per dashboard), the phone stays online on every view of the card's dashboard, goes offline when the browser leaves it, and the dashboard opens the card's view when the phone rings, once per call. `show_on_ring`, auto-answer after a WebView reload and the camera encoder's software fallback are in the `release-test` branch of the fork `matt-sullivan/esphome-intercom` (VoIP Stack 2026.11.0 plus those commits), not yet in a release.
- Dashboards are YAML-mode, registered in `packages/common/dashboard.yaml`. Resources are in storage mode, so HACS and VoIP Stack register them with version stamps that change on update; `frontend: extra_module_url` loads kiosk-mode and card-mod. `kiosk-mode` (hides header and sidebar), `advanced-camera-card` and `button-card` are already installed through HACS.
- Cameras come from the Frigate integration (`camera.downstairs`, `camera.footpath`, `camera.frontyard`, `camera.upstairs`), served by frigate-srv3 (192.168.3.9), which also runs Caddy in Docker.
- Entities used on the controls view: `cover.garage_door`, `input_select.downstairs_mode`, `script.leaving_home` (turns everything off and opens the garage).
- Google Keep Sync (HACS, `watkins-matt/home-assistant-google-keep-sync`) authenticates with a Google master token whose scope can't be limited, creates a `todo` entity per selected list, pushes HA edits to Keep immediately per item, and pulls from Keep every 15 minutes by default (configurable). If an item is edited in both places between pulls, the HA edit wins.
- The Google Calendar integration refreshes events from Google about every 15 minutes; it isn't push.
- Kiosk Satellite exposes `select.kitchen_tablet_dashboard_view`, whose options are the dashboards' views (e.g. `kitchen-display/garage`); selecting one switches the view without reloading the frontend (verified on the tablet). `sensor.kitchen_tablet_current_page` is the full URL of the page shown.
- `week-planner-card` (HACS) shows N day columns with per-calendar colours, a legend, an event detail popup, and refreshes from HA every 60 s by default.
- SM-T580 custom ROMs (codename `gtaxlwifi`, all unofficial):
  - LineageOS 24.0 / Android 17 (GitHub `alessandro-fontana/gtaxlwifi-lineageos`, 2026-10-16, 2026-10-01 patch level): mainline Linux 7.2 kernel; both cameras, internal mic, Wi-Fi and hardware H.264/HEVC/VP8 encode and decode work; wired-headset mic doesn't. No charge limit documented. Single developer, releases since early Oct 2026; updates are sideloaded from recovery (the built-in Updater only sees official builds); MindTheGapps for Android 17 installs from recovery. Install repartitions the tablet.
  - LineageOS 19.1 / Android 12L (XDA, long-running): reportedly has LineageOS charging control; last update date unconfirmed.
  - /e/OS Android 14 (community, build 2026-08).
- HA currently has no `http:` section and a YAML `route53:` integration updating the `ha` A record in `matt-sullivan.id.au`; its AWS keys are in `secrets.yaml`.

## Decisions

### Flash LineageOS 24.0 with Google Play services
The tablet runs the unofficial LineageOS 24.0 with MindTheGapps, so the kiosk app updates from the Play Store. The ROM's own WebView is the only accepted provider, so WebView updates come with ROM builds. It's the only build with the camera, internal mic and hardware video encoding all documented as working, which video calls need, and it's current. Straight after flashing, check camera, mic, a WebRTC test page and whether a charge limit is available (see the battery decision). ROM updates (including WebView) are sideloaded by hand every few months.
- **Alternative:** stay on stock Android 8.1 — rejected because the WebView no longer updates.
- **Alternative:** LineageOS 19.1 — fallback if 24.0 is unstable or can't limit charging; not first choice because its camera, mic and video encoding status isn't confirmed and it's an older base.
- **Alternative:** /e/OS Android 14 — rejected because it ships microG instead of Play, so the WebView needs side-loading, and it has no advantage for this use.
- **Alternative:** no Play services — rejected because Play keeps the kiosk app and Google apps updated.

### Kiosk Satellite as kiosk app, Fully Kiosk PLUS as fallback
Kiosk Satellite provides the full-screen kiosk, boot start, the HA device (screen, battery sensor) and a native Voice Satellite with on-device wake word. It's chosen if, on the tablet, the dashboard's `voip-stack-card` gets camera and microphone access while the wake word is listening. Otherwise use Fully Kiosk Browser with a PLUS licence (~€9) plus the Voice Satellite integration (HACS) for in-page wake word.
- **Alternative:** HA Companion app — rejected because it can't lock the tablet to the dashboard.
- **Alternative:** wake word processed on the HA server (openWakeWord app) — not needed; both options detect on the tablet, and streaming audio continuously costs more. Revisit only if on-device detection is too slow on the tablet.

### Dedicated non-admin HA user for the tablet
A `kitchen` HA user (non-admin; remote login allowed, because through Caddy HA sees the tablet's public IPv6 address and a local-only user is blocked) logs in on the tablet and owns the kiosk app's long-lived token. Kiosk-mode applies by user, so other users keep the normal UI if they open the dashboard.
- **Alternative:** Matt's account — rejected because an unattended wall device would have admin rights.

### Low-resolution camera streams for the tablet
Frigate's go2rtc restreams each camera as `<name>_540p` (960×540 H.264, 10 fps) at `rtsp://192.168.3.9:8554/<name>_540p`. Generic Camera entities `camera.<name>_540p` use them; HA's built-in go2rtc pulls the RTSP stream and serves WebRTC to the tablet. The tablet uses them for all live video; snapshots stay on the Frigate integration's cameras.
- **Alternative:** the Frigate 4K HEVC main streams — rejected: software decode exhausts video memory and leaks it when the app is killed, hardware decode stalls.
- **Alternative:** the Frigate integration's `rtsp_url_template` — rejected because it would make every dashboard's live view low resolution.
- **Alternative:** `advanced-camera-card` with Frigate's go2rtc through the Frigate integration's proxy — rejected as too complex and flaky for a kiosk.

### One YAML dashboard with a shared navigation bar
New YAML dashboard `kitchen-display` (`ui-lovelace-kitchen.yaml`, not in the sidebar), registered in `packages/common/dashboard.yaml`. Views:
- `home` (`panel`): week planner across the full width.
- `controls`: `cover.garage_door` tile (`cover-open-close` feature), `input_select.downstairs_mode` tile (`select-options`) and a Leaving Home shortcut with confirmation.
- `garage` (panel, in the navbar): `camera.footpath_540p` and `camera.frontyard_540p` live (`picture-entity`) and the garage door tile.
- `cameras`: the four Frigate cameras as `picture-entity` cards in a 2×2 grid showing snapshots (`camera_view: auto`); tapping one opens the live dialog of its `_540p` camera, so only one stream plays. No more than two live streams at once: the hardware decoder allows four instances and view changes or a call need spare ones.
- `shopping`: built-in to-do list card for the Keep list.
- `call` (`panel`): `voip-stack-card` for the Kitchen phone with `show_on_ring: true`; the dashboard's only phone card. A card-mod rule on its vertical stack stretches it to the view height, and the card scales video to fit without cropping.

`show_on_ring` keeps the Kitchen phone online on every view and opens `call` when it rings.
- **Alternative:** a hidden phone card on every other view (`button-card` template with `display: none`) plus an automation selecting `call` on ring — replaced by `show_on_ring`; it needs a card copy per view, and the view switch waits for HA.
- **Alternative:** a visible phone card on every view — rejected as clutter; calls start from the navbar's Call button.

`navbar-card` (HACS) gives the always-visible navigation (side rail on a landscape tablet) with Home, Controls, Garage, Cameras, Shopping, Call and an Assist action; it's defined once as a `navbar-templates` entry in the dashboard file and each view adds a `navbar-card` using that template (in `panel` views, stacked with the main card, since a panel shows only one card). Kiosk-mode hides the HA header and sidebar for the `kitchen` user.
- **Alternative:** a storage-mode dashboard — rejected to match the repo's YAML dashboards tracked in git.
- **Alternative:** everything on one view — rejected because a readable 7-day planner needs most of a 10" landscape screen.

### Week planner from four Google calendars
The official Google Calendar integration (Matt's account) adds Matt's and Sara's own calendars (shared with Matt; there's no family calendar) and two new shared calendars, "Kids" and "Meals", as `calendar.matt`, `calendar.sara`, `calendar.kids` and `calendar.meals`. `week-planner-card` shows 7 days starting today with a colour per calendar, a legend, an icon for Meals events and a weather condition icon per day; day headings show only the weekday name (`dayFormat`; the card has no option for weekday without the date number), and all-day events show no "Entire day" label; tapping an event opens its detail popup. Changes reach the tablet after the integration's next refresh (up to ~15 minutes).
- **Alternative:** built-in calendar card — rejected because its week view is a time grid that doesn't fit all-day items and is hard to read at a distance.
- **Alternative:** `startingDay: monday` — rejected because past days would use half the screen late in the week.

### Keep shopping list through Google Keep Sync with a dedicated Google account
A dedicated Google account is added as a collaborator on the Keep "Shopping" note, and Google Keep Sync logs in as that account with only that list selected. The pull interval is lowered from 15 to 5 minutes. The `todo` entity is named "Shopping List" and exposed to Assist, so the built-in "add X to the shopping list" intent writes to it.
- **Alternative:** Matt's own account — rejected because the master token can't be scoped and would expose his whole Google account.
- **Alternative:** a custom intent or script for adding items — not needed; the built-in list intent targets to-do entities by name.

### Navigation driven by Kiosk Satellite from automations
Automations in a new `packages/common/kitchen_display.yaml` switch views with `select.kitchen_tablet_dashboard_view`:
- garage starts opening (`garage_door.opened`) → `kitchen-display/garage`; garage closed → `kitchen-display/home` if the garage view is still shown; neither during a call;
- 2 minutes after the last touch (`sensor.kitchen_tablet_last_interaction`) or view change → `kitchen-display/home`, except during a call or while the garage view shows an open garage. Kiosk Satellite has no idle-return setting. This is also how the tablet leaves `call` after a call.
- **Alternative:** return to the view shown before the call as soon as it ends (an automation, or a return option in `show_on_ring`) — rejected for simplicity; the idle return covers it. Reconsider a card option if upstream accepts `show_on_ring`.
- **Alternative:** Browser Mod (`browser_mod.navigate`, `history.back()`) — rejected because Kiosk Satellite already switches views without reloading, and it would be another integration to maintain and load on the tablet.
- **Alternative:** the kiosk app's load-URL action — rejected because it reloads the whole frontend, which is slow on this tablet, and isn't available if the kiosk app changes.
- **Alternative:** conditional cards on every view — rejected because a full-screen video call needs its own view.

### Kitchen phone auto-answers with video
`voip_stack.set_ha_softphone_settings` on the Kitchen phone: `auto_answer: true`, `send_video: true`. `show_on_ring` keeps the browser attached so calls ring and auto-answer on any view.
- **Alternative:** answer prompt — replaced by the delta spec's auto-answer requirement.

### Local HTTPS through Caddy at `ha.mattnet.xyz`
Caddy on frigate-srv3 serves `ha.mattnet.xyz` with its existing Route 53 DNS-01 certificate setup and proxies to `http://192.168.3.5:8123` (websockets pass through). `ha.mattnet.xyz` gets an AAAA record pointing at Caddy's IPv6 address. HA's HTTP server settings (Settings → System → Network; YAML `http:` is ignored since 2026.8) get `use_x_forwarded_for` on and trusted proxy `192.168.3.9`. HA's internal URL stays `http://homeassistant.local:8123`; only the tablet uses the HTTPS name. HA's IP gets a DHCP reservation in UniFi (frigate-srv3's is already fixed).
- **Alternative:** HA serving HTTPS itself — rejected because 8123 would become HTTPS-only, breaking HTTP access and TTS casting, and every renewal needs an HA restart.
- **Alternative:** NGINX SSL proxy and Let's Encrypt apps on HA — rejected as two more apps to maintain when Caddy already does this.
- **Alternative:** IPv6 upstream and IPv6 trusted proxy — rejected because the ISP prefix can change, and IPv4 avoids Docker IPv6 setup.

### Remove the Route 53 IPv4 updater
Delete the `route53:` block and its `logger` entry from `configuration.yaml`, and the `ha` A record in Route 53. The AWS key and its secrets are kept.

### Charge limit set on the tablet
The tablet stops charging at about 80% using LineageOS charging control (Settings → Battery) if 24.0 offers it, otherwise by writing the kernel's charge-limit setting (`charge_control_end_threshold`) at boot if the mainline kernel exposes it for this battery. The kiosk app's battery sensor in HA shows it holding.
- **Alternative:** smart plug switched by an HA automation — rejected to avoid another device and an HA dependency for charging.
- **Alternative:** permanent charging to 100% — rejected because of battery swelling.

### Screen brightness by time of day
An automation in `packages/common/kitchen_display.yaml` sets `light.kitchen_tablet_screen` (`brightness_pct`) from three `input_number` helpers in the same package: `kitchen_tablet_brightness_day` (100%) while the sun is up, `kitchen_tablet_brightness_evening` (50%) after sunset while `light.kitchen` is on, and `kitchen_tablet_brightness_night` (1%) after sunset with it off. 1% is the lowest Kiosk Satellite sets from HA (backlight 13/255); Android's own slider goes down to 1/255. It runs at sunrise and sunset, when `light.kitchen` or a level changes, when the screen entity comes back and when HA starts.
- **Alternative:** brightness by presence — no kitchen presence sensor exists, and the tablet camera's motion detection costs CPU, RAM and power. Revisit if a mmWave sensor is added.
- **Alternative:** Kiosk Satellite's adaptive brightness — rejected because it follows room light, not chosen levels per time of day.
- **Alternative:** brighten on touch at night — not needed.

### Dark screen at night
`kitchen_tablet_night_screensaver` turns on `switch.kitchen_tablet_screensaver` (mode Black, screensaver brightness 0, `number.kitchen_tablet_screensaver_timeout` 60 s) while the sun is down, `light.kitchen` is off and `sensor.home_call_state` is `offline` or `idle`, and turns it off otherwise. Turning it off dismisses an active screensaver. The screensaver shows black at Android's minimum backlight (10/255); the display, touch and the app's wake lock stay on, so a touch dismisses it. A view change from `select.kitchen_tablet_dashboard_view` also dismisses it (the garage view), so the idle return to home turns it back on with `switch.kitchen_tablet_screensaver_active` when it was active. Brightness changes from HA don't dismiss it.
- **Alternative:** turning the display off — rejected: the touchscreen driver (`stmfts`) has no tap-to-wake and Android ignores touches while non-interactive, and if the tablet suspends, Wi-Fi disconnects (no WoWLAN on the QCA9377 firmware).
- **Alternative:** backlight 0 through root sysfs — Android rewrites it on its next brightness change.

## Risks

- **LineageOS 24.0 unstable, or its single developer stops** → it keeps working as installed; LineageOS 19.1 is the fallback, then stock with Odin and cut video.
- **No charge limit on 24.0** → try LineageOS 19.1's charging control; if neither works, decide then between a smart plug and accepting the swelling risk.
- **Tablet too slow for planner, video and wake word together** → cut video first, then hands-free voice (tap-to-talk remains), per the proposal.
- **Kiosk Satellite's wake word and the call card can't share the microphone** → fall back to Fully Kiosk PLUS with the Voice Satellite card; if the same conflict appears there, pause the wake word during calls.
- **Keep edit lost when edited in Keep and on the tablet between pulls** → 5-minute pull interval makes it rare. Accepted.
- **Google master token revoked or expires** → the integration raises a repair; the list keeps working in Keep and Google Home.
- **A ROM leak crashes the kiosk app after long video** → the ROM must be 24.0-20261108 or later (gralloc fd leak fixed); no scheduled restart unless another leak is found.
- **`show_on_ring` isn't accepted upstream** → keep running the fork, installed by hand rather than through HACS; or restore the hidden phone cards and call-view automation from git history.
- **Fallback to Fully Kiosk** → navigation needs Browser Mod, since Fully has no view select.
- **ISP changes the IPv6 prefix** → the tablet loses HTTPS until the AAAA record is updated; Nabu Casa URL works as a temporary start URL.
- **VoIP Stack and Kiosk Satellite are fast-moving** → pin known-good versions and check release notes before updating.

