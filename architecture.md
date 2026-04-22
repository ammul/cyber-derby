# Cyber-Derby — Architecture

## Game Overview

Single-scene arcade game. One race per session: select horse → countdown → race with tile manipulation → result → restart.

Player interaction is entirely mouse-based: click/drag places tiles on the track grid to boost or slow horses. Manipulating the race accumulates karma; at 100 karma a punishment event fires.

---

## Scene Hierarchy

```
RaceTrack (Node2D)            ← RaceTrack.gd
├── MainCamera (Camera2D)     ← MainCamera.gd
├── Horse1..Horse8 (Node2D)   ← Horse.gd  (group: "horses")
├── WorldEnvironment          ← glow/HDR environment
├── HUD (CanvasLayer)         ← hud.gd
│   ├── UI (MarginContainer)
│   │   ├── KarmaBar (ProgressBar)
│   │   └── KarmaLabel (Label)
│   ├── WinOverlay (ColorRect)
│   │   ├── WinnerText (Label)
│   │   └── RestartButton (Button)
│   └── CountdownLabel (Label)
└── CanvasLayer (layer 10)
    └── CrtFilter (ColorRect)  ← inline shader
```

---

## Script Responsibilities

### `GameConfig.gd`
**Owns:** all game constants (no instance needed — accessed via `GameConfig.CONST_NAME`)

A `class_name`-registered script with `const` declarations for every magic number in the project. Groups names, track geometry, karma values, speed modifiers, NPC AI weights, rendering colors, and timing constants are all here.

---

### `RaceTrack.gd`
**Owns:** track grid, tile placement input, karma, race state, camera shake

| Function | Purpose |
|----------|---------|
| `_generate_track()` | Build grid, scatter initial BOOST/SLOW tiles |
| `_handle_selection_click(event)` | Selection-phase mouse input |
| `_handle_aiming(event)` | Aiming-phase mouse input (press/move/release) |
| `_place_selected_tile()` | Write tile to grid, add karma |
| `_get_placement_x_global()` | Shared camera-edge calculation (used by `_place_selected_tile` and `_draw`) |
| `trigger_karma_event()` | Strike selected horse, shake camera |
| `_spawn_punishment_tiles()` | Place 10 SLOW tiles near camera during karma event |
| `_screen_shake()` | Tween-based camera offset shake |
| `_on_horse_finished(horse_index, karma_score)` | Handle `horse_finished` signal; set race over, re-emit `race_finished` |
| `_draw()` | Draw track lanes, tile rectangles, finish line, aim preview |

**Signals emitted:**
- `selection_done` — horse chosen, ready for countdown
- `race_finished(winner_index, karma_score)` — a horse crossed the finish line

**Key state:**
- `grid: Array` — GRID_WIDTH × GRID_HEIGHT, values `Tile.EMPTY / BOOST / SLOW`
- `karma_points: float`
- `race_started: bool`
- `is_race_over: bool`
- `selected_horse_index: int`

---

### `Horse.gd`
**Owns:** movement, tile reactions, NPC AI, procedural rendering, dynamics

| Function | Purpose |
|----------|---------|
| `_update_movement(delta)` | Speed calculation + position update |
| `_handle_lightning_timer(delta)` | Lightning countdown and recovery |
| `_check_finish_line()` | Emit `horse_finished` when crossing finish |
| `_calculate_dynamics()` | Rubber-band catch-up + slipstream bonus |
| `_handle_npc_tactics(delta)` | Decision timer, collision avoidance, lane choice |
| `_score_lane(lane, cell_x) -> float` | Pure scoring function: tile lookahead + preview weight |
| `_try_switch_lane()` | Pick a random adjacent valid lane |
| `_check_tiles()` | Read grid at current position, set `speed_modifier` |
| `_handle_repulsion(delta)` | Push overlapping horses apart |
| `get_struck_by_lightning()` | Set `speed_modifier = 0.1`, trigger visual flash |
| `_draw_body(bob, leg_swing)` | Horse body, legs, tail, saddle, number |
| `_draw_selection_indicator()` | Wobbling triangle above selected horse |
| `_draw_lightning_effect()` | Zap polylines during shock |
| `_draw_slipstream()` | Trailing streak lines when drafting |

**Signal emitted:**
- `horse_finished(horse_index, karma_score)` — emitted locally when crossing finish line; RaceTrack listens to re-emit the typed `race_finished` signal

**Key state:**
- `base_speed: float` — default `GameConfig.BASE_SPEED`
- `speed_modifier: float` — multiplied with base speed
- `slipstream_bonus: float` — added when drafting in same lane
- `catch_up_mult: float` — rubber-band multiplier for trailing horses
- `is_npc: bool` — same script for all 8 horses
- `lane_index: int` — current lane (0–7); Y position lerped to match
- `_horses_cache: Array` — cached result of `get_nodes_in_group("horses")`, populated after all `_ready()` calls via `call_deferred`

---

### `hud.gd`
**Owns:** karma bar display, countdown sequence, win/loss overlay, restart

| Function | Purpose |
|----------|---------|
| `_on_selection_done()` | Start countdown when horse is selected |
| `_start_countdown()` | Async 3-2-1-START! sequence; sets `track.race_started = true` |
| `_on_race_finished(horse_index, karma_score)` | Show result with karma commentary |
| `_process(delta)` | Update progress bar value and green→red color gradient |

---

