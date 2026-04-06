extends Control

const ARENA_SCENE := "res://scenes/arena/arena.tscn"

const CHARACTER_NAMES := [
	"Instant Dash",
	"Life Steal",
	"Shrink",
	"Invisible"
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

const CLASSIC_DEFAULT_SPAWN_MIN := 1.2
const CLASSIC_DEFAULT_SPAWN_MAX := 2.4
const CLASSIC_DEFAULT_TACTICAL_CHANCE := 0.3
const CLASSIC_DEFAULT_MAX_PICKUPS := 10

@onready var title_panel: Control = $TitlePanel
@onready var main_panel: Control = $MainPanel
@onready var settings_panel: Control = $SettingsPanel
@onready var select_panel: Control = $PlayerSelectPanel
@onready var help_panel: Control = $HelpPanel
@onready var main_panel_vbox: VBoxContainer = $MainPanel
@onready var select_panel_vbox: VBoxContainer = $PlayerSelectPanel/Margin/VBox

@onready var volume_slider: HSlider = $SettingsPanel/Margin/VBox/VolumeSlider
@onready var window_mode_option: OptionButton = $SettingsPanel/Margin/VBox/WindowModeOption
@onready var aim_assist_checkbox: CheckBox = $SettingsPanel/Margin/VBox/AimAssistCheckbox
@onready var keybind_list: VBoxContainer = $SettingsPanel/Margin/VBox/KeybindScroll/KeybindList

@onready var rounds_spinbox: SpinBox = $PlayerSelectPanel/Margin/VBox/RoundsRow/RoundsSpinBox
@onready var game_mode_option: OptionButton = $PlayerSelectPanel/Margin/VBox/GameModeRow/GameModeOption
@onready var p1_name_input: LineEdit = $PlayerSelectPanel/Margin/VBox/P1Row/P1NameInput
@onready var p1_character_option: OptionButton = $PlayerSelectPanel/Margin/VBox/P1Row/P1CharacterOption
@onready var p1_color_option: OptionButton = $PlayerSelectPanel/Margin/VBox/P1Row/P1ColorOption
@onready var p2_name_input: LineEdit = $PlayerSelectPanel/Margin/VBox/P2Row/P2NameInput
@onready var p2_character_option: OptionButton = $PlayerSelectPanel/Margin/VBox/P2Row/P2CharacterOption
@onready var p2_color_option: OptionButton = $PlayerSelectPanel/Margin/VBox/P2Row/P2ColorOption
@onready var p2_ai_checkbox: CheckBox = $PlayerSelectPanel/Margin/VBox/AIRow/P2AICheckbox

var _binding_buttons: Dictionary = {}
var _pending_bind_action := ""
var _network_panel: PanelContainer
var _network_status_label: Label
var _network_host_ready_label: Label
var _network_client_ready_label: Label
var _network_address_input: LineEdit
var _network_port_spinbox: SpinBox
var _network_ready_button: Button
var _network_start_button: Button
var _network_create_button: Button
var _network_join_button: Button
var _network_local_ready := false
var _classic_pool_button: Button
var _classic_pool_overlay: ColorRect
var _classic_pool_panel: PanelContainer
var _classic_pool_status_label: Label
var _classic_weapon_checks: Dictionary = {}
var _classic_tactical_checks: Dictionary = {}
var _classic_spawn_min_spin: SpinBox
var _classic_spawn_max_spin: SpinBox
var _classic_tactical_chance_spin: SpinBox
var _classic_max_pickups_spin: SpinBox


func _ready() -> void:
	_ensure_network_panel_ui()
	_ensure_classic_pool_settings_ui()
	if not NetworkManager.lobby_state_changed.is_connected(_on_network_lobby_state_changed):
		NetworkManager.lobby_state_changed.connect(_on_network_lobby_state_changed)
	if not NetworkManager.match_start_requested.is_connected(_on_network_match_start_requested):
		NetworkManager.match_start_requested.connect(_on_network_match_start_requested)
	if not NetworkManager.connection_succeeded.is_connected(_on_network_connection_succeeded):
		NetworkManager.connection_succeeded.connect(_on_network_connection_succeeded)
	if not NetworkManager.connection_failed.is_connected(_on_network_connection_failed):
		NetworkManager.connection_failed.connect(_on_network_connection_failed)
	if not NetworkManager.server_disconnected.is_connected(_on_network_server_disconnected):
		NetworkManager.server_disconnected.connect(_on_network_server_disconnected)
	if not game_mode_option.item_selected.is_connected(_on_game_mode_option_item_selected):
		game_mode_option.item_selected.connect(_on_game_mode_option_item_selected)
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

	game_mode_option.add_item("Classic Duel", GameState.MODE_CLASSIC_DUEL)
	game_mode_option.add_item("Arms Dealer", GameState.MODE_ARMS_DEALER)
	game_mode_option.add_item("Draft Duel", GameState.MODE_DRAFT_DUEL)

	window_mode_option.add_item("Windowed", GameState.WINDOW_WINDOWED)
	window_mode_option.add_item("Fullscreen", GameState.WINDOW_FULLSCREEN)


func _sync_from_state() -> void:
	rounds_spinbox.value = GameState.rounds_to_win
	volume_slider.value = GameState.master_volume
	window_mode_option.select(GameState.window_mode)
	aim_assist_checkbox.button_pressed = GameState.aim_assist_enabled
	var mode_id := GameState.game_mode
	if mode_id != GameState.MODE_ARMS_DEALER and mode_id != GameState.MODE_DRAFT_DUEL:
		mode_id = GameState.MODE_CLASSIC_DUEL
	var mode_index := game_mode_option.get_item_index(mode_id)
	game_mode_option.select(mode_index if mode_index >= 0 else 0)
	_update_classic_pool_settings_visibility()
	_refresh_classic_pool_status()

	p1_character_option.select(GameState.p1_character)
	p2_character_option.select(GameState.p2_character)
	p1_name_input.text = GameState.p1_name
	p2_name_input.text = GameState.p2_name
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
	help_panel.visible = false
	if _network_panel:
		_network_panel.visible = false
	if _classic_pool_overlay:
		_classic_pool_overlay.visible = false
	if _classic_pool_panel:
		_classic_pool_panel.visible = false
	panel.visible = true


func _ui_click(back := false) -> void:
	AudioManager.play_sfx_varied("ui_back" if back else "ui_click", -6.0, 0.98, 1.03)


func _on_start_button_pressed() -> void:
	_ui_click()
	_show_panel(main_panel)


func _on_play_button_pressed() -> void:
	_ui_click()
	_update_classic_pool_settings_visibility()
	_refresh_classic_pool_status()
	_show_panel(select_panel)


func _on_network_button_pressed() -> void:
	_ui_click()
	_network_local_ready = false
	if _network_panel:
		_network_panel.visible = true
	_show_panel(_network_panel)
	_update_network_panel_labels("Create or join a room.")


func _on_training_button_pressed() -> void:
	_ui_click()
	NetworkManager.stop()
	GameState.game_mode = GameState.MODE_TRAINING
	get_tree().change_scene_to_file(ARENA_SCENE)


func _on_settings_button_pressed() -> void:
	_ui_click()
	_show_panel(settings_panel)


func _on_help_button_pressed() -> void:
	_ui_click()
	_show_panel(help_panel)


func _on_quit_button_pressed() -> void:
	_ui_click(true)
	get_tree().quit()


func _on_back_from_settings_button_pressed() -> void:
	_ui_click(true)
	_show_panel(main_panel)


func _on_save_settings_button_pressed() -> void:
	_ui_click()
	GameState.master_volume = volume_slider.value
	GameState.window_mode = window_mode_option.get_selected_id()
	GameState.aim_assist_enabled = aim_assist_checkbox.button_pressed
	GameState.apply_runtime_settings()
	GameState.save_settings()


func _on_reset_bindings_button_pressed() -> void:
	_ui_click()
	_pending_bind_action = ""
	GameState.reset_bindings_to_default()
	_refresh_keybind_labels()


func _on_back_from_select_button_pressed() -> void:
	_ui_click(true)
	if _classic_pool_overlay:
		_classic_pool_overlay.visible = false
	if _classic_pool_panel:
		_classic_pool_panel.visible = false
	_show_panel(main_panel)


func _on_back_from_help_button_pressed() -> void:
	_ui_click(true)
	_show_panel(main_panel)


func _on_network_back_pressed() -> void:
	_ui_click(true)
	NetworkManager.stop()
	_network_local_ready = false
	_show_panel(main_panel)


func _on_network_create_room_pressed() -> void:
	_ui_click()
	GameState.online_server_port = int(_network_port_spinbox.value)
	if not NetworkManager.start_host(GameState.online_server_port):
		_update_network_panel_labels("Failed to create room.")
		return
	_network_local_ready = false
	_update_network_panel_labels("Room created. Waiting for player 2...")


func _on_network_join_room_pressed() -> void:
	_ui_click()
	GameState.online_server_address = _network_address_input.text.strip_edges()
	GameState.online_server_port = int(_network_port_spinbox.value)
	if not NetworkManager.start_client(GameState.online_server_address, GameState.online_server_port):
		_update_network_panel_labels("Failed to join room.")
		return
	_network_local_ready = false
	_update_network_panel_labels("Connecting...")


func _on_network_ready_pressed() -> void:
	if not NetworkManager.is_online():
		_update_network_panel_labels("Join or create a room first.")
		return
	_ui_click()
	_network_local_ready = not _network_local_ready
	NetworkManager.set_local_ready(_network_local_ready)
	_update_network_panel_labels("Ready" if _network_local_ready else "Not ready")


func _on_network_start_pressed() -> void:
	if not NetworkManager.is_host():
		_update_network_panel_labels("Only host can start the match.")
		return
	if not NetworkManager.host_can_start_match():
		_update_network_panel_labels("Both players must be ready.")
		return
	_ui_click()
	NetworkManager.start_match_by_host()


func _on_network_lobby_state_changed(host_ready: bool, client_ready: bool, is_host: bool) -> void:
	if _network_host_ready_label:
		_network_host_ready_label.text = "Host: %s" % ("READY" if host_ready else "NOT READY")
	if _network_client_ready_label:
		_network_client_ready_label.text = "Client: %s" % ("READY" if client_ready else "NOT READY")
	if _network_start_button:
		_network_start_button.disabled = not is_host or not (host_ready and client_ready)


func _on_network_connection_succeeded() -> void:
	_update_network_panel_labels("Connected to host. Set Ready.")


func _on_network_connection_failed() -> void:
	_update_network_panel_labels("Connection failed.")


func _on_network_server_disconnected() -> void:
	_network_local_ready = false
	_update_network_panel_labels("Disconnected from room.")


func _on_network_match_start_requested() -> void:
	GameState.game_mode = GameState.MODE_ONLINE_HOST if NetworkManager.is_host() else GameState.MODE_ONLINE_CLIENT
	GameState.save_settings()
	get_tree().change_scene_to_file(ARENA_SCENE)


func _update_network_panel_labels(status: String) -> void:
	if _network_status_label:
		_network_status_label.text = status
	if _network_ready_button:
		_network_ready_button.text = "Unready" if _network_local_ready else "Ready"


func _on_start_match_button_pressed() -> void:
	_ui_click()
	if _classic_pool_overlay:
		_classic_pool_overlay.visible = false
	if _classic_pool_panel and _classic_pool_panel.visible:
		_classic_pool_panel.visible = false
	GameState.game_mode = game_mode_option.get_selected_id()
	GameState.rounds_to_win = int(rounds_spinbox.value)
	GameState.p1_character = p1_character_option.get_selected_id()
	GameState.p2_character = p2_character_option.get_selected_id()
	GameState.p1_name = _sanitize_player_name(p1_name_input.text, "Player 1")
	GameState.p2_name = _sanitize_player_name(p2_name_input.text, "Player 2")
	GameState.p2_is_ai = p2_ai_checkbox.button_pressed
	GameState.p1_color = COLOR_PRESETS[p1_color_option.get_selected_id()]["color"]
	GameState.p2_color = COLOR_PRESETS[p2_color_option.get_selected_id()]["color"]
	if GameState.game_mode == GameState.MODE_ONLINE_HOST:
		if not NetworkManager.start_host(GameState.online_server_port):
			push_warning("Failed to host online session on port %d" % GameState.online_server_port)
	elif GameState.game_mode == GameState.MODE_ONLINE_CLIENT:
		if not NetworkManager.start_client(GameState.online_server_address, GameState.online_server_port):
			push_warning("Failed to connect to %s:%d" % [GameState.online_server_address, GameState.online_server_port])
	else:
		NetworkManager.stop()
	GameState.save_settings()
	get_tree().change_scene_to_file(ARENA_SCENE)


func _sanitize_player_name(raw: String, fallback: String) -> String:
	var cleaned := raw.strip_edges()
	if cleaned == "":
		return fallback
	if cleaned.length() > 16:
		cleaned = cleaned.substr(0, 16)
	return cleaned


func _ensure_network_panel_ui() -> void:
	if _network_panel != null:
		return

	# Add dedicated Network Multiplayer button in main menu.
	var network_btn := Button.new()
	network_btn.name = "NetworkButton"
	network_btn.custom_minimum_size = Vector2(240, 48)
	network_btn.add_theme_font_size_override("font_size", 22)
	network_btn.text = "Network Multiplayer"
	network_btn.pressed.connect(_on_network_button_pressed)
	main_panel_vbox.add_child(network_btn)

	# Keep Back/Quit flow intuitive by moving Quit to the bottom.
	if has_node("MainPanel/QuitButton"):
		$MainPanel/QuitButton.reparent(main_panel_vbox)

	_network_panel = PanelContainer.new()
	_network_panel.name = "NetworkPanel"
	_network_panel.visible = false
	_network_panel.set_anchors_preset(Control.PRESET_CENTER)
	_network_panel.anchor_left = 0.2
	_network_panel.anchor_top = 0.16
	_network_panel.anchor_right = 0.8
	_network_panel.anchor_bottom = 0.86
	add_child(_network_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	_network_panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var title := Label.new()
	title.text = "Network Multiplayer"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	root.add_child(title)

	var addr_row := HBoxContainer.new()
	addr_row.add_theme_constant_override("separation", 10)
	root.add_child(addr_row)

	var addr_label := Label.new()
	addr_label.text = "Address"
	addr_label.custom_minimum_size = Vector2(120, 0)
	addr_row.add_child(addr_label)

	_network_address_input = LineEdit.new()
	_network_address_input.placeholder_text = "127.0.0.1"
	_network_address_input.text = GameState.online_server_address
	_network_address_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	addr_row.add_child(_network_address_input)

	var port_row := HBoxContainer.new()
	port_row.add_theme_constant_override("separation", 10)
	root.add_child(port_row)

	var port_label := Label.new()
	port_label.text = "Port"
	port_label.custom_minimum_size = Vector2(120, 0)
	port_row.add_child(port_label)

	_network_port_spinbox = SpinBox.new()
	_network_port_spinbox.min_value = 1024
	_network_port_spinbox.max_value = 65535
	_network_port_spinbox.step = 1
	_network_port_spinbox.value = GameState.online_server_port
	_network_port_spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	port_row.add_child(_network_port_spinbox)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	root.add_child(action_row)

	_network_create_button = Button.new()
	_network_create_button.text = "Create Room"
	_network_create_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_network_create_button.pressed.connect(_on_network_create_room_pressed)
	action_row.add_child(_network_create_button)

	_network_join_button = Button.new()
	_network_join_button.text = "Join Room"
	_network_join_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_network_join_button.pressed.connect(_on_network_join_room_pressed)
	action_row.add_child(_network_join_button)

	_network_status_label = Label.new()
	_network_status_label.text = "Create or join a room."
	_network_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_network_status_label)

	_network_host_ready_label = Label.new()
	_network_host_ready_label.text = "Host: NOT READY"
	_network_host_ready_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_network_host_ready_label)

	_network_client_ready_label = Label.new()
	_network_client_ready_label.text = "Client: NOT READY"
	_network_client_ready_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_network_client_ready_label)

	var control_row := HBoxContainer.new()
	control_row.add_theme_constant_override("separation", 10)
	root.add_child(control_row)

	_network_ready_button = Button.new()
	_network_ready_button.text = "Ready"
	_network_ready_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_network_ready_button.pressed.connect(_on_network_ready_pressed)
	control_row.add_child(_network_ready_button)

	_network_start_button = Button.new()
	_network_start_button.text = "Start Match (Host)"
	_network_start_button.disabled = true
	_network_start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_network_start_button.pressed.connect(_on_network_start_pressed)
	control_row.add_child(_network_start_button)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(180, 42)
	back_btn.pressed.connect(_on_network_back_pressed)
	root.add_child(back_btn)


