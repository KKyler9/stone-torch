extends Area2D
class_name FuelPickup

signal picked(amount: float)

var fuel_name := "Grass"
var fuel_amount := 3.0

func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	queue_redraw()

func configure(name: String, amount: float) -> void:
	fuel_name = name
	fuel_amount = amount

func _on_body_entered(body: Node) -> void:
	if body is Player:
		picked.emit(fuel_amount)
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 7.0, Color(0.2, 0.8, 0.35))
