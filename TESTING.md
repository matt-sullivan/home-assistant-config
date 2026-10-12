# Testing
Maintain a list of devices and features that need to be tested physically after devices are flashed

## Test Items
- [x] hallway-stairs (CB3S board, stairs rewired to ch1): bottom (ch2) LED follows Landing state (press here, at pool room, and from HA)
- [x] hallway-stairs: bottom press toggles Landing; top press toggles internal stairs lamp, pooltable-stairs ch1 reports it
- [x] hallway-stairs: top (ch1) LED follows the sensed stairs lamp state, from either switch
- [x] hallway-stairs: Power Status 1 Edges stays 0 with the stairs lamp steady (ch1 sense parts now on the stairs travellers)
- [ ] lights-media-room (old hallway WB3S board), once installed: both lights switch from buttons and HA
- [ ] lights-media-room: Power Status 2 Edges - counting would mean the old hallway ch2 sense fault is on this logic board