func _ensure_classic_pool_settings_ui() -> void:
	if _classic_pool_button != null:
		return

	var row := VBoxContainer.new()
	row.name = "ClassicPoolRow"
	row.add_theme_constant_override("separation", 6)

	_classic_pool_button = Button.new()
	_classic_pool_button.text = "Classic Duel Pool Settings"
	_classic_pool_button.custom_minimum_size = Vector2(260, 38)
	_classic_pool_button.pressed.connect(_on_classic_pool_button_pressed)
	row.add_child(_classic_pool_button)

	_classic_pool_status_label = Label.new()
	_classic_pool_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_classic_pool_status_label.text = "Allowed: All weapons, all items"
	row.add_child(_classic_pool_status_label)

	var button_row := select_panel_vbox.get_node_or_null("ButtonRow")
	if button_row:
		select_panel_vbox.add_child(row)
		select_panel_vbox.move_child(row, button_row.get_index())
	else:
		select_panel_vbox.add_child(row)

	_classic_pool_overlay = ColorRect.new()
	_classic_pool_overlay.name = "ClassicPoolOverlay"
	_classic_pool_overlay.visible = false
	_classic_pool_overlay.color = Color(0.02, 0.03, 0.06, 0.82)
	_classic_pool_overlay.anchor_left = 0.0
	_classic_pool_overlay.anchor_top = 0.0
	_classic_pool_overlay.anchor_right = 1.0
	_classic_pool_overlay.anchor_bottom = 1.0
	_classic_pool_overlay.offset_left = 0.0
	_classic_pool_overlay.offset_top = 0.0
	_classic_pool_overlay.offset_right = 0.0
	_classic_pool_overlay.offset_bottom = 0.0
	_classic_pool_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	select_panel.add_child(_classic_pool_overlay)

	_classic_pool_panel = PanelContainer.new()
	_classic_pool_panel.name = "ClassicPoolPanel"
	_classic_pool_panel.visible = false
	_classic_pool_panel.anchor_left = 0.05
	_classic_pool_panel.anchor_top = 0.05
	_classic_pool_panel.anchor_right = 0.95
	_classic_pool_panel.anchor_bottom = 0.95
	_classic_pool_panel.offset_left = 0.0
	_classic_pool_panel.offset_top = 0.0
	_classic_pool_panel.offset_right = 0.0
	_classic_pool_panel.offset_bottom = 0.0
	_classic_pool_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.08, 0.12, 0.98)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.32, 0.44, 0.68, 0.95)
	_classic_pool_panel.add_theme_stylebox_override("panel", panel_style)

	_classic_pool_overlay.add_child(_classic_pool_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	_classic_pool_panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var title := Label.new()
	title.text = "Classic Duel Pool Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	root.add_child(title)

	var hint := Label.new()
	hint.text = "Choose which weapons and items can spawn in Classic Duel (sorted by category)."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint)

	var settings_panel := PanelContainer.new()
	root.add_child(settings_panel)

	var settings_margin := MarginContainer.new()
	settings_margin.add_theme_constant_override("margin_left", 10)
	settings_margin.add_theme_constant_override("margin_top", 8)
	settings_margin.add_theme_constant_override("margin_right", 10)
	settings_margin.add_theme_constant_override("margin_bottom", 8)
	settings_panel.add_child(settings_margin)

	var settings_grid := GridContainer.new()
	settings_grid.columns = 4
	settings_grid.add_theme_constant_override("h_separation", 8)
	settings_grid.add_theme_constant_override("v_separation", 6)
	settings_margin.add_child(settings_grid)

	var min_label := Label.new()
	min_label.text = "Spawn Min (s)"
	settings_grid.add_child(min_label)

	_classic_spawn_min_spin = SpinBox.new()
	_classic_spawn_min_spin.min_value = 0.2
	_classic_spawn_min_spin.max_value = 30.0
	_classic_spawn_min_spin.step = 0.1
	_classic_spawn_min_spin.value = CLASSIC_DEFAULT_SPAWN_MIN
	_classic_spawn_min_spin.custom_minimum_size = Vector2(120, 0)
	settings_grid.add_child(_classic_spawn_min_spin)

	var max_label := Label.new()
	max_label.text = "Spawn Max (s)"
	settings_grid.add_child(max_label)

	_classic_spawn_max_spin = SpinBox.new()
	_classic_spawn_max_spin.min_value = 0.2
	_classic_spawn_max_spin.max_value = 30.0
	_classic_spawn_max_spin.step = 0.1
	_classic_spawn_max_spin.value = CLASSIC_DEFAULT_SPAWN_MAX
	_classic_spawn_max_spin.custom_minimum_size = Vector2(120, 0)
	settings_grid.add_child(_classic_spawn_max_spin)

	var chance_label := Label.new()
	chance_label.text = "Item Chance (%)"
	settings_grid.add_child(chance_label)

	_classic_tactical_chance_spin = SpinBox.new()
	_classic_tactical_chance_spin.min_value = 0.0
	_classic_tactical_chance_spin.max_value = 100.0
	_classic_tactical_chance_spin.step = 1.0
	_classic_tactical_chance_spin.value = CLASSIC_DEFAULT_TACTICAL_CHANCE * 100.0
	_classic_tactical_chance_spin.custom_minimum_size = Vector2(120, 0)
	settings_grid.add_child(_classic_tactical_chance_spin)

	var cap_label := Label.new()
	cap_label.text = "Map Pickup Cap"
	settings_grid.add_child(cap_label)

	_classic_max_pickups_spin = SpinBox.new()
	_classic_max_pickups_spin.min_value = 1.0
	_classic_max_pickups_spin.max_value = 64.0
	_classic_max_pickups_spin.step = 1.0
	_classic_max_pickups_spin.value = CLASSIC_DEFAULT_MAX_PICKUPS
	_classic_max_pickups_spin.custom_minimum_size = Vector2(120, 0)
	settings_grid.add_child(_classic_max_pickups_spin)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(split)

	var weapons_col := VBoxContainer.new()
	weapons_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapons_col.add_theme_constant_override("separation", 8)
	split.add_child(weapons_col)

	var weapons_title := Label.new()
	weapons_title.text = "Weapons"
	weapons_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weapons_title.add_theme_font_size_override("font_size", 20)
	weapons_col.add_child(weapons_title)

	var weapons_scroll := ScrollContainer.new()
	weapons_scroll.custom_minimum_size = Vector2(0, 360)
	weapons_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	weapons_col.add_child(weapons_scroll)

	var weapons_list := VBoxContainer.new()
	weapons_list.add_theme_constant_override("separation", 6)
	weapons_scroll.add_child(weapons_list)

	var tactics_col := VBoxContainer.new()
	tactics_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tactics_col.add_theme_constant_override("separation", 8)
	split.add_child(tactics_col)

	var tactics_title := Label.new()
	tactics_title.text = "Items"
	tactics_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tactics_title.add_theme_font_size_override("font_size", 20)
	tactics_col.add_child(tactics_title)

	var tactics_scroll := ScrollContainer.new()
	tactics_scroll.custom_minimum_size = Vector2(0, 360)
	tactics_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tactics_col.add_child(tactics_scroll)

	var tactics_list := VBoxContainer.new()
	tactics_list.add_theme_constant_override("separation", 6)
	tactics_scroll.add_child(tactics_list)

	_classic_weapon_checks.clear()
	_classic_tactical_checks.clear()

	var unique_weapon_map := {}
	var weapon_pool: Array[WeaponData] = []
	for w in WeaponDB.get_pool():
		if unique_weapon_map.has(w.weapon_name):
			continue
		unique_weapon_map[w.weapon_name] = true
		weapon_pool.append(w)

	weapon_pool.sort_custom(func(a: WeaponData, b: WeaponData) -> bool:
		var group_a := _get_weapon_group_order(a)
		var group_b := _get_weapon_group_order(b)
		if group_a != group_b:
			return group_a < group_b
		if a.rarity != b.rarity:
			return a.rarity < b.rarity
		return a.weapon_name < b.weapon_name
	)

	var last_weapon_group := ""
	for w in weapon_pool:
		var group_name := _get_weapon_group_label(w)
		if group_name != last_weapon_group:
			last_weapon_group = group_name
			var group_label := Label.new()
			group_label.text = group_name
			group_label.add_theme_font_size_override("font_size", 16)
			group_label.modulate = Color(0.84, 0.92, 1.0)
			weapons_list.add_child(group_label)
			var sep := HSeparator.new()
			weapons_list.add_child(sep)

		var cb := CheckBox.new()
		cb.text = "%s  [%s]" % [w.weapon_name, _get_rarity_label(w.rarity)]
		cb.button_pressed = true
		cb.modulate = w.get_rarity_color().lerp(Color.WHITE, 0.45)
		weapons_list.add_child(cb)
		_classic_weapon_checks[w.weapon_name] = cb

	var tactical_pool: Array[TacticalData] = TacticalData.get_all_tacticals()
	tactical_pool.sort_custom(func(a: TacticalData, b: TacticalData) -> bool:
		var group_a := _get_tactical_group_order(a)
		var group_b := _get_tactical_group_order(b)
		if group_a != group_b:
			return group_a < group_b
		return a.item_name < b.item_name
	)

	var last_tactical_group := ""
	for t in tactical_pool:
		if _classic_tactical_checks.has(t.item_name):
			continue
		var group_name := _get_tactical_group_label(t)
		if group_name != last_tactical_group:
			last_tactical_group = group_name
			var group_label := Label.new()
			group_label.text = group_name
			group_label.add_theme_font_size_override("font_size", 16)
			group_label.modulate = Color(0.84, 0.92, 1.0)
			tactics_list.add_child(group_label)
			var sep := HSeparator.new()
			tactics_list.add_child(sep)

		var cb := CheckBox.new()
		cb.text = t.item_name
		cb.button_pressed = true
		cb.modulate = t.get_color().lerp(Color.WHITE, 0.45)
		tactics_list.add_child(cb)
		_classic_tactical_checks[t.item_name] = cb

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	root.add_child(action_row)

	var all_btn := Button.new()
	all_btn.text = "Select All"
	all_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	all_btn.pressed.connect(func() -> void:
		_set_classic_pool_checks(true)
	)
	action_row.add_child(all_btn)

	var clear_btn := Button.new()
	clear_btn.text = "Clear All"
	clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear_btn.pressed.connect(func() -> void:
		_set_classic_pool_checks(false)
	)
	action_row.add_child(clear_btn)

	var defaults_btn := Button.new()
	defaults_btn.text = "Reset Defaults"
	defaults_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defaults_btn.pressed.connect(_on_classic_pool_reset_defaults_pressed)
	action_row.add_child(defaults_btn)

	var apply_btn := Button.new()
	apply_btn.text = "Apply"
	apply_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	apply_btn.pressed.connect(_on_classic_pool_apply_pressed)
	action_row.add_child(apply_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.pressed.connect(_on_classic_pool_cancel_pressed)
	action_row.add_child(cancel_btn)

	_load_classic_spawn_settings_from_state()
	_load_classic_pool_checks_from_state()
	_refresh_classic_pool_status()


func _on_game_mode_option_item_selected(_index: int) -> void:
	_update_classic_pool_settings_visibility()


func _update_classic_pool_settings_visibility() -> void:
	var is_classic := game_mode_option.get_selected_id() == GameState.MODE_CLASSIC_DUEL
	if _classic_pool_button:
		_classic_pool_button.visible = is_classic
	if _classic_pool_status_label:
		_classic_pool_status_label.visible = is_classic
	if _classic_pool_overlay and not is_classic:
		_classic_pool_overlay.visible = false
	if _classic_pool_panel and not is_classic:
		_classic_pool_panel.visible = false


func _on_classic_pool_button_pressed() -> void:
	_ui_click()
	_load_classic_spawn_settings_from_state()
	_load_classic_pool_checks_from_state()
	if _classic_pool_overlay:
		_classic_pool_overlay.visible = true
	if _classic_pool_panel:
		_classic_pool_panel.visible = true


func _on_classic_pool_apply_pressed() -> void:
	if _apply_classic_pool_filters():
		_ui_click()
		if _classic_pool_overlay:
			_classic_pool_overlay.visible = false
		if _classic_pool_panel:
			_classic_pool_panel.visible = false


func _on_classic_pool_cancel_pressed() -> void:
	_ui_click(true)
	_load_classic_spawn_settings_from_state()
	_load_classic_pool_checks_from_state()
	if _classic_pool_overlay:
		_classic_pool_overlay.visible = false
	if _classic_pool_panel:
		_classic_pool_panel.visible = false


func _on_classic_pool_reset_defaults_pressed() -> void:
	_ui_click()
	_set_classic_pool_checks(true)
	_set_classic_spawn_defaults()
	if _classic_pool_status_label:
		_classic_pool_status_label.text = "Defaults loaded. Press Apply."


func _apply_classic_pool_filters() -> bool:
	var selected_weapons := PackedStringArray()
	for name in _classic_weapon_checks.keys():
		var cb: CheckBox = _classic_weapon_checks[name]
		if cb.button_pressed:
			selected_weapons.append(name)

	var selected_tacticals := PackedStringArray()
	for name in _classic_tactical_checks.keys():
		var cb: CheckBox = _classic_tactical_checks[name]
		if cb.button_pressed:
			selected_tacticals.append(name)

	selected_weapons.sort()
	selected_tacticals.sort()

	var use_weapon_filter := selected_weapons.size() < _classic_weapon_checks.size()
	var use_tactical_filter := selected_tacticals.size() < _classic_tactical_checks.size()

	GameState.set_classic_pool_filters(selected_weapons, selected_tacticals, use_weapon_filter, use_tactical_filter)
	GameState.set_classic_spawn_settings(
		float(_classic_spawn_min_spin.value),
		float(_classic_spawn_max_spin.value),
		float(_classic_tactical_chance_spin.value) / 100.0,
		int(_classic_max_pickups_spin.value)
	)
	GameState.save_settings()
	_refresh_classic_pool_status()
	return true


func _set_classic_pool_checks(pressed: bool) -> void:
	for cb in _classic_weapon_checks.values():
		(cb as CheckBox).button_pressed = pressed
	for cb in _classic_tactical_checks.values():
		(cb as CheckBox).button_pressed = pressed


func _load_classic_pool_checks_from_state() -> void:
	var all_weapons := not GameState.classic_use_weapon_filter
	for name in _classic_weapon_checks.keys():
		var cb: CheckBox = _classic_weapon_checks[name]
		cb.button_pressed = all_weapons or GameState.classic_enabled_weapons.has(name)

	var all_tacticals := not GameState.classic_use_tactical_filter
	for name in _classic_tactical_checks.keys():
		var cb: CheckBox = _classic_tactical_checks[name]
		cb.button_pressed = all_tacticals or GameState.classic_enabled_tacticals.has(name)


func _load_classic_spawn_settings_from_state() -> void:
	if _classic_spawn_min_spin:
		_classic_spawn_min_spin.value = GameState.classic_spawn_interval_min
	if _classic_spawn_max_spin:
		_classic_spawn_max_spin.value = GameState.classic_spawn_interval_max
	if _classic_tactical_chance_spin:
		_classic_tactical_chance_spin.value = GameState.classic_tactical_chance * 100.0
	if _classic_max_pickups_spin:
		_classic_max_pickups_spin.value = GameState.classic_max_pickups


func _set_classic_spawn_defaults() -> void:
	if _classic_spawn_min_spin:
		_classic_spawn_min_spin.value = CLASSIC_DEFAULT_SPAWN_MIN
	if _classic_spawn_max_spin:
		_classic_spawn_max_spin.value = CLASSIC_DEFAULT_SPAWN_MAX
	if _classic_tactical_chance_spin:
		_classic_tactical_chance_spin.value = CLASSIC_DEFAULT_TACTICAL_CHANCE * 100.0
	if _classic_max_pickups_spin:
		_classic_max_pickups_spin.value = CLASSIC_DEFAULT_MAX_PICKUPS


func _refresh_classic_pool_status() -> void:
	if _classic_pool_status_label == null:
		return
	var weapon_total := _classic_weapon_checks.size()
	var tactical_total := _classic_tactical_checks.size()
	if weapon_total <= 0 or tactical_total <= 0:
		_classic_pool_status_label.text = "Allowed: All weapons, all items"
		return

	var weapon_enabled := weapon_total if not GameState.classic_use_weapon_filter else GameState.classic_enabled_weapons.size()
	var tactical_enabled := tactical_total if not GameState.classic_use_tactical_filter else GameState.classic_enabled_tacticals.size()

	if weapon_enabled == weapon_total and tactical_enabled == tactical_total:
		_classic_pool_status_label.text = "Allowed: All weapons, all items"
	else:
		_classic_pool_status_label.text = "Allowed: %d/%d weapons, %d/%d items" % [weapon_enabled, weapon_total, tactical_enabled, tactical_total]


func _get_weapon_group_order(w: WeaponData) -> int:
	if w.type == WeaponData.Type.MELEE:
		return 0
	match w.gun_category:
		WeaponData.GunCategory.PISTOL:
			return 10
		WeaponData.GunCategory.SMG:
			return 20
		WeaponData.GunCategory.ASSAULT_RIFLE:
			return 30
		WeaponData.GunCategory.BATTLE_RIFLE:
			return 40
		WeaponData.GunCategory.DMR:
			return 50
		WeaponData.GunCategory.SNIPER:
			return 60
		WeaponData.GunCategory.SHOTGUN:
			return 70
		WeaponData.GunCategory.LMG:
			return 80
		WeaponData.GunCategory.LAUNCHER:
			return 90
		_:
			return 100


func _get_weapon_group_label(w: WeaponData) -> String:
	if w.type == WeaponData.Type.MELEE:
		return "Melee"
	match w.gun_category:
		WeaponData.GunCategory.PISTOL:
			return "Guns - Pistol"
		WeaponData.GunCategory.SMG:
			return "Guns - SMG"
		WeaponData.GunCategory.ASSAULT_RIFLE:
			return "Guns - Assault Rifle"
		WeaponData.GunCategory.BATTLE_RIFLE:
			return "Guns - Battle Rifle"
		WeaponData.GunCategory.DMR:
			return "Guns - DMR"
		WeaponData.GunCategory.SNIPER:
			return "Guns - Sniper"
		WeaponData.GunCategory.SHOTGUN:
			return "Guns - Shotgun"
		WeaponData.GunCategory.LMG:
			return "Guns - LMG"
		WeaponData.GunCategory.LAUNCHER:
			return "Guns - Launcher"
		_:
			return "Guns - Other"


func _get_rarity_label(rarity: WeaponData.Rarity) -> String:
	match rarity:
		WeaponData.Rarity.COMMON:
			return "Common"
		WeaponData.Rarity.UNCOMMON:
			return "Uncommon"
		WeaponData.Rarity.RARE:
			return "Rare"
		WeaponData.Rarity.EPIC:
			return "Epic"
		WeaponData.Rarity.LEGENDARY:
			return "Legendary"
		WeaponData.Rarity.MYTHIC:
			return "Mythic"
		WeaponData.Rarity.CONTRABAND:
			return "Contraband"
		_:
			return "Unknown"


func _get_tactical_group_order(t: TacticalData) -> int:
	match t.tactical_type:
		TacticalData.TacticalType.FRAG_GRENADE, TacticalData.TacticalType.MOLOTOV:
			return 10
		TacticalData.TacticalType.FLASH_FREEZE, TacticalData.TacticalType.CONFUSION:
			return 20
		TacticalData.TacticalType.MED_KIT, TacticalData.TacticalType.SHIELD:
			return 30
		TacticalData.TacticalType.JETPACK:
			return 40
		_:
			return 50


func _get_tactical_group_label(t: TacticalData) -> String:
	match t.tactical_type:
		TacticalData.TacticalType.FRAG_GRENADE, TacticalData.TacticalType.MOLOTOV:
			return "Offense"
		TacticalData.TacticalType.FLASH_FREEZE, TacticalData.TacticalType.CONFUSION:
			return "Control"
		TacticalData.TacticalType.MED_KIT, TacticalData.TacticalType.SHIELD:
			return "Defense"
		TacticalData.TacticalType.JETPACK:
			return "Mobility"
		_:
			return "Other"
