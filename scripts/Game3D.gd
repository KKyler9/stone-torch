extends Node3D

const ZONE_1 := 1
const ZONE_2 := 2
const ZONE_3 := 3

const FUEL_TABLE := [
	{"kind": "moss", "value": 16.0},
	{"kind": "cloth", "value": 22.0},
	{"kind": "resin", "value": 28.0}
]

var zone := ZONE_1
var deaths := 0
var meta_embers := 0
var upgrades := {"longer_flame": 0.0, "wind_resist": 0.0, "stamina": 0.0, "ember_relight": false}

var player: Player3D
var hud: HUD3D
var beacon_position := Vector3.ZERO
var objective_count := 0
var collected_count := 0
var run_over := false
var can_finish := false
var inventory := {"moss": 0, "cloth": 0, "resin": 0}

func _ready() -> void:
	randomize()
	load_progress()
	hud = HUD3D.new()
	add_child(hud)
	start_zone(_starting_zone())

func _starting_zone() -> int:
	if deaths >= 6: return ZONE_3
	if deaths >= 2: return ZONE_2
	return ZONE_1

func clear_world() -> void:
	for c in get_children():
		if c == hud:
			continue
		c.queue_free()

func start_zone(target_zone: int) -> void:
	clear_world()
	zone = target_zone
	run_over = false
	can_finish = false
	objective_count = 0
	collected_count = 0
	inventory = {"moss": 0, "cloth": 0, "resin": 0}

	spawn_floor()
	spawn_environment(zone)

	player = preload("res://scenes/Player3D.tscn").instantiate()
	add_child(player)
	player.position = Vector3(0, 1.2, 0)
	player.apply_upgrades(upgrades)
	player.flame_state_changed.connect(_on_flame_state_changed)
	player.torch_extinguished.connect(_on_torch_extinguished)

	match zone:
		ZONE_1:
			setup_zone(Vector3(24, 0, 24), 8, 3, 0.2, 0.4, "Cave: learn to protect the torch.")
		ZONE_2:
			setup_zone(Vector3(30, 0, 30), 11, 5, max(0.1, 1.2 - float(upgrades["wind_resist"])), 0.3, "Forest: wind and exposure.")
		ZONE_3:
			setup_zone(Vector3(36, 0, 36), 12, 7, 0.45, 0.8, "Ash Village: return the flame to the beacon.")

	update_hud()

func setup_zone(beacon: Vector3, fuel_count: int, monster_count: int, wind: float, ash: float, prompt: String) -> void:
	beacon_position = beacon
	objective_count = fuel_count - 1
	spawn_beacon(beacon)
	spawn_fuels(fuel_count)
	spawn_monsters(monster_count)
	player.set_environment_pressures(wind, ash)
	hud.set_prompt(prompt)

func spawn_floor() -> void:
	var floor_mesh_instance := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(90, 90)
	floor_mesh_instance.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.19, 0.18)
	floor_mesh_instance.material_override = mat
	add_child(floor_mesh_instance)

	var floor_body := StaticBody3D.new()
	var floor_collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(90.0, 1.0, 90.0)
	floor_collision.shape = floor_shape
	floor_collision.position = Vector3(0, -0.5, 0)
	floor_body.add_child(floor_collision)
	add_child(floor_body)

func spawn_environment(zone_id: int) -> void:
	for i in range(24):
		var tree := MeshInstance3D.new()
		tree.mesh = CylinderMesh.new()
		tree.scale = Vector3(0.5, 2.0 + randf() * 2.0, 0.5)
		tree.position = Vector3(randf_range(-40, 40), 1.0, randf_range(-40, 40))
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.24, 0.18) if zone_id == ZONE_1 else Color(0.2, 0.28, 0.18)
		tree.material_override = mat
		add_child(tree)

func spawn_beacon(pos: Vector3) -> void:
	var beacon := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.8
	mesh.bottom_radius = 1.1
	mesh.height = 4.0
	beacon.mesh = mesh
	beacon.position = pos + Vector3(0, 2, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.43, 0.48)
	beacon.material_override = mat
	add_child(beacon)

func spawn_fuels(count: int) -> void:
	for _i in range(count):
		var f := preload("res://scenes/FuelPickup3D.tscn").instantiate()
		f.position = Vector3(randf_range(-35, 35), 0.5, randf_range(-35, 35))
		var entry: Dictionary = FUEL_TABLE[randi() % FUEL_TABLE.size()]
		f.configure(String(entry["kind"]), float(entry["value"]))
		f.picked.connect(_on_fuel_picked)
		add_child(f)

