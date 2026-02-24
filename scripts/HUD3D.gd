extends CanvasLayer
class_name HUD3D

var objective := Label.new()
var mood := Label.new()
var prompt := Label.new()
var fuel := Label.new()

func _ready() -> void:
	objective.position = Vector2(16, 14)
	mood.position = Vector2(16, 40)
	prompt.position = Vector2(16, 66)
	fuel.position = Vector2(16, 92)
	prompt.modulate = Color(1.0, 0.86, 0.55)
	add_child(objective)
	add_child(mood)
	add_child(prompt)
	add_child(fuel)

func set_objective(t: String) -> void:
	objective.text = t

func set_mood(t: String) -> void:
	mood.text = t

func set_prompt(t: String) -> void:
	prompt.text = t

func set_fuel(t: String) -> void:
	fuel.text = t
