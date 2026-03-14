extends Control

const ARENA_SCENE := "res://scenes/arena/arena.tscn"

const CHARACTER_NAMES := [
	"Tsutaya (Dash)",
	"Aichok (Lifesteal)"
]

const COLOR_PRESETS := [
	{"name": "Azure", "color": Color(0.2, 0.6, 1.0)},
	{"name": "Crimson", "color": Color(1.0, 0.3, 0.2)},
	{"name": "Lime", "color": Color(0.3, 1.0, 0.45)},
	{"name": "Sunset", "color": Color(1.0, 0.65, 0.22)},
	{"name": "Violet", "color": Color(0.7, 0.45, 1.0)},
	{"name": "Slate", "color": Color(0.6, 0.75, 0.85)}
]

const KEYBIND_ROWS := [
	{"header": "Player 1"},
	{"label": "Move Left", "action": "p1_left"},
	{"label": "Move Right", "action": "p1_right"},
	{"label": "Jump", "action": "p1_jump"},
	{"label": "Crouch", "action": "p1_crouch"},
	{"label": "Attack", "action": "p1_attack"},
	{"label": "Secondary", "action": "p1_secondary"},
	{"label": "Sprint", "action": "p1_sprint"},
	{"label": "Skill", "action": "p1_skill"},
	{"label": "Item", "action": "p1_item"},
	{"label": "Reload", "action": "p1_reload"},
	{"header": "Player 2"},
	{"label": "Move Left", "action": "p2_left"},
	{"label": "Move Right", "action": "p2_right"},
	{"label": "Jump", "action": "p2_jump"},
	{"label": "Crouch", "action": "p2_crouch"},
	{"label": "Attack", "action": "p2_attack"},
	{"label": "Secondary", "action": "p2_secondary"},
	{"label": "Sprint", "action": "p2_sprint"},
	{"label": "Skill", "action": "p2_skill"},
	{"label": "Item", "action": "p2_item"},
	{"label": "Reload", "action": "p2_reload"}
]

@onready var title_panel: Control = $TitlePanel
@onready var main_panel: Control = $MainPanel
@onready var settings_panel: Control = $SettingsPanel
@onready var select_panel: Control = $PlayerSelectPanel

@onready var volume_slider: HSlider = $SettingsPanel/Margin/VBox/VolumeSlider
@onready var window_mode_option: OptionButton = $SettingsPanel/Margin/VBox/WindowModeOption
@onready var keybind_list: VBoxContainer = $SettingsPanel/Margin/VBox/KeybindScroll/KeybindList

@onready var rounds_spinbox: SpinBox = $PlayerSelectPanel/Margin/VBox/RoundsRow/RoundsSpinBox
@onready var p1_character_option: OptionButton = $PlayerSelectPanel/Margin/VBox/P1Row/P1CharacterOption
@onready var p1_color_option: OptionButton = $PlayerSelectPanel/Margin/VBox/P1Row/P1ColorOption
@onready var p2_character_option: OptionButton = $PlayerSelectPanel/Margin/VBox/P2Row/P2CharacterOption
@onready var p2_color_option: OptionButton = $PlayerSelectPanel/Margin/VBox/P2Row/P2ColorOption
@onready var p2_ai_checkbox: CheckBox = $PlayerSelectPanel/Margin/VBox/AIRow/P2AICheckbox

var _binding_buttons: Dictionary = {}
var _pending_bind_action := ""


func _ready() -> void:
	_build_keybind_ui()
	_populate_selectors()
	_sync_from_state()
	_show_panel(title_panel)


func _unhandled_input(event: InputEvent) -> void:
	if _pending_bind_action != "" and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			_pending_bind_action = ""
			_refresh_keybind_labels()
			get_viewport().set_input_as_handled()
			return
		GameState.set_binding_key(_pending_bind_action, event.physical_keycode)
		GameState.apply_key_bindings()
		_pending_bind_action = ""
		_refresh_keybind_labels()
		get_viewport().set_input_as_handled()
		return
	if title_panel.visible and event is InputEventKey and event.pressed:
		_show_panel(main_panel)


