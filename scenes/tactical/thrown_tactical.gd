extends Area2D
## A thrown tactical item: frag grenade, flash freeze, or molotov.
## Arcs through the air, then detonates on fuse timeout or ground impact (molotov).

var tactical_data: TacticalData
var direction := Vector2.RIGHT
var speed := 500.0
var owner_id: int = -1

var _velocity: Vector2
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _fuse_timer: float = 0.0
var _detonated := false


func init(data: TacticalData, dir: Vector2, thrower_id: int) -> void:
	tactical_data = data
	direction = dir.normalized()
	speed = data.throw_speed
	owner_id = thrower_id
	_fuse_timer = data.fuse_time
	_velocity = direction * speed + Vector2(0, -200)  # arc upward slightly


func _ready() -> void:
	add_to_group("projectiles")
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _detonated:
		return
	_velocity.y += _gravity * delta
	global_position += _velocity * delta
	_fuse_timer -= delta
	if _fuse_timer <= 0.0 and tactical_data.tactical_type != TacticalData.TacticalType.MOLOTOV:
		_detonate()
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if _detonated:
		return
	# Molotov detonates on first surface hit
	if tactical_data.tactical_type == TacticalData.TacticalType.MOLOTOV:
		_detonate()
	# Other grenades bounce slightly off walls/ground but don't detonate
	elif body is StaticBody2D:
		_velocity.y = -absf(_velocity.y) * 0.3
		_velocity.x *= 0.5


func _detonate() -> void:
	_detonated = true
	match tactical_data.tactical_type:
		TacticalData.TacticalType.FRAG_GRENADE:
			_explode_frag()
		TacticalData.TacticalType.FLASH_FREEZE:
			_explode_freeze()
		TacticalData.TacticalType.MOLOTOV:
			_spawn_fire_zone()
	# Visual flash, then remove
	queue_redraw()
	get_tree().create_timer(0.15).timeout.connect(queue_free)


func _explode_frag() -> void:
	var radius := tactical_data.radius
	for body in _get_players_in_radius(radius):
		var dist := global_position.distance_to(body.global_position + Vector2(0, -32))
		var falloff := 1.0 - clampf(dist / radius, 0.0, 1.0)
		var dir_sign := 1 if body.global_position.x >= global_position.x else -1
		body.take_damage(tactical_data.damage * falloff, tactical_data.knockback * falloff, dir_sign)


func _explode_freeze() -> void:
	var radius := tactical_data.radius
	for body in _get_players_in_radius(radius):
		body.take_damage(tactical_data.damage, tactical_data.knockback, 0)
		if body.has_method("apply_freeze"):
			body.apply_freeze(tactical_data.duration)


func _spawn_fire_zone() -> void:
	var zone_scene := load("res://scenes/tactical/fire_zone.tscn")
	var zone: Node2D = zone_scene.instantiate()
	zone.global_position = global_position
	zone.init(tactical_data.damage, tactical_data.radius, tactical_data.duration, owner_id)
	get_tree().current_scene.add_child(zone)


func _get_players_in_radius(radius: float) -> Array:
	var result := []
	for p in get_tree().get_nodes_in_group("players"):
		var dist := global_position.distance_to(p.global_position + Vector2(0, -32))
		if dist <= radius:
			result.append(p)
	return result


func _draw() -> void:
	if not tactical_data:
		return
	var col := tactical_data.get_color()
	if _detonated:
		# Explosion flash
		draw_circle(Vector2.ZERO, tactical_data.radius, Color(col, 0.3))
		draw_circle(Vector2.ZERO, tactical_data.radius * 0.5, Color(col, 0.5))
	else:
		# Grenade body
		draw_circle(Vector2.ZERO, 6.0, col)
		draw_circle(Vector2.ZERO, 6.0, Color.WHITE, false, 1.0)
