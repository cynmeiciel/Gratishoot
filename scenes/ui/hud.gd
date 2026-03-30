extends Control
## Node-based HUD updater. Layout is authored in hud.tscn so designers can tweak visually.

var player1: CharacterBody2D
var player2: CharacterBody2D
var arena_manager: Node2D
var _display_hp_p1 := 100.0
var _display_hp_p2 := 100.0

@onready var p1_panel: PanelContainer = $P1Panel
@onready var p1_title: Label = $P1Panel/Margin/VBox/Title
@onready var p1_hp_value: Label = $P1Panel/Margin/VBox/HPValue
@onready var p1_hp_delayed: ProgressBar = $P1Panel/Margin/VBox/HPStack/HPDelayed
@onready var p1_hp_bar: ProgressBar = $P1Panel/Margin/VBox/HPStack/HPBar
@onready var p1_stamina_bar: ProgressBar = $P1Panel/Margin/VBox/StaminaBar
@onready var p1_gun: Label = $P1Panel/Margin/VBox/GunValue
@onready var p1_ammo: Label = $P1Panel/Margin/VBox/AmmoValue
@onready var p1_melee: Label = $P1Panel/Margin/VBox/MeleeValue
@onready var p1_misc: Label = $P1Panel/Margin/VBox/MiscRow/MiscValue
@onready var p1_tac_dot: ColorRect = $P1Panel/Margin/VBox/MiscRow/TacDot
@onready var p1_skill_bar: ProgressBar = $P1Panel/Margin/VBox/SkillBar
@onready var p1_skill_state: Label = $P1Panel/Margin/VBox/SkillState

@onready var p2_panel: PanelContainer = $P2Panel
@onready var p2_title: Label = $P2Panel/Margin/VBox/Title
@onready var p2_hp_value: Label = $P2Panel/Margin/VBox/HPValue
@onready var p2_hp_delayed: ProgressBar = $P2Panel/Margin/VBox/HPStack/HPDelayed
@onready var p2_hp_bar: ProgressBar = $P2Panel/Margin/VBox/HPStack/HPBar
@onready var p2_stamina_bar: ProgressBar = $P2Panel/Margin/VBox/StaminaBar
@onready var p2_gun: Label = $P2Panel/Margin/VBox/GunValue
@onready var p2_ammo: Label = $P2Panel/Margin/VBox/AmmoValue
@onready var p2_melee: Label = $P2Panel/Margin/VBox/MeleeValue
@onready var p2_misc: Label = $P2Panel/Margin/VBox/MiscRow/MiscValue
@onready var p2_tac_dot: ColorRect = $P2Panel/Margin/VBox/MiscRow/TacDot
@onready var p2_skill_bar: ProgressBar = $P2Panel/Margin/VBox/SkillBar
@onready var p2_skill_state: Label = $P2Panel/Margin/VBox/SkillState
@onready var p1_regen_bar: ProgressBar = $P1Panel/Margin/VBox/RegenDelayBar
@onready var p2_regen_bar: ProgressBar = $P2Panel/Margin/VBox/RegenDelayBar

@onready var round_panel: PanelContainer = $RoundPanel
@onready var round_info: Label = $RoundPanel/Margin/VBox/RoundInfo
@onready var round_score: Label = $RoundPanel/Margin/VBox/RoundScore
@onready var p1_round_dots: HBoxContainer = $RoundPanel/Margin/VBox/DotsRow/P1Dots
@onready var p2_round_dots: HBoxContainer = $RoundPanel/Margin/VBox/DotsRow/P2Dots

@onready var victory_overlay: PanelContainer = $VictoryOverlay
@onready var victory_text: Label = $VictoryOverlay/Center/VBox/VictoryText
@onready var victory_hint: Label = $VictoryOverlay/Center/VBox/VictoryHint


func _ready() -> void:
	_setup_bar_styles()


func init(p1: CharacterBody2D, p2: CharacterBody2D, manager: Node2D) -> void:
	player1 = p1
	player2 = p2
	arena_manager = manager
	_display_hp_p1 = p1.hp
	_display_hp_p2 = p2.hp
	_rebuild_round_dots()


