extends CharacterBody2D
class_name Monster

var base_speed := 55.0
var panic_bonus := 40.0
var stand_distance := 130.0
var chase_target: Player
var behavior_state := "observe"

func _ready() -> void:
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 9.0
	cs.shape = shape
	add_child(cs)

func set_behavior(state_name: String) -> void:
	behavior_state = state_name

func _physics_process(_delta: float) -> void:
	if chase_target == null:
		return

	var to_player := chase_target.global_position - global_position
	var distance := to_player.length()
	if distance < 0.001:
		return

	var sprinting := Input.is_action_pressed("sprint")
	var speed := base_speed + (panic_bonus if sprinting else 0.0)

	match behavior_state:
		"observe":
			if distance > stand_distance:
				velocity = to_player.normalized() * speed * 0.75
			else:
				velocity = Vector2.ZERO
		"encroach":
			if distance > 72.0:
				velocity = to_player.normalized() * speed
			else:
				velocity = Vector2.ZERO
		"claim":
			if distance > 42.0:
				velocity = to_player.normalized() * (speed * 1.15)
			else:
				velocity = Vector2.ZERO
		_:
			velocity = Vector2.ZERO

	if distance < chase_target.light_radius() * 0.45 and behavior_state == "observe":
		velocity -= to_player.normalized() * speed * 0.9

	move_and_slide()
	queue_redraw()

func _draw() -> void:
	var body_col := Color(0.25, 0.06, 0.06)
	if behavior_state == "claim":
		body_col = Color(0.45, 0.08, 0.08)
	draw_circle(Vector2.ZERO, 9.0, body_col)
	draw_circle(Vector2(-3.0, -2.0), 1.4, Color.WHITE)
	draw_circle(Vector2(3.0, -2.0), 1.4, Color.WHITE)
