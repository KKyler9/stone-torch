extends Node2D

const ZONE_1 := 1
const ZONE_2 := 2
const ZONE_3 := 3

const FUEL_TABLE := [
	{"name": "Grass", "value": 3.0},
	{"name": "Vines", "value": 4.0},
	{"name": "Moss", "value": 5.0},
	{"name": "Scrap Cloth", "value": 7.0}
]

var zone := ZONE_1
var unlocked_zone := ZONE_1
var meta_embers := 0
var upgrades := {
	"fuel_bonus": 0.0,
	"light_bonus": 0.0,
	"stamina_bonus": 0.0
}

var player: Player
var hud: HUD
var exit_position := Vector2.ZERO
var objective_count := 0
var collected_count := 0
var at_beacon := false

func _ready() -> void:
	randomize()
	load_progress()
	hud = HUD.new()
	add_child(hud)
	start_zone(zone)

func clear_world() -> void:
	for child in get_children():
		if child == hud:
			continue
		child.queue_free()

func start_zone(target_zone: int) -> void:
	clear_world()
	zone = target_zone
	collected_count = 0
	at_beacon = false

	player = Player.new()
	player.position = Vector2(80, 80)
	player.apply_upgrades(upgrades)
	player.player_died.connect(_on_player_died)
	player.torch_changed.connect(_on_torch_changed)
	add_child(player)

	match zone:
		ZONE_1:
			setup_fixed_zone("Cave", 7, 4, 2, Vector2(1120, 620))
		ZONE_2:
			setup_procedural_zone("Forest", 12, 7, 3, Vector2(1180, 660))
		ZONE_3:
			setup_final_zone()

	update_objective_text()

func setup_fixed_zone(zone_name: String, fuels: int, traps: int, monsters: int, exit_pos: Vector2) -> void:
	exit_position = exit_pos
	objective_count = fuels
	spawn_fuels(fuels, Rect2(100, 100, 980, 520), false)
	spawn_traps(traps, Rect2(180, 120, 920, 500))
	spawn_monsters(monsters, Rect2(220, 120, 900, 480))
	hud.set_prompt("%s: gather fuel and reach the exit marker." % zone_name)

func setup_procedural_zone(zone_name: String, fuels: int, traps: int, monsters: int, exit_pos: Vector2) -> void:
	exit_position = exit_pos
	objective_count = fuels
	spawn_fuels(fuels, Rect2(120, 100, 1000, 540), true)
	spawn_traps(traps, Rect2(120, 100, 1000, 540))
	spawn_monsters(monsters, Rect2(150, 120, 960, 500))
	player.torch_drain_multiplier = 1.2
	hud.set_prompt("%s winds drain your torch faster. Keep moving." % zone_name)

func setup_final_zone() -> void:
	exit_position = Vector2(1170, 640)
	objective_count = 9
	spawn_fuels(9, Rect2(150 + randi_range(-40, 40), 120, 930, 460), true)
	spawn_traps(8, Rect2(140, 100, 960, 530))
	spawn_monsters(4, Rect2(180, 110, 900, 500))
	hud.set_prompt("Village: bring the torch to the beacon. Press [E] to light or [Q] to smother.")

func spawn_fuels(amount: int, region: Rect2, upgradeable: bool) -> void:
	for i in amount:
		var fuel := FuelPickup.new()
		fuel.position = Vector2(
			randf_range(region.position.x, region.position.x + region.size.x),
			randf_range(region.position.y, region.position.y + region.size.y)
		)
		var entry := FUEL_TABLE[randi() % FUEL_TABLE.size()]
		var bonus := upgrades["fuel_bonus"] if upgradeable else 0.0
		fuel.configure(entry["name"], entry["value"] + bonus)
		fuel.picked.connect(_on_fuel_picked)
		add_child(fuel)

func spawn_traps(amount: int, region: Rect2) -> void:
	for i in amount:
		var trap := Trap.new()
		trap.position = Vector2(
			randf_range(region.position.x, region.position.x + region.size.x),
			randf_range(region.position.y, region.position.y + region.size.y)
		)
		add_child(trap)

