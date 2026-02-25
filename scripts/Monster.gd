extends CharacterBody3D

@export var speed := 1.6
@export var hunt_speed_multiplier := 1.8
@export var light_buffer := 2.0   # extra distance outside light before approaching

var player : Node3D
var torch : Node

func _ready():
	player = get_tree().get_first_node_in_group("player")

	if player:
		# TorchPivot is the node that has Torch.gd attached
		torch = player.get_node("TorchPivot")


func _physics_process(delta):

	if not player or not torch:
		return

	# If torch is completely out -> aggressive hunt mode
	if torch.state == torch.TorchState.OUT:
		chase_player(delta)
		return

	var light_node = torch.get_node("TorchLight")
	var light_range = light_node.omni_range

	var dist = global_position.distance_to(player.global_position)

	# Outside the torch light -> creep closer
	if dist > light_range + light_buffer:
		move_closer(delta)

	# Inside torch light -> retreat
	else:
		move_away(delta)


# ---------------------------
# Movement Behaviors
# ---------------------------

func chase_player(delta):
	var dir = (player.global_position - global_position)
	dir.y = 0
	dir = dir.normalized()

	velocity.x = dir.x * speed * hunt_speed_multiplier
	velocity.z = dir.z * speed * hunt_speed_multiplier

	move_and_slide()


func move_closer(delta):
	var dir = (player.global_position - global_position)
	dir.y = 0
	dir = dir.normalized()

	velocity.x = dir.x * speed * 0.7
	velocity.z = dir.z * speed * 0.7

	move_and_slide()


func move_away(delta):
	var dir = (global_position - player.global_position)
	dir.y = 0
	dir = dir.normalized()

	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

	move_and_slide()
