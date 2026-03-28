class_name ShrinkSkill
extends BaseSkill
## Shrink skill: become smaller for a short duration (also shrinks hurtbox/hitbox via node scale).

const DURATION := 8.0
const SHRINK_SCALE := 0.72

var _active := false
var _active_timer := 0.0
var _owner: CharacterBody2D = null


func _init() -> void:
	cooldown = 20.0


func get_skill_name() -> String:
	return "Shrink"


func get_color() -> Color:
	return Color(0.55, 1.0, 0.65)


func is_active() -> bool:
	return _active


func process(delta: float) -> void:
	super.process(delta)
	if not _active:
		return
	_active_timer -= delta
	if _active_timer <= 0.0:
		_end_effect()


func activate(player: CharacterBody2D) -> void:
	super.activate(player)
	_owner = player
	_active = true
	_active_timer = DURATION
	if is_instance_valid(_owner):
		_owner.scale = Vector2.ONE * SHRINK_SCALE


func reset() -> void:
	super.reset()
	_end_effect()


func _end_effect() -> void:
	if _active and is_instance_valid(_owner):
		_owner.scale = Vector2.ONE
	_active = false
	_active_timer = 0.0
	_owner = null