func spawn_monsters(count: int) -> void:
	for _i in range(count):
		var m := preload("res://scenes/Monster3D.tscn").instantiate()
		m.position = Vector3(randf_range(-30, 30), 1.0, randf_range(-30, 30))
		m.chase_target = player
		add_child(m)

func _process(_delta: float) -> void:
	if player == null or run_over:
		return
	if Input.is_action_just_pressed("interact"):
		await try_feed_torch()

	if collected_count >= objective_count and player.global_position.distance_to(beacon_position) < 3.0:
		can_finish = true

	if zone < ZONE_3 and can_finish:
		start_zone(zone + 1)
	elif zone == ZONE_3 and can_finish:
		hud.set_prompt("Press E to ignite the beacon.")
		if Input.is_action_just_pressed("interact"):
			await finish_game()

	update_hud()

func try_feed_torch() -> void:
	if not player.can_refuel():
		hud.set_prompt("The flame is stable for now.")
		return
	var kind := ""
	if inventory["resin"] > 0: kind = "resin"
	elif inventory["cloth"] > 0: kind = "cloth"
	elif inventory["moss"] > 0: kind = "moss"
	if kind == "":
		hud.set_prompt("No fuel in hand.")
		return
	inventory[kind] -= 1
	var val := 16.0
	if kind == "cloth": val = 22.0
	elif kind == "resin": val = 30.0
	hud.set_prompt("You stop and feed the torch...")
	await player.feed_flame(val)
	meta_embers += 1

func _on_fuel_picked(kind: String, _amount: float) -> void:
	if inventory.has(kind):
		inventory[kind] += 1
		collected_count += 1

func _on_flame_state_changed(state_name: String) -> void:
	for c in get_children():
		if c is Monster3D:
			if state_name == "healthy": c.set_behavior("observe")
			elif state_name == "hungry" or state_name == "failing": c.set_behavior("encroach")
			else: c.set_behavior("claim")

func _on_torch_extinguished() -> void:
	if run_over:
		return
	run_over = true
	if bool(upgrades["ember_relight"]):
		upgrades["ember_relight"] = false
		player.flame_value = 20.0
		player.state_name = "ember"
		player.flame_state_changed.emit("ember")
		hud.set_prompt("An ember reignites. One last chance.")
		run_over = false
		return
	deaths += 1
	meta_embers += int(collected_count / 2.0)
	apply_meta_progress()
	save_progress()
	hud.set_prompt("Darkness absorbs you.")
	await get_tree().create_timer(2.0).timeout
	start_zone(_starting_zone())

func apply_meta_progress() -> void:
	if meta_embers >= 4 and upgrades["longer_flame"] < 30.0:
		upgrades["longer_flame"] += 5.0; meta_embers -= 4
	elif meta_embers >= 4 and upgrades["wind_resist"] < 0.8:
		upgrades["wind_resist"] += 0.2; meta_embers -= 4
	elif meta_embers >= 5 and upgrades["stamina"] < 25.0:
		upgrades["stamina"] += 5.0; meta_embers -= 5
	elif meta_embers >= 6 and not bool(upgrades["ember_relight"]):
		upgrades["ember_relight"] = true; meta_embers -= 6

func finish_game() -> void:
	run_over = true
	hud.set_prompt("The beacon ignites. Stone figures emerge from darkness.")
	save_progress(true)
	await get_tree().create_timer(4.0).timeout
	start_zone(ZONE_1)

func update_hud() -> void:
	if player == null: return
	hud.set_objective("Zone %d | Fuel %d/%d | Reach beacon" % [zone, collected_count, objective_count])
	var mood := "Flame steady"
	if player.state_name == "hungry": mood = "Flame flickers"
	elif player.state_name == "failing": mood = "Shadows close in"
	elif player.state_name == "ember": mood = "Only embers remain"
	elif player.state_name == "out": mood = "No flame"
	hud.set_mood(mood)
	hud.set_fuel("moss:%d cloth:%d resin:%d" % [inventory["moss"], inventory["cloth"], inventory["resin"]])

func save_progress(completed: bool = false) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "deaths", deaths)
	cfg.set_value("meta", "embers", meta_embers)
	cfg.set_value("meta", "upgrades", upgrades)
	cfg.set_value("meta", "completed_once", completed)
	cfg.save("user://progress.cfg")

func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://progress.cfg") != OK:
		return
	deaths = int(cfg.get_value("meta", "deaths", 0))
	meta_embers = int(cfg.get_value("meta", "embers", 0))
	upgrades = cfg.get_value("meta", "upgrades", upgrades)
