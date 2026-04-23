# Cyber-Derby

A retro arcade horse racing game where you secretly manipulate the race — at a karmic cost.

Built with **Godot 4.6** and GDScript. All visuals are procedurally drawn; no external assets required.
<!-- connection test -->

---

## Gameplay

1. **Pick your horse** — choose one of 8 horses to root for
2. **The race starts** — all 8 horses bolt down the track
3. **Manipulate the race** — place tiles to influence the outcome:
   - Click/drag on the **right side** of the screen → place a **BOOST** tile (speeds up whoever hits it)
   - Click/drag on the **left side** → place a **SLOW** tile (slows whoever hits it)
4. **Watch your karma** — every tile you place fills the karma bar. Hit 100 and the universe strikes back: your horse gets hit by lightning, slow zones appear, and the screen shakes
5. **Win or lose** — first horse across the finish line wins

Horse AI actively scans ahead for tiles and switches lanes to avoid your sabotage. They also draft off each other (slipstream) and trailing horses gradually catch up (rubber-banding).

---

## Controls

| Action | Input |
|--------|-------|
| Select horse | Click near a horse before the race |
| Aim tile | Click and hold |
| Place tile | Release mouse button |
| Restart | Click RESTART after the race |

---

## Requirements

- [Godot 4.6](https://godotengine.org/) or later

## Running the Game

1. Clone or download this repo
2. Open Godot and import `project.godot`
3. Press **F5** (or the Play button) to run

## Export

An Android export preset is included (`export_presets.cfg`). Set up an Android export template in Godot to build for mobile.

---

## License

MIT — see [LICENSE](LICENSE)