func _process(delta: float) -> void:
	if not player1 or not player2 or not arena_manager:
		return

	_display_hp_p1 = move_toward(_display_hp_p1, player1.hp, 35.0 * delta)
	_display_hp_p2 = move_toward(_display_hp_p2, player2.hp, 35.0 * delta)

	_update_player_panel(player1, true)
	_update_player_panel(player2, false)
	_update_round_ui()
	_update_victory_ui()


func _update_player_panel(p: CharacterBody2D, is_left: bool) -> void:
	var panel := p1_panel if is_left else p2_panel
	var title := p1_title if is_left else p2_title
	var hp_value := p1_hp_value if is_left else p2_hp_value
	var hp_delayed := p1_hp_delayed if is_left else p2_hp_delayed
	var hp_bar := p1_hp_bar if is_left else p2_hp_bar
	var stamina_bar := p1_stamina_bar if is_left else p2_stamina_bar
	var gun_label := p1_gun if is_left else p2_gun
	var ammo_label := p1_ammo if is_left else p2_ammo
	var melee_label := p1_melee if is_left else p2_melee
	var misc_label := p1_misc if is_left else p2_misc
	var tac_dot := p1_tac_dot if is_left else p2_tac_dot
	var skill_bar := p1_skill_bar if is_left else p2_skill_bar
	var skill_state := p1_skill_state if is_left else p2_skill_state

	var hp_frac: float = p.hp / p.HP_MAX
	var panel_box := panel.get_theme_stylebox("panel")
	if panel_box is StyleBoxFlat:
		var border_col: Color = p.player_color
		if hp_frac < 0.25 and not p.is_dead:
			var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008)
			border_col = p.player_color.lerp(Color.RED, pulse)
		panel_box.border_color = border_col

	title.text = "%s" % _player_name_for_id(p.player_id)
	title.modulate = p.player_color.lerp(Color.WHITE, 0.30)
	hp_value.text = "%d / %d" % [ceili(p.hp), int(p.HP_MAX)]
	hp_value.modulate = Color.WHITE.lerp(Color(1.0, 0.25, 0.10), 1.0 - hp_frac)

	hp_bar.max_value = p.HP_MAX
	hp_delayed.max_value = p.HP_MAX
	hp_bar.value = p.hp
	hp_delayed.value = _display_hp_p1 if is_left else _display_hp_p2
	var hp_fill := hp_bar.get_theme_stylebox("fill")
	if hp_fill is StyleBoxFlat:
		var hp_color: Color
		if hp_frac >= 0.5:
			hp_color = Color(0.15, 0.88, 0.25).lerp(Color(0.95, 0.88, 0.10), (1.0 - hp_frac) * 2.0)
		else:
			hp_color = Color(0.95, 0.88, 0.10).lerp(Color(0.92, 0.12, 0.08), (0.5 - hp_frac) * 2.0)
		if hp_frac < 0.30 and not p.is_dead:
			var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
			hp_color = hp_color.lerp(Color(1.0, 0.05, 0.05), pulse * 0.40)
		hp_fill.bg_color = hp_color

	stamina_bar.max_value = p.STAMINA_MAX
	stamina_bar.value = p.stamina

	var gun_name := "Unarmed"
	var gun_category := ""
	var gun_mode := ""
	if p.current_gun:
		gun_name = p.current_gun.weapon_name
		var category_names := {
			WeaponData.GunCategory.PISTOL: "Pistol",
			WeaponData.GunCategory.SMG: "SMG",
			WeaponData.GunCategory.SHOTGUN: "Shotgun",
			WeaponData.GunCategory.ASSAULT_RIFLE: "AR",
			WeaponData.GunCategory.LMG: "LMG",
			WeaponData.GunCategory.BATTLE_RIFLE: "BR",
			WeaponData.GunCategory.DMR: "DMR",
			WeaponData.GunCategory.SNIPER: "Sniper",
			WeaponData.GunCategory.LAUNCHER: "Launcher"
		}
		gun_category = category_names.get(p.current_gun.gun_category, "")
		var mode_names := {
			WeaponData.FireMode.SINGLE: "SINGLE",
			WeaponData.FireMode.BURST: "BURST",
			WeaponData.FireMode.AUTO: "AUTO"
		}
		gun_mode = mode_names.get(p.current_gun.fire_mode, "")
	gun_label.text = _clip_text(("%s [%s] %s" % [gun_name, gun_category, gun_mode]).strip_edges(), 36)
	gun_label.modulate = p.current_gun.get_rarity_color() if p.current_gun else Color(0.65, 0.65, 0.65)

	if p.current_gun:
		ammo_label.text = "%d/%d" % [p.ammo_current, p.ammo_reserve]
	else:
		ammo_label.text = "--/--"
	if p.is_reloading:
		ammo_label.text = "RELOADING"
	if p.current_gun and not p.is_reloading:
		var ammo_frac := float(p.ammo_current) / maxf(p.current_gun.capacity, 1)
		if ammo_frac <= 0.20:
			var pulse := 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.007)
			ammo_label.modulate = Color(1.0, 0.30, 0.15).lerp(Color.WHITE, pulse)
		else:
			ammo_label.modulate = Color.WHITE
	else:
		ammo_label.modulate = Color(0.70, 0.70, 0.70)

	var melee_text := "Bare Fists"
	if p.current_melee:
		melee_text = p.current_melee.weapon_name
	melee_label.text = _clip_text(melee_text, 28)
	melee_label.modulate = p.current_melee.get_rarity_color() if p.current_melee else Color(0.65, 0.65, 0.65)

	var tac_text := "None"
	if p.current_tactical:
		if p.current_tactical.charges > 1:
			tac_text = "%s x%d" % [p.current_tactical.item_name, p.current_tactical.charges]
		else:
			tac_text = p.current_tactical.item_name
	var skill_name: String = p.skill.get_skill_name() if p.skill else "Skill"
	misc_label.text = _clip_text("%s | %s" % [tac_text, skill_name], 34)
	tac_dot.color = p.current_tactical.get_color() if p.current_tactical else Color(0.35, 0.35, 0.35)

	var cd_frac := 1.0
	if p.skill and p.skill.cooldown > 0.0:
		cd_frac = 1.0 - (p.skill.cooldown_timer / p.skill.cooldown)
	cd_frac = clampf(cd_frac, 0.0, 1.0)
	skill_bar.value = cd_frac * 100.0
	skill_bar.modulate = p.skill.get_color() if p.skill else Color.WHITE
	if p.skill and p.skill.cooldown_timer > 0.0:
		skill_state.text = "COOLDOWN %.1fs" % p.skill.cooldown_timer
		skill_state.modulate = Color(0.65, 0.65, 0.65)
	else:
		skill_state.text = "SKILL READY"
		var ready_pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.004)
		var skill_col := (skill_bar.modulate if p.skill else Color.WHITE)
		skill_state.modulate = skill_col.lerp(Color.WHITE, ready_pulse)

	# Regen delay indicator
	var regen_bar := p1_regen_bar if is_left else p2_regen_bar
	const REGEN_DELAY := 2.0
	var regen_fill := regen_bar.get_theme_stylebox("fill")
	if p._regen_timer > 0.0:
		regen_bar.visible = true
		regen_bar.max_value = REGEN_DELAY
		regen_bar.value = p._regen_timer
		if regen_fill is StyleBoxFlat:
			regen_fill.bg_color = Color(0.95, 0.55, 0.10)
	elif p.hp < p.HP_MAX and not p.is_dead:
		regen_bar.visible = true
		regen_bar.max_value = 1.0
		regen_bar.value = 1.0
		if regen_fill is StyleBoxFlat:
			var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.005)
			regen_fill.bg_color = Color(0.10, 0.90, 0.40) * Color(pulse, pulse, pulse, 1.0)
	else:
		regen_bar.visible = false


