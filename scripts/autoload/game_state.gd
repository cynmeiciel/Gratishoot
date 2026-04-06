extends Node

const SETTINGS_PATH := "user://settings.cfg"
const WINDOW_WINDOWED := 0
const WINDOW_FULLSCREEN := 1
const MODE_CLASSIC_DUEL := 0
const MODE_TRAINING := 1
const MODE_ARMS_DEALER := 2
const MODE_DRAFT_DUEL := 3
const MODE_ONLINE_HOST := 4
const MODE_ONLINE_CLIENT := 5
const DEFAULT_BINDINGS := {
	"p1_left": KEY_A,
	"p1_right": KEY_D,
	"p1_jump": KEY_W,
	"p1_crouch": KEY_S,
	"p1_attack": KEY_G,
	"p1_secondary": KEY_H,
	"p1_sprint": KEY_J,
	"p1_skill": KEY_T,
	"p1_item": KEY_Y,
	"p1_reload": KEY_U,
	"p2_left": KEY_LEFT,
	"p2_right": KEY_RIGHT,
	"p2_jump": KEY_UP,
	"p2_crouch": KEY_DOWN,
	"p2_attack": KEY_KP_1,
	"p2_secondary": KEY_KP_2,
	"p2_sprint": KEY_KP_3,
	"p2_skill": KEY_KP_4,
	"p2_item": KEY_KP_5,
	"p2_reload": KEY_KP_6
}

var rounds_to_win: int = 3
var p1_character: int = 0
var p2_character: int = 1
var p1_name: String = "Player 1"
var p2_name: String = "Player 2"
var p1_color: Color = Color(0.2, 0.6, 1.0)
var p2_color: Color = Color(1.0, 0.3, 0.2)
var master_volume: float = 0.85
var window_mode: int = WINDOW_WINDOWED
var aim_assist_enabled: bool = true
var key_bindings: Dictionary = {}
var game_mode: int = MODE_CLASSIC_DUEL
var p2_is_ai: bool = false
var online_server_address: String = "127.0.0.1"
var online_server_port: int = 28991
# When filter is disabled, all entries are allowed.
var classic_use_weapon_filter: bool = false
var classic_use_tactical_filter: bool = false
var classic_enabled_weapons: PackedStringArray = PackedStringArray()
var classic_enabled_tacticals: PackedStringArray = PackedStringArray()
var classic_spawn_interval_min: float = 1.2
var classic_spawn_interval_max: float = 2.4
var classic_tactical_chance: float = 0.3
var classic_max_pickups: int = 10


func _ready() -> void:
	load_settings()
	apply_runtime_settings()
	if key_bindings.is_empty():
		key_bindings = DEFAULT_BINDINGS.duplicate(true)
	apply_key_bindings()


