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

## Interesting stuff

- Some simple tones (such as mode switch) are done by a sending haptic pulse command targeting a trackpad with the on/off duration and repeat count set to produce the desired frequency.

## Firmware

- Controller firmware image in `~/.local/share/Steam/bin/hardwareupdater`
- Triton (controller) firmware named `IBEX_FW_*.fw`
- Proteus (puck) firmware named `PROTEUS_FW_*.fw`
- Need to strip 32-byte header from these images and then the rest should be a Cortex-M binary

### Triton firmware

- Base address seems to be `0x8000`, entrypoint `0x267ec` (as in Cortex-M vector table)

### Firmware updater

- Extract `hardwareupdater.x86_64` with <https://github.com/extremecoders-re/pyinstxtractor>
- Decompile `hardwareupdater.pyc` with <https://pylingual.io> or something else

## Misc notes

- SDL refers to the 2026 Steam Controller as Triton. Ibex may have been the codename for an older revision.
- HID descriptor for puck (on controller interfaces) and controller is identical.

## TODO

- wireshark PR, perhaps: <https://gitlab.com/wireshark/wireshark/-/merge_requests/25464>
- write wireshark dissector
  - note: currently dissector depends on `usbhid.product` field added in PR mentioned above
- figure out config set_report format
- figure out haptics output format
