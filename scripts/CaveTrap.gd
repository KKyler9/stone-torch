extends Area3D

@export var trap_name := "Trap"
@export var disable_item := "cloth"
@export var fuel_damage := 14.0

var is_active := true

func _ready():
	add_to_group("interactable")
	monitoring = true
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if not is_active:
		return
	if body and body.has_method("apply_trap_hit"):
		body.apply_trap_hit(trap_name, fuel_damage)

func get_interact_text(player) -> String:
	if not is_active:
		return "%s disabled" % trap_name
	var count := 0
	if player and player.has_method("get_item_count"):
		count = player.get_item_count(disable_item)
	return "Disable %s (%s x1, have %d)" % [trap_name, disable_item, count]

func interact(player):
	if not is_active:
		return
	if player and player.has_method("consume_item") and player.consume_item(disable_item, 1):
		is_active = false
		monitoring = false
		if player.has_method("show_feedback"):
			player.show_feedback("Disabled %s" % trap_name)
		var owner = get_node_or_null("Mesh")
		if owner and owner is MeshInstance3D:
			(owner as MeshInstance3D).modulate = Color(0.4, 0.4, 0.4)
	else:
		if player and player.has_method("show_feedback"):
			player.show_feedback("Need %s to disable %s" % [disable_item, trap_name])
