class_name BaseSkill
extends RefCounted
## Base class for character skills. Override activate() to implement skill behavior.

var cooldown: float = 5.0
var cooldown_timer: float = 0.0


func get_skill_name() -> String:
	return ""


func get_color() -> Color:
	return Color.WHITE


func is_ready() -> bool:
	return cooldown_timer <= 0.0


func is_active() -> bool:
	return false


func process(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer -= delta


func activate(_player: CharacterBody2D) -> void:
	cooldown_timer = cooldown


func on_damage_dealt(_player: CharacterBody2D, _amount: float) -> void:
	pass


func on_owner_damaged(_player: CharacterBody2D, _amount: float) -> void:
	pass


func get_visual_alpha() -> float:
	return 1.0


func reset() -> void:
	cooldown_timer = 0.0
