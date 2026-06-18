# Steam Controller (2026) protocol stuff

Place to document the protocol of the new Steam Controller (apparently codenamed Triton). Information seems somewhat scattered currently. It would be nice to have most information in one place.

## Useful links to other projects

- SteamHapticsPlayer: <https://github.com/Pixel1011/SteamHapticsPlayer/blob/master/sharedSrc/TritonController.cpp>
- libSDL hidapi_steam_triton
  - <https://github.com/libsdl-org/SDL/blob/main/src/joystick/hidapi/SDL_hidapi_steam_triton.c>
  - <https://github.com/libsdl-org/SDL/blob/main/src/joystick/hidapi/steam/controller_structs.h>
  - <https://github.com/libsdl-org/SDL/blob/main/src/joystick/hidapi/steam/controller_constants.h>
- OpenPuck: <https://github.com/safijari/openpuck/blob/main/docs/PROTOCOL.md>

## Overview

Primary report is `0x45` which seems to contain most information. OpenPuck PROTOCOL.md has a good overview of this.

Note that Trackpad Lockout and Grip Sensors settings (among others) in the Steam "Calibration & Advanced Settings" menu affect what is reported. These settings are sent by Steam to the controller via HID Set Feature Report request, not via HID Set Output Report. Might be `SETTING_*` values in SDL's `controller_constants.h`.

Haptics seem to use several report ids in the range `0x81 - 0x89`.

`0x7B` is sent by the controller periodically only when using the puck.

## TODO

- write wireshark dissector
- figure out config set_report format
- figure out haptics output format
