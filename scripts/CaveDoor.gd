extends StaticBody3D

# Simple progression gate.
# Opens once interacted with (prototype behavior: no lock condition).

var is_open := false

func _ready():
	add_to_group("interactable")

func get_interact_text(_player) -> String:
	if is_open:
		return "Door open"
	return "Open cave door"

func interact(player):
	if is_open:
		return
	is_open = true
	global_position.y += 3.0
	if player and player.has_method("show_feedback"):
		player.show_feedback("Cave door opened")
