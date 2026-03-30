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
var _is_arms_dealer := false
var _is_draft_duel := false
var _is_online_host := false
var _is_online_client := false
var _training_gun_p1 := ""
var _training_gun_p2 := ""
var _training_melee_p1 := ""
var _training_melee_p2 := ""
var _training_tactical_p1 := ""
var _training_tactical_p2 := ""
var _training_skill_p1 := "Dash"
var _training_skill_p2 := "Life Steal"

var _hud_scene: PackedScene = preload("res://scenes/ui/hud.tscn")
var _training_hud_scene: PackedScene = preload("res://scenes/ui/training_hud.tscn")
var _pause_menu_scene: PackedScene = preload("res://scenes/ui/pause_menu.tscn")
var _arms_buy_ui_script: Script = preload("res://scenes/ui/arms_dealer_buy.gd")
var _draft_pick_ui_script: Script = preload("res://scenes/ui/draft_duel_pick.gd")

const ARMS_START_CREDITS := 800
const ARMS_BASE_INCOME := 400
const ARMS_WIN_BONUS := 300
const ARMS_KILL_BONUS := 150
const ARMS_CREDIT_CAP := 5000
const ARMS_BUY_PHASE_TIME := 12.0
const ARMS_REROLL_COST := 150
const ARMS_GRID_COLUMNS := 2

const DRAFT_CONSTRAINT_NONE := 0
const DRAFT_CONSTRAINT_RARITY := 1
const DRAFT_CONSTRAINT_CATEGORY := 2
const DRAFT_GRID_COLUMNS := 3

var _pause_menu: Control
var _arms_buy_ui: Control
var _draft_pick_ui: Control
var _arms_buy_timer := 0.0
var _arms_buy_active := false
var _arms_credits := {1: ARMS_START_CREDITS, 2: ARMS_START_CREDITS}
var _arms_loss_streak := {1: 0, 2: 0}
var _arms_ready := {1: false, 2: false}
var _arms_free_rerolls := {1: 1, 2: 1}
var _arms_offers := {1: [], 2: []}
var _arms_select_index := {1: 0, 2: 0}
var _arms_loadout := {
	1: {"gun": null, "melee": null, "tactical": null},
	2: {"gun": null, "melee": null, "tactical": null},
}

var _draft_active := false
var _draft_final_round := false
var _draft_chooser := 1
var _draft_constraint_type := DRAFT_CONSTRAINT_NONE
var _draft_constraint_rarity := WeaponData.Rarity.COMMON
var _draft_constraint_category := WeaponData.GunCategory.PISTOL
var _draft_options: Array[WeaponData] = []
var _draft_index := {1: 0, 2: 0}
var _draft_locked := {1: false, 2: false}
var _draft_picks := {1: null, 2: null}
var _draft_countdown_active := false

var _net_snapshot_timer := 0.0
var _net_snapshot_id := 0
var _client_last_snapshot_id := -1
var _client_has_snapshot := false
const NET_SNAPSHOT_RATE := 45.0
const NET_REMOTE_POS_LERP := 0.62
const NET_LOCAL_POS_LERP := 0.10
const NET_REMOTE_VEL_LERP := 0.55
const NET_LOCAL_VEL_LERP := 0.14
const NET_SNAP_DISTANCE := 96.0
const NET_LOCAL_CORRECTION_DISTANCE := 32.0


func _ready() -> void:
	# Wait for all children to be ready before accessing them
	await get_tree().process_frame
	_init_match()


func _process(delta: float) -> void:
	if _arms_buy_active:
		_arms_buy_timer -= delta
		if _arms_buy_ui and _arms_buy_ui.has_method("set_timer"):
			_arms_buy_ui.set_timer(_arms_buy_timer)
		_process_arms_buy_input()
		if _arms_buy_timer <= 0.0 or (_arms_ready[1] and _arms_ready[2]):
			_begin_arms_round()
	if _draft_active:
		_process_draft_input()


func _physics_process(delta: float) -> void:
	if _is_online_host or _is_online_client:
		_process_online_sync(delta)


func _init_match() -> void:
	rounds_to_win = GameState.rounds_to_win
	_is_training = GameState.game_mode == GameState.MODE_TRAINING
	_is_arms_dealer = GameState.game_mode == GameState.MODE_ARMS_DEALER
	_is_draft_duel = GameState.game_mode == GameState.MODE_DRAFT_DUEL
	_is_online_host = GameState.game_mode == GameState.MODE_ONLINE_HOST
	_is_online_client = GameState.game_mode == GameState.MODE_ONLINE_CLIENT
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
		_training_skill_p1 = player1.skill.get_skill_name() if player1.skill else "Dash"
		_training_skill_p2 = player2.skill.get_skill_name() if player2.skill else "Life Steal"
		player1.died.connect(_on_training_player_died)
		player2.died.connect(_on_training_player_died)
		if weapon_spawner:
			weapon_spawner.clear_pickups()
			weapon_spawner.set_process(false)
	else:
		if not _is_online_client:
			player1.died.connect(_on_player_died)
			player2.died.connect(_on_player_died)
		if (_is_arms_dealer or _is_draft_duel) and weapon_spawner:
			weapon_spawner.clear_pickups()
			weapon_spawner.set_process(false)

	if _is_online_host:
		_configure_online_player_controls()
	if _is_online_client:
		_configure_online_player_controls()
		if not NetworkManager.snapshot_received.is_connected(_on_network_snapshot_received):
			NetworkManager.snapshot_received.connect(_on_network_snapshot_received)

	# Setup HUD
	var hud_canvas: CanvasLayer = _hud_scene.instantiate()
	add_child(hud_canvas)
	hud = hud_canvas.get_node("Overlay")
	hud.init(player1, player2, self)

	if _is_training:
		var training_canvas: CanvasLayer = _training_hud_scene.instantiate()
		add_child(training_canvas)
		var training_hud: Control = training_canvas.get_node("Overlay")
		training_hud.init(player1, player2, self)
	elif _is_arms_dealer:
		_setup_arms_buy_ui()
		_start_arms_buy_phase(true)
	elif _is_draft_duel:
		_setup_draft_pick_ui()
		_start_draft_phase(true)

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
		if _is_arms_dealer:
			_award_arms_credits(2)
	else:
		p1_wins += 1
		if _is_arms_dealer:
			_award_arms_credits(1)
	if _is_arms_dealer:
		_clear_arms_loadout(pid)
	AudioManager.play_sfx_varied("round_win", -1.5, 0.97, 1.03)

	if p1_wins >= rounds_to_win or p2_wins >= rounds_to_win:
		AudioManager.play_sfx_varied("match_victory", -0.5, 0.98, 1.02)
		# Match over — wait then could go to results (for now just pause)
		get_tree().create_timer(2.0).timeout.connect(_show_victory)
	else:
		if _is_arms_dealer:
			get_tree().create_timer(1.2).timeout.connect(func() -> void:
				_start_arms_buy_phase(false)
			)
		elif _is_draft_duel:
			get_tree().create_timer(1.0).timeout.connect(func() -> void:
				_start_draft_phase(false)
			)
		else:
			get_tree().create_timer(1.5).timeout.connect(_start_new_round)


