# Stone Torch - Systems Notation & Tuning Guide

This document explains *what each gameplay script is responsible for*, *why values exist*, and *how to tune them*.

## Core loop at a glance
- Player explores cave, gathers **moss / cloth / resin**.
- Fueling the torch changes light, VFX, decay speed, and enemy behavior profile.
- Traps tax fuel and can be disabled with specific resources.
- Door provides simple progression endpoint.

## Script map
- `scripts/Torch.gd`: Decay + flicker + fuel boost system, particle/light control, and AI-facing torch profile.
- `scripts/Monster.gd`: Enemy movement logic reacting to torch profile and state.
- `scripts/Player.gd`: Movement, interaction, inventory, and hotbar fuel usage.
- `scripts/CaveZone.gd`: Runtime spawning of collectibles, traps, and door.
- `scripts/Collectible.gd`: Generic pickup behavior.
- `scripts/CaveTrap.gd`: Trap trigger + disable item requirement.
- `scripts/CaveDoor.gd`: Interactable door behavior.
- `scripts/PlayerHUD.gd`: Prompt/feedback/hotbar UI text updates.

## Fuel design intent (Torch.gd)
### Moss
- Fast tactical use: short efficient burn + high flicker.
- After mini-boost expires, decay becomes harsher (risk).
- Sparks stay lively to sell unstable flame behavior.

### Cloth
- Emergency visibility: temporary brightness burst with short decay relief.
- After timer ends, returns to baseline behavior.

### Resin
- Stability choice: reduced flicker, slower decay, wider steady radius.
- Better for safe traversal and keeping enemies farther away.

## Tuning recommendations
### Overall pacing
- `base_decay_rate`: global fuel drain speed.
- `max_fuel`: max exploration window per full torch.

### Visual intensity
- `base_flicker_rate`, `base_flicker_amount`: baseline flame jitter.
- `*_flicker_*_multiplier`: per-fuel personality layer.

### Fuel identity
- moss: `moss_boost_duration`, `moss_boost_decay_multiplier`, `moss_after_decay_multiplier`
- cloth: `cloth_boost_duration`, `cloth_boost_decay_multiplier`
- resin: `resin_decay_multiplier`

### Enemy pressure
- Tune in `Torch.gd -> get_enemy_modifiers()`:
  - `aggression`: chase pressure
  - `fear`: light avoidance radius
  - `hesitation`: willingness to close in from outside light
- Tune in `Monster.gd`:
  - `speed`, `hunt_speed_multiplier`, `light_buffer`

## Source of ideas for this model
These balancing ideas came from the requested gameplay fantasy:
- choose **resin** for stable control,
- choose **moss** for short power at long-term risk,
- choose **cloth** for temporary visibility rescue,
- and make enemy behavior reflect that strategic choice.
