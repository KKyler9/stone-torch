extends Node3D

enum TorchState { HEALTHY, FAILING, DYING, OUT }

@export var max_fuel := 120.0
var fuel := max_fuel
var state : TorchState = TorchState.HEALTHY

@onready var light: OmniLight3D = $TorchLight

func _process(delta):
    if state == TorchState.OUT:
        return
    fuel -= delta
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