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

const ARMS_START_CREDITS := 800
const ARMS_BASE_INCOME := 400
const ARMS_WIN_BONUS := 300
const ARMS_KILL_BONUS := 150
const ARMS_CREDIT_CAP := 5000
const ARMS_BUY_PHASE_TIME := 12.0
const ARMS_REROLL_COST := 150

var _pause_menu: Control
var _arms_buy_ui: Control
var _arms_buy_timer := 0.0
var _arms_buy_active := false
var _arms_credits := {1: ARMS_START_CREDITS, 2: ARMS_START_CREDITS}
var _arms_loss_streak := {1: 0, 2: 0}
var _arms_ready := {1: false, 2: false}
var _arms_free_rerolls := {1: 1, 2: 1}
var _arms_offers := {1: [], 2: []}
var _arms_loadout := {
	1: {"gun": null, "melee": null, "tactical": null},
	2: {"gun": null, "melee": null, "tactical": null},
}


func _ready() -> void:
	# Wait for all children to be ready before accessing them
	await get_tree().process_frame
	_init_match()


func _process(delta: float) -> void:
	if _arms_buy_active:
		_arms_buy_timer -= delta
		if _arms_buy_ui and _arms_buy_ui.has_method("set_timer"):
			_arms_buy_ui.set_timer(_arms_buy_timer)
		if _arms_buy_timer <= 0.0 or (_arms_ready[1] and _arms_ready[2]):
			_begin_arms_round()


func _init_match() -> void:
	rounds_to_win = GameState.rounds_to_win
	_is_training = GameState.game_mode == GameState.MODE_TRAINING
	_is_arms_dealer = GameState.game_mode == GameState.MODE_ARMS_DEALER
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
		player1.died.connect(_on_player_died)
		player2.died.connect(_on_player_died)
		if _is_arms_dealer and weapon_spawner:
			weapon_spawner.clear_pickups()
			weapon_spawner.set_process(false)

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
		else:
			get_tree().create_timer(1.5).timeout.connect(_start_new_round)


func _start_new_round() -> void:
	if _is_arms_dealer:
		_start_arms_buy_phase(false)
		return
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
	AudioManager.play_sfx_varied("round_start", -2.0, 0.98, 1.02)


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
				if _is_arms_dealer:
					_reset_arms_economy()
					_start_arms_buy_phase(true)
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
		_arms_buy_ui.set_info("Buy gear and lock in before timer ends.")
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
	_set_players_frozen(false)
	round_active = true
	AudioManager.play_sfx_varied("round_start", -2.0, 0.98, 1.02)


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
	_arms_buy_ui.set_credits(player_id, int(_arms_credits[player_id]))
	if _arms_buy_ui.has_method("set_equipped"):
		_arms_buy_ui.set_equipped(player_id, _get_arms_loadout_summary(player_id))
	_arms_buy_ui.set_offers(player_id, _arms_offers[player_id])
	_arms_buy_ui.set_ready(player_id, bool(_arms_ready[player_id]))


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
