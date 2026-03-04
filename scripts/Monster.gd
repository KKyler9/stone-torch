extends CharacterBody3D

# Enemy behavior notes:
# - Enemies key off torch source profile from Torch.gd.
# - aggression raises pursuit speed, fear widens retreat distance, hesitation delays approach.
# - moss adds boundary strafing for more chaotic pressure.

@export var speed := 1.6
@export var hunt_speed_multiplier := 1.8
@export var light_buffer := 2.0

var player: Node3D
var torch: Node

func _ready():
	player = get_tree().get_first_node_in_group("player")
	if player:
		torch = player.get_node("TorchPivot")

func _physics_process(delta):
	if not player or not torch:
		return

	var profile: Dictionary = {
		"aggression": 1.0,
		"fear": 1.0,
		"hesitation": 1.0,
	}
	if torch.has_method("get_enemy_modifiers"):
		profile = torch.get_enemy_modifiers()

	var aggression := _profile_value(profile, "aggression")
	var fear := _profile_value(profile, "fear")
	var hesitation := _profile_value(profile, "hesitation")

	if torch.state == torch.TorchState.OUT:
		chase_player(delta, aggression)
		return

	var light_node: OmniLight3D = torch.get_node("TorchLight")
	var light_range := light_node.omni_range * fear
	var dist := global_position.distance_to(player.global_position)
	var source: String = "base"
	if torch.has_method("get_fuel_source_name"):
		source = String(torch.get_fuel_source_name())

	# Moss flames are unstable: enemies probe around the light boundary.
	if source == "moss" and dist <= light_range + light_buffer and dist > light_range * 0.6:
		strafe_player(delta, aggression)
		return

	if dist > light_range + (light_buffer * hesitation):
		move_closer(delta, aggression)
	else:
		move_away(delta, fear)

func _profile_value(profile: Dictionary, key: String) -> float:
	# Godot 4.6 strict typing: dictionary lookups are Variant unless cast.
	return float(profile.get(key, 1.0))

func chase_player(_delta: float, aggression: float):
	var dir := (player.global_position - global_position)
	dir.y = 0
	dir = dir.normalized()

	velocity.x = dir.x * speed * hunt_speed_multiplier * aggression
	velocity.z = dir.z * speed * hunt_speed_multiplier * aggression
	move_and_slide()

func move_closer(_delta: float, aggression: float):
	var dir := (player.global_position - global_position)
	dir.y = 0
	dir = dir.normalized()

	velocity.x = dir.x * speed * 0.7 * aggression
	velocity.z = dir.z * speed * 0.7 * aggression
	move_and_slide()

func move_away(_delta: float, fear: float):
	var dir := (global_position - player.global_position)
	dir.y = 0
	dir = dir.normalized()

	velocity.x = dir.x * speed * fear
	velocity.z = dir.z * speed * fear
	move_and_slide()

func strafe_player(_delta: float, aggression: float):
	var to_player := (player.global_position - global_position)
	to_player.y = 0
	to_player = to_player.normalized()

	var lateral := Vector3(-to_player.z, 0, to_player.x)
	var blend := (to_player * 0.35) + (lateral * 0.65)
	blend = blend.normalized()

	velocity.x = blend.x * speed * aggression
	velocity.z = blend.z * speed * aggression
	move_and_slide()
