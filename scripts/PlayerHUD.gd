extends CanvasLayer
class_name PlayerHUD

@onready var root: Control = $Root
@onready var prompt_label: Label = $Root/PromptLabel
@onready var feedback_label: Label = $Root/FeedbackLabel
@onready var slot_labels := [
	$Root/Hotbar/Slot1Label,
	$Root/Hotbar/Slot2Label,
	$Root/Hotbar/Slot3Label,
]

func _ready():
	_disable_input_capture()

func _disable_input_capture():
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for label in slot_labels:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_prompt(text: String):
	prompt_label.text = text

func set_feedback(text: String):
	feedback_label.text = text

func update_hotbar(slot_items: Array, inventory: Dictionary, selected_slot: int):
	for i in slot_labels.size():
		var item_name: String = slot_items[i]
		var marker := "  "
		if i == selected_slot:
			marker = "> "
		var count := int(inventory.get(item_name, 0))
		slot_labels[i].text = "%s[%d] %s x%d" % [marker, i + 1, item_name.capitalize(), count]
