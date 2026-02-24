extends CharacterBody2D
class_name Player

signal torch_changed(current: float, max_value: float)
signal player_died

var walk_speed := 120.0
var sprint_speed := 190.0
var crouch_speed := 75.0

var stamina_max := 100.0
var stamina := 100.0
var stamina_drain := 26.0
var stamina_regen := 18.0

var torch_max := 60.0
var torch_current := 60.0
var torch_drain_multiplier := 1.0
var light_radius := 170.0

func apply_upgrades(upgrades: Dictionary) -> void:
	if upgrades.has("fuel_bonus"):
		torch_max += upgrades["fuel_bonus"]
		torch_current = min(torch_current, torch_max)
	if upgrades.has("light_bonus"):
		light_radius += upgrades["light_bonus"]
	if upgrades.has("stamina_bonus"):
		stamina_max += upgrades["stamina_bonus"]
		stamina = stamina_max

func add_torch_time(amount: float) -> void:
	torch_current = clamp(torch_current + amount, 0.0, torch_max)
	torch_changed.emit(torch_current, torch_max)

func _ready() -> void:
	torch_changed.emit(torch_current, torch_max)

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed := walk_speed

	if Input.is_action_pressed("crouch"):
		speed = crouch_speed
	elif Input.is_action_pressed("sprint") and stamina > 0.0 and input_dir.length() > 0.1:
		speed = sprint_speed
		stamina = max(0.0, stamina - stamina_drain * delta)
	else:
		stamina = min(stamina_max, stamina + stamina_regen * delta)

	velocity = input_dir * speed
	move_and_slide()

func _process(delta: float) -> void:
	torch_current = max(0.0, torch_current - delta * torch_drain_multiplier)
	torch_changed.emit(torch_current, torch_max)
	if torch_current <= 0.0:
		player_died.emit()
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 10.0, Color(0.95, 0.85, 0.4))
	draw_arc(Vector2.ZERO, light_radius, 0.0, TAU, 48, Color(1.0, 0.75, 0.25, 0.15), 3.0)
