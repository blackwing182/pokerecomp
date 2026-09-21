# PokéRecomp R36S / RK3326 build

This is a dedicated R36S build layer for the supplied PokéRecomp source.

## What changed

1. Added `Linux ARM64 R36S` export preset.
2. Keeps the upstream GL Compatibility renderer.
3. Targets native 640×480 / 4:3.
4. Builds the same stripped Godot ARM64 export template strategy used by the
   upstream project.
5. Packages the resulting ARM64 executable for PortMaster.
6. Uses WestonPack for the R36S display path.
7. Does not include Pokémon ROMs.

## Fastest way to get the real binary

The included GitHub Actions workflow is the recommended build route because
Godot's R36S export template is built natively on an ARM64 runner.

Push this project to a GitHub repository, then run:

Actions → Build R36S ARM64 → Run workflow

The workflow produces:

`PokeRecomp-R36S.zip`

That ZIP is the actual ARM64 PortMaster test package.

## Local build

On an ARM64 Linux machine with SCons:

```bash
cd pokerecomp-main
./r36s/build-r36s.sh
```

The script builds the exact Godot commit pinned by the project and creates:

`dist/PokeRecomp-R36S.zip`

## R36S installation

Copy the resulting PortMaster package to the normal Ports location for your
EmuELEC/PortMaster setup. PortMaster will request `weston_pkg_0.2.squashfs`.

Then add your own supported Pokémon ROM through PokéRecomp's normal ROM importer.

## Important

The supplied source itself contains no Pokémon ROM data. The build intentionally
does not add any ROM.