func _start_new_round() -> void:
	if _is_arms_dealer:
		_start_arms_buy_phase(false)
		return
	if _is_draft_duel:
		_start_draft_phase(false)
		return
	# Clear all weapons and projectiles
	weapon_spawner.clear_pickups()
	for node in get_tree().get_nodes_in_group("projectiles"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("ephemeral_fx"):
		node.queue_free()
	player1.reset(_p1_spawn)
	player2.reset(_p2_spawn)
	if _is_online_host or _is_online_client:
		_configure_online_player_controls()
	else:
		player1.set_ai_control(false, null)
		player2.set_ai_control(GameState.p2_is_ai and not _is_training, player1)
	round_active = true
	AudioManager.play_sfx_varied("round_start", -2.0, 0.98, 1.02)


func _show_victory() -> void:
	if _pause_menu:
		_pause_menu.can_open = false
	set_process_input(true)


func _on_pause_quit() -> void:
	if _is_online_host or _is_online_client:
		NetworkManager.stop()
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")


func _input(event: InputEvent) -> void:
	if _is_training:
		return
	if not round_active and (p1_wins >= rounds_to_win or p2_wins >= rounds_to_win):
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_ENTER:
				p1_wins = 0
				p2_wins = 0
				if _is_arms_dealer:
					_reset_arms_economy()
					_start_arms_buy_phase(true)
				elif _is_draft_duel:
					_start_draft_phase(true)
				else:
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


func get_training_tactical_names() -> PackedStringArray:
	var names: PackedStringArray = []
	for t in TacticalData.get_all_tacticals():
		names.append(t.item_name)
	names.sort()
	return names


func get_training_skill_names() -> PackedStringArray:
	return PackedStringArray(["Dash", "Life Steal", "Shrink", "Invisible"])


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


func equip_training_tactical(player_id: int, tactical_name: String) -> void:
	var p := _get_player(player_id)
	if p == null:
		return
	for tac in TacticalData.get_all_tacticals():
		if tac.item_name == tactical_name:
			p.current_tactical = tac
			if player_id == 1:
				_training_tactical_p1 = tactical_name
			else:
				_training_tactical_p2 = tactical_name
			return


func clear_training_tactical(player_id: int) -> void:
	var p := _get_player(player_id)
	if p == null:
		return
	p.current_tactical = null
	if player_id == 1:
		_training_tactical_p1 = ""
	else:
		_training_tactical_p2 = ""


func equip_training_skill(player_id: int, skill_name: String) -> void:
	var p := _get_player(player_id)
	if p == null:
		return
	p.set_skill_by_name(skill_name)
	if player_id == 1:
		_training_skill_p1 = skill_name
	else:
		_training_skill_p2 = skill_name


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
	var tactical_name := _training_tactical_p1 if player_id == 1 else _training_tactical_p2
	var skill_name := _training_skill_p1 if player_id == 1 else _training_skill_p2
	if gun_name != "":
		equip_training_weapon(player_id, gun_name)
	if melee_name != "":
		equip_training_weapon(player_id, melee_name)
	if tactical_name != "":
		equip_training_tactical(player_id, tactical_name)
	if skill_name != "":
		equip_training_skill(player_id, skill_name)


func _get_player(player_id: int) -> CharacterBody2D:
	if player_id == 1:
		return player1
	if player_id == 2:
		return player2
	return null


func _setup_arms_buy_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	_arms_buy_ui = _arms_buy_ui_script.new()
	_arms_buy_ui.name = "ArmsDealerBuyUI"
	canvas.add_child(_arms_buy_ui)
	_arms_buy_ui.configure_players(GameState.p1_name, GameState.p2_name)
	_arms_buy_ui.buy_requested.connect(_on_arms_buy_requested)
	_arms_buy_ui.reroll_requested.connect(_on_arms_reroll_requested)
	_arms_buy_ui.ready_toggled.connect(_on_arms_ready_toggled)


func _start_arms_buy_phase(is_first_round: bool) -> void:
	round_active = false
	_arms_buy_active = true
	_arms_buy_timer = ARMS_BUY_PHASE_TIME
	_arms_ready[1] = false
	_arms_ready[2] = false
	_arms_select_index[1] = 0
	_arms_select_index[2] = 0
	_arms_free_rerolls[1] = 1
	_arms_free_rerolls[2] = 1

	if is_first_round:
		_reset_arms_economy()

	for node in get_tree().get_nodes_in_group("projectiles"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("ephemeral_fx"):
		node.queue_free()
	if weapon_spawner:
		weapon_spawner.clear_pickups()

	player1.reset(_p1_spawn)
	player2.reset(_p2_spawn)
	_set_players_frozen(true)

	_generate_arms_offers(1)
	_generate_arms_offers(2)

	if _arms_buy_ui:
		_arms_buy_ui.visible = true
		_arms_buy_ui.set_info("Move: Left/Right/Up/Down  |  Attack: Buy  |  Secondary: Ready  |  Reload: Reroll")
		_arms_buy_ui.set_timer(_arms_buy_timer)
		_refresh_arms_ui_player(1)
		_refresh_arms_ui_player(2)

	if GameState.p2_is_ai:
		_ai_buy_for_player(2)
		_arms_ready[2] = true
		if _arms_buy_ui:
			_arms_buy_ui.set_ready(2, true)


func _begin_arms_round() -> void:
	_arms_buy_active = false
	if _arms_buy_ui:
		_arms_buy_ui.visible = false

	player1.reset(_p1_spawn)
	player2.reset(_p2_spawn)
	_apply_arms_loadout(1)
	_apply_arms_loadout(2)

	player1.set_ai_control(false, null)
	player2.set_ai_control(GameState.p2_is_ai, player1)
	if _is_online_host or _is_online_client:
		_configure_online_player_controls()
	_set_players_frozen(false)
	round_active = true
	AudioManager.play_sfx_varied("round_start", -2.0, 0.98, 1.02)


func _configure_online_player_controls() -> void:
	if _is_online_host:
		player1.set_ai_control(false, null)
		player1.set_network_control(false)
		player2.set_ai_control(false, null)
		player2.set_network_control(true)
	elif _is_online_client:
		player1.set_ai_control(false, null)
		player2.set_ai_control(false, null)
		# Client predicts player2 locally and receives player1 as remote snapshot state.
		player1.set_network_control(false)
		player2.set_network_control(true)


func _setup_draft_pick_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	_draft_pick_ui = _draft_pick_ui_script.new()
	_draft_pick_ui.name = "DraftDuelPickUI"
	canvas.add_child(_draft_pick_ui)
	_draft_pick_ui.configure_players(GameState.p1_name, GameState.p2_name)


func _start_draft_phase(_is_first_round: bool) -> void:
	round_active = false
	_draft_active = true
	_draft_countdown_active = false
	_draft_final_round = _is_draft_final_round()
	_draft_chooser = _get_draft_chooser_player()
	_draft_locked[1] = false
	_draft_locked[2] = false
	_draft_picks[1] = null
	_draft_picks[2] = null

	_roll_draft_constraint()
	_draft_options = _get_draft_options()
	if _draft_options.is_empty():
		# Safety fallback: free pick from all non-Contraband guns.
		_draft_constraint_type = DRAFT_CONSTRAINT_NONE
		_draft_options = _get_draft_options()

	_draft_index[1] = 0
	_draft_index[2] = _draft_options.size() - 1 if _draft_options.size() > 1 else 0

	for node in get_tree().get_nodes_in_group("projectiles"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("ephemeral_fx"):
		node.queue_free()
	if weapon_spawner:
		weapon_spawner.clear_pickups()

	player1.reset(_p1_spawn)
	player2.reset(_p2_spawn)
	_set_players_frozen(true)

	if _draft_pick_ui:
		_draft_pick_ui.visible = true
	if hud:
		hud.visible = false
	_update_draft_ui()

	if GameState.p2_is_ai:
		if _draft_final_round:
			_ai_lock_draft_pick(2)
		elif _draft_chooser == 2:
			_ai_lock_draft_pick(2)
		_try_begin_draft_round()
		_update_draft_ui()


func _process_draft_input() -> void:
	if _draft_options.is_empty():
		return
	if _draft_final_round:
		_process_draft_input_for_player(1)
		if not GameState.p2_is_ai:
			_process_draft_input_for_player(2)
		_try_begin_draft_round()
		return

	if _draft_chooser == 1:
		_process_draft_input_for_player(1)
	elif not GameState.p2_is_ai:
		_process_draft_input_for_player(2)

	_try_begin_draft_round()


func _process_draft_input_for_player(player_id: int) -> void:
	if bool(_draft_locked[player_id]):
		return
	var left_action := "p1_left" if player_id == 1 else "p2_left"
	var right_action := "p1_right" if player_id == 1 else "p2_right"
	var up_action := "p1_jump" if player_id == 1 else "p2_jump"
	var down_action := "p1_crouch" if player_id == 1 else "p2_crouch"
	var confirm_action := "p1_attack" if player_id == 1 else "p2_attack"

	var moved := false
	if Input.is_action_just_pressed(left_action):
		_draft_index[player_id] = _move_draft_index(int(_draft_index[player_id]), -1, 0)
		moved = true
	elif Input.is_action_just_pressed(right_action):
		_draft_index[player_id] = _move_draft_index(int(_draft_index[player_id]), 1, 0)
		moved = true
	elif Input.is_action_just_pressed(up_action):
		_draft_index[player_id] = _move_draft_index(int(_draft_index[player_id]), 0, -1)
		moved = true
	elif Input.is_action_just_pressed(down_action):
		_draft_index[player_id] = _move_draft_index(int(_draft_index[player_id]), 0, 1)
		moved = true

	if moved:
		AudioManager.play_sfx_varied("ui_click", -8.0, 0.98, 1.02)
		_update_draft_ui()

	if Input.is_action_just_pressed(confirm_action):
		_confirm_draft_pick(player_id)
		_update_draft_ui()


func _confirm_draft_pick(player_id: int) -> void:
	if _draft_options.is_empty() or bool(_draft_locked[player_id]):
		return
	var idx := int(_draft_index[player_id])
	idx = clampi(idx, 0, _draft_options.size() - 1)
	var chosen: WeaponData = _draft_options[idx]
	_draft_picks[player_id] = chosen
	_draft_locked[player_id] = true

	if not _draft_final_round:
		# Single chooser picks for both players.
		var other := 1 if player_id == 2 else 2
		_draft_picks[other] = chosen
		_draft_locked[other] = true

	AudioManager.play_sfx_varied("ui_click", -6.5, 1.0, 1.04)


func _ai_lock_draft_pick(player_id: int) -> void:
	if _draft_options.is_empty() or bool(_draft_locked[player_id]):
		return
	var idx := randi() % _draft_options.size()
	_draft_index[player_id] = idx
	_confirm_draft_pick(player_id)


func _try_begin_draft_round() -> void:
	if not bool(_draft_locked[1]) or not bool(_draft_locked[2]):
		return
	if _draft_countdown_active:
		return
	_start_draft_countdown_and_begin()


func _start_draft_countdown_and_begin() -> void:
	_draft_countdown_active = true
	for sec in [3, 2, 1]:
		if _draft_pick_ui:
			_draft_pick_ui.set_turn_text("Round Starts In %d..." % sec, true)
			_draft_pick_ui.set_help_text("Get ready!")
		await get_tree().create_timer(1.0).timeout
	_begin_draft_round()


func _begin_draft_round() -> void:
	_draft_active = false
	_draft_countdown_active = false
	if _draft_pick_ui:
		_draft_pick_ui.visible = false
	if hud:
		hud.visible = true

	if weapon_spawner:
		weapon_spawner.clear_pickups()

	player1.reset(_p1_spawn)
	player2.reset(_p2_spawn)
	_apply_draft_pick(1)
	_apply_draft_pick(2)

	player1.set_ai_control(false, null)
	player2.set_ai_control(GameState.p2_is_ai, player1)
	_set_players_frozen(false)
	round_active = true
	AudioManager.play_sfx_varied("round_start", -2.0, 0.98, 1.02)


func _apply_draft_pick(player_id: int) -> void:
	var p := _get_player(player_id)
	if p == null:
		return
	var gun: WeaponData = _draft_picks[player_id]
	if gun:
		p.equip_weapon(gun, gun.capacity, gun.reserve_ammo)


func _is_draft_final_round() -> bool:
	return p1_wins == rounds_to_win - 1 and p2_wins == rounds_to_win - 1


func _get_draft_chooser_player() -> int:
	var round_idx := p1_wins + p2_wins + 1
	return 1 if round_idx % 2 == 1 else 2


func _roll_draft_constraint() -> void:
	var roll := randf()
	if roll < 0.15:
		_draft_constraint_type = DRAFT_CONSTRAINT_NONE
		return
	if roll < 0.55:
		_draft_constraint_type = DRAFT_CONSTRAINT_RARITY
		var rarity_pool := [
			WeaponData.Rarity.COMMON,
			WeaponData.Rarity.UNCOMMON,
			WeaponData.Rarity.RARE,
			WeaponData.Rarity.EPIC,
			WeaponData.Rarity.LEGENDARY,
			WeaponData.Rarity.MYTHIC,
		]
		_draft_constraint_rarity = rarity_pool.pick_random()
		return
	_draft_constraint_type = DRAFT_CONSTRAINT_CATEGORY
	var category_pool := [
		WeaponData.GunCategory.PISTOL,
		WeaponData.GunCategory.ASSAULT_RIFLE,
		WeaponData.GunCategory.BATTLE_RIFLE,
		WeaponData.GunCategory.SMG,
		WeaponData.GunCategory.LMG,
		WeaponData.GunCategory.SHOTGUN,
		WeaponData.GunCategory.SNIPER,
		WeaponData.GunCategory.DMR,
	]
	_draft_constraint_category = category_pool.pick_random()


func _get_draft_options() -> Array[WeaponData]:
	var options: Array[WeaponData] = []
	for w in WeaponDB.get_pool():
		if w.type != WeaponData.Type.GUN:
			continue
		if w.rarity == WeaponData.Rarity.CONTRABAND:
			continue
		if _draft_constraint_type == DRAFT_CONSTRAINT_RARITY and w.rarity != _draft_constraint_rarity:
			continue
		if _draft_constraint_type == DRAFT_CONSTRAINT_CATEGORY and w.gun_category != _draft_constraint_category:
			continue
		options.append(w)
	options.sort_custom(func(a: WeaponData, b: WeaponData) -> bool:
		return a.weapon_name < b.weapon_name
	)
	return options


func _wrap_draft_index(idx: int) -> int:
	if _draft_options.is_empty():
		return 0
	var n := _draft_options.size()
	return posmod(idx, n)


func _move_draft_index(current_idx: int, dx: int, dy: int) -> int:
	if _draft_options.is_empty():
		return 0
	var cols := DRAFT_GRID_COLUMNS
	var count := _draft_options.size()
	var rows := int(ceil(float(count) / float(cols)))

	var row := current_idx / cols
	var col := current_idx % cols

	row = posmod(row + dy, rows)
	col = posmod(col + dx, cols)

	var next := row * cols + col
	# If landing on an empty slot in the last row, clamp to last valid option in that row.
	if next >= count:
		next = count - 1
	return clampi(next, 0, count - 1)


func _draft_constraint_text() -> String:
	if _draft_constraint_type == DRAFT_CONSTRAINT_NONE:
		return "Constraint: NONE (Free Pick)"
	if _draft_constraint_type == DRAFT_CONSTRAINT_RARITY:
		var names := {
			WeaponData.Rarity.COMMON: "Common",
			WeaponData.Rarity.UNCOMMON: "Uncommon",
			WeaponData.Rarity.RARE: "Rare",
			WeaponData.Rarity.EPIC: "Epic",
			WeaponData.Rarity.LEGENDARY: "Legendary",
			WeaponData.Rarity.MYTHIC: "Mythic",
		}
		return "Constraint: Rarity = %s" % String(names.get(_draft_constraint_rarity, "Unknown"))
	var categories := {
		WeaponData.GunCategory.PISTOL: "Pistol",
		WeaponData.GunCategory.ASSAULT_RIFLE: "Assault Rifle",
		WeaponData.GunCategory.BATTLE_RIFLE: "Battle Rifle",
		WeaponData.GunCategory.SMG: "SMG",
		WeaponData.GunCategory.LMG: "LMG",
		WeaponData.GunCategory.SHOTGUN: "Shotgun",
		WeaponData.GunCategory.SNIPER: "Sniper",
		WeaponData.GunCategory.DMR: "DMR",
	}
	return "Constraint: Category = %s" % String(categories.get(_draft_constraint_category, "Unknown"))


func _update_draft_ui() -> void:
	if _draft_pick_ui == null:
		return
	_draft_pick_ui.set_constraint_text(_draft_constraint_text())
	if _draft_final_round:
		_draft_pick_ui.set_turn_text("Final Round: Both Players Choose", true)
		_draft_pick_ui.set_help_text("Navigate with movement keys (Left/Right/Up/Down). Confirm with Attack.")
	else:
		var chooser_name := GameState.p1_name if _draft_chooser == 1 else GameState.p2_name
		_draft_pick_ui.set_turn_text("%s Choosing For Both" % chooser_name, _draft_chooser == 1)
		_draft_pick_ui.set_help_text("Only chooser can navigate (Left/Right/Up/Down) and confirm with Attack.")

	var p1_pick := "-"
	var p2_pick := "-"
	if bool(_draft_locked[1]) and _draft_picks[1] != null:
		p1_pick = (_draft_picks[1] as WeaponData).weapon_name
	elif not _draft_options.is_empty():
		p1_pick = _draft_options[int(_draft_index[1])].weapon_name
	if bool(_draft_locked[2]) and _draft_picks[2] != null:
		p2_pick = (_draft_picks[2] as WeaponData).weapon_name
	elif not _draft_options.is_empty():
		p2_pick = _draft_options[int(_draft_index[2])].weapon_name

	_draft_pick_ui.set_selection_names(GameState.p1_name, GameState.p2_name, p1_pick, p2_pick)
	_draft_pick_ui.set_options(
		_draft_options,
		int(_draft_index[1]),
		int(_draft_index[2]),
		_draft_chooser,
		_draft_final_round,
		bool(_draft_locked[1]),
		bool(_draft_locked[2]),
		DRAFT_GRID_COLUMNS
	)


func _process_online_sync(delta: float) -> void:
	if _is_online_client:
		# Client sends merged local bindings (P1/P2 layouts) each physics tick.
		var local_input := _collect_online_client_input()
		player2.apply_network_input(local_input)
		NetworkManager.send_client_input(local_input)
		return
	if _is_online_host:
		player2.apply_network_input(NetworkManager.get_remote_input())
		_net_snapshot_timer += delta
		if _net_snapshot_timer >= (1.0 / NET_SNAPSHOT_RATE):
			_net_snapshot_timer = 0.0
			NetworkManager.broadcast_snapshot(_build_snapshot())


func _collect_online_client_input() -> Dictionary:
	var p1 := _collect_local_input_for_player(1)
	var p2 := _collect_local_input_for_player(2)
	var merged := {}
	for action in p1.keys():
		merged[action] = bool(p1[action]) or bool(p2[action])
	return merged


func _collect_local_input_for_player(player_id: int) -> Dictionary:
	var prefix := "p%d_" % player_id
	return {
		"left": Input.is_action_pressed(prefix + "left") or Input.is_action_just_pressed(prefix + "left"),
		"right": Input.is_action_pressed(prefix + "right") or Input.is_action_just_pressed(prefix + "right"),
		"jump": Input.is_action_pressed(prefix + "jump") or Input.is_action_just_pressed(prefix + "jump"),
		"crouch": Input.is_action_pressed(prefix + "crouch") or Input.is_action_just_pressed(prefix + "crouch"),
		"attack": Input.is_action_pressed(prefix + "attack") or Input.is_action_just_pressed(prefix + "attack"),
		"secondary": Input.is_action_pressed(prefix + "secondary") or Input.is_action_just_pressed(prefix + "secondary"),
		"sprint": Input.is_action_pressed(prefix + "sprint") or Input.is_action_just_pressed(prefix + "sprint"),
		"skill": Input.is_action_pressed(prefix + "skill") or Input.is_action_just_pressed(prefix + "skill"),
		"item": Input.is_action_pressed(prefix + "item") or Input.is_action_just_pressed(prefix + "item"),
		"reload": Input.is_action_pressed(prefix + "reload") or Input.is_action_just_pressed(prefix + "reload"),
	}


func _build_snapshot() -> Dictionary:
	_net_snapshot_id += 1
	return {
		"sid": _net_snapshot_id,
		"p1_pos": player1.global_position,
		"p2_pos": player2.global_position,
		"p1_vel": player1.velocity,
		"p2_vel": player2.velocity,
		"p1_hp": player1.hp,
		"p2_hp": player2.hp,
		"p1_wins": p1_wins,
		"p2_wins": p2_wins,
		"round_active": round_active,
	}


func _on_network_snapshot_received(snapshot: Dictionary) -> void:
	if not _is_online_client:
		return
	var sid := int(snapshot.get("sid", 0))
	if sid <= _client_last_snapshot_id:
		return
	_client_last_snapshot_id = sid

	var p1_target_pos: Vector2 = snapshot.get("p1_pos", player1.global_position)
	var p2_target_pos: Vector2 = snapshot.get("p2_pos", player2.global_position)
	var p1_target_vel: Vector2 = snapshot.get("p1_vel", player1.velocity)
	var p2_target_vel: Vector2 = snapshot.get("p2_vel", player2.velocity)

	if not _client_has_snapshot:
		player1.global_position = p1_target_pos
		player2.global_position = p2_target_pos
		player1.velocity = p1_target_vel
		player2.velocity = p2_target_vel
		_client_has_snapshot = true
	else:
		if player1.global_position.distance_to(p1_target_pos) > NET_SNAP_DISTANCE:
			player1.global_position = p1_target_pos
		else:
			player1.global_position = player1.global_position.lerp(p1_target_pos, NET_REMOTE_POS_LERP)
		var p2_error := player2.global_position.distance_to(p2_target_pos)
		if p2_error > NET_SNAP_DISTANCE:
			player2.global_position = p2_target_pos
		elif p2_error > NET_LOCAL_CORRECTION_DISTANCE:
			player2.global_position = player2.global_position.lerp(p2_target_pos, NET_LOCAL_POS_LERP)
		player1.velocity = player1.velocity.lerp(p1_target_vel, NET_REMOTE_VEL_LERP)
		if p2_error > NET_LOCAL_CORRECTION_DISTANCE:
			player2.velocity = player2.velocity.lerp(p2_target_vel, NET_LOCAL_VEL_LERP)

	player1.hp = float(snapshot.get("p1_hp", player1.hp))
	player2.hp = float(snapshot.get("p2_hp", player2.hp))
	p1_wins = int(snapshot.get("p1_wins", p1_wins))
	p2_wins = int(snapshot.get("p2_wins", p2_wins))
	var next_round_active := bool(snapshot.get("round_active", round_active))
	if next_round_active != round_active:
		round_active = next_round_active
		_set_players_frozen(not round_active)


func _set_players_frozen(frozen: bool) -> void:
	for p in [player1, player2]:
		if p == null:
			continue
		p.velocity = Vector2.ZERO
		p.set_process(not frozen)
		p.set_physics_process(not frozen)


func _reset_arms_economy() -> void:
	_arms_credits[1] = ARMS_START_CREDITS
	_arms_credits[2] = ARMS_START_CREDITS
	_arms_loss_streak[1] = 0
	_arms_loss_streak[2] = 0
	_clear_arms_loadout(1)
	_clear_arms_loadout(2)


func _award_arms_credits(winner_pid: int) -> void:
	var loser_pid := 1 if winner_pid == 2 else 2
	_arms_credits[winner_pid] = mini(ARMS_CREDIT_CAP, int(_arms_credits[winner_pid]) + ARMS_BASE_INCOME + ARMS_WIN_BONUS + ARMS_KILL_BONUS)
	var loser_gain := ARMS_BASE_INCOME
	_arms_loss_streak[winner_pid] = 0
	_arms_loss_streak[loser_pid] = int(_arms_loss_streak[loser_pid]) + 1
	if int(_arms_loss_streak[loser_pid]) >= 3:
		loser_gain += 250
	elif int(_arms_loss_streak[loser_pid]) >= 2:
		loser_gain += 150
	_arms_credits[loser_pid] = mini(ARMS_CREDIT_CAP, int(_arms_credits[loser_pid]) + loser_gain)


func _price_for_weapon(w: WeaponData) -> int:
	var table := {
		WeaponData.Rarity.COMMON: 300,
		WeaponData.Rarity.UNCOMMON: 550,
		WeaponData.Rarity.RARE: 850,
		WeaponData.Rarity.EPIC: 1200,
		WeaponData.Rarity.LEGENDARY: 1700,
		WeaponData.Rarity.MYTHIC: 2300,
		WeaponData.Rarity.CONTRABAND: 3000,
	}
	if w.type == WeaponData.Type.MELEE:
		table = {
			WeaponData.Rarity.COMMON: 250,
			WeaponData.Rarity.UNCOMMON: 400,
			WeaponData.Rarity.RARE: 600,
			WeaponData.Rarity.EPIC: 850,
			WeaponData.Rarity.LEGENDARY: 1150,
			WeaponData.Rarity.MYTHIC: 1500,
			WeaponData.Rarity.CONTRABAND: 1800,
		}
	return int(table.get(w.rarity, 500))


func _price_for_tactical(t: TacticalData) -> int:
	match t.tactical_type:
		TacticalData.TacticalType.FRAG_GRENADE, TacticalData.TacticalType.FLASH_FREEZE, TacticalData.TacticalType.MOLOTOV:
			return 350
		TacticalData.TacticalType.MED_KIT:
			return 400
		TacticalData.TacticalType.JETPACK:
			return 450
		_:
			return 500


func _generate_arms_offers(player_id: int) -> void:
	var offers: Array = []
	var round_idx := _get_arms_round_index()
	var max_rarity := WeaponData.Rarity.RARE
	if round_idx >= 4:
		max_rarity = WeaponData.Rarity.EPIC
	if round_idx >= 6:
		max_rarity = WeaponData.Rarity.LEGENDARY
	if round_idx >= 8:
		max_rarity = WeaponData.Rarity.MYTHIC
	if round_idx >= 10:
		max_rarity = WeaponData.Rarity.CONTRABAND

	var guns := WeaponDB.get_pool().filter(func(w):
		return w.type == WeaponData.Type.GUN and w.rarity <= max_rarity and (round_idx >= 10 or w.rarity != WeaponData.Rarity.CONTRABAND)
	)
	var melees := WeaponDB.get_pool().filter(func(w):
		return w.type == WeaponData.Type.MELEE and w.rarity <= max_rarity and (round_idx >= 10 or w.rarity != WeaponData.Rarity.CONTRABAND)
	)
	var tacticals := TacticalData.get_all_tacticals()
	var picked_guns := {}
	for i in mini(3, guns.size()):
		var gun: WeaponData = _pick_weighted_weapon_from(guns, round_idx, picked_guns)
		if gun == null:
			break
		picked_guns[gun.weapon_name] = true
		offers.append({
			"kind": "gun",
			"name": gun.weapon_name,
			"price": _price_for_weapon(gun),
			"color": gun.get_rarity_color(),
			"weapon": gun,
		})
	if not melees.is_empty():
		var melee: WeaponData = _pick_weighted_weapon_from(melees, round_idx)
		offers.append({
			"kind": "melee",
			"name": melee.weapon_name,
			"price": _price_for_weapon(melee),
			"color": melee.get_rarity_color(),
			"weapon": melee,
		})
	if not tacticals.is_empty():
		var tac: TacticalData = tacticals.pick_random()
		offers.append({
			"kind": "tactical",
			"name": tac.item_name,
			"price": _price_for_tactical(tac),
			"color": tac.get_color(),
			"tactical": tac,
		})
	_arms_offers[player_id] = offers


func _refresh_arms_ui_player(player_id: int) -> void:
	if not _arms_buy_ui:
		return
	var offers: Array = _arms_offers[player_id]
	if offers.is_empty():
		_arms_select_index[player_id] = 0
	else:
		_arms_select_index[player_id] = clampi(int(_arms_select_index[player_id]), 0, offers.size() - 1)
	_arms_buy_ui.set_credits(player_id, int(_arms_credits[player_id]))
	if _arms_buy_ui.has_method("set_equipped"):
		_arms_buy_ui.set_equipped(player_id, _get_arms_loadout_summary(player_id))
	_arms_buy_ui.set_offers(player_id, offers, int(_arms_select_index[player_id]), ARMS_GRID_COLUMNS)
	_arms_buy_ui.set_ready(player_id, bool(_arms_ready[player_id]))


func _process_arms_buy_input() -> void:
	_process_arms_buy_input_for_player(1)
	if not GameState.p2_is_ai:
		_process_arms_buy_input_for_player(2)


func _process_arms_buy_input_for_player(player_id: int) -> void:
	if bool(_arms_ready[player_id]):
		return
	var left_action := "p1_left" if player_id == 1 else "p2_left"
	var right_action := "p1_right" if player_id == 1 else "p2_right"
	var up_action := "p1_jump" if player_id == 1 else "p2_jump"
	var down_action := "p1_crouch" if player_id == 1 else "p2_crouch"
	var buy_action := "p1_attack" if player_id == 1 else "p2_attack"
	var ready_action := "p1_secondary" if player_id == 1 else "p2_secondary"
	var reroll_action := "p1_reload" if player_id == 1 else "p2_reload"

	var moved := false
	if Input.is_action_just_pressed(left_action):
		_arms_select_index[player_id] = _move_arms_offer_index(int(_arms_select_index[player_id]), -1, 0, player_id)
		moved = true
	elif Input.is_action_just_pressed(right_action):
		_arms_select_index[player_id] = _move_arms_offer_index(int(_arms_select_index[player_id]), 1, 0, player_id)
		moved = true
	elif Input.is_action_just_pressed(up_action):
		_arms_select_index[player_id] = _move_arms_offer_index(int(_arms_select_index[player_id]), 0, -1, player_id)
		moved = true
	elif Input.is_action_just_pressed(down_action):
		_arms_select_index[player_id] = _move_arms_offer_index(int(_arms_select_index[player_id]), 0, 1, player_id)
		moved = true

	if moved:
		AudioManager.play_sfx_varied("ui_click", -8.0, 0.98, 1.02)
		_refresh_arms_ui_player(player_id)

	if Input.is_action_just_pressed(buy_action):
		_on_arms_buy_requested(player_id, int(_arms_select_index[player_id]))

	if Input.is_action_just_pressed(reroll_action):
		_on_arms_reroll_requested(player_id)

	if Input.is_action_just_pressed(ready_action):
		_on_arms_ready_toggled(player_id, true)


func _move_arms_offer_index(current_idx: int, dx: int, dy: int, player_id: int) -> int:
	var offers: Array = _arms_offers[player_id]
	if offers.is_empty():
		return 0
	var cols := ARMS_GRID_COLUMNS
	var count := offers.size()
	var rows := int(ceil(float(count) / float(cols)))

	var row := current_idx / cols
	var col := current_idx % cols
	row = posmod(row + dy, rows)
	col = posmod(col + dx, cols)

	var next := row * cols + col
	if next >= count:
		next = count - 1
	return clampi(next, 0, count - 1)


func _on_arms_buy_requested(player_id: int, offer_index: int) -> void:
	if not _arms_buy_active:
		return
	var offers: Array = _arms_offers[player_id]
	if offer_index < 0 or offer_index >= offers.size():
		return
	var offer = offers[offer_index]
	var price := int(offer["price"])
	if int(_arms_credits[player_id]) < price:
		if _arms_buy_ui:
			_arms_buy_ui.set_status(player_id, "Not enough credits", Color(1.0, 0.35, 0.35))
		return
	_arms_credits[player_id] = int(_arms_credits[player_id]) - price
	match String(offer["kind"]):
		"gun":
			_arms_loadout[player_id]["gun"] = offer["weapon"]
		"melee":
			_arms_loadout[player_id]["melee"] = offer["weapon"]
		"tactical":
			_arms_loadout[player_id]["tactical"] = offer["tactical"]
	offers.remove_at(offer_index)
	_arms_offers[player_id] = offers
	if _arms_buy_ui:
		_arms_buy_ui.set_status(player_id, "Purchased: %s" % String(offer["name"]), Color(0.55, 1.0, 0.6))
	_refresh_arms_ui_player(player_id)


func _on_arms_reroll_requested(player_id: int) -> void:
	if not _arms_buy_active:
		return
	if int(_arms_free_rerolls[player_id]) > 0:
		_arms_free_rerolls[player_id] = int(_arms_free_rerolls[player_id]) - 1
	else:
		if int(_arms_credits[player_id]) < ARMS_REROLL_COST:
			if _arms_buy_ui:
				_arms_buy_ui.set_status(player_id, "Need %d credits to reroll" % ARMS_REROLL_COST, Color(1.0, 0.35, 0.35))
			return
		_arms_credits[player_id] = int(_arms_credits[player_id]) - ARMS_REROLL_COST
	_generate_arms_offers(player_id)
	if _arms_buy_ui:
		_arms_buy_ui.set_status(player_id, "Shop rerolled", Color(0.7, 0.9, 1.0))
	_refresh_arms_ui_player(player_id)


func _on_arms_ready_toggled(player_id: int, _ready: bool) -> void:
	if not _arms_buy_active:
		return
	_arms_ready[player_id] = true
	if _arms_buy_ui:
		_arms_buy_ui.set_ready(player_id, true)
		_arms_buy_ui.set_status(player_id, "Locked in", Color(0.55, 1.0, 0.6))


func _apply_arms_loadout(player_id: int) -> void:
	var p := _get_player(player_id)
	if p == null:
		return
	var loadout: Dictionary = _arms_loadout[player_id]
	var gun: WeaponData = loadout.get("gun")
	if gun:
		p.equip_weapon(gun, gun.capacity, gun.reserve_ammo)
	var melee: WeaponData = loadout.get("melee")
	if melee:
		p.equip_weapon(melee)
	var tactical: TacticalData = loadout.get("tactical")
	p.current_tactical = tactical


func _ai_buy_for_player(player_id: int) -> void:
	var failsafe := 0
	while failsafe < 10:
		failsafe += 1
		var offers: Array = _arms_offers[player_id]
		if offers.is_empty():
			break
		var affordable_indexes: Array[int] = []
		for i in offers.size():
			if int(offers[i]["price"]) <= int(_arms_credits[player_id]):
				affordable_indexes.append(i)
		if affordable_indexes.is_empty():
			break
		_on_arms_buy_requested(player_id, affordable_indexes.pick_random())


func _clear_arms_loadout(player_id: int) -> void:
	_arms_loadout[player_id] = {"gun": null, "melee": null, "tactical": null}


func _get_arms_round_index() -> int:
	return p1_wins + p2_wins + 1


func _get_arms_rarity_weights(round_idx: int) -> Dictionary:
	if round_idx <= 3:
		return {
			WeaponData.Rarity.COMMON: 34.0,
			WeaponData.Rarity.UNCOMMON: 28.0,
			WeaponData.Rarity.RARE: 18.0,
			WeaponData.Rarity.EPIC: 7.0,
			WeaponData.Rarity.LEGENDARY: 2.0,
			WeaponData.Rarity.MYTHIC: 0.4,
			WeaponData.Rarity.CONTRABAND: 0.0,
		}
	if round_idx <= 7:
		return {
			WeaponData.Rarity.COMMON: 16.0,
			WeaponData.Rarity.UNCOMMON: 22.0,
			WeaponData.Rarity.RARE: 24.0,
			WeaponData.Rarity.EPIC: 19.0,
			WeaponData.Rarity.LEGENDARY: 8.0,
			WeaponData.Rarity.MYTHIC: 2.0,
			WeaponData.Rarity.CONTRABAND: 0.0,
		}
	return {
		WeaponData.Rarity.COMMON: 8.0,
		WeaponData.Rarity.UNCOMMON: 12.0,
		WeaponData.Rarity.RARE: 20.0,
		WeaponData.Rarity.EPIC: 24.0,
		WeaponData.Rarity.LEGENDARY: 20.0,
		WeaponData.Rarity.MYTHIC: 12.0,
		WeaponData.Rarity.CONTRABAND: 2.0,
	}


func _pick_weighted_weapon_from(pool: Array, round_idx: int, exclude_names: Dictionary = {}) -> WeaponData:
	var candidates: Array = []
	for w in pool:
		if exclude_names.has(w.weapon_name):
			continue
		candidates.append(w)
	if candidates.is_empty():
		return null

	var weights := _get_arms_rarity_weights(round_idx)
	var total := 0.0
	for w in candidates:
		total += float(weights.get(w.rarity, 1.0))
	if total <= 0.0:
		return candidates.pick_random()

	var roll := randf() * total
	var acc := 0.0
	for w in candidates:
		acc += float(weights.get(w.rarity, 1.0))
		if roll <= acc:
			return w
	return candidates.back()


func _get_arms_loadout_summary(player_id: int) -> String:
	var loadout: Dictionary = _arms_loadout[player_id]
	var gun: WeaponData = loadout.get("gun")
	var melee: WeaponData = loadout.get("melee")
	var tactical: TacticalData = loadout.get("tactical")
	var gun_name := gun.weapon_name if gun else "-"
	var melee_name := melee.weapon_name if melee else "-"
	var tactical_name := tactical.item_name if tactical else "-"
	return "G:%s | M:%s | T:%s" % [gun_name, melee_name, tactical_name]
