extends CharacterBody3D
class_name Player3D

signal flame_state_changed(state_name: String)
signal torch_extinguished

const MOUSE_SENS := 0.0025
const TORCH_COLOR := Color(1.0, 0.74, 0.42)

var walk_speed := 4.2
var sprint_speed := 6.1
var crouch_speed := 2.6
var gravity := 18.0

var stamina_max := 100.0
var stamina := 100.0
var stamina_drain := 20.0
var stamina_regen := 14.0

var flame_value := 100.0
var flame_max := 100.0
var base_drain := 3.0
var wind_pressure := 0.0
var ash_pressure := 0.0
var is_cupping := false
var is_refueling := false
var state_name := "healthy"

@onready var head: Node3D = $Head
@onready var cam: Camera3D = $Head/Camera3D
@onready var torch_light: OmniLight3D = $Head/TorchLight

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_update_torch_visuals()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENS)
		head.rotate_x(-event.relative.y * MOUSE_SENS)
		head.rotation.x = clamp(head.rotation.x, -1.2, 1.2)
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func apply_upgrades(upgrades: Dictionary) -> void:
	flame_max += float(upgrades.get("longer_flame", 0.0))
	flame_value = flame_max
	stamina_max += float(upgrades.get("stamina", 0.0))
	stamina = stamina_max

func set_environment_pressures(wind: float, ash: float) -> void:
	wind_pressure = wind
	ash_pressure = ash

func can_refuel() -> bool:
	return not is_refueling and flame_value > 0.0 and flame_value < flame_max - 5.0

func feed_flame(amount: float) -> void:
	if amount <= 0.0:
		return
	is_refueling = true
	velocity.x = 0
	velocity.z = 0
	await get_tree().create_timer(1.0).timeout
	flame_value = clamp(flame_value + amount, 0.0, flame_max)
	is_refueling = false
	_update_flame_state()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if is_refueling:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	is_cupping = Input.is_action_pressed("crouch")
	var input_vec := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir := (transform.basis * Vector3(input_vec.x, 0, input_vec.y)).normalized()

	var speed := walk_speed
	if is_cupping:
		speed = crouch_speed
	elif Input.is_action_pressed("sprint") and stamina > 0.0 and input_vec.length() > 0.1:
		speed = sprint_speed
		stamina = max(0.0, stamina - stamina_drain * delta)
	else:
		stamina = min(stamina_max, stamina + stamina_regen * delta)

	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()

func _process(delta: float) -> void:
	if flame_value <= 0.0:
		return
	var cup_mod := 0.55 if is_cupping else 1.0
	var drain: float = (base_drain + ash_pressure + wind_pressure) * cup_mod
	flame_value = max(0.0, flame_value - drain * delta)
	_update_flame_state()
	_update_torch_visuals()
	if flame_value <= 0.0:
		state_name = "out"
		flame_state_changed.emit(state_name)
		torch_extinguished.emit()

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

func _update_torch_visuals() -> void:
	var energy := 1.0
	var range_v := 10.0
	match state_name:
		"healthy":
			energy = 1.8
			range_v = 14.0
		"hungry":
			energy = 1.3
			range_v = 11.0
		"failing":
			energy = 0.95
			range_v = 8.5
		"ember":
			energy = 0.65
			range_v = 6.5
		_:
			energy = 0.2
			range_v = 4.0
	torch_light.light_energy = energy
	torch_light.omni_range = range_v
	torch_light.light_color = TORCH_COLOR
