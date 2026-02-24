extends Area2D
class_name FuelPickup

signal picked(kind: String, amount: float)

var kind := "moss"
var amount := 14.0

func _ready() -> void:
	monitoring = true
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 8.0
	cs.shape = shape
	add_child(cs)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func configure(fuel_kind: String, fuel_amount: float) -> void:
	kind = fuel_kind
	amount = fuel_amount

func _on_body_entered(body: Node) -> void:
	if body is Player:
		picked.emit(kind, amount)
		queue_free()

func _draw() -> void:
	var col := Color(0.2, 0.8, 0.35)
	if kind == "cloth":
		col = Color(0.8, 0.8, 0.8)
	elif kind == "resin":
		col = Color(1.0, 0.65, 0.2)
	draw_circle(Vector2.ZERO, 7.0, col)
