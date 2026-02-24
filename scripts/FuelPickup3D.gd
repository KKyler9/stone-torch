extends Area3D
class_name FuelPickup3D

signal picked(kind: String, amount: float)

var kind := "moss"
var amount := 16.0

@onready var mesh: MeshInstance3D = $Mesh

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_color()

func configure(fuel_kind: String, fuel_amount: float) -> void:
	kind = fuel_kind
	amount = fuel_amount
	_update_color()

func _on_body_entered(body: Node) -> void:
	if body is Player3D:
		picked.emit(kind, amount)
		queue_free()

func _update_color() -> void:
	if mesh == null:
		return
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.6
	mat.albedo_color = Color(0.35, 0.8, 0.35)
	if kind == "cloth":
		mat.albedo_color = Color(0.85, 0.85, 0.85)
	elif kind == "resin":
		mat.albedo_color = Color(0.95, 0.65, 0.3)
	mesh.material_override = mat
