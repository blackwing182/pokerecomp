# PokéRecomp — R36S / RK3326

## Target

- RK3326 / ARM64
- 640×480 4:3
- Godot 4.8-dev4 Compatibility renderer
- WestonPack/PortMaster display path
- Native Godot gamepad input
- Audio through ALSA
- Full upstream PokéRecomp functionality

## ROMs

PokéRecomp does **not** include Pokémon ROMs.

Use your own supported cartridge dump. The upstream importer verifies the ROM SHA-1 before importing it.

Supported upstream hashes are documented in `roms/README.md`.

## Installation

Install through PortMaster or place the package in the normal Ports location for your CFW.

The port requests:

`weston_pkg_0.2.squashfs`

PortMaster can download the runtime automatically when networking is available.

## Why WestonPack?

The R36S/PortMaster environment normally has no X11 display server. WestonPack supplies the Wayland/Xwayland/EGL environment needed by a standard Godot 4 Linux ARM64 executable.

This is the intended Godot 4 route for PortMaster handhelds; the R36S is an RK3326 ARM64 device.
