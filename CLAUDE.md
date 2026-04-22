# Cyber-Derby — Claude Context

## Project

Arcade horse racing game built in **Godot 4.6** with GDScript. The player picks a horse, then manipulates the race by placing boost/slow tiles. A karma system punishes heavy manipulation. Retro CRT aesthetic, all visuals procedurally drawn.

## Engine & Stack

- Godot 4.6 (Jolt physics, HDR 2D, mobile canvas stretch)
- Pure GDScript — no third-party libraries
- No sprite assets — all rendering via `_draw()` and shaders

## Key Files

| File | Role |
|------|------|
| `RaceTrack.tscn` | Main (and only) scene |
| `RaceTrack.gd` | Game controller: grid, tile placement, karma, signals |
| `Horse.gd` | Per-horse logic: movement, AI tactics, procedural rendering |
| `hud.gd` | UI: karma bar, countdown, win/loss overlay |
| `MainCamera.gd` | Smooth camera follow on lead horse |

## Architecture

See `architecture.md` for the full breakdown (scene hierarchy, signal flow, data structures, AI, dynamics).

## Notes for Future Sessions

- UI strings are in **German** (e.g. "WÄHLE DEIN PFERD!" = "Choose your horse!") — this is intentional
- Code comments are also partly in German
- The grid is a 2D array `360 × 8` of tile types (`EMPTY`, `BOOST`, `SLOW`)
- Karma threshold is `100`; resets after each lightning event
- `Horse.gd` handles both NPC and player-selected horses (same script, `is_npc` flag)
- Next planned step: **code analysis and refactoring**
