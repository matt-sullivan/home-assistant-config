# Testing
Maintain a list of devices and features that need to be tested physically after devices are flashed

## Test Items
- [x] hallway-stairs (CB3S board, stairs rewired to ch1): bottom (ch2) LED follows Landing state (press here, at pool room, and from HA)
- [x] hallway-stairs: bottom press toggles Landing; top press toggles internal stairs lamp, pooltable-stairs ch1 reports it
- [x] hallway-stairs: top (ch1) LED follows the sensed stairs lamp state, from either switch
- [x] hallway-stairs: Power Status 1 Edges stays 0 with the stairs lamp steady (ch1 sense parts now on the stairs travellers)
- [x] media room remote: from each starting state (both off, both on, only Door, only Interior), a press gives both off if either was on, else both on; HA Door/Interior match the lamps
- [x] lights-media-room: each button and HA command changes only its own lamp
- [x] lights-media-room: HA on/off in the current state changes nothing
- [x] lights-media-room-remote: button LED on when any lamp is on (incl. only Interior)
- [x] reboot media room, then remote: no lamp changes; remote LED correct within 30s
- [x] lights-media-room: a remote press raises "Link media-room Toggles" by 1 and duplicates rise; remote State Age stays under ~30s, rises while the media room reboots
- [x] lights-media-room: Door and Interior button LEDs follow their lamps
- [ ] lights-media-room: Unconfirmed Switches and Edges stay quiet over the following weeks (ch2 sense fault was on this logic board or the old hallway wiring)
- [x] lights-downstairs-deck: Pool button toggles Dining Room Fan Pool Light
- [x] lights-downstairs-deck: ch3 LED follows Pool Light when switched at dining and from HA
- [x] lights-downstairs-deck: no Pool entity in HA
- [x] lights-downstairs-deck: Yard still switches from its button and HA
- [x] lights-lounge-fan-2: light button toggles deck Yard; its LED follows Yard (press here, at deck, and from HA)
- [x] lights-lounge-fan-1: Pool Light still switches from its own button and HA
