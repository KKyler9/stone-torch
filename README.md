# Stone Torch (Godot / GDScript Prototype)

A fresh Godot prototype based on your survival-horror premise:
- You carry one dying torch.
- Monsters stalk you and fear light, but keep following.
- You scavenge fuel (grass, vines, moss, scrap cloth).
- Traps punish mistakes.
- Run ends when your torch dies (or monsters catch you in darkness).

## Current prototype flow

1. **Zone 1: Cave (fixed layout feel)**
   - Tutorial-like space with fixed objective counts.
2. **Zone 2: Forest (procedural placement)**
   - Pickups/traps/monster spawns are randomized each run.
   - Torch drains faster due to "wind" pressure.
3. **Zone 3: Village + beacon finale**
   - Slightly varied layout.
   - Reach beacon with enough fuel and choose:
     - **E**: true ending (light beacon)
     - **Q**: bad ending (smother torch)

## Meta progression (replayable loop)

On death, embers are banked and an auto-upgrade is applied when affordable:
- Fuel bonus (higher fuel value per pickup)
- Light radius bonus
- Stamina bonus

Progress is saved to `user://progress.cfg`.

## Controls

- `WASD`: Move
- `Shift`: Sprint
- `C`: Crouch
- `E`: Interact / good ending at beacon
- `Q`: Trigger bad ending at beacon

## Run

1. Open project in **Godot 4.2+**.
2. Run `scenes/Main.tscn` (already set as main scene in `project.godot`).

## Notes for next iteration

- Add proper first-person rendering and real lighting/shadows.
- Replace debug circles with sprites/animations/audio cues and jumpscare events.
- Convert zone generation to tile-based navigation + authored encounter beats.
- Add explicit in-run upgrade station/menu instead of auto-upgrades only.
