extends Control

var player1: CharacterBody2D
var player2: CharacterBody2D
var arena_manager: Node2D
var _hud_visible := true

@onready var backdrop: ColorRect = $Backdrop
@onready var top_bar: PanelContainer = $TopBar
@onready var root: MarginContainer = $Root
@onready var toggle_hud_button: Button = $ToggleHudButton

@onready var p1_gun_option: OptionButton = $Root/Stack/MainRow/P1Panel/P1Margin/P1VBox/P1GunGroup/P1GunPad/P1GunRow/P1GunOption
@onready var p1_melee_option: OptionButton = $Root/Stack/MainRow/P1Panel/P1Margin/P1VBox/P1MeleeGroup/P1MeleePad/P1MeleeRow/P1MeleeOption
@onready var p1_current_label: Label = $Root/Stack/MainRow/P1Panel/P1Margin/P1VBox/P1Current
@onready var p1_preview: RichTextLabel = $Root/Stack/MainRow/P1Panel/P1Margin/P1VBox/P1Preview

@onready var p2_gun_option: OptionButton = $Root/Stack/MainRow/P2Panel/P2Margin/P2VBox/P2GunGroup/P2GunPad/P2GunRow/P2GunOption
@onready var p2_melee_option: OptionButton = $Root/Stack/MainRow/P2Panel/P2Margin/P2VBox/P2MeleeGroup/P2MeleePad/P2MeleeRow/P2MeleeOption
@onready var p2_current_label: Label = $Root/Stack/MainRow/P2Panel/P2Margin/P2VBox/P2Current
@onready var p2_preview: RichTextLabel = $Root/Stack/MainRow/P2Panel/P2Margin/P2VBox/P2Preview


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
		p1_current_label.text = "Current: %s | %s" % [_gun_text(player1), _melee_text(player1)]
	if player2:
		p2_current_label.text = "Current: %s | %s" % [_gun_text(player2), _melee_text(player2)]


func _populate_weapon_options() -> void:
	if arena_manager == null:
		return

	p1_gun_option.clear()
	p1_melee_option.clear()
	p2_gun_option.clear()
	p2_melee_option.clear()

	var guns: PackedStringArray = arena_manager.get_training_weapon_names(WeaponData.Type.GUN)
	var melees: PackedStringArray = arena_manager.get_training_weapon_names(WeaponData.Type.MELEE)

	for name in guns:
		p1_gun_option.add_item(name)
		p2_gun_option.add_item(name)
	for name in melees:
		p1_melee_option.add_item(name)
		p2_melee_option.add_item(name)

	if p1_gun_option.item_count > 0:
		p1_gun_option.select(0)
	if p1_melee_option.item_count > 0:
		p1_melee_option.select(0)
	if p2_gun_option.item_count > 0:
		p2_gun_option.select(0)
	if p2_melee_option.item_count > 0:
		p2_melee_option.select(0)

	_update_preview(1)
	_update_preview(2)


func _gun_text(p: CharacterBody2D) -> String:
	return p.current_gun.weapon_name if p.current_gun else "Unarmed"


func _melee_text(p: CharacterBody2D) -> String:
	return p.current_melee.weapon_name if p.current_melee else "Bare Fists"


func _on_p1_equip_gun_pressed() -> void:
	if p1_gun_option.item_count == 0:
		return
	arena_manager.equip_training_weapon(1, p1_gun_option.get_item_text(p1_gun_option.selected))


func _on_p1_clear_gun_pressed() -> void:
	arena_manager.clear_training_weapon(1, WeaponData.Type.GUN)


func _on_p1_equip_melee_pressed() -> void:
	if p1_melee_option.item_count == 0:
		return
	arena_manager.equip_training_weapon(1, p1_melee_option.get_item_text(p1_melee_option.selected))


func _on_p1_clear_melee_pressed() -> void:
	arena_manager.clear_training_weapon(1, WeaponData.Type.MELEE)


func _on_p2_equip_gun_pressed() -> void:
	if p2_gun_option.item_count == 0:
		return
	arena_manager.equip_training_weapon(2, p2_gun_option.get_item_text(p2_gun_option.selected))


func _on_p2_clear_gun_pressed() -> void:
	arena_manager.clear_training_weapon(2, WeaponData.Type.GUN)


func _on_p2_equip_melee_pressed() -> void:
	if p2_melee_option.item_count == 0:
		return
	arena_manager.equip_training_weapon(2, p2_melee_option.get_item_text(p2_melee_option.selected))


func _on_p2_clear_melee_pressed() -> void:
	arena_manager.clear_training_weapon(2, WeaponData.Type.MELEE)


func _on_refill_ammo_pressed() -> void:
	arena_manager.refill_training_ammo()


func _on_reset_positions_pressed() -> void:
	arena_manager.reset_training_positions()


func _on_back_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")


func _on_toggle_hud_button_pressed() -> void:
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
	var target: RichTextLabel = p1_preview
	if player_id == 1:
		if p1_gun_option.item_count > 0:
			gun_name = p1_gun_option.get_item_text(p1_gun_option.selected)
		if p1_melee_option.item_count > 0:
			melee_name = p1_melee_option.get_item_text(p1_melee_option.selected)
		target = p1_preview
	else:
		if p2_gun_option.item_count > 0:
			gun_name = p2_gun_option.get_item_text(p2_gun_option.selected)
		if p2_melee_option.item_count > 0:
			melee_name = p2_melee_option.get_item_text(p2_melee_option.selected)
		target = p2_preview

	var gun_text := _weapon_preview_text(gun_name)
	var melee_text := _weapon_preview_text(melee_name)
	target.text = "[b]Gun Pick[/b]\n%s\n\n[b]Melee Pick[/b]\n%s" % [gun_text, melee_text]


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
		return "%s  |  DMG %.0f  RATE %.1f  VEL %.0f  AMMO %d/%d  MODE %s" % [
			w.weapon_name, w.damage, w.fire_rate, w.velocity, w.capacity, w.reserve_ammo, mode
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
