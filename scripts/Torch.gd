extends Node3D

# Torch System Design Notes
# - This script drives three linked systems: decay, flicker, and temporary fuel boosts.
# - Design intention:
#   * moss  -> quick unstable boost, then harsher decay (high risk / high tempo)
#   * cloth -> emergency brightness burst with short fuel retention bump
#   * resin -> stable low-flicker flame with slower decay and wide radius
# - Tuning quick start:
#   * overall game pace: increase/decrease `base_decay_rate`
#   * visual chaos: adjust `base_flicker_rate` and `base_flicker_amount`
#   * each fuel personality: tweak source-specific multipliers below

signal fuel_source_changed(source: String)

enum TorchState { HEALTHY, FAILING, DYING, OUT }
enum FuelSource { BASE, MOSS, CLOTH, RESIN }

# --- Fuel economy -----------------------------------------------------------
@export var max_fuel := 120.0
@export var moss_fuel_gain := 12.0
@export var cloth_fuel_gain := 20.0
@export var resin_fuel_gain := 30.0

# --- Decay profile ----------------------------------------------------------
@export var base_decay_rate := 1.0
@export var moss_boost_duration := 2.2
@export var moss_boost_decay_multiplier := 0.4
@export var moss_after_decay_multiplier := 1.75
@export var cloth_boost_duration := 3.6
@export var cloth_boost_decay_multiplier := 0.35
@export var resin_decay_multiplier := 0.62

# --- Flicker profile --------------------------------------------------------
@export var base_flicker_rate := 4.0
@export var base_flicker_amount := 0.15
@export var moss_flicker_rate_multiplier := 1.9
@export var moss_flicker_amount_multiplier := 1.3
@export var cloth_flicker_rate_multiplier := 1.2
@export var cloth_flicker_amount_multiplier := 1.0
@export var resin_flicker_rate_multiplier := 0.65
@export var resin_flicker_amount_multiplier := 0.4

var fuel := max_fuel
var state: TorchState = TorchState.HEALTHY
var fuel_source: FuelSource = FuelSource.BASE

# Effect runtime state:
# - _effect_timer: temporary boost window for moss/cloth
# - _moss_afterburn: once moss boost expires, decay becomes harsher
var _effect_timer := 0.0
var _moss_afterburn := false
var _flicker_clock := 0.0
var _smoothed_energy := 3.0

@onready var light: OmniLight3D = $TorchLight
@onready var flame_particles: GPUParticles3D = $FireParticle
@onready var spark_particles: GPUParticles3D = $FireParticle/SparkParticle

func _ready():
	# Duplicate materials so this torch instance can safely mutate particle values.
	_prepare_particle_materials()
	update_state()
	apply_visuals(0.0)

func _process(delta):
	if state == TorchState.OUT:
		return

	fuel = max(fuel - _current_decay_rate() * delta, 0.0)
	_tick_source_effect(delta)
	update_state()
	apply_visuals(delta)

func add_fuel(resource_name: String):
	# Maps item pickups to fuel gain and source behavior profile.
	var gain := 0.0
	match resource_name:
		"moss":
			gain = moss_fuel_gain
			_set_fuel_source(FuelSource.MOSS)
			_effect_timer = moss_boost_duration
			_moss_afterburn = false
		"cloth":
			gain = cloth_fuel_gain
			_set_fuel_source(FuelSource.CLOTH)
			_effect_timer = cloth_boost_duration
			_moss_afterburn = false
		"resin":
			gain = resin_fuel_gain
			_set_fuel_source(FuelSource.RESIN)
			_effect_timer = 0.0
			_moss_afterburn = false
	if gain <= 0.0:
		return

	fuel = clamp(fuel + gain, 0.0, max_fuel)
	# If fuel was out, particles should relight.
	flame_particles.emitting = true
	spark_particles.emitting = true
	update_state()
	apply_visuals(0.0)

