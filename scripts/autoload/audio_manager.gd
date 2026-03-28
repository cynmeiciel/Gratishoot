extends Node
## Centralized SFX manager.
## - Add/replace sounds by editing DEFAULT_EVENT_PATHS or calling set_event_path/register_bank.
## - Gameplay code only references event names, not file paths.

const POOL_SIZE := 20

const DEFAULT_EVENT_PATHS := {
	# UI
	"ui_click": "res://assets/audio/sfx/ui_click.ogg",
	"ui_back": "res://assets/audio/sfx/ui_back.ogg",
	# Combat
	"gun_pistol": "res://assets/audio/sfx/gun_pistol.ogg",
	"gun_rifle": "res://assets/audio/sfx/gun_rifle.ogg",
	"gun_shotgun": "res://assets/audio/sfx/gun_shotgun.ogg",
	"gun_smg": "res://assets/audio/sfx/gun_smg.ogg",
	"gun_sniper": "res://assets/audio/sfx/gun_sniper.ogg",
	"gun_lmg": "res://assets/audio/sfx/gun_lmg.ogg",
	"gun_dmr": "res://assets/audio/sfx/gun_dmr.ogg",
	"reload": "res://assets/audio/sfx/reload.ogg",
	"melee_swing": "res://assets/audio/sfx/melee_swing.ogg",
	"melee_hit": "res://assets/audio/sfx/melee_hit.ogg",
	"bullet_impact": "res://assets/audio/sfx/bullet_impact.ogg",
	"hurt": "res://assets/audio/sfx/hurt.ogg",
	"death": "res://assets/audio/sfx/death.ogg",
	# Items / pickups
	"pickup_weapon": "res://assets/audio/sfx/pickup_weapon.ogg",
	"pickup_tactical": "res://assets/audio/sfx/pickup_tactical.ogg",
	"use_tactical": "res://assets/audio/sfx/use_tactical.ogg",
	"use_medkit": "res://assets/audio/sfx/use_medkit.ogg",
	"use_jetpack": "res://assets/audio/sfx/use_jetpack.ogg",
	# Match flow
	"round_start": "res://assets/audio/sfx/round_start.ogg",
	"round_win": "res://assets/audio/sfx/round_win.ogg",
	"match_victory": "res://assets/audio/sfx/match_victory.ogg"
}

var _event_paths: Dictionary = {}
var _event_streams: Dictionary = {}
var _warned_missing_events: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _pool_cursor := 0
var _sfx_bus := "Master"


func _ready() -> void:
	_event_paths = DEFAULT_EVENT_PATHS.duplicate(true)
	_sfx_bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
	for _i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = _sfx_bus
		add_child(p)
		_pool.append(p)


func register_bank(bank: Dictionary) -> void:
	for event_name in bank.keys():
		set_event_path(String(event_name), String(bank[event_name]))


func set_event_path(event_name: String, path: String) -> void:
	_event_paths[event_name] = path
	_event_streams.erase(event_name)
	_warned_missing_events.erase(event_name)


func get_event_path(event_name: String) -> String:
	return String(_event_paths.get(event_name, ""))


func has_event(event_name: String) -> bool:
	return _event_paths.has(event_name)


func list_events() -> PackedStringArray:
	var names := PackedStringArray()
	for k in _event_paths.keys():
		names.append(String(k))
	names.sort()
	return names


func play_sfx(event_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var stream := _get_stream(event_name)
	if stream == null:
		return
	var player := _pool[_pool_cursor]
	_pool_cursor = (_pool_cursor + 1) % _pool.size()
	player.stop()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()


func play_sfx_varied(event_name: String, volume_db: float = 0.0, pitch_min: float = 0.96, pitch_max: float = 1.04) -> void:
	play_sfx(event_name, volume_db, randf_range(pitch_min, pitch_max))


func play_sfx_2d(event_name: String, world_position: Vector2, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var stream := _get_stream(event_name)
	if stream == null:
		return
	var p := AudioStreamPlayer2D.new()
	p.bus = _sfx_bus
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch_scale
	p.max_distance = 1200.0
	p.attenuation = 1.0
	p.global_position = world_position
	get_tree().current_scene.add_child(p)
	p.play()
	p.finished.connect(func() -> void:
		p.queue_free()
	)


func _get_stream(event_name: String) -> AudioStream:
	if _event_streams.has(event_name):
		return _event_streams[event_name]
	if not _event_paths.has(event_name) and event_name.begins_with("gun_"):
		var gun_path := "res://assets/audio/sfx/guns/%s.ogg" % event_name.substr(4)
		if ResourceLoader.exists(gun_path):
			_event_paths[event_name] = gun_path
	if not _event_paths.has(event_name):
		if not _warned_missing_events.has(event_name):
			push_warning("AudioManager: unknown SFX event '%s'" % event_name)
			_warned_missing_events[event_name] = true
		return null
	var path: String = _event_paths[event_name]
	if path == "" or not ResourceLoader.exists(path):
		if not _warned_missing_events.has(event_name):
			push_warning("AudioManager: missing SFX file for '%s' at '%s'" % [event_name, path])
			_warned_missing_events[event_name] = true
		return null
	var stream := load(path) as AudioStream
	if stream == null:
		if not _warned_missing_events.has(event_name):
			push_warning("AudioManager: failed to load SFX '%s' at '%s'" % [event_name, path])
			_warned_missing_events[event_name] = true
		return null
	_event_streams[event_name] = stream
	return stream