### `MainCamera.gd`
**Owns:** smooth horizontal follow of lead horse

Each frame: find highest `position.x` among all horses, lerp camera to `lead_x + lead_offset`. `lead_offset` defaults to `GameConfig.CAMERA_LEAD_OFFSET` (200) — places lead horse on left, leaving right screen space for tile aiming.

---

## Signal Flow

```
Player clicks horse
  → RaceTrack._handle_selection_click()
    → RaceTrack._check_horse_selection()
      → emit selection_done
        → hud._on_selection_done()
          → hud._start_countdown()
            → track.race_started = true

Horse.position.x >= FINISH_LINE_COL * CELL_SIZE
  → Horse._check_finish_line()
    → emit horse_finished(horse_index, karma_score)
      → RaceTrack._on_horse_finished()
        → is_race_over = true
        → emit race_finished(horse_index, karma_score)
          → hud._on_race_finished()
            → show WinOverlay
```

---

## Key Data Structures

### Track Grid
```gdscript
var grid: Array  # grid[col][row], col 0..GRID_WIDTH-1, row 0..GRID_HEIGHT-1
# Values: RaceTrack.Tile.EMPTY (0), BOOST (1), SLOW (2)
```
Column index maps directly to X position: `col * GameConfig.CELL_SIZE`.

### Horse Speed Calculation
```
total_speed = (base_speed + flavor_speed) * speed_modifier * catch_up_mult + slipstream_bonus
```
- `speed_modifier`: `LIGHTNING_SPEED_MOD` (0.1) … 1.0 (normal) … `BOOST_MODIFIER` (1.5)
- `catch_up_mult`: 1.0 … 1.0 + `CATCHUP_MAX_MULT` (trailing horses)
- `slipstream_bonus`: 0 or `(SLIPSTREAM_DIST - x_dist) * SLIPSTREAM_BONUS_MULT` (drafting)
- `flavor_speed`: `sin(time * FLAVOR_FREQUENCY) * FLAVOR_AMPLITUDE` (per-horse sinusoidal variance)

---

## Karma System

1. Each tile placed → `karma_points += KARMA_BOOST_PENALTY` or `KARMA_SLOW_PENALTY`
2. HUD progress bar fills 0–`KARMA_THRESHOLD` (green → red via `Color.lerp`)
3. At `karma_points >= KARMA_THRESHOLD (100)`:
   - `_spawn_punishment_tiles()` — 10 SLOW tiles placed near camera
   - `get_struck_by_lightning()` on selected horse
   - `_screen_shake()` tween fires
   - `karma_points` resets to 0

---

## Horse AI (NPC Tactics)

Runs on a timer (`NPC_DECISION_MIN`–`NPC_DECISION_MAX` seconds) in `_handle_npc_tactics(delta)`:

1. **Collision avoidance:** if another horse is directly ahead in same lane → `_try_switch_lane()` immediately
2. **Lane scoring** via `_score_lane(lane, cell_x)`:
   - Current lane gets `LANE_STAY_BONUS` to reduce jitter
   - `NPC_LOOK_AHEAD` tiles scanned; closer tiles weighted higher
   - BOOST tiles → `BOOST_LANE_WEIGHT * distance_weight`
   - SLOW tiles → `-SLOW_LANE_WEIGHT * distance_weight`
   - Player aim preview adds ±`PREVIEW_BOOST_WEIGHT` / `PREVIEW_SLOW_WEIGHT`
3. **Decision:** highest-scoring lane wins; switch if different from current

`_score_lane()` is a pure function (no side effects), making it straightforward to test.

---

## Dynamics

**Rubber-banding:**
- Compare each horse's X to the leader's X
- Gap / `CATCHUP_DIST_THRESHOLD` → `catch_up_mult` scales up to `1 + CATCHUP_MAX_MULT`
- Prevents runaway leaders

**Slipstream:**
- If within `SLIPSTREAM_DIST` px behind another horse in the same lane → `slipstream_bonus` active
- Encourages pack racing and tactical lane use

---

## Rendering

All visuals are procedural — no sprite files.

- **`Horse._draw()`:** dispatches to `_draw_body()`, `_draw_selection_indicator()`, `_draw_lightning_effect()`, `_draw_slipstream()`
- **`RaceTrack._draw()`:** horizontal lane lines, colored tile rectangles, start/finish lines, aim preview
- **CRT shader (inline on ColorRect):** scanlines, chromatic aberration, screen curvature (fisheye), vignette — applied as top-layer post-process

---

## Testing

Tests live in `tests/` and use the **GUT** (Godot Unit Test) plugin (`addons/gut/`).

Run headlessly:
```
./godot --headless -d -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -gprefix=test_ -gexit -glog=1
```

| Test file | Covers |
|-----------|--------|
| `test_config.gd` | GameConfig constant ranges and relationships |
| `test_horse_scoring.gd` | `_score_lane()` with real RaceTrack + Horse instances |
| `test_karma.gd` | Karma accumulation, tile penalties, event reset |

---

## CI/CD Pipeline

`.github/workflows/deploy.yml` — triggered on push to `main`:

1. **test** — run GUT tests headlessly
2. **build** *(needs: test)* — Godot headless web export
3. **deploy** *(needs: build)* — GitHub Pages deployment

---

## Export

`export_presets.cfg` targets **Android** and **Web**. The Web preset is what the CI pipeline uses.