func _populate_selectors() -> void:
	for i in CHARACTER_NAMES.size():
		p1_character_option.add_item(CHARACTER_NAMES[i], i)
		p2_character_option.add_item(CHARACTER_NAMES[i], i)

	for i in COLOR_PRESETS.size():
		p1_color_option.add_item(COLOR_PRESETS[i]["name"], i)
		p2_color_option.add_item(COLOR_PRESETS[i]["name"], i)

	window_mode_option.add_item("Windowed", GameState.WINDOW_WINDOWED)
	window_mode_option.add_item("Fullscreen", GameState.WINDOW_FULLSCREEN)


func _sync_from_state() -> void:
	rounds_spinbox.value = GameState.rounds_to_win
	volume_slider.value = GameState.master_volume
	window_mode_option.select(GameState.window_mode)

	p1_character_option.select(GameState.p1_character)
	p2_character_option.select(GameState.p2_character)
	p1_color_option.select(_find_color_index(GameState.p1_color))
	p2_color_option.select(_find_color_index(GameState.p2_color))
	p2_ai_checkbox.button_pressed = GameState.p2_is_ai
	_refresh_keybind_labels()


func _build_keybind_ui() -> void:
	for child in keybind_list.get_children():
		child.queue_free()
	_binding_buttons.clear()

	for row in KEYBIND_ROWS:
		if row.has("header"):
			var header := Label.new()
			header.text = row["header"]
			#header.theme_override_font_sizes.font_size = 20
			keybind_list.add_child(header)
			continue

		var line := HBoxContainer.new()
		#line.theme_override_constants.separation = 10

		var title := Label.new()
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.text = row["label"]
		line.add_child(title)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(190, 34)
		btn.text = "-"
		btn.pressed.connect(_on_rebind_button_pressed.bind(String(row["action"])))
		line.add_child(btn)

		_binding_buttons[String(row["action"])] = btn
		keybind_list.add_child(line)


func _refresh_keybind_labels() -> void:
	for action in _binding_buttons.keys():
		var btn: Button = _binding_buttons[action]
		if action == _pending_bind_action:
			btn.text = "Press key..."
		else:
			btn.text = OS.get_keycode_string(GameState.get_binding_key(action))


func _on_rebind_button_pressed(action: String) -> void:
	_pending_bind_action = action
	_refresh_keybind_labels()


func _find_color_index(target: Color) -> int:
	for i in COLOR_PRESETS.size():
		var c: Color = COLOR_PRESETS[i]["color"]
		if c.is_equal_approx(target):
			return i
	return 0


func _show_panel(panel: Control) -> void:
	title_panel.visible = false
	main_panel.visible = false
	settings_panel.visible = false
	select_panel.visible = false
	panel.visible = true


func _on_start_button_pressed() -> void:
	_show_panel(main_panel)


func _on_play_button_pressed() -> void:
	GameState.game_mode = GameState.MODE_VERSUS
	_show_panel(select_panel)


func _on_training_button_pressed() -> void:
	GameState.game_mode = GameState.MODE_TRAINING
	get_tree().change_scene_to_file(ARENA_SCENE)


func _on_settings_button_pressed() -> void:
	_show_panel(settings_panel)


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_back_from_settings_button_pressed() -> void:
	_show_panel(main_panel)


func _on_save_settings_button_pressed() -> void:
	GameState.master_volume = volume_slider.value
	GameState.window_mode = window_mode_option.get_selected_id()
	GameState.apply_runtime_settings()
	GameState.save_settings()


func _on_reset_bindings_button_pressed() -> void:
	_pending_bind_action = ""
	GameState.reset_bindings_to_default()
	_refresh_keybind_labels()


func _on_back_from_select_button_pressed() -> void:
	_show_panel(main_panel)


func _on_start_match_button_pressed() -> void:
	GameState.game_mode = GameState.MODE_VERSUS
	GameState.rounds_to_win = int(rounds_spinbox.value)
	GameState.p1_character = p1_character_option.get_selected_id()
	GameState.p2_character = p2_character_option.get_selected_id()
	GameState.p2_is_ai = p2_ai_checkbox.button_pressed
	GameState.p1_color = COLOR_PRESETS[p1_color_option.get_selected_id()]["color"]
	GameState.p2_color = COLOR_PRESETS[p2_color_option.get_selected_id()]["color"]
	GameState.save_settings()
	get_tree().change_scene_to_file(ARENA_SCENE)
