# Stone Torch (Godot 4.6.1 Prototype)

A short atmospheric horror roguelite prototype where the torch is the only thing that matters.

## Identity

- No combat
- No weapons
- No boss fights
- Creatures react to the **flame**, not to you
- Failure is expected and advances progression

You do not lose to monsters. You lose when the flame goes out.

## Core Run Loop

1. Start with a lit torch.
2. Explore zone and collect fuel items (`moss`, `cloth`, `resin`).
3. Manage environment pressure (wind/ash) while creatures react to flame state.
4. Manually refuel (`E`) while standing still (high vulnerability).
5. Reach next zone beacon.
6. If flame extinguishes, run ends and meta progression applies.

## Zone Structure

- **Zone 1 — Cave (fixed-feel)**: mechanic onboarding, claustrophobic pressure.
- **Zone 2 — Forest (semi-procedural)**: randomized placement + stronger wind pressure.
- **Zone 3 — Ash Village (fixed-feel with variation)**: final pilgrimage to the beacon.

## Flame States (No numeric bar)

The game uses text/mood cues instead of explicit timers:

- **Healthy** → creatures observe
- **Hungry** → creatures encroach
- **Failing** → shadows close in
- **Dying Ember** → creatures claim paths
- **Out** → run ends unless emergency relight upgrade is available

## Meta Progression

Each failed run grants embers and progression boosts:

- Slightly longer flame
- Wind resistance
- Small stamina improvement
- One emergency ember relight (consumable)

World progression is tied to deaths (deeper start zones unlock over time).

## Controls

- `WASD`: Move
- `Shift`: Sprint
- `C`: Cup flame / cautious movement
- `E`: Feed fuel to torch / interact with final beacon

## Run

1. Open in **Godot 4.6.1**.
2. Run project (`project.godot`) or `scenes/Main.tscn`.

## Notes

This is still a prototype layer (debug visuals). Next iteration should add:
- First-person presentation
- Real lighting and shadow systems
- Audio-driven fear cues and jumpscare pacing
- Authored encounter scripting per zone


## Placeholder Art Included

Simple SVG placeholder textures are now included in `assets/textures/` for:
- ground tile
- grass patch
- tree
- torch
- monster
- fuel items (moss/cloth/resin)

These are intentionally lightweight prototypes so you can replace them later with hand-made art packs.
