extends CharacterBody3D

@export var speed := 5.0
@export var mouse_sensitivity := 0.003
@export var interaction_range := 3.0
@export var hud_scene: PackedScene = preload("res://ui/PlayerHUD.tscn")

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var inventory := {
	"moss": 0,
	"cloth": 0,
	"resin": 0,
}

var slot_items := ["moss", "cloth", "resin"]
var selected_slot := 0

@onready var camera: Camera3D = $Camera3D
@onready var torch: Node3D = $TorchPivot

var hud: PlayerHUD

func _ready():
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_setup_hud()
	_update_hud()

func _setup_hud():
	if not hud_scene:
		return
	hud = hud_scene.instantiate() as PlayerHUD
	if not hud:
		return
	add_child(hud)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_E:
				_try_interact()
			KEY_1:
				_use_hotbar_slot(0)
			KEY_2:
				_use_hotbar_slot(1)
			KEY_3:
				_use_hotbar_slot(2)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
	_update_interaction_prompt()

func _try_interact():
	var target = _get_interactable_target()
	if target and target.has_method("interact"):
		target.interact(self)

func _update_interaction_prompt():
	var target = _get_interactable_target()
	if target and target.has_method("get_interact_text"):
		_set_prompt("[E] %s" % target.get_interact_text(self))
	else:
		_set_prompt("")

func _set_prompt(text: String):
	if hud:
		hud.set_prompt(text)

func _get_interactable_target() -> Node:
	var from = camera.global_position
	var to = from + (-camera.global_transform.basis.z * interaction_range)
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [self]

	var result = get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return null

	var collider: Object = result.get("collider")
	if collider is Node and (collider as Node).is_in_group("interactable"):
		return collider

	if collider is Node and (collider as Node).get_parent() and (collider as Node).get_parent().is_in_group("interactable"):
		return (collider as Node).get_parent()

	return null

func add_item(item_name: String, amount := 1):
	if not inventory.has(item_name):
		return
	inventory[item_name] += amount
	show_feedback("Picked up %d %s" % [amount, item_name])
	_update_hud()

func consume_item(item_name: String, amount := 1) -> bool:
	if not inventory.has(item_name):
		return false
	if inventory[item_name] < amount:
		return false
	inventory[item_name] -= amount
	_update_hud()
	return true

func get_item_count(item_name: String) -> int:
	if not inventory.has(item_name):
		return 0
	return inventory[item_name]

func _use_hotbar_slot(slot_index: int):
	if slot_index < 0 or slot_index >= slot_items.size():
		return
	selected_slot = slot_index
	var item_name = slot_items[slot_index]
	if consume_item(item_name, 1):
		if torch and torch.has_method("add_fuel"):
			torch.add_fuel(item_name)
			show_feedback("Fueled torch with %s" % item_name)
	else:
		show_feedback("No %s in inventory" % item_name)
	_update_hud()

func apply_trap_hit(trap_name: String, fuel_loss := 10.0):
	if torch and torch.has_method("drain_fuel"):
		torch.drain_fuel(fuel_loss)
	show_feedback("Triggered trap: %s" % trap_name)

func show_feedback(message: String):
	if hud:
		hud.set_feedback(message)

func _update_hud():
	if hud:
		hud.update_hotbar(slot_items, inventory, selected_slot)
