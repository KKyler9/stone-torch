extends Area2D
class_name Trap

var torch_penalty := 8.0
var cooldown := 1.25
var _armed := true

func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if not _armed:
		return
	if body is Player:
		(body as Player).add_torch_time(-torch_penalty)
		_armed = false
		await get_tree().create_timer(cooldown).timeout
		_armed = true

func _draw() -> void:
	draw_circle(Vector2.ZERO, 8.0, Color(0.8, 0.1, 0.1, 0.8))
