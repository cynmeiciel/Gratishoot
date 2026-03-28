extends Control

var player1: CharacterBody2D
var player2: CharacterBody2D
var arena_manager: Node2D
var _hud_visible := true
var _rarity_icon_cache: Dictionary = {}

const RARITY_PRIORITY: Dictionary = {
	WeaponData.Rarity.CONTRABAND: 0,
	WeaponData.Rarity.MYTHIC: 1,
	WeaponData.Rarity.LEGENDARY: 2,
	WeaponData.Rarity.EPIC: 3,
	WeaponData.Rarity.RARE: 4,
	WeaponData.Rarity.UNCOMMON: 5,
	WeaponData.Rarity.COMMON: 6,
}

@onready var backdrop: ColorRect = $Backdrop
@onready var top_bar: PanelContainer = $TopBar
@onready var root: MarginContainer = $Root
@onready var toggle_hud_button: Button = $ToggleHudButton

@onready var p1_gun_option: OptionButton = $Root/Stack/MainRow/P1Panel/P1Margin/P1VBox/P1GunGroup/P1GunPad/P1GunRow/P1GunOption
@onready var p1_melee_option: OptionButton = $Root/Stack/MainRow/P1Panel/P1Margin/P1VBox/P1MeleeGroup/P1MeleePad/P1MeleeRow/P1MeleeOption
@onready var p1_tac_option: OptionButton = $Root/Stack/MainRow/P1Panel/P1Margin/P1VBox/P1TacGroup/P1TacPad/P1TacRow/P1TacOption
@onready var p1_skill_option: OptionButton = $Root/Stack/MainRow/P1Panel/P1Margin/P1VBox/P1SkillGroup/P1SkillPad/P1SkillRow/P1SkillOption
@onready var p1_current_label: Label = $Root/Stack/MainRow/P1Panel/P1Margin/P1VBox/P1Current
@onready var p1_assist_label: Label = $Root/Stack/MainRow/P1Panel/P1Margin/P1VBox/P1Assist
@onready var p1_preview: RichTextLabel = $Root/Stack/MainRow/P1Panel/P1Margin/P1VBox/P1Preview

@onready var p2_gun_option: OptionButton = $Root/Stack/MainRow/P2Panel/P2Margin/P2VBox/P2GunGroup/P2GunPad/P2GunRow/P2GunOption
@onready var p2_melee_option: OptionButton = $Root/Stack/MainRow/P2Panel/P2Margin/P2VBox/P2MeleeGroup/P2MeleePad/P2MeleeRow/P2MeleeOption
@onready var p2_tac_option: OptionButton = $Root/Stack/MainRow/P2Panel/P2Margin/P2VBox/P2TacGroup/P2TacPad/P2TacRow/P2TacOption
@onready var p2_skill_option: OptionButton = $Root/Stack/MainRow/P2Panel/P2Margin/P2VBox/P2SkillGroup/P2SkillPad/P2SkillRow/P2SkillOption
@onready var p2_current_label: Label = $Root/Stack/MainRow/P2Panel/P2Margin/P2VBox/P2Current
@onready var p2_assist_label: Label = $Root/Stack/MainRow/P2Panel/P2Margin/P2VBox/P2Assist
@onready var p2_preview: RichTextLabel = $Root/Stack/MainRow/P2Panel/P2Margin/P2VBox/P2Preview


func _ready() -> void:
	if toggle_hud_button:
		toggle_hud_button.top_level = true
		toggle_hud_button.z_as_relative = false
		toggle_hud_button.z_index = 200
		move_child(toggle_hud_button, get_child_count() - 1)


func init(p1: CharacterBody2D, p2: CharacterBody2D, manager: Node2D) -> void:
	player1 = p1
	player2 = p2
	arena_manager = manager
	_populate_weapon_options()
	_apply_hud_visibility()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		_hud_visible = not _hud_visible
		_apply_hud_visibility()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if player1:
		p1_current_label.text = "Current: %s | %s | %s | %s" % [_gun_text(player1), _melee_text(player1), _tactical_text(player1), _skill_text(player1)]
		_update_assist_label(player1, p1_assist_label)
	if player2:
		p2_current_label.text = "Current: %s | %s | %s | %s" % [_gun_text(player2), _melee_text(player2), _tactical_text(player2), _skill_text(player2)]
		_update_assist_label(player2, p2_assist_label)


func _update_assist_label(p: CharacterBody2D, label: Label) -> void:
	if label == null or p == null or not p.has_method("get_precision_assist_status"):
		return
	var status: Dictionary = p.get_precision_assist_status()
	var active := bool(status.get("active", false))
	if active:
		var distance := float(status.get("distance", 0.0))
		label.text = "Assist: ACTIVE (%.0fpx)" % distance
		label.modulate = Color(0.35, 1.0, 0.62)
	else:
		var reason := String(status.get("reason", "STANDBY"))
		label.text = "Assist: %s" % reason
		label.modulate = Color(0.95, 0.78, 0.38)


