extends CanvasLayer
class_name HUD

var objective_label := Label.new()
var mood_label := Label.new()
var prompt_label := Label.new()
var inventory_label := Label.new()

func _ready() -> void:
	objective_label.position = Vector2(16, 12)
	mood_label.position = Vector2(16, 40)
	prompt_label.position = Vector2(16, 68)
	inventory_label.position = Vector2(16, 96)
	prompt_label.modulate = Color(1.0, 0.86, 0.55)
	add_child(objective_label)
	add_child(mood_label)
	add_child(prompt_label)
	add_child(inventory_label)

func set_objective(text: String) -> void:
	objective_label.text = text

func set_mood(text: String) -> void:
	mood_label.text = text

func set_prompt(text: String) -> void:
	prompt_label.text = text

func set_inventory(text: String) -> void:
	inventory_label.text = text