func _update_round_ui() -> void:
	var p1w: int = arena_manager.p1_wins
	var p2w: int = arena_manager.p2_wins
	var rtw: int = arena_manager.rounds_to_win

	round_info.text = "FIRST TO %d" % rtw
	round_score.text = "%d - %d" % [p1w, p2w]

	if p1_round_dots.get_child_count() != rtw or p2_round_dots.get_child_count() != rtw:
		_rebuild_round_dots()

	for i in rtw:
		var p1_dot := p1_round_dots.get_child(i) as ColorRect
		var p2_dot := p2_round_dots.get_child(i) as ColorRect
		p1_dot.color = player1.player_color if i < p1w else Color(0.28, 0.28, 0.28)
		p2_dot.color = player2.player_color if i < p2w else Color(0.28, 0.28, 0.28)


func _rebuild_round_dots() -> void:
	if not arena_manager:
		return
	_clear_children(p1_round_dots)
	_clear_children(p2_round_dots)
	for _i in arena_manager.rounds_to_win:
		var d1 := ColorRect.new()
		d1.custom_minimum_size = Vector2(10, 10)
		d1.color = Color(0.28, 0.28, 0.28)
		p1_round_dots.add_child(d1)
		var d2 := ColorRect.new()
		d2.custom_minimum_size = Vector2(10, 10)
		d2.color = Color(0.28, 0.28, 0.28)
		p2_round_dots.add_child(d2)


