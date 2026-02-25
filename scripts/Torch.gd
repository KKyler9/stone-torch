extends Node3D

enum TorchState { HEALTHY, FAILING, DYING, OUT }

@export var max_fuel := 120.0
@export var moss_fuel_gain := 12.0
@export var cloth_fuel_gain := 20.0
@export var resin_fuel_gain := 30.0

var fuel := max_fuel
var state: TorchState = TorchState.HEALTHY

@onready var light: OmniLight3D = $TorchLight

func _process(delta):
	if state == TorchState.OUT:
		return
	fuel -= delta
	update_state()
	apply_visuals()

func add_fuel(resource_name: String):
	var gain := 0.0
	match resource_name:
		"moss":
			gain = moss_fuel_gain
		"cloth":
			gain = cloth_fuel_gain
		"resin":
			gain = resin_fuel_gain
	if gain <= 0.0:
		return
	fuel = clamp(fuel + gain, 0.0, max_fuel)
	update_state()
	apply_visuals()

func drain_fuel(amount: float):
	fuel = max(fuel - amount, 0.0)
	update_state()
	apply_visuals()

func update_state():
	var percent = fuel / max_fuel
	if percent > 0.5:
		state = TorchState.HEALTHY
	elif percent > 0.2:
		state = TorchState.FAILING
	elif percent > 0:
		state = TorchState.DYING
	else:
		state = TorchState.OUT
		light.light_energy = 0.0

func apply_visuals():
	match state:
		TorchState.HEALTHY:
			light.omni_range = 10.0
			light.light_energy = 3.0
		TorchState.FAILING:
			light.omni_range = 6.0
			light.light_energy = 2.0
		TorchState.DYING:
			light.omni_range = 3.0
			light.light_energy = 1.0
