extends CanvasLayer
class_name HUD

var status_label := Label.new()
var objective_label := Label.new()
var prompt_label := Label.new()

func _ready() -> void:
	status_label.position = Vector2(16, 12)
	objective_label.position = Vector2(16, 44)
	prompt_label.position = Vector2(16, 76)
	prompt_label.modulate = Color(1.0, 0.85, 0.6)
	add_child(status_label)
	add_child(objective_label)
	add_child(prompt_label)

func set_status(text: String) -> void:
	status_label.text = text

func set_objective(text: String) -> void:
	objective_label.text = text

func set_prompt(text: String) -> void:
	prompt_label.text = text