func _update_victory_ui() -> void:
	var p1w: int = arena_manager.p1_wins
	var p2w: int = arena_manager.p2_wins
	var rtw: int = arena_manager.rounds_to_win
	var show: bool = (not arena_manager.round_active) and (p1w >= rtw or p2w >= rtw)
	victory_overlay.visible = show
	if not show:
		return

	if p1w >= rtw:
		victory_text.text = ("%s WINS!" % _player_name_for_id(1)).to_upper()
		victory_text.modulate = player1.player_color
	else:
		victory_text.text = ("%s WINS!" % _player_name_for_id(2)).to_upper()
		victory_text.modulate = player2.player_color
	victory_hint.text = "Press Enter to restart"


func _setup_bar_styles() -> void:
	_setup_bar_style(p1_hp_bar,      Color(0.15, 0.88, 0.25), Color(0.09, 0.12, 0.09, 0.75))
	_setup_bar_style(p1_hp_delayed,  Color(0.95, 0.48, 0.05), Color(0.09, 0.12, 0.09, 0.75))
	_setup_bar_style(p1_stamina_bar, Color(0.18, 0.58, 1.00), Color(0.07, 0.09, 0.18, 0.75))
	_setup_bar_style(p1_skill_bar,   Color(0.85, 0.80, 0.10), Color(0.08, 0.08, 0.08, 0.75))
	_setup_bar_style(p1_regen_bar,   Color(0.95, 0.55, 0.10), Color(0.12, 0.08, 0.04, 0.75))
	_setup_bar_style(p2_hp_bar,      Color(0.15, 0.88, 0.25), Color(0.09, 0.12, 0.09, 0.75))
	_setup_bar_style(p2_hp_delayed,  Color(0.95, 0.48, 0.05), Color(0.09, 0.12, 0.09, 0.75))
	_setup_bar_style(p2_stamina_bar, Color(0.18, 0.58, 1.00), Color(0.07, 0.09, 0.18, 0.75))
	_setup_bar_style(p2_skill_bar,   Color(0.85, 0.80, 0.10), Color(0.08, 0.08, 0.08, 0.75))
	_setup_bar_style(p2_regen_bar,   Color(0.95, 0.55, 0.10), Color(0.12, 0.08, 0.04, 0.75))
	_setup_panel_style(p1_panel)
	_setup_panel_style(p2_panel)
	_setup_panel_style(round_panel)
	_setup_panel_style(victory_overlay)


func _setup_bar_style(bar: ProgressBar, fill: Color, bg: Color) -> void:
	var fill_box := StyleBoxFlat.new()
	fill_box.bg_color = fill
	fill_box.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill_box)
	var bg_box := StyleBoxFlat.new()
	bg_box.bg_color = bg
	bg_box.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg_box)


func _setup_panel_style(panel: PanelContainer) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.07, 0.07, 0.10, 0.88)
	box.border_width_left   = 2
	box.border_width_top    = 2
	box.border_width_right  = 2
	box.border_width_bottom = 2
	box.border_color = Color(0.28, 0.28, 0.38, 0.95)
	box.set_corner_radius_all(5)
	panel.add_theme_stylebox_override("panel", box)


func _player_name_for_id(pid: int) -> String:
	if pid == 1:
		return GameState.p1_name
	if pid == 2:
		return GameState.p2_name
	return "Player"


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _clip_text(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	if max_chars <= 3:
		return "..."
	return text.substr(0, max_chars - 3) + "..."
