extends Node

signal connection_succeeded
signal connection_failed
signal server_disconnected
signal snapshot_received(snapshot: Dictionary)
signal lobby_state_changed(host_ready: bool, client_ready: bool, is_host: bool)
signal match_start_requested

const DEFAULT_PORT := 28991
const REMOTE_INPUT_TIMEOUT := 0.22

var _peer: ENetMultiplayerPeer
var _ready_by_peer: Dictionary = {}
var _local_input_seq := 0
var _last_remote_input_seq := -1
var _remote_input_age := 0.0
var _latest_remote_input: Dictionary = {
	"left": false,
	"right": false,
	"jump": false,
	"crouch": false,
	"attack": false,
	"secondary": false,
	"sprint": false,
	"skill": false,
	"item": false,
	"reload": false,
}


func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func _process(delta: float) -> void:
	if not is_host():
		return
	_remote_input_age += delta
	if _remote_input_age >= REMOTE_INPUT_TIMEOUT:
		# Prevent stale held keys when packets are delayed or dropped.
		_reset_remote_input()


func start_host(port: int = DEFAULT_PORT) -> bool:
	stop()
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_server(port)
	if err != OK:
		_peer = null
		return false
	multiplayer.multiplayer_peer = _peer
	_ready_by_peer = {1: false}
	_remote_input_age = 0.0
	_emit_lobby_state_changed()
	return true


func start_client(address: String, port: int = DEFAULT_PORT) -> bool:
	stop()
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_client(address, port)
	if err != OK:
		_peer = null
		return false
	multiplayer.multiplayer_peer = _peer
	_ready_by_peer.clear()
	_remote_input_age = 0.0
	return true


func stop() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	_peer = null
	_ready_by_peer.clear()
	_local_input_seq = 0
	_last_remote_input_seq = -1
	_remote_input_age = 0.0
	_reset_remote_input()


func is_online() -> bool:
	return multiplayer.multiplayer_peer != null


func is_host() -> bool:
	return is_online() and multiplayer.is_server()


func is_client() -> bool:
	return is_online() and not multiplayer.is_server()


func get_remote_input() -> Dictionary:
	return _latest_remote_input.duplicate(true)


func send_client_input(input_state: Dictionary) -> void:
	if not is_client():
		return
	_local_input_seq += 1
	var payload := input_state.duplicate(true)
	payload["_seq"] = _local_input_seq
	rpc_id(1, "_rpc_submit_input", payload)


func broadcast_snapshot(snapshot: Dictionary) -> void:
	if not is_host():
		return
	rpc("_rpc_receive_snapshot", snapshot)


func set_local_ready(ready: bool) -> void:
	if not is_online():
		return
	if is_host():
		_ready_by_peer[1] = ready
		_broadcast_lobby_state()
	else:
		rpc_id(1, "_rpc_set_ready", ready)


func host_can_start_match() -> bool:
	if not is_host():
		return false
	if _ready_by_peer.size() < 2:
		return false
	for v in _ready_by_peer.values():
		if not bool(v):
			return false
	return true


func start_match_by_host() -> void:
	if not host_can_start_match():
		return
	match_start_requested.emit()
	rpc("_rpc_start_match")


func get_lobby_flags() -> Dictionary:
	var host_ready := bool(_ready_by_peer.get(1, false))
	var client_ready := false
	for peer_id in _ready_by_peer.keys():
		if int(peer_id) != 1:
			client_ready = bool(_ready_by_peer[peer_id])
			break
	return {
		"host_ready": host_ready,
		"client_ready": client_ready,
		"is_host": is_host(),
		"peer_count": _ready_by_peer.size(),
	}


@rpc("any_peer", "unreliable")
func _rpc_submit_input(input_state: Dictionary) -> void:
	if not is_host():
		return
	var seq := int(input_state.get("_seq", 0))
	if seq <= _last_remote_input_seq:
		return
	_last_remote_input_seq = seq
	_remote_input_age = 0.0
	var cleaned := input_state.duplicate(true)
	cleaned.erase("_seq")
	_latest_remote_input = cleaned


@rpc("authority", "unreliable")
func _rpc_receive_snapshot(snapshot: Dictionary) -> void:
	if is_host():
		return
	snapshot_received.emit(snapshot)


@rpc("any_peer", "reliable")
func _rpc_set_ready(ready: bool) -> void:
	if not is_host():
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender <= 0:
		return
	_ready_by_peer[sender] = ready
	_broadcast_lobby_state()


@rpc("authority", "reliable")
func _rpc_sync_lobby_state(ready_by_peer: Dictionary) -> void:
	if is_host():
		return
	_ready_by_peer = ready_by_peer.duplicate(true)
	_emit_lobby_state_changed()


@rpc("authority", "reliable")
func _rpc_start_match() -> void:
	if is_host():
		return
	match_start_requested.emit()


func _on_connected_to_server() -> void:
	_ready_by_peer.clear()
	connection_succeeded.emit()


func _on_connection_failed() -> void:
	connection_failed.emit()


func _on_server_disconnected() -> void:
	stop()
	server_disconnected.emit()


func _on_peer_connected(id: int) -> void:
	if not is_host():
		return
	if id == 1:
		return
	_ready_by_peer[id] = false
	_broadcast_lobby_state()


func _on_peer_disconnected(id: int) -> void:
	if not is_online():
		return
	if is_host():
		_ready_by_peer.erase(id)
		_broadcast_lobby_state()
	else:
		_ready_by_peer.erase(id)
		_emit_lobby_state_changed()


func _broadcast_lobby_state() -> void:
	_emit_lobby_state_changed()
	if is_host():
		rpc("_rpc_sync_lobby_state", _ready_by_peer)


func _emit_lobby_state_changed() -> void:
	var flags := get_lobby_flags()
	lobby_state_changed.emit(bool(flags["host_ready"]), bool(flags["client_ready"]), bool(flags["is_host"]))


func _reset_remote_input() -> void:
	for key in _latest_remote_input.keys():
		_latest_remote_input[key] = false