func _populate_weapon_options() -> void:
	if arena_manager == null:
		return

	var pool: Array[WeaponData] = WeaponDB.get_pool()
	var guns: Array[WeaponData] = []
	var melees: Array[WeaponData] = []
	var tacticals: PackedStringArray = arena_manager.get_training_tactical_names()
	var skills: PackedStringArray = arena_manager.get_training_skill_names()
	for weapon in pool:
		if weapon.type == WeaponData.Type.GUN:
			guns.append(weapon)
		else:
			melees.append(weapon)

	guns.sort_custom(_sort_training_weapons)
	melees.sort_custom(_sort_training_weapons)

	_fill_option_with_weapons(p1_gun_option, guns)
	_fill_option_with_weapons(p2_gun_option, guns)
	_fill_option_with_weapons(p1_melee_option, melees)
	_fill_option_with_weapons(p2_melee_option, melees)
	_fill_option_with_strings(p1_tac_option, tacticals)
	_fill_option_with_strings(p2_tac_option, tacticals)
	_fill_option_with_strings(p1_skill_option, skills)
	_fill_option_with_strings(p2_skill_option, skills)

	if player1:
		_select_option_by_value(p1_tac_option, _tactical_text(player1))
		_select_option_by_value(p1_skill_option, _skill_text(player1))
	if player2:
		_select_option_by_value(p2_tac_option, _tactical_text(player2))
		_select_option_by_value(p2_skill_option, _skill_text(player2))

	_update_preview(1)
	_update_preview(2)


func _sort_training_weapons(a: WeaponData, b: WeaponData) -> bool:
	var rarity_a: int = int(RARITY_PRIORITY.get(a.rarity, 999))
	var rarity_b: int = int(RARITY_PRIORITY.get(b.rarity, 999))
	if rarity_a == rarity_b:
		return a.weapon_name.naturalnocasecmp_to(b.weapon_name) < 0
	return rarity_a < rarity_b


func _fill_option_with_weapons(option: OptionButton, weapons: Array[WeaponData]) -> void:
	option.clear()
	for w in weapons:
		option.add_icon_item(_get_rarity_icon(w.get_rarity_color()), w.weapon_name)
		var item_index := option.item_count - 1
		option.set_item_metadata(item_index, w.weapon_name)
	if option.item_count > 0:
		option.select(0)


func _fill_option_with_strings(option: OptionButton, values: PackedStringArray) -> void:
	option.clear()
	for value in values:
		option.add_item(value)
		var item_index := option.item_count - 1
		option.set_item_metadata(item_index, value)
	if option.item_count > 0:
		option.select(0)


func _select_option_by_value(option: OptionButton, value: String) -> void:
	for i in option.item_count:
		if option.get_item_text(i) == value:
			option.select(i)
			return


func _get_rarity_icon(color: Color) -> Texture2D:
	var key := color.to_html()
	if _rarity_icon_cache.has(key):
		return _rarity_icon_cache[key]
	var image := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var texture := ImageTexture.create_from_image(image)
	_rarity_icon_cache[key] = texture
	return texture


func _selected_weapon_name(option: OptionButton) -> String:
	if option.item_count == 0 or option.selected < 0:
		return ""
	var selected_meta = option.get_item_metadata(option.selected)
	if typeof(selected_meta) == TYPE_STRING:
		return selected_meta
	return option.get_item_text(option.selected)


func _gun_text(p: CharacterBody2D) -> String:
	return p.current_gun.weapon_name if p.current_gun else "Unarmed"


func _ui_click(back := false) -> void:
	AudioManager.play_sfx_varied("ui_back" if back else "ui_click", -6.0, 0.98, 1.03)


func _melee_text(p: CharacterBody2D) -> String:
	return p.current_melee.weapon_name if p.current_melee else "Bare Fists"


func _tactical_text(p: CharacterBody2D) -> String:
	if not p.current_tactical:
		return "No Tactical"
	if p.current_tactical.charges > 1:
		return "%s x%d" % [p.current_tactical.item_name, p.current_tactical.charges]
	return p.current_tactical.item_name


func _skill_text(p: CharacterBody2D) -> String:
	return p.skill.get_skill_name() if p.skill else "No Skill"


func _on_p1_equip_gun_pressed() -> void:
	_ui_click()
	if p1_gun_option.item_count == 0:
		return
	arena_manager.equip_training_weapon(1, _selected_weapon_name(p1_gun_option))


func _on_p1_clear_gun_pressed() -> void:
	_ui_click()
	arena_manager.clear_training_weapon(1, WeaponData.Type.GUN)


func _on_p1_equip_melee_pressed() -> void:
	_ui_click()
	if p1_melee_option.item_count == 0:
		return
	arena_manager.equip_training_weapon(1, _selected_weapon_name(p1_melee_option))


func _on_p1_clear_melee_pressed() -> void:
	_ui_click()
	arena_manager.clear_training_weapon(1, WeaponData.Type.MELEE)


func _on_p2_equip_gun_pressed() -> void:
	_ui_click()
	if p2_gun_option.item_count == 0:
		return
	arena_manager.equip_training_weapon(2, _selected_weapon_name(p2_gun_option))


