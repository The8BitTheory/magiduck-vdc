# magiduck-vdc

Experiments for a port of [MagiDuck](https://github.com/bluepandion/magiduck) (DOS, CGA, Toni Svenström 2015, freeware)
to the Commodore 128 VDC, written in BASIC 7.0 with [VDC-BASIC](https://github.com/the8bittheory/vdc-basic) (branch v2h)
and compiled with Blitz! 128.

## Prototype

- Bitmap mode with attributes, 40 columns with double pixels, 50 rows of 4 scanlines:
  one attribute byte = 2 pixels, the same layout as the CGA original (80x50 pixels, 16 colours).
  A text mode variant (80x50, one attribute byte per pixel) is still supported by the tools.
- Level 1 from the original data, tile Ring Buffer in VRAM, Double Buffering with Page Flip,
  sprites with transparency (VMS), one VCL list per page and frame; the list ends with a SYN entry
  (type 13, VDC-BASIC v2h from 2026-11-24) that shows the page at the vertical blank.
- Joystick port 2: left/right walk, fire or up jumps. No enemy contact, shooting or HUD yet.

Playable disk: `proto/magiduck-demo.d81` (C128, 80 columns, 64 KiB VRAM): `RUN"MAGIDUCK"`.

Measured in VICE (level 1, duck + 4 enemies, automatic input, 300 frames): 7.1 fps with the original
Blitz! runtime, 7.8 fps with the Improved 2026 runtime (blitz-compiler, branch `perf`), 8.3 fps with the
page flip inside the VCL list instead of a separate `::SYN`, 8.5 fps with that SYN entry waiting
level-triggered (high byte of n = 1: no wait if the border has already begun). The demo disk uses the improved runtime with fast math (FASTMATH=auto turns it on for this program).

## Files

| Path | Content |
|---|---|
| `tools/mdgfx.py` | readers for the packed MagiDuck files (LEVELS.CLP, TILES.CTP, *.CSP, *.CSD) |
| `tools/make_proto.py` | converter: level, tiles, sprites, VMS and VCL lists (text or bitmap mode) |
| `proto/mdload.bas` | loader (interpreted): video mode, data to VRAM and RAM, starts the game |
| `proto/mdgame.bas` | game loop (Blitz! compatible, extension commands with `::`) |
| `tools/run_proto.sh` | benchmark: build, compile, run headless in x128, exit code = fps x 10 |
| `tools/make_demo_disk.sh` | builds `proto/magiduck-demo.d81` |
| `tools/mkprof.py` | profiling variant of the game loop (time per section) |
| `tools/blitzcomp.sh` | compiles with the original Blitz! 128 headless in x128 |
| `proto/bench/` | earlier measurements (statement costs, text vs. bitmap mode) |

## Requirements

- VICE 3.x (`x128`, `c1541`), Python 3 with Pillow.
- The `RELEASE` folder of github.com/bluepandion/magiduck: `export RELEASE=<path>/magiduck/RELEASE`.
- Blitz! 128: not included. Copy `blitz!.128.prg` (fixed build) from
  [blitz-compiler](https://github.com/the8bittheory/blitz-compiler) (`blitz128/fixed/`) to `tools/blitz/`,
  or set `BLITZ=<path>`.

```
tools/run_proto.sh blitz 1 bitmap     # benchmark
tools/make_demo_disk.sh 1             # playable disk
```

With the JS compiler of blitz-compiler (needed for the Improved 2026 runtime):

```
export BLITZC=<blitz-compiler>/blitz128/blitzc NODE=<path to node>
RUNTIME=improved FASTMATH=auto tools/run_proto.sh blitz 1 bitmap
RUNTIME=improved FASTMATH=auto tools/make_demo_disk.sh 1
```

MagiDuck, its assets and source code are freeware by Toni Svenström.
