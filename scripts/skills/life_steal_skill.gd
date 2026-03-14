class_name LifeStealSkill
extends BaseSkill
## Aichok's Life Steal — heal a fraction of damage dealt for a limited time.

const DURATION := 3.0
const FRACTION := 0.4

var _active := false
var _active_timer := 0.0


func get_skill_name() -> String:
	return "Life Steal"


func get_color() -> Color:
	return Color(0.9, 0.3, 0.5)


func is_active() -> bool:
	return _active


func process(delta: float) -> void:
	super.process(delta)
	if _active:
		_active_timer -= delta
		if _active_timer <= 0.0:
			_active = false


func activate(player: CharacterBody2D) -> void:
	super.activate(player)
	_active = true
	_active_timer = DURATION


func on_damage_dealt(player: CharacterBody2D, amount: float) -> void:
	if _active:
		player.hp = minf(player.hp + amount * FRACTION, player.HP_MAX)


func reset() -> void:
	super.reset()
	_active = false
	_active_timer = 0.0