func apply_runtime_settings() -> void:
	var db := linear_to_db(clampf(master_volume, 0.0, 1.0))
	AudioServer.set_bus_volume_db(0, db)
	if window_mode == WINDOW_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("match", "rounds_to_win", rounds_to_win)
	cfg.set_value("players", "p1_character", p1_character)
	cfg.set_value("players", "p2_character", p2_character)
	cfg.set_value("players", "p1_name", p1_name)
	cfg.set_value("players", "p2_name", p2_name)
	cfg.set_value("players", "p2_is_ai", p2_is_ai)
	cfg.set_value("players", "p1_color", p1_color.to_html())
	cfg.set_value("players", "p2_color", p2_color.to_html())
	cfg.set_value("match", "game_mode", game_mode)
	cfg.set_value("network", "server_address", online_server_address)
	cfg.set_value("network", "server_port", online_server_port)
	cfg.set_value("match", "classic_use_weapon_filter", classic_use_weapon_filter)
	cfg.set_value("match", "classic_use_tactical_filter", classic_use_tactical_filter)
	cfg.set_value("match", "classic_enabled_weapons", classic_enabled_weapons)
	cfg.set_value("match", "classic_enabled_tacticals", classic_enabled_tacticals)
	cfg.set_value("match", "classic_spawn_interval_min", classic_spawn_interval_min)
	cfg.set_value("match", "classic_spawn_interval_max", classic_spawn_interval_max)
	cfg.set_value("match", "classic_tactical_chance", classic_tactical_chance)
	cfg.set_value("match", "classic_max_pickups", classic_max_pickups)
	cfg.set_value("settings", "master_volume", master_volume)
	cfg.set_value("settings", "window_mode", window_mode)
	cfg.set_value("settings", "aim_assist_enabled", aim_assist_enabled)
	for action in DEFAULT_BINDINGS.keys():
		cfg.set_value("bindings", action, int(key_bindings.get(action, DEFAULT_BINDINGS[action])))
	cfg.save(SETTINGS_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return

	rounds_to_win = int(cfg.get_value("match", "rounds_to_win", rounds_to_win))
	game_mode = int(cfg.get_value("match", "game_mode", game_mode))
	classic_use_weapon_filter = bool(cfg.get_value("match", "classic_use_weapon_filter", classic_use_weapon_filter))
	classic_use_tactical_filter = bool(cfg.get_value("match", "classic_use_tactical_filter", classic_use_tactical_filter))
	classic_enabled_weapons = PackedStringArray(cfg.get_value("match", "classic_enabled_weapons", []))
	classic_enabled_tacticals = PackedStringArray(cfg.get_value("match", "classic_enabled_tacticals", []))
	classic_spawn_interval_min = float(cfg.get_value("match", "classic_spawn_interval_min", classic_spawn_interval_min))
	classic_spawn_interval_max = float(cfg.get_value("match", "classic_spawn_interval_max", classic_spawn_interval_max))
	classic_tactical_chance = float(cfg.get_value("match", "classic_tactical_chance", classic_tactical_chance))
	classic_max_pickups = int(cfg.get_value("match", "classic_max_pickups", classic_max_pickups))
	online_server_address = String(cfg.get_value("network", "server_address", online_server_address))
	online_server_port = int(cfg.get_value("network", "server_port", online_server_port))
	p1_character = int(cfg.get_value("players", "p1_character", p1_character))
	p2_character = int(cfg.get_value("players", "p2_character", p2_character))
	p1_name = String(cfg.get_value("players", "p1_name", p1_name)).strip_edges()
	p2_name = String(cfg.get_value("players", "p2_name", p2_name)).strip_edges()
	p2_is_ai = bool(cfg.get_value("players", "p2_is_ai", p2_is_ai))
	p1_color = Color(cfg.get_value("players", "p1_color", p1_color.to_html()))
	p2_color = Color(cfg.get_value("players", "p2_color", p2_color.to_html()))
	master_volume = float(cfg.get_value("settings", "master_volume", master_volume))
	window_mode = int(cfg.get_value("settings", "window_mode", window_mode))
	aim_assist_enabled = bool(cfg.get_value("settings", "aim_assist_enabled", aim_assist_enabled))

	key_bindings.clear()
	for action in DEFAULT_BINDINGS.keys():
		key_bindings[action] = int(cfg.get_value("bindings", action, DEFAULT_BINDINGS[action]))

	master_volume = clampf(master_volume, 0.0, 1.0)
	rounds_to_win = maxi(1, mini(9, rounds_to_win))
	game_mode = maxi(MODE_CLASSIC_DUEL, mini(MODE_ONLINE_CLIENT, game_mode))
	online_server_port = clampi(online_server_port, 1024, 65535)
	classic_spawn_interval_min = clampf(classic_spawn_interval_min, 0.2, 30.0)
	classic_spawn_interval_max = clampf(classic_spawn_interval_max, 0.2, 30.0)
	if classic_spawn_interval_max < classic_spawn_interval_min:
		classic_spawn_interval_max = classic_spawn_interval_min
	classic_tactical_chance = clampf(classic_tactical_chance, 0.0, 1.0)
	classic_max_pickups = clampi(classic_max_pickups, 1, 64)
	p1_character = maxi(0, mini(3, p1_character))
	p2_character = maxi(0, mini(3, p2_character))
	if p1_name == "":
		p1_name = "Player 1"
	if p2_name == "":
		p2_name = "Player 2"
	window_mode = maxi(WINDOW_WINDOWED, mini(WINDOW_FULLSCREEN, window_mode))


func set_classic_pool_filters(
	weapons: PackedStringArray,
	tacticals: PackedStringArray,
	use_weapon_filter: bool,
	use_tactical_filter: bool
) -> void:
	classic_use_weapon_filter = use_weapon_filter
	classic_use_tactical_filter = use_tactical_filter
	classic_enabled_weapons = weapons.duplicate()
	classic_enabled_tacticals = tacticals.duplicate()


func set_classic_spawn_settings(interval_min: float, interval_max: float, tactical_chance: float, max_pickups: int) -> void:
	classic_spawn_interval_min = clampf(interval_min, 0.2, 30.0)
	classic_spawn_interval_max = clampf(interval_max, classic_spawn_interval_min, 30.0)
	classic_tactical_chance = clampf(tactical_chance, 0.0, 1.0)
	classic_max_pickups = clampi(max_pickups, 1, 64)


func is_classic_weapon_allowed(weapon_name: String) -> bool:
	if not classic_use_weapon_filter:
		return true
	return classic_enabled_weapons.has(weapon_name)


func is_classic_tactical_allowed(tactical_name: String) -> bool:
	if not classic_use_tactical_filter:
		return true
	return classic_enabled_tacticals.has(tactical_name)


func apply_key_bindings() -> void:
	for action in DEFAULT_BINDINGS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = int(key_bindings.get(action, DEFAULT_BINDINGS[action]))
		InputMap.action_add_event(action, ev)


func get_binding_key(action: String) -> int:
	return int(key_bindings.get(action, DEFAULT_BINDINGS.get(action, KEY_NONE)))


func set_binding_key(action: String, keycode: int) -> void:
	if not DEFAULT_BINDINGS.has(action):
		return
	key_bindings[action] = keycode


func reset_bindings_to_default() -> void:
	key_bindings = DEFAULT_BINDINGS.duplicate(true)
	apply_key_bindings()
