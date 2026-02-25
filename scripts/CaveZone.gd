extends Node3D

const COLLECTIBLE_SCENE := preload("res://scripts/Collectible.gd")
const TRAP_SCENE := preload("res://scripts/CaveTrap.gd")
const DOOR_SCENE := preload("res://scripts/CaveDoor.gd")

func _ready():
	_build_collectibles()
	_build_traps()
	_build_door()

func _build_collectibles():
	_spawn_collectible(Vector3(2.5, 0.4, 3.0), "moss", Color(0.2, 0.8, 0.3))
	_spawn_collectible(Vector3(-2.0, 0.4, 1.5), "moss", Color(0.2, 0.8, 0.3))
	_spawn_collectible(Vector3(1.0, 0.4, -2.0), "cloth", Color(0.75, 0.75, 0.75))
	_spawn_collectible(Vector3(-3.0, 0.4, -2.5), "resin", Color(0.9, 0.55, 0.1))

func _spawn_collectible(pos: Vector3, item_name: String, color: Color):
	var collectible := Area3D.new()
	collectible.script = COLLECTIBLE_SCENE
	collectible.position = pos
	collectible.item_name = item_name
	collectible.amount = 1
	collectible.name = "%sCollectible" % item_name.capitalize()
	
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	mesh.mesh = sphere
	mesh.modulate = color
	collectible.add_child(mesh)
	
	var shape := CollisionShape3D.new()
	var collision := SphereShape3D.new()
	collision.radius = 0.35
	shape.shape = collision
	collectible.add_child(shape)
	
	add_child(collectible)

func _build_traps():
	_spawn_trap(Vector3(0, 0.4, -5.2), "Boulder Trap", "cloth", Color(0.35, 0.35, 0.35), Vector3(1.2, 1.2, 1.2))
	_spawn_trap(Vector3(4.0, 0.3, -1.0), "Spike Pit", "resin", Color(0.65, 0.1, 0.1), Vector3(1.8, 0.6, 1.8))

func _spawn_trap(pos: Vector3, trap_name: String, disable_item: String, color: Color, size: Vector3):
	var trap := Area3D.new()
	trap.script = TRAP_SCENE
	trap.position = pos
	trap.trap_name = trap_name
	trap.disable_item = disable_item
	trap.name = trap_name.replace(" ", "")
	
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.modulate = color
	trap.add_child(mesh)
	
	var shape := CollisionShape3D.new()
	var collision := BoxShape3D.new()
	collision.size = size
	shape.shape = collision
	trap.add_child(shape)
	
	add_child(trap)

func _build_door():
	var door := StaticBody3D.new()
	door.script = DOOR_SCENE
	door.position = Vector3(0, 1.3, -8.2)
	door.name = "CaveDoor"
	
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = Vector3(2.3, 2.6, 0.3)
	mesh.mesh = cube
	mesh.modulate = Color(0.4, 0.22, 0.15)
	door.add_child(mesh)
	
	var shape := CollisionShape3D.new()
	var collision := BoxShape3D.new()
	collision.size = Vector3(2.3, 2.6, 0.3)
	shape.shape = collision
	door.add_child(shape)
	
	add_child(door)
