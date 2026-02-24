# Stone Torch (Godot 4.6.1) — First-Person 3D Prototype

The project is now refactored into a **first-person 3D** torch-survival prototype.

## Core Identity

- No combat
- No weapons
- No boss fights
- Creatures react to flame state, not direct attack logic
- Failure is expected and feeds progression

## Current 3D Loop

1. Spawn with a lit torch (first-person camera + torch light).
2. Explore dark space, gather `moss`, `cloth`, `resin` fuel pickups.
3. Manage flame pressure from wind/ash by zone.
4. Press `E` to feed torch (you become immobile briefly).
5. Reach beacon to advance zones and complete final sequence.
6. If flame dies, run ends (or ember relight triggers if unlocked).

## Zones

- Zone 1: Cave onboarding
- Zone 2: Forest pressure and wind
- Zone 3: Ash Village final return of the flame

## Controls

- `WASD` Move
- `Mouse` Look
- `Shift` Sprint
- `C` Cup flame / cautious movement
- `E` Feed torch / interact beacon
- `Esc` Release mouse cursor

## Notes

- This is still prototype geometry (primitive meshes).
- The previous 2D placeholder art is kept in repo, but runtime is now 3D-first.
