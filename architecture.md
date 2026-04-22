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
│   └── UI (MarginContainer)
│       ├── KarmaBar (ProgressBar)
│       ├── KarmaLabel (Label)
│       ├── CountdownLabel (Label)
│       └── WinOverlay (ColorRect)
│           ├── WinnerText (Label)
│           └── RestartButton (Button)
└── CanvasLayer (layer 10)
    └── CrtFilter (ColorRect)  ← inline shader
```

---

## Script Responsibilities

### `RaceTrack.gd`
**Owns:** track grid, tile placement input, karma, race state, camera shake

| Function | Purpose |
|----------|---------|
| `_generate_track()` | Build 360×8 grid, scatter random BOOST/SLOW tiles |
| `_input(event)` | Mouse input → aim/place tiles |
| `_place_selected_tile()` | Write tile to grid, increment karma, call `queue_redraw()` |
| `trigger_karma_event()` | Strike selected horse, scatter 10 slow zones, shake camera |
| `_screen_shake()` | Tween-based camera offset shake |
| `_draw()` | Draw track lanes, tile rectangles, finish line |

**Signals emitted:**
- `selection_done` — horse chosen, ready for countdown
- `race_finished(winner_index, karma_score)` — a horse crossed the finish line

**Key state:**
- `grid: Array` — 360×8, values `EMPTY/BOOST/SLOW`
- `karma_points: float`
- `karma_threshold: float = 100.0`
- `race_started: bool`
- `selected_horse_index: int`

---

### `Horse.gd`
**Owns:** movement, tile reactions, NPC AI, procedural rendering, dynamics

| Function | Purpose |
|----------|---------|
| `_process(delta)` | Move, animate, check tiles, handle repulsion |
| `_calculate_dynamics()` | Rubber-band catch-up + slipstream bonus |
| `_handle_npc_tactics(delta)` | 4-tile lookahead, lane scoring, lane switch |
| `_try_switch_lane()` | Evaluate adjacent lanes, call `_switch_to_lane()` |
| `_check_tiles()` | Read `grid` at current position, set `speed_modifier` |
| `_handle_repulsion(delta)` | Push overlapping horses apart |
| `get_struck_by_lightning()` | Set `speed_modifier = 0.1`, trigger visual flash, 2s duration |
| `_draw()` | Procedural horse body, legs, tail, number, indicators, effects |

**Key state:**
- `base_speed: float = 110.0`
- `speed_modifier: float` — multiplied with base speed (tiles, lightning)
- `slipstream_bonus: float` — added when drafting in same lane
- `catch_up_mult: float` — rubber-band multiplier for trailing horses
- `is_npc: bool` — same script for all 8 horses
- `lane_index: int` — current lane (0–7); Y position lerped to match

---

### `hud.gd`
**Owns:** karma bar display, countdown sequence, win/loss overlay, restart

| Function | Purpose |
|----------|---------|
| `_on_selection_done()` | Start countdown when horse is selected |
| `_start_countdown()` | Async 3-2-1-GO sequence; sets `track.race_started = true` |
| `_on_race_finished(horse_index, karma_score)` | Show result with karma commentary |
| `_process(delta)` | Update progress bar value and green→red color gradient |

---

### `MainCamera.gd`
**Owns:** smooth horizontal follow of lead horse

Each frame: find highest `position.x` among all horses, lerp camera to `lead_x + lead_offset`. `lead_offset = 200` places lead horse on left, leaving right screen space for tile aiming.

---

## Signal Flow

```
Player clicks horse
  → RaceTrack._check_horse_selection()
    → emit selection_done
      → hud._on_selection_done()
        → hud._start_countdown()
          → track.race_started = true

Horse.position.x >= finish_line_column * cell_size
  → Horse notifies RaceTrack (via direct call or signal)
    → emit race_finished(winner_index, karma_score)
      → hud._on_race_finished()
        → show WinOverlay
```

---

## Key Data Structures

### Track Grid
```gdscript
var grid: Array  # grid[col][row], col 0..359, row 0..7
# Values: RaceTrack.EMPTY (0), RaceTrack.BOOST (1), RaceTrack.SLOW (2)
```
Column index maps directly to X position: `col * cell_size`. Row index maps to lane.

### Horse Speed Calculation
```
total_speed = (base_speed * speed_modifier * catch_up_mult) + slipstream_bonus + flavor_speed
```
- `speed_modifier`: 0.1 (lightning) … 1.0 (normal) … 1.5 (boost tile)
- `catch_up_mult`: 1.0 … 1.3 (trailing horses)
- `slipstream_bonus`: 0 or ~20 (within 180px behind horse in same lane)
- `flavor_speed`: sinusoidal random variance

---

## Karma System

1. Each tile placed → `karma_points += tile_karma_value`
2. HUD progress bar fills 0–100 (green → red via `Color.lerp`)
3. At `karma_points >= karma_threshold (100)`:
   - `get_struck_by_lightning()` on selected horse
   - 10 SLOW tiles placed randomly ahead
   - `_screen_shake()` tween fires
   - `karma_points` resets to 0

---

## Horse AI (NPC Tactics)

Runs every frame in `_handle_npc_tactics(delta)`:

1. **Lookahead:** scan next 4 tile columns in current and adjacent lanes
2. **Score lanes:** BOOST tiles → positive score (weighted by 1/distance), SLOW tiles → negative, player's aim preview → negative
3. **Collision check:** if another horse is directly ahead, highest priority to switch
4. **Decision:** if adjacent lane score beats current lane by threshold → `_try_switch_lane()`

---

## Dynamics

**Rubber-banding:**
- Compare each horse's X to the leader's X
- Gap > threshold → `catch_up_mult` scales up to 1.3×
- Prevents runaway leaders

**Slipstream:**
- If within 180px behind another horse in the same lane → `slipstream_bonus` active
- Encourages pack racing and tactical lane use

---

## Rendering

All visuals are procedural — no sprite files.

- **`Horse._draw()`:** rectangles for body/head, lines for legs/tail, polylines for lightning bolts and slipstream streaks, triangle for selection indicator
- **`RaceTrack._draw()`:** horizontal lane lines, colored tile rectangles (green = boost, red = slow), finish line
- **CRT shader (inline on ColorRect):** scanlines, chromatic aberration, screen curvature (fisheye), vignette — applied as top-layer post-process

---

## Export

`export_presets.cfg` targets **Android**. No desktop export preset is configured (but the game runs from the Godot editor on any platform).
