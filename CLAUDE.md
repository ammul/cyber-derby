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
| `GameConfig.gd` | Global constants — all magic numbers live here (`class_name GameConfig`) |
| `RaceTrack.gd` | Game controller: grid, tile placement, karma, signals (`class_name RaceTrack`) |
| `Horse.gd` | Per-horse logic: movement, AI tactics, procedural rendering |
| `hud.gd` | UI: karma bar, countdown, win/loss overlay |
| `MainCamera.gd` | Smooth camera follow on lead horse |
| `tests/` | GUT unit tests — run headlessly with `gut_cmdln.gd` |
| `addons/gut/` | GUT v9.6.0 plugin (committed to repo) |

## Architecture

See `architecture.md` for the full breakdown (scene hierarchy, signal flow, data structures, AI, dynamics, testing).

## Notes for Future Sessions

- UI strings are in **German** (e.g. "WÄHLE DEIN PFERD!" = "Choose your horse!") — this is intentional
- Code comments are also partly in German
- The grid is `GameConfig.GRID_WIDTH × GameConfig.GRID_HEIGHT` tiles (`RaceTrack.Tile` enum: `EMPTY`, `BOOST`, `SLOW`)
- **`GameConfig`** is a `class_name` script — use `GameConfig.SOME_CONST` from anywhere, no autoload or import needed
- **`RaceTrack`** also has `class_name RaceTrack` — use `RaceTrack.Tile.BOOST` etc. from `Horse.gd`
- Signal flow: `Horse` emits `horse_finished` → `RaceTrack._on_horse_finished()` → re-emits typed `race_finished` → `hud`
- `Horse._horses_cache` is populated via `call_deferred` in `_ready()` — cache is valid from the first `_process()` frame
- `_score_lane(lane, cell_x)` in `Horse.gd` is a pure function and the primary NPC test target
- CI pipeline: **test → build → deploy** (all in `.github/workflows/deploy.yml`)
- `Horse.gd` handles both NPC and player-selected horses (same script, `is_npc` flag)
- Next planned step: gameplay polish / feature additions