func drain_fuel(amount: float):
	fuel = max(fuel - amount, 0.0)
	update_state()
	apply_visuals(0.0)

func get_fuel_percent() -> float:
	if max_fuel <= 0.0:
		return 0.0
	return clamp(fuel / max_fuel, 0.0, 1.0)

func get_fuel_source_name() -> String:
	match fuel_source:
		FuelSource.MOSS:
			return "moss"
		FuelSource.CLOTH:
			return "cloth"
		FuelSource.RESIN:
			return "resin"
		_:
			return "base"

func get_enemy_modifiers() -> Dictionary:
	# AI profile consumed by Monster.gd.
	# aggression: pursuit speed bias
	# fear: light safety distance multiplier
	# hesitation: how far outside light they wait before approaching
	var profile := {
		"aggression": 1.0,
		"fear": 1.0,
		"hesitation": 1.0,
	}

	match fuel_source:
		FuelSource.MOSS:
			profile.aggression = 1.25
			profile.fear = 0.75
			profile.hesitation = 0.6
		FuelSource.CLOTH:
			profile.aggression = 0.85
			profile.fear = 1.1
			profile.hesitation = 1.05
		FuelSource.RESIN:
			profile.aggression = 0.65
			profile.fear = 1.4
			profile.hesitation = 1.3

	if state == TorchState.DYING:
		profile.aggression *= 1.35
		profile.fear *= 0.8
	elif state == TorchState.OUT:
		profile.aggression *= 1.8
		profile.fear *= 0.5

	return profile

func update_state():
	var percent := get_fuel_percent()
	if percent > 0.5:
		state = TorchState.HEALTHY
	elif percent > 0.2:
		state = TorchState.FAILING
	elif percent > 0:
		state = TorchState.DYING
	else:
		state = TorchState.OUT
		light.light_energy = 0.0
		flame_particles.emitting = false
		spark_particles.emitting = false

func apply_visuals(delta: float):
	if state == TorchState.OUT:
		return

	var percent := get_fuel_percent()
	var source_data := _source_visual_modifiers()

	# State-driven baseline: healthy has larger radius/energy than dying.
	var base_range := lerp(3.0, 10.0, percent)
	var base_energy := lerp(0.9, 3.3, percent)

	# Source overlays: resin wider radius, cloth brighter during burst, etc.
	light.omni_range = base_range * source_data.radius_mult

	var target_energy := base_energy * source_data.energy_mult
	var flicker := _sample_flicker(delta, source_data)
	_smoothed_energy = lerp(_smoothed_energy, target_energy + flicker, 0.22)
	light.light_energy = max(_smoothed_energy, 0.1)

	_update_particle_visuals(percent, source_data)

func _sample_flicker(delta: float, source_data: Dictionary) -> float:
	_flicker_clock += delta * base_flicker_rate * source_data.flicker_rate_mult
	var random_component := randf_range(-1.0, 1.0) * base_flicker_amount * source_data.flicker_amount_mult
	return sin(_flicker_clock) * base_flicker_amount * source_data.flicker_amount_mult + random_component

func _update_particle_visuals(percent: float, source_data: Dictionary):
	var flame_material := flame_particles.process_material as ParticleProcessMaterial
	var spark_material := spark_particles.process_material as ParticleProcessMaterial

	# Healthy torch => fuller, taller flame.
	var flame_life := lerp(0.5, 1.15, percent)
	var flame_intensity := clamp(percent * source_data.flame_mult, 0.15, 1.25)

	flame_particles.amount_ratio = clamp(flame_intensity, 0.15, 1.0)
	flame_particles.lifetime = flame_life
	flame_particles.speed_scale = lerp(0.75, 1.2, percent) * source_data.flame_speed_mult
	flame_material.spread = lerp(6.0, 16.0, percent) * source_data.flame_spread_mult
	flame_material.initial_velocity_min = lerp(0.35, 1.1, percent)
	flame_material.initial_velocity_max = lerp(0.9, 2.3, percent) * source_data.flame_speed_mult

	# Smolder stage => smaller flame but more active sparks.
	var smolder_factor := 1.0 - percent
	var spark_ratio := clamp(0.2 + (smolder_factor * 0.95) * source_data.spark_mult, 0.1, 1.0)
	spark_particles.amount_ratio = spark_ratio
	spark_particles.lifetime = lerp(0.45, 0.9, smolder_factor)
	spark_particles.speed_scale = lerp(1.4, 0.7, percent)
	spark_material.spread = lerp(10.0, 36.0, smolder_factor) * source_data.spark_spread_mult
	spark_material.initial_velocity_min = lerp(0.5, 0.9, smolder_factor)
	spark_material.initial_velocity_max = lerp(1.2, 2.7, smolder_factor)