func _on_p2_clear_gun_pressed() -> void:
	_ui_click()
	arena_manager.clear_training_weapon(2, WeaponData.Type.GUN)


func _on_p2_equip_melee_pressed() -> void:
	_ui_click()
	if p2_melee_option.item_count == 0:
		return
	arena_manager.equip_training_weapon(2, _selected_weapon_name(p2_melee_option))


func _on_p2_clear_melee_pressed() -> void:
	_ui_click()
	arena_manager.clear_training_weapon(2, WeaponData.Type.MELEE)


func _on_p1_equip_tac_pressed() -> void:
	_ui_click()
	if p1_tac_option.item_count == 0:
		return
	arena_manager.equip_training_tactical(1, _selected_weapon_name(p1_tac_option))
	_update_preview(1)


func _on_p1_clear_tac_pressed() -> void:
	_ui_click()
	arena_manager.clear_training_tactical(1)
	_update_preview(1)


func _on_p2_equip_tac_pressed() -> void:
	_ui_click()
	if p2_tac_option.item_count == 0:
		return
	arena_manager.equip_training_tactical(2, _selected_weapon_name(p2_tac_option))
	_update_preview(2)


func _on_p2_clear_tac_pressed() -> void:
	_ui_click()
	arena_manager.clear_training_tactical(2)
	_update_preview(2)


func _on_p1_apply_skill_pressed() -> void:
	_ui_click()
	if p1_skill_option.item_count == 0:
		return
	arena_manager.equip_training_skill(1, _selected_weapon_name(p1_skill_option))
	_update_preview(1)


func _on_p2_apply_skill_pressed() -> void:
	_ui_click()
	if p2_skill_option.item_count == 0:
		return
	arena_manager.equip_training_skill(2, _selected_weapon_name(p2_skill_option))
	_update_preview(2)


func _on_refill_ammo_pressed() -> void:
	_ui_click()
	arena_manager.refill_training_ammo()


func _on_reset_positions_pressed() -> void:
	_ui_click()
	arena_manager.reset_training_positions()


func _on_back_to_menu_pressed() -> void:
	_ui_click(true)
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")


func _on_toggle_hud_button_pressed() -> void:
	_ui_click()
	_hud_visible = not _hud_visible
	_apply_hud_visibility()


func _on_p1_gun_option_item_selected(_index: int) -> void:
	_update_preview(1)


func _on_p1_melee_option_item_selected(_index: int) -> void:
	_update_preview(1)


func _on_p2_gun_option_item_selected(_index: int) -> void:
	_update_preview(2)


func _on_p2_melee_option_item_selected(_index: int) -> void:
	_update_preview(2)


func _update_preview(player_id: int) -> void:
	var gun_name := ""
	var melee_name := ""
	var tactical_name := ""
	var skill_name := ""
	var target: RichTextLabel = p1_preview
	if player_id == 1:
		if p1_gun_option.item_count > 0:
			gun_name = _selected_weapon_name(p1_gun_option)
		if p1_melee_option.item_count > 0:
			melee_name = _selected_weapon_name(p1_melee_option)
		tactical_name = _tactical_text(player1)
		skill_name = _skill_text(player1)
		target = p1_preview
	else:
		if p2_gun_option.item_count > 0:
			gun_name = _selected_weapon_name(p2_gun_option)
		if p2_melee_option.item_count > 0:
			melee_name = _selected_weapon_name(p2_melee_option)
		tactical_name = _tactical_text(player2)
		skill_name = _skill_text(player2)
		target = p2_preview

	var gun_text := _weapon_preview_text(gun_name)
	var melee_text := _weapon_preview_text(melee_name)
	target.text = "[b]Gun Pick[/b]\n%s\n\n[b]Melee Pick[/b]\n%s\n\n[b]Tactical[/b] %s\n[b]Skill[/b] %s" % [gun_text, melee_text, tactical_name, skill_name]


func _weapon_preview_text(weapon_name: String) -> String:
	var w := WeaponDB.get_by_name(weapon_name)
	if w == null:
		return "-"
	if w.type == WeaponData.Type.GUN:
		var mode := "SINGLE"
		if w.fire_mode == WeaponData.FireMode.BURST:
			mode = "BURST"
		elif w.fire_mode == WeaponData.FireMode.AUTO:
			mode = "AUTO"
		return "%s  |  DMG %.0f  RATE %.1f  VEL %.0f  SPREAD %.2f  AMMO %d/%d  MODE %s" % [
			w.weapon_name, w.damage, w.fire_rate, w.velocity, w.spread, w.capacity, w.reserve_ammo, mode
		]
	return "%s  |  DMG %.0f  RATE %.1f  RANGE %.0f  KNOCK %.0f" % [
		w.weapon_name, w.damage, w.fire_rate, w.melee_range, w.knockback
	]


func _apply_hud_visibility() -> void:
	if backdrop:
		backdrop.visible = _hud_visible
	if top_bar:
		top_bar.visible = _hud_visible
	if root:
		root.visible = _hud_visible
	if toggle_hud_button:
		toggle_hud_button.text = "Show HUD (F1)" if not _hud_visible else "Hide HUD (F1)"
