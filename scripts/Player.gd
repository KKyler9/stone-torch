extends CharacterBody2D
class_name Player

const TORCH_TEX := preload("res://assets/textures/torch.svg")

signal flame_state_changed(state_name: String)
signal torch_extinguished

var walk_speed := 95.0
var sprint_speed := 145.0
var crouch_speed := 65.0

var stamina_max := 100.0
var stamina := 100.0
var stamina_drain := 20.0
var stamina_regen := 16.0

var flame_value := 100.0
var flame_max := 100.0
var base_drain := 3.2
var wind_pressure := 0.0
var ash_pressure := 0.0
var is_cupping := false
var is_refueling := false

var state_name := "healthy"

func apply_upgrades(upgrades: Dictionary) -> void:
	flame_max += float(upgrades.get("longer_flame", 0.0))
	flame_value = flame_max
	stamina_max += float(upgrades.get("stamina", 0.0))
	stamina = stamina_max

func set_environment_pressures(wind: float, ash: float) -> void:
	wind_pressure = wind
	ash_pressure = ash

func light_radius() -> float:
	match state_name:
		"healthy":
			return 210.0
		"hungry":
			return 160.0
		"failing":
			return 120.0
		"ember":
			return 80.0
		_:
			return 60.0

func can_refuel() -> bool:
	return not is_refueling and flame_value > 0.0 and flame_value < flame_max - 5.0

func feed_flame(amount: float) -> void:
	if amount <= 0.0:
		return
	is_refueling = true
	velocity = Vector2.ZERO
	await get_tree().create_timer(0.9).timeout
	flame_value = clamp(flame_value + amount, 0.0, flame_max)
	is_refueling = false
	_update_flame_state()

func _ready() -> void:
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 9.0
	cs.shape = shape
	add_child(cs)

func _physics_process(delta: float) -> void:
	if is_refueling:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	is_cupping = Input.is_action_pressed("crouch")

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed := walk_speed
	if is_cupping:
		speed = crouch_speed
	elif Input.is_action_pressed("sprint") and stamina > 0.0 and input_dir.length() > 0.1:
		speed = sprint_speed
		stamina = max(0.0, stamina - stamina_drain * delta)
	else:
		stamina = min(stamina_max, stamina + stamina_regen * delta)

	velocity = input_dir * speed
	move_and_slide()

func _process(delta: float) -> void:
	if flame_value <= 0.0:
		return

	var cup_mod := 0.55 if is_cupping else 1.0
	var drain := (base_drain + ash_pressure + wind_pressure) * cup_mod
	flame_value = max(0.0, flame_value - drain * delta)
	_update_flame_state()

	if flame_value <= 0.0:
		state_name = "out"
		flame_state_changed.emit(state_name)
		torch_extinguished.emit()

	queue_redraw()

func _update_flame_state() -> void:
	var ratio: float = float(flame_value) / max(float(flame_max), 0.01)
	var new_state := state_name
	if ratio > 0.66:
		new_state = "healthy"
	elif ratio > 0.4:
		new_state = "hungry"
	elif ratio > 0.2:
		new_state = "failing"
	else:
		new_state = "ember"

	if new_state != state_name:
		state_name = new_state
		flame_state_changed.emit(state_name)

func _draw() -> void:
	draw_texture(TORCH_TEX, -TORCH_TEX.get_size() * 0.5)
	var alpha := 0.16 if not is_cupping else 0.09
	draw_arc(Vector2.ZERO, light_radius(), 0.0, TAU, 44, Color(1.0, 0.75, 0.25, alpha), 3.0)
