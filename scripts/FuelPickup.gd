extends Area2D
class_name FuelPickup

const MOSS_TEX := preload("res://assets/textures/moss.svg")
const CLOTH_TEX := preload("res://assets/textures/cloth.svg")
const RESIN_TEX := preload("res://assets/textures/resin.svg")

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
	var tex: Texture2D = MOSS_TEX
	if kind == "cloth":
		tex = CLOTH_TEX
	elif kind == "resin":
		tex = RESIN_TEX
	draw_texture(tex, -tex.get_size() * 0.5)
