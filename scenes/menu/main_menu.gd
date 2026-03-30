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

@onready var title_panel: Control = $TitlePanel
@onready var main_panel: Control = $MainPanel
@onready var settings_panel: Control = $SettingsPanel
@onready var select_panel: Control = $PlayerSelectPanel
@onready var help_panel: Control = $HelpPanel
@onready var main_panel_vbox: VBoxContainer = $MainPanel

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


func _ready() -> void:
	_ensure_network_panel_ui()
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
	panel.visible = true


func _ui_click(back := false) -> void:
	AudioManager.play_sfx_varied("ui_back" if back else "ui_click", -6.0, 0.98, 1.03)


func _on_start_button_pressed() -> void:
	_ui_click()
	_show_panel(main_panel)


func _on_play_button_pressed() -> void:
	_ui_click()
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
