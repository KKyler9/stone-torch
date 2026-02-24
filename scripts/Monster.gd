extends CharacterBody2D
class_name Monster

signal player_caught

var move_speed := 90.0
var fear_speed := 130.0
var catch_distance := 16.0
var chase_target: Player

func _physics_process(_delta: float) -> void:
	if chase_target == null:
		return

	var to_player := chase_target.global_position - global_position
	var distance := to_player.length()

	if distance < chase_target.light_radius:
		velocity = -to_player.normalized() * fear_speed
	else:
		velocity = to_player.normalized() * move_speed
		if distance <= catch_distance and chase_target.torch_current < 5.0:
			player_caught.emit()
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 9.0, Color(0.3, 0.05, 0.05))
	draw_circle(Vector2(-3.0, -2.0), 1.4, Color.WHITE)
	draw_circle(Vector2(3.0, -2.0), 1.4, Color.WHITE)
