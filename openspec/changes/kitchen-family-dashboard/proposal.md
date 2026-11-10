# Kitchen family dashboard

Turn an old Samsung tablet in the kitchen into the family's wall display. It shows the week's calendar including the kids' activities and meal planner, with hands-free Assist, video calls to the videophone, and the shopping list. It might replace the printed routine sheets on the wall, and is a step toward tracking the kids' jobs later.

## Context

- The family routine is printed on sheets on the wall: the kids' morning jobs, afternoon/night jobs, and a weekly table of sport, tutoring, OSHC and what goes in school bags.
- Matt and Sara share a Google calendar for non-routine events. The kids' weekly routine isn't in any calendar, and there's no meal plan.
- Shopping lists are in Google Keep, used from Matt's Android phone, Sara's and Emily's iPhones, and the Google Home devices. No Google calendar or Keep list is in Home Assistant yet.
- The tablet is a Samsung Galaxy Tab A 10.1 (SM-T580, 2016, 2 GB RAM). Its last update was Android 8.1, and Chrome stopped updating on Android 8 and 9 at version 138 (2025). It will be wall-mounted in landscape on permanent power.
- A videophone in Emily's bedroom (Waveshare ESP32-P4, ESPHome) supports intercom calls. Its video is still being developed in ESPHome, outside this repo.
- Home Assistant is reached as `http://homeassistant:8123` locally and through Nabu Casa remotely. It has no local HTTPS, and browsers only allow the microphone and camera on HTTPS pages. There's probably not much using that address but it is companion app fallback and HA uses it for casting TTS to google home speakers.
- The ISP uses CGNAT, so nothing at home is reachable over IPv4 from outside. Yet Home Assistant regularly updates `ha.matt-sullivan.id.au`'s IPv4 record to the CGNAT address, which leads nowhere. That name's IPv6 record points at Home Assistant.

## Goals

- From the kitchen, the family can see the week's shared events, the kids' routine and the meals together at a glance.
- Anyone in the kitchen can use Assist by voice without touching the tablet.
- The kitchen and the videophone can video call each other in either direction.
- The family can see and change the Google Keep shopping list from the tablet and add to it by asking Assist, and keep using Keep and Google Home as they do now.
- The garage door can be checked and opened or closed from the tablet, and the cameras can be checked.
- The tablet runs unattended: it recovers from power and network loss on its own, and the kids can't leave the dashboard.
- Everything that uses `http://homeassistant:8123` today keeps working.
- `ha.matt-sullivan.id.au` no longer gets an IPv4 address that leads nowhere.

## Approach

The tablet runs a kiosk browser showing a single Home Assistant dashboard built for it: a week planner as the home view, a side column for status and calls, a few further views reached from a navigation bar that's always on screen, and pop-ups for incoming calls and Assist. The kids' routine and meals become two new shared Google calendars, and the Keep shopping list is synced into Home Assistant. The tablet reaches Home Assistant over local HTTPS through the existing Caddy reverse proxy, so the microphone and camera work, while plain HTTP stays available to everything else.

## Trade-offs and limits

- The calendar is view-only on the tablet; events are added from phones in Google Calendar, where Matt and Sara already manage them.
- The kids' job checklists, what goes in school bags, and rewards aren't part of this change; they're planned for a later one.
- Meals are only calendar events: there are no recipes or ingredient lists.
- The screen is always on, which costs power, and the battery must be managed to keep it from swelling on permanent charge.
- If the tablet proves too slow, features are cut rather than replacing it, starting with the heaviest (video, then hands-free voice).
- The tablet's HTTPS access depends on the frigate-srv3 VM, which runs Caddy, and on the ISP's IPv6 prefix. The tablet's camera views already depend on that VM. That's easier and less setup than letsencrypt and nginx HA addons.
- The Keep sync is a community integration, and changes made in Keep reach the tablet only every few minutes.

## Capabilities

- `kitchen-display` (new)
- `family-calendar` (new)
- `shopping-lists` (new)
- `intercom` (new)
- `local-https-access` (new)
