extends Area3D

@export var item_name := "moss"
@export var amount := 1

func _ready():
	add_to_group("interactable")
	monitoring = true

func get_interact_text(_player) -> String:
	return "Collect %s" % item_name

func interact(player):
	if player and player.has_method("add_item"):
		player.add_item(item_name, amount)
	queue_free()
