extends Area2D
## A lingering fire zone left by a Molotov. Damages players standing in it.

var _damage_per_tick: float = 8.0
var _radius: float = 100.0
var _duration: float = 3.0
var _tick_interval: float = 0.4
var _tick_timer: float = 0.0
var _life_timer: float = 0.0
var _owner_id: int = -1


func init(damage: float, radius: float, duration: float, owner_id: int) -> void:
	_damage_per_tick = damage
	_radius = radius
	_duration = duration
	_owner_id = owner_id


func _ready() -> void:
	add_to_group("projectiles")
	var shape := CircleShape2D.new()
	shape.radius = _radius
	$Shape.shape = shape


func _physics_process(delta: float) -> void:
	_life_timer += delta
	if _life_timer >= _duration:
		queue_free()
		return

	_tick_timer += delta
	if _tick_timer >= _tick_interval:
		_tick_timer = 0.0
		_apply_damage()
	queue_redraw()


func _apply_damage() -> void:
	for body in get_overlapping_bodies():
		if body is CharacterBody2D and body.has_method("take_damage"):
			var dir_sign := 1 if body.global_position.x >= global_position.x else -1
			body.take_damage(_damage_per_tick, 30.0, dir_sign)


func _draw() -> void:
	var alpha := 1.0 - (_life_timer / _duration) * 0.6
	# Fire base
	draw_circle(Vector2.ZERO, _radius, Color(1.0, 0.3, 0.0, alpha * 0.3))
	draw_circle(Vector2.ZERO, _radius * 0.6, Color(1.0, 0.6, 0.0, alpha * 0.4))
	# Outline
	draw_arc(Vector2.ZERO, _radius, 0, TAU, 32, Color(1.0, 0.2, 0.0, alpha * 0.6), 2.0)
