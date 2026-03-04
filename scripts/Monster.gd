extends CharacterBody3D

# Shadow Monster Prototype System (Godot 4.6 typed)
# - Three placeholder monster archetypes use the same scene + script with different type values:
#   * LURKER (common observer): keeps distance in shadow and paces around perimeter.
#   * LEECH (fuel drainer): trails behind player and siphons torch fuel when close in darkness.
#   * STALKER (turn-trigger ghost): appears/disappears when player snaps view around.
# - Hard rule: these monsters avoid torch light and should not stay visible in lit radius.
# - Tension rule: they spawn/reposition behind player, not in front-facing view cone.

enum MonsterType { LURKER, LEECH, STALKER }

@export var monster_type: MonsterType = MonsterType.LURKER
@export var speed := 1.7
@export var shadow_padding := 1.8
@export var despawn_check_cooldown := 0.25
@export var leech_drain_rate := 5.5
@export var stalker_turn_threshold_degrees := 130.0
@export var stalker_toggle_cooldown := 1.0

var player: CharacterBody3D
var torch: Node
var torch_light: OmniLight3D

var _is_active := true
var _despawn_timer := 0.0
var _stalker_toggle_timer := 0.0
var _last_player_yaw := 0.0
var _last_player_position := Vector3.ZERO

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var collider: CollisionShape3D = $CollisionShape3D

func _ready():
	player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if player:
		torch = player.get_node_or_null("TorchPivot")
	if torch:
		torch_light = torch.get_node_or_null("TorchLight") as OmniLight3D

	_apply_type_visuals()
	if player:
		_last_player_yaw = player.rotation.y
		_last_player_position = player.global_position
		_place_in_shadow_behind_player()

func _physics_process(delta: float):
	if not player or not torch or not torch_light:
		return

	_despawn_timer = max(_despawn_timer - delta, 0.0)
	_stalker_toggle_timer = max(_stalker_toggle_timer - delta, 0.0)

	# If player is not moving, keep monsters mostly still to avoid noisy jitter.
	var player_moved := player.global_position.distance_to(_last_player_position) > 0.01
	_last_player_position = player.global_position

	if monster_type == MonsterType.STALKER:
		_process_stalker_visibility()

	if not _is_active:
		velocity = Vector3.ZERO
		if _despawn_timer <= 0.0 and monster_type != MonsterType.STALKER:
			_show_from_shadow()
		return

	if _is_in_torch_light():
		_hide_and_reposition()
		return

	if not player_moved:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	match monster_type:
		MonsterType.LURKER:
			_lurker_move(delta)
		MonsterType.LEECH:
			_leech_move_and_drain(delta)
		MonsterType.STALKER:
			_stalker_follow(delta)

func _lurker_move(_delta: float):
	# Lurker hovers at dark perimeter and drifts laterally.
	var target := _shadow_perimeter_target(7.0, 10.5)
	_move_towards(target, speed * 0.75)

func _leech_move_and_drain(delta: float):
	# Leech tracks from behind and drains torch when in close shadow range.
	var target := _shadow_perimeter_target(4.2, 6.2)
	_move_towards(target, speed * 1.05)

	var dist := global_position.distance_to(player.global_position)
	if dist < 2.0 and not _is_in_torch_light():
		if torch.has_method("drain_fuel"):
			torch.drain_fuel(leech_drain_rate * delta)

func _stalker_follow(_delta: float):
	# Stalker is intermittent: when active it trails from farther back.
	var target := _shadow_perimeter_target(6.5, 11.5)
	_move_towards(target, speed * 0.9)

func _process_stalker_visibility():
	# 180-style turn detection: if player rapidly changes yaw, stalker may pop.
	var current_yaw := player.rotation.y
	var turn_delta := abs(wrapf(current_yaw - _last_player_yaw, -PI, PI))
	_last_player_yaw = current_yaw

	if _stalker_toggle_timer > 0.0:
		return

	if rad_to_deg(turn_delta) >= stalker_turn_threshold_degrees:
		_stalker_toggle_timer = stalker_toggle_cooldown
		if randf() < 0.65:
			_hide_and_reposition()
		else:
			_show_from_shadow()

func _is_in_torch_light() -> bool:
	var light_range := torch_light.omni_range
	var dist := global_position.distance_to(player.global_position)
	return dist <= light_range + shadow_padding

func _hide_and_reposition():
	_is_active = false
	visible = false
	collider.disabled = true
	velocity = Vector3.ZERO
	_place_in_shadow_behind_player()
	_despawn_timer = despawn_check_cooldown

func _show_from_shadow():
	# Never reveal inside light or in front of player's gaze.
	_place_in_shadow_behind_player()
	_is_active = true
	visible = true
	collider.disabled = false

func _place_in_shadow_behind_player():
	if not player:
		return

	var forward := -player.global_transform.basis.z.normalized()
	var right := player.global_transform.basis.x.normalized()
	var light_range: float = 8.0
	if torch_light:
		light_range = torch_light.omni_range

	# Choose candidate points behind player; reject front-facing spots.
	for i in range(10):
		var behind_distance := randf_range(light_range + 2.5, light_range + 7.5)
		var side_offset := randf_range(-4.5, 4.5)
		var candidate := player.global_position - forward * behind_distance + right * side_offset
		candidate.y = global_position.y

		var to_candidate := (candidate - player.global_position).normalized()
		var facing_dot := forward.dot(to_candidate)
		if facing_dot < 0.25:
			global_position = candidate
			return

	# Fallback: hard-behind spawn.
	global_position = player.global_position - forward * (light_range + 4.0)

func _shadow_perimeter_target(min_distance: float, max_distance: float) -> Vector3:
	var forward := -player.global_transform.basis.z.normalized()
	var right := player.global_transform.basis.x.normalized()
	var back_distance := randf_range(min_distance, max_distance)
	var side_offset := randf_range(-2.0, 2.0)
	var target := player.global_position - forward * back_distance + right * side_offset
	target.y = global_position.y
	return target

func _move_towards(target: Vector3, move_speed: float):
	var dir := (target - global_position)
	dir.y = 0
	if dir.length_squared() > 0.001:
		dir = dir.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)
	move_and_slide()

func _apply_type_visuals():
	# Placeholder color coding for quick in-editor differentiation.
	var mat := StandardMaterial3D.new()
	match monster_type:
		MonsterType.LURKER:
			mat.albedo_color = Color(0.24, 0.24, 0.34) # bluish gray
		MonsterType.LEECH:
			mat.albedo_color = Color(0.5, 0.25, 0.7) # purple
		MonsterType.STALKER:
			mat.albedo_color = Color(0.9, 0.18, 0.18) # red
	mesh.material_override = mat
