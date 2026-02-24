extends Node2D

const ZONE_1 := 1
const ZONE_2 := 2
const ZONE_3 := 3

const GROUND_TEX := preload("res://assets/textures/ground_tile.svg")
const TREE_TEX := preload("res://assets/textures/tree.svg")
const GRASS_TEX := preload("res://assets/textures/grass_patch.svg")

const FUEL_TABLE := [
	{"kind": "moss", "value": 16.0},
	{"kind": "cloth", "value": 22.0},
	{"kind": "resin", "value": 28.0}
]

var zone := ZONE_1
var deaths := 0
var meta_embers := 0
var upgrades := {
	"longer_flame": 0.0,
	"wind_resist": 0.0,
	"stamina": 0.0,
	"ember_relight": false
}

var player: Player
var hud: HUD
var beacon_position := Vector2.ZERO
var collected_count := 0
var objective_count := 0
var can_finish := false
var run_over := false

var inventory := {
	"moss": 0,
	"cloth": 0,
	"resin": 0
}

func _ready() -> void:
	randomize()
	load_progress()
	hud = HUD.new()
	add_child(hud)
	start_zone(_starting_zone())

func _starting_zone() -> int:
	if deaths >= 6:
		return ZONE_3
	if deaths >= 2:
		return ZONE_2
	return ZONE_1

func clear_world() -> void:
	for child in get_children():
		if child == hud:
			continue
		child.queue_free()

func start_zone(target_zone: int) -> void:
	clear_world()
	zone = target_zone
	run_over = false
	can_finish = false
	collected_count = 0
	objective_count = 0
	inventory = {"moss": 0, "cloth": 0, "resin": 0}

	player = Player.new()
	player.position = Vector2(90, 90)
	player.apply_upgrades(upgrades)
	player.flame_state_changed.connect(_on_flame_state_changed)
	player.torch_extinguished.connect(_on_torch_extinguished)
	add_child(player)

	match zone:
		ZONE_1:
			setup_cave_zone()
		ZONE_2:
			setup_forest_zone()
		ZONE_3:
			setup_village_zone()

	_on_flame_state_changed(player.state_name)
	update_hud()

func setup_cave_zone() -> void:
	spawn_environment_art(3, 10)
	beacon_position = Vector2(1140, 640)
	objective_count = 7
	spawn_fuels(8, Rect2(120, 110, 940, 500), false)
	spawn_creatures(3, Rect2(220, 140, 820, 440))
	player.set_environment_pressures(0.0, 0.5)
	hud.set_prompt("Cave: gather fuel, learn the dark, reach the tunnel exit.")

func setup_forest_zone() -> void:
	spawn_environment_art(14, 22)
	beacon_position = Vector2(1170, 660)
	objective_count = 10
	var shift := randi_range(-70, 70)
	spawn_fuels(12, Rect2(130 + shift, 120, 930, 500), true)
	spawn_creatures(5, Rect2(170, 120, 930, 520))
	player.set_environment_pressures(max(0.1, 1.2 - float(upgrades["wind_resist"])), 0.3)
	hud.set_prompt("Forest: long sightlines, wind gusts, and uncertain paths.")

func setup_village_zone() -> void:
	spawn_environment_art(8, 16)
	beacon_position = Vector2(1180, 650)
	objective_count = 9
	var shift := randi_range(-40, 40)
	spawn_fuels(10, Rect2(150 + shift, 130, 900, 470), true)
	spawn_creatures(7, Rect2(180, 120, 900, 520))
	player.set_environment_pressures(0.4, 0.9)
	hud.set_prompt("Ash Village: escort hope to the unlit tower.")


func spawn_environment_art(tree_count: int, grass_count: int) -> void:
	for y in range(0, 12):
		for x in range(0, 20):
			var tile := Sprite2D.new()
			tile.texture = GROUND_TEX
			tile.position = Vector2(32 + x * 64, 32 + y * 64)
			tile.z_index = -20
			add_child(tile)

	for _i in range(grass_count):
		var grass := Sprite2D.new()
		grass.texture = GRASS_TEX
		grass.position = Vector2(randf_range(60, 1220), randf_range(60, 680))
		grass.z_index = -10
		add_child(grass)

	for _i in range(tree_count):
		var tree := Sprite2D.new()
		tree.texture = TREE_TEX
		tree.position = Vector2(randf_range(80, 1200), randf_range(80, 680))
		tree.z_index = -9
		add_child(tree)

func spawn_fuels(amount: int, region: Rect2, empowered: bool) -> void:
	for _i in range(amount):
		var fuel := FuelPickup.new()
		fuel.position = Vector2(
			randf_range(region.position.x, region.position.x + region.size.x),
			randf_range(region.position.y, region.position.y + region.size.y)
		)
		var entry: Dictionary = FUEL_TABLE[randi() % FUEL_TABLE.size()]
		var bonus := 3.0 if empowered else 0.0
		fuel.configure(String(entry["kind"]), float(entry["value"]) + bonus)
		fuel.picked.connect(_on_fuel_picked)
		add_child(fuel)

