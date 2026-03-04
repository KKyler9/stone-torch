# Stone Torch - Systems Notation & Tuning Guide

This document explains *what each gameplay script is responsible for*, *why values exist*, and *how to tune them*.

## Core loop at a glance
- Player explores cave, gathers **moss / cloth / resin**.
- Fueling the torch changes light, VFX, decay speed, and enemy behavior profile.
- Traps tax fuel and can be disabled with specific resources.
- Door provides simple progression endpoint.

## Script map
- `scripts/Torch.gd`: Decay + flicker + fuel boost system, particle/light control, and AI-facing torch profile.
- `scripts/Monster.gd`: Shadow-monster behavior logic (lurker/leech/stalker) with spawn/despawn tension rules.
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

## Shadow monster archetypes (placeholder spheres)
All monster types share `Monster.tscn` + `scripts/Monster.gd` and are differentiated by `monster_type` + color:
- **Lurker (common)**: stays on dark perimeter and mostly observes.
- **Leech**: trails behind and drains torch fuel when close in darkness.
- **Stalker**: reacts to hard player turn-arounds and may appear/disappear for tension.

Behavior constraints implemented for all types:
- avoid entering the torch light radius
- hide/reposition if they drift into lit space
- respawn behind player (not in front-facing cone)
- movement is primarily driven when player moves, to keep pressure readable

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
- `Monster.gd` tuning exports:
  - `speed`
  - `shadow_padding`
  - `leech_drain_rate`
  - `stalker_turn_threshold_degrees`
  - `stalker_toggle_cooldown`

### Testing pickup density
`CaveZone.gd` currently spawns extra moss/cloth/resin nodes to speed up tuning passes.
Trim the list in `_build_collectibles()` after balance testing.

## Source of ideas for this model
These balancing ideas came from the requested gameplay fantasy:
- choose **resin** for stable control,
- choose **moss** for short power at long-term risk,
- choose **cloth** for temporary visibility rescue,
- and make enemy behavior reflect that strategic choice.