func _source_visual_modifiers() -> Dictionary:
	var data := {
		"radius_mult": 1.0,
		"energy_mult": 1.0,
		"flicker_rate_mult": 1.0,
		"flicker_amount_mult": 1.0,
		"flame_mult": 1.0,
		"flame_spread_mult": 1.0,
		"flame_speed_mult": 1.0,
		"spark_mult": 1.0,
		"spark_spread_mult": 1.0,
	}

	match fuel_source:
		FuelSource.MOSS:
			data.flicker_rate_mult = moss_flicker_rate_multiplier
			data.flicker_amount_mult = moss_flicker_amount_multiplier
			data.flame_speed_mult = 1.15
			data.flame_spread_mult = 1.1
			data.spark_mult = 1.2
			data.spark_spread_mult = 1.25
		FuelSource.CLOTH:
			data.energy_mult = 1.2 if _effect_timer > 0.0 else 1.02
			data.radius_mult = 1.1 if _effect_timer > 0.0 else 1.0
			data.flicker_rate_mult = cloth_flicker_rate_multiplier
			data.flicker_amount_mult = cloth_flicker_amount_multiplier
			data.flame_mult = 1.1
		FuelSource.RESIN:
			data.radius_mult = 1.35
			data.energy_mult = 1.12
			data.flicker_rate_mult = resin_flicker_rate_multiplier
			data.flicker_amount_mult = resin_flicker_amount_multiplier
			data.flame_spread_mult = 0.8
			data.spark_mult = 0.7
			data.spark_spread_mult = 0.75

	return data

func _current_decay_rate() -> float:
	# Decay strategy by source:
	# moss: brief efficient burn, then afterburn penalty
	# cloth: brief efficient burn then return to base
	# resin: always slower than base while active
	match fuel_source:
		FuelSource.MOSS:
			if _effect_timer > 0.0:
				return base_decay_rate * moss_boost_decay_multiplier
			if _moss_afterburn:
				return base_decay_rate * moss_after_decay_multiplier
		FuelSource.CLOTH:
			if _effect_timer > 0.0:
				return base_decay_rate * cloth_boost_decay_multiplier
		FuelSource.RESIN:
			return base_decay_rate * resin_decay_multiplier
	return base_decay_rate

func _tick_source_effect(delta: float):
	if fuel_source == FuelSource.RESIN:
		return

	if _effect_timer > 0.0:
		_effect_timer = max(_effect_timer - delta, 0.0)
		if fuel_source == FuelSource.MOSS and _effect_timer == 0.0:
			_moss_afterburn = true
		if fuel_source == FuelSource.CLOTH and _effect_timer == 0.0:
			_set_fuel_source(FuelSource.BASE)

func _set_fuel_source(new_source: FuelSource):
	if fuel_source == new_source:
		return
	fuel_source = new_source
	emit_signal("fuel_source_changed", get_fuel_source_name())

func _prepare_particle_materials():
	if flame_particles.process_material:
		flame_particles.process_material = (flame_particles.process_material as ParticleProcessMaterial).duplicate()
	if spark_particles.process_material:
		spark_particles.process_material = (spark_particles.process_material as ParticleProcessMaterial).duplicate()