func spawn_creatures(amount: int, region: Rect2) -> void:
	for _i in range(amount):
		var creature := Monster.new()
		creature.position = Vector2(
			randf_range(region.position.x, region.position.x + region.size.x),
			randf_range(region.position.y, region.position.y + region.size.y)
		)
		creature.chase_target = player
		add_child(creature)

func _process(_delta: float) -> void:
	if player == null or run_over:
		return

	if Input.is_action_just_pressed("interact"):
		try_feed_torch()

	if collected_count >= objective_count and player.global_position.distance_to(beacon_position) < 35.0:
		can_finish = true

	if zone < ZONE_3 and can_finish:
		advance_zone()
	elif zone == ZONE_3 and can_finish:
		hud.set_prompt("Beacon is ready. Press [E] to return the flame.")
		if Input.is_action_just_pressed("interact"):
			finish_game()

	update_hud()
	queue_redraw()

func _draw() -> void:
	draw_circle(beacon_position, 14.0, Color(0.35, 0.65, 1.0, 0.7))

func try_feed_torch() -> void:
	if not player.can_refuel():
		hud.set_prompt("You steady your breath. The flame needs no fuel yet.")
		return

	var selected := ""
	if inventory["resin"] > 0:
		selected = "resin"
	elif inventory["cloth"] > 0:
		selected = "cloth"
	elif inventory["moss"] > 0:
		selected = "moss"

	if selected == "":
		hud.set_prompt("No fuel in hand. Search the dark.")
		return

	inventory[selected] -= 1
	var val := 16.0
	if selected == "cloth":
		val = 22.0
	elif selected == "resin":
		val = 30.0

	hud.set_prompt("You kneel to feed the flame. You are exposed.")
	await player.feed_flame(val)
	meta_embers += 1
	update_hud()

func _on_fuel_picked(kind: String, _amount: float) -> void:
	if not inventory.has(kind):
		return
	inventory[kind] += 1
	collected_count += 1
	hud.set_prompt("You collect %s." % kind)
	update_hud()

func _on_flame_state_changed(state_name: String) -> void:
	for node in get_children():
		if node is Monster:
			var creature := node as Monster
			match state_name:
				"healthy":
					creature.set_behavior("observe")
				"hungry", "failing":
					creature.set_behavior("encroach")
				"ember":
					creature.set_behavior("claim")
				_:
					creature.set_behavior("claim")

func _on_torch_extinguished() -> void:
	if run_over:
		return
	run_over = true

	if bool(upgrades["ember_relight"]):
		upgrades["ember_relight"] = false
		player.flame_value = 20.0
		player.state_name = "ember"
		player.flame_state_changed.emit("ember")
		hud.set_prompt("A buried ember catches. One final chance.")
		run_over = false
		return

	deaths += 1
	meta_embers += int(collected_count / 2)
	apply_meta_progress()
	save_progress()
	hud.set_prompt("Silence. A figure stands before you. The run ends.")
	await get_tree().create_timer(2.2).timeout
	start_zone(_starting_zone())

func apply_meta_progress() -> void:
	if meta_embers >= 4 and upgrades["longer_flame"] < 30.0:
		upgrades["longer_flame"] += 5.0
		meta_embers -= 4
	elif meta_embers >= 4 and upgrades["wind_resist"] < 0.8:
		upgrades["wind_resist"] += 0.2
		meta_embers -= 4
	elif meta_embers >= 5 and upgrades["stamina"] < 25.0:
		upgrades["stamina"] += 5.0
		meta_embers -= 5
	elif meta_embers >= 6 and not bool(upgrades["ember_relight"]):
		upgrades["ember_relight"] = true
		meta_embers -= 6

func advance_zone() -> void:
	if zone == ZONE_1:
		start_zone(ZONE_2)
	elif zone == ZONE_2:
		start_zone(ZONE_3)

func finish_game() -> void:
	run_over = true
	hud.set_prompt("The beacon ignites. The watchers are revealed in stone. Darkness ends.")
	save_progress(true)
	await get_tree().create_timer(4.0).timeout
	start_zone(ZONE_1)

func update_hud() -> void:
	if player == null:
		return

	var obj := "Zone %d | Gathered %d/%d | Reach beacon" % [zone, collected_count, objective_count]
	hud.set_objective(obj)

	var mood := "Flame steady"
	match player.state_name:
		"healthy":
			mood = "Flame steady"
		"hungry":
			mood = "Flame flickers"
		"failing":
			mood = "Shadows close in"
		"ember":
			mood = "Only embers remain"
		"out":
			mood = "No flame"
	hud.set_mood(mood)

	hud.set_inventory("Fuel in hand → moss:%d cloth:%d resin:%d" % [inventory["moss"], inventory["cloth"], inventory["resin"]])

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
