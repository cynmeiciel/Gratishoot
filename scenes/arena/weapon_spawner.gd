extends Node2D

@export var spawn_interval_min := 1.2
@export var spawn_interval_max := 2.4
@export var max_weapons_on_map := 10
@export var tactical_chance := 0.3  # 30% chance to spawn a tactical instead of a weapon
@export var replacement_radius := 28.0
@export var spawn_jitter_radius := 26.0

var _timer := 0.0
var _next_spawn := 4.0
var _pickup_scene: PackedScene = preload("res://scenes/weapon/weapon_pickup.tscn")
var _tactical_pickup_scene: PackedScene = preload("res://scenes/tactical/tactical_pickup.tscn")


func _ready() -> void:
	_apply_classic_spawn_settings()
	_next_spawn = randf_range(spawn_interval_min, spawn_interval_max)


func _apply_classic_spawn_settings() -> void:
	if GameState.game_mode != GameState.MODE_CLASSIC_DUEL:
		return
	spawn_interval_min = GameState.classic_spawn_interval_min
	spawn_interval_max = GameState.classic_spawn_interval_max
	if spawn_interval_max < spawn_interval_min:
		spawn_interval_max = spawn_interval_min
	tactical_chance = GameState.classic_tactical_chance
	max_weapons_on_map = GameState.classic_max_pickups


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= _next_spawn:
		_timer = 0.0
		_next_spawn = randf_range(spawn_interval_min, spawn_interval_max)
		_try_spawn()


func _try_spawn() -> void:
	var spawn_points := get_children().filter(func(c): return c is Marker2D)
	if spawn_points.is_empty():
		return

	var point: Marker2D = spawn_points.pick_random()
	var has_existing := _clear_pickup_at_point(point)

	# If the map is already saturated, only allow replacement at occupied markers.
	var existing := get_tree().get_nodes_in_group("weapon_pickups").size()
	existing += get_tree().get_nodes_in_group("tactical_pickups").size()
	if existing >= max_weapons_on_map and not has_existing:
		return

	var use_classic_filter := GameState.game_mode == GameState.MODE_CLASSIC_DUEL
	var force_tactical_only := use_classic_filter and GameState.classic_use_weapon_filter and GameState.classic_enabled_weapons.is_empty()
	if force_tactical_only:
		_spawn_tactical(point)
		return

	if randf() < tactical_chance:
		_spawn_tactical(point)
	else:
		_spawn_weapon(point)


func _spawn_weapon(point: Marker2D) -> void:
	var pool: Array[WeaponData] = []
	var use_classic_filter := GameState.game_mode == GameState.MODE_CLASSIC_DUEL
	for w in WeaponDB.get_pool():
		if not use_classic_filter or GameState.is_classic_weapon_allowed(w.weapon_name):
			pool.append(w)
	if pool.is_empty():
		# Respect intentional "no weapons" selection in Classic filter mode.
		if use_classic_filter and GameState.classic_use_weapon_filter and GameState.classic_enabled_weapons.is_empty():
			return
		# Safety fallback: if user filter gets invalid/outdated names, allow default pool.
		pool = WeaponDB.get_pool()
	if pool.is_empty():
		return
	var weapon := _pick_weighted(pool)
	var pickup: Area2D = _pickup_scene.instantiate()
	pickup.global_position = _randomized_spawn_position(point)
	pickup.add_to_group("weapon_pickups")
	get_tree().current_scene.add_child(pickup)
	pickup.init(weapon)


func _spawn_tactical(point: Marker2D) -> void:
	var allowed_tacticals: Array[TacticalData] = []
	var use_classic_filter := GameState.game_mode == GameState.MODE_CLASSIC_DUEL
	for tac in TacticalData.get_all_tacticals():
		if not use_classic_filter or GameState.is_classic_tactical_allowed(tac.item_name):
			allowed_tacticals.append(tac)
	if allowed_tacticals.is_empty():
		_spawn_weapon(point)
		return
	var tac: TacticalData = allowed_tacticals[randi() % allowed_tacticals.size()]
	var pickup: Area2D = _tactical_pickup_scene.instantiate()
	pickup.global_position = _randomized_spawn_position(point)
	pickup.add_to_group("tactical_pickups")
	get_tree().current_scene.add_child(pickup)
	pickup.init(tac)


func _pick_weighted(pool: Array[WeaponData]) -> WeaponData:
	# Weights: Common=30, Uncommon=25, Rare=18, Epic=12, Legendary=6, Mythic=2, Contraband=0.6
	var weights := {
		WeaponData.Rarity.COMMON: 30.0,
		WeaponData.Rarity.UNCOMMON: 25.0,
		WeaponData.Rarity.RARE: 18.0,
		WeaponData.Rarity.EPIC: 12.0,
		WeaponData.Rarity.LEGENDARY: 6.0,
		WeaponData.Rarity.MYTHIC: 2.0,
		WeaponData.Rarity.CONTRABAND: 0.6,
	}
	var total := 0.0
	for w in pool:
		total += weights.get(w.rarity, 10.0)
	var roll := randf() * total
	var acc := 0.0
	for w in pool:
		acc += weights.get(w.rarity, 10.0)
		if roll <= acc:
			return w
	return pool.back()


func clear_pickups() -> void:
	for node in get_tree().get_nodes_in_group("weapon_pickups"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("tactical_pickups"):
		node.queue_free()
	_timer = 0.0
	_next_spawn = randf_range(spawn_interval_min, spawn_interval_max)


func _clear_pickup_at_point(point: Marker2D) -> bool:
	var replaced := false
	for node in get_tree().get_nodes_in_group("weapon_pickups"):
		if node.global_position.distance_to(point.global_position) <= replacement_radius:
			node.queue_free()
			replaced = true
	for node in get_tree().get_nodes_in_group("tactical_pickups"):
		if node.global_position.distance_to(point.global_position) <= replacement_radius:
			node.queue_free()
			replaced = true
	return replaced


func _randomized_spawn_position(point: Marker2D) -> Vector2:
	if spawn_jitter_radius <= 0.0:
		return point.global_position
	var angle := randf() * TAU
	var radius := randf() * spawn_jitter_radius
	return point.global_position + Vector2(cos(angle), sin(angle)) * radius
