extends Node
## Registers all input actions for both players at startup.
## Using code ensures correct key constants without hardcoding integer keycodes.

func _ready() -> void:
	# Player 1 — WASD + GHJTYU
	_add_key_action("p1_left", KEY_A)
	_add_key_action("p1_right", KEY_D)
	_add_key_action("p1_jump", KEY_W)
	_add_key_action("p1_crouch", KEY_S)
	_add_key_action("p1_attack", KEY_G)
	_add_key_action("p1_secondary", KEY_H)
	_add_key_action("p1_sprint", KEY_J)
	_add_key_action("p1_skill", KEY_T)
	_add_key_action("p1_item", KEY_Y)
	_add_key_action("p1_reload", KEY_U)

	# Player 2 — Arrow keys + Numpad 1-6
	_add_key_action("p2_left", KEY_LEFT)
	_add_key_action("p2_right", KEY_RIGHT)
	_add_key_action("p2_jump", KEY_UP)
	_add_key_action("p2_crouch", KEY_DOWN)
	_add_key_action("p2_attack", KEY_KP_1)
	_add_key_action("p2_secondary", KEY_KP_2)
	_add_key_action("p2_sprint", KEY_KP_3)
	_add_key_action("p2_skill", KEY_KP_4)
	_add_key_action("p2_item", KEY_KP_5)
	_add_key_action("p2_reload", KEY_KP_6)


func _add_key_action(action_name: String, key: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action_name, event)
