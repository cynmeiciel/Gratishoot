class_name InvisibleSkill
extends BaseSkill
## Invisibility skill: fully invisible for a duration; briefly reveals when hit.

const DURATION := 7
const REVEAL_ON_HIT_TIME := 0.32
const HIDDEN_ALPHA := 0.0
const REVEALED_ALPHA := 0.9

var _active := false
var _active_timer := 0.0
var _reveal_timer := 0.0


func _init() -> void:
	cooldown = 25.0


func get_skill_name() -> String:
	return "Invisible"


func get_color() -> Color:
	return Color(0.72, 0.72, 1.0)


func is_active() -> bool:
	return _active


func process(delta: float) -> void:
	super.process(delta)
	if _reveal_timer > 0.0:
		_reveal_timer = maxf(_reveal_timer - delta, 0.0)
	if _active:
		_active_timer -= delta
		if _active_timer <= 0.0:
			_active = false
			_reveal_timer = 0.0


func activate(_player: CharacterBody2D) -> void:
	super.activate(_player)
	_active = true
	_active_timer = DURATION
	_reveal_timer = 0.0


func on_owner_damaged(_player: CharacterBody2D, _amount: float) -> void:
	if _active:
		_reveal_timer = REVEAL_ON_HIT_TIME


func get_visual_alpha() -> float:
	if not _active:
		return 1.0
	if _reveal_timer > 0.0:
		return REVEALED_ALPHA
	return HIDDEN_ALPHA


func reset() -> void:
	super.reset()
	_active = false
	_active_timer = 0.0
	_reveal_timer = 0.0