func spawn_monsters(amount: int, region: Rect2) -> void:
	for i in amount:
		var monster := Monster.new()
		monster.position = Vector2(
			randf_range(region.position.x, region.position.x + region.size.x),
			randf_range(region.position.y, region.position.y + region.size.y)
		)
		monster.chase_target = player
		monster.player_caught.connect(_on_player_caught)
		add_child(monster)

func _process(_delta: float) -> void:
	if player == null:
		return
	if zone != ZONE_3 and collected_count >= objective_count and player.global_position.distance_to(exit_position) < 28.0:
		advance_zone()
	if zone == ZONE_3 and player.global_position.distance_to(exit_position) < 35.0 and collected_count >= objective_count:
		at_beacon = true
		hud.set_prompt("Press [E] to LIGHT beacon (true ending) or [Q] to SNUFF it (bad ending).")
		if Input.is_action_just_pressed("interact"):
			finish_game(true)
		elif Input.is_action_just_pressed("bad_ending"):
			finish_game(false)
	update_objective_text()
	queue_redraw()

func _draw() -> void:
	draw_circle(exit_position, 14.0, Color(0.35, 0.65, 1.0, 0.7))

func _on_torch_changed(_current: float, _max_value: float) -> void:
	update_objective_text()

func _on_fuel_picked(amount: float) -> void:
	player.add_torch_time(amount)
	collected_count += 1
	meta_embers += 1
	update_objective_text()

func _on_player_caught() -> void:
	if player.torch_current < 3.0:
		_on_player_died()

func _on_player_died() -> void:
	meta_embers += int(collected_count / 2.0)
	attempt_auto_upgrade()
	save_progress()
	hud.set_prompt("You were consumed by darkness. Auto-upgrade applied. Restarting zone 1...")
	await get_tree().create_timer(2.0).timeout
	start_zone(ZONE_1)

func attempt_auto_upgrade() -> void:
	if meta_embers >= 3 and upgrades["fuel_bonus"] < 2.0:
		upgrades["fuel_bonus"] += 1.0
		meta_embers -= 3
	elif meta_embers >= 4 and upgrades["light_bonus"] < 60.0:
		upgrades["light_bonus"] += 15.0
		meta_embers -= 4
	elif meta_embers >= 4 and upgrades["stamina_bonus"] < 50.0:
		upgrades["stamina_bonus"] += 10.0
		meta_embers -= 4

func advance_zone() -> void:
	if zone == ZONE_1:
		unlocked_zone = max(unlocked_zone, ZONE_2)
		start_zone(ZONE_2)
	elif zone == ZONE_2:
		unlocked_zone = max(unlocked_zone, ZONE_3)
		start_zone(ZONE_3)

func finish_game(good_ending: bool) -> void:
	if good_ending:
		hud.set_prompt("The beacon ignites. The watchers are unpetrified. You are finally free.")
	else:
		hud.set_prompt("You smother the torch. Stone crawls over your hand. Silence forever.")
	save_progress(true)
	await get_tree().create_timer(4.0).timeout
	start_zone(ZONE_1)

func update_objective_text() -> void:
	if player == null:
		return
	hud.set_status("Zone %d | Torch %.1fs/%.1fs | Stamina %.0f | Embers %d" % [zone, player.torch_current, player.torch_max, player.stamina, meta_embers])
	if zone == ZONE_3:
		hud.set_objective("Fuel %d/%d | Reach beacon" % [collected_count, objective_count])
	else:
		hud.set_objective("Fuel %d/%d | Reach exit marker" % [collected_count, objective_count])

func save_progress(completed: bool = false) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "embers", meta_embers)
	cfg.set_value("meta", "unlocked_zone", unlocked_zone)
	cfg.set_value("meta", "upgrades", upgrades)
	cfg.set_value("meta", "completed_once", completed)
	cfg.save("user://progress.cfg")

func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://progress.cfg") != OK:
		return
	meta_embers = int(cfg.get_value("meta", "embers", 0))
	unlocked_zone = int(cfg.get_value("meta", "unlocked_zone", 1))
	upgrades = cfg.get_value("meta", "upgrades", upgrades)
