extends CharacterBody3D
class_name Monster3D

var base_speed := 1.7
var panic_bonus := 1.2
var stand_distance := 8.0
var chase_target: Player3D
var behavior_state := "observe"

@onready var eye_mesh: MeshInstance3D = $Body

func set_behavior(state_name: String) -> void:
	behavior_state = state_name

func _physics_process(_delta: float) -> void:
	if chase_target == null:
		return
	var to_player := chase_target.global_position - global_position
	to_player.y = 0
	var dist := to_player.length()
	if dist < 0.01:
		return
	look_at(global_position + to_player.normalized(), Vector3.UP)

	var speed := base_speed + (panic_bonus if Input.is_action_pressed("sprint") else 0.0)
	var desired := Vector3.ZERO
	match behavior_state:
		"observe":
			if dist > stand_distance:
				desired = to_player.normalized() * speed * 0.7
		"encroach":
			if dist > 4.5:
				desired = to_player.normalized() * speed
		"claim":
			if dist > 2.5:
				desired = to_player.normalized() * speed * 1.2
	velocity.x = desired.x
	velocity.z = desired.z
	velocity.y = -2
	move_and_slide()

	if eye_mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1, 0.75, 0.75) if behavior_state == "claim" else Color(0.85, 0.85, 0.9)
		mat.emission_enabled = true
		mat.emission = mat.albedo_color
		mat.emission_energy_multiplier = 0.25
		eye_mesh.material_override = mat
