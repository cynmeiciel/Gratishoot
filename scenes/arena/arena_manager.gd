extends Node2D

@export var rounds_to_win: int = 3

var p1_wins := 0
var p2_wins := 0
var round_active := true

var player1: CharacterBody2D
var player2: CharacterBody2D
var weapon_spawner: Node2D
var hud: Control

var _p1_spawn: Vector2
var _p2_spawn: Vector2
var _is_training := false
var _training_gun_p1 := ""
var _training_gun_p2 := ""
var _training_melee_p1 := ""
var _training_melee_p2 := ""

var _hud_scene: PackedScene = preload("res://scenes/ui/hud.tscn")
var _training_hud_scene: PackedScene = preload("res://scenes/ui/training_hud.tscn")
var _pause_menu_scene: PackedScene = preload("res://scenes/ui/pause_menu.tscn")

var _pause_menu: Control


func _ready() -> void:
	# Wait for all children to be ready before accessing them
	await get_tree().process_frame
	_init_match()


func _init_match() -> void:
	rounds_to_win = GameState.rounds_to_win
	_is_training = GameState.game_mode == GameState.MODE_TRAINING
	player1 = get_node_or_null("Player1")
	player2 = get_node_or_null("Player2")
	weapon_spawner = get_node_or_null("WeaponSpawner")
	if player1 == null:
		push_error("Player1 node not found! Children: %s" % str(get_children().map(func(c): return c.name)))
		return
	if player2 == null:
		push_error("Player2 node not found!")
		return
	player1.configure_for_match(GameState.p1_character, GameState.p1_color)
	player2.configure_for_match(GameState.p2_character, GameState.p2_color)
	player1.set_ai_control(false, null)
	player2.set_ai_control(GameState.p2_is_ai and not _is_training, player1)
	_p1_spawn = player1.global_position
	_p2_spawn = player2.global_position
	if _is_training:
		player1.died.connect(_on_training_player_died)
		player2.died.connect(_on_training_player_died)
		if weapon_spawner:
			weapon_spawner.clear_pickups()
			weapon_spawner.set_process(false)
	else:
		player1.died.connect(_on_player_died)
		player2.died.connect(_on_player_died)

	# Setup HUD
	var hud_canvas: CanvasLayer = (_training_hud_scene if _is_training else _hud_scene).instantiate()
	add_child(hud_canvas)
	hud = hud_canvas.get_node("Overlay")
	hud.init(player1, player2, self)

	var pause_canvas: CanvasLayer = _pause_menu_scene.instantiate()
	add_child(pause_canvas)
	_pause_menu = pause_canvas.get_node("Overlay")
	_pause_menu.quit_to_menu.connect(_on_pause_quit)


func _on_player_died(pid: int) -> void:
	if not round_active:
		return
	round_active = false

	if pid == 1:
		p2_wins += 1
	else:
		p1_wins += 1

	if p1_wins >= rounds_to_win or p2_wins >= rounds_to_win:
		# Match over — wait then could go to results (for now just pause)
		get_tree().create_timer(2.0).timeout.connect(_show_victory)
	else:
		get_tree().create_timer(1.5).timeout.connect(_start_new_round)


func _start_new_round() -> void:
	# Clear all weapons and projectiles
	weapon_spawner.clear_pickups()
	for node in get_tree().get_nodes_in_group("projectiles"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("ephemeral_fx"):
		node.queue_free()
	player1.reset(_p1_spawn)
	player2.reset(_p2_spawn)
	player1.set_ai_control(false, null)
	player2.set_ai_control(GameState.p2_is_ai and not _is_training, player1)
	round_active = true


func _show_victory() -> void:
	if _pause_menu:
		_pause_menu.can_open = false
	set_process_input(true)


func _on_pause_quit() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")


func _input(event: InputEvent) -> void:
	if _is_training:
		return
	if not round_active and (p1_wins >= rounds_to_win or p2_wins >= rounds_to_win):
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_ENTER:
				p1_wins = 0
				p2_wins = 0
				_start_new_round()
			elif event.keycode == KEY_ESCAPE:
				get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")


func _on_training_player_died(pid: int) -> void:
	for node in get_tree().get_nodes_in_group("projectiles"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("ephemeral_fx"):
		node.queue_free()

	if pid == 1:
		player1.reset(_p1_spawn)
		_reapply_training_loadout(1)
	else:
		player2.reset(_p2_spawn)
		_reapply_training_loadout(2)


func get_training_weapon_names(weapon_type: WeaponData.Type) -> PackedStringArray:
	var names: PackedStringArray = []
	for w in WeaponDB.get_pool():
		if w.type == weapon_type:
			names.append(w.weapon_name)
	names.sort()
	return names


func equip_training_weapon(player_id: int, weapon_name: String) -> void:
	var p := _get_player(player_id)
	if p == null:
		return
	var weapon := WeaponDB.get_by_name(weapon_name)
	if weapon == null:
		return

	if weapon.type == WeaponData.Type.GUN:
		p.equip_weapon(weapon, weapon.capacity, maxi(weapon.reserve_ammo, weapon.capacity * 4))
		if player_id == 1:
			_training_gun_p1 = weapon_name
		else:
			_training_gun_p2 = weapon_name
	else:
		p.equip_weapon(weapon)
		if player_id == 1:
			_training_melee_p1 = weapon_name
		else:
			_training_melee_p2 = weapon_name


func clear_training_weapon(player_id: int, weapon_type: WeaponData.Type) -> void:
	var p := _get_player(player_id)
	if p == null:
		return

	if weapon_type == WeaponData.Type.GUN:
		p.current_gun = null
		p.ammo_current = 0
		p.ammo_reserve = 0
		p.is_aiming = false
		p.aim_pitch = 0.0
		if player_id == 1:
			_training_gun_p1 = ""
		else:
			_training_gun_p2 = ""
	else:
		p.current_melee = null
		if player_id == 1:
			_training_melee_p1 = ""
		else:
			_training_melee_p2 = ""


func refill_training_ammo() -> void:
	for p in [player1, player2]:
		if p and p.current_gun:
			p.ammo_current = p.current_gun.capacity
			p.ammo_reserve = maxi(p.current_gun.reserve_ammo, p.current_gun.capacity * 4)


func reset_training_positions() -> void:
	player1.reset(_p1_spawn)
	player2.reset(_p2_spawn)
	_reapply_training_loadout(1)
	_reapply_training_loadout(2)


func _reapply_training_loadout(player_id: int) -> void:
	var p := _get_player(player_id)
	if p == null:
		return
	var gun_name := _training_gun_p1 if player_id == 1 else _training_gun_p2
	var melee_name := _training_melee_p1 if player_id == 1 else _training_melee_p2
	if gun_name != "":
		equip_training_weapon(player_id, gun_name)
	if melee_name != "":
		equip_training_weapon(player_id, melee_name)


func _get_player(player_id: int) -> CharacterBody2D:
	if player_id == 1:
		return player1
	if player_id == 2:
		return player2
	return null
