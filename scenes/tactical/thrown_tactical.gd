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
var _bounce_count := 0
const THROW_COLLISION_MASK := 3  # World + one-way platforms
const THROW_COLLISION_MASK_AFTER_BOUNCES := 1  # Only world (solid), skip one-way
const BOUNCES_BEFORE_PASS_THROUGH_THIN := 3


func init(data: TacticalData, initial_velocity: Vector2, thrower_id: int) -> void:
	tactical_data = data
	if initial_velocity.length() > 0.0:
		direction = initial_velocity.normalized()
		speed = initial_velocity.length()
	else:
		speed = data.throw_speed
	owner_id = thrower_id
	_fuse_timer = data.fuse_time
	_velocity = initial_velocity


func _ready() -> void:
	add_to_group("projectiles")


func _physics_process(delta: float) -> void:
	if _detonated:
		return
	var from := global_position
	_velocity.y += _gravity * delta
	var to := from + _velocity * delta

	# Sweep collision catches surfaces reliably.
	# After 2 bounces, stop colliding with one-way platforms to allow pass-through.
	var active_mask := THROW_COLLISION_MASK
	if _bounce_count >= BOUNCES_BEFORE_PASS_THROUGH_THIN:
		active_mask = THROW_COLLISION_MASK_AFTER_BOUNCES
	
	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = active_mask
	query.exclude = [self]
	for p in get_tree().get_nodes_in_group("players"):
		if p.player_id == owner_id:
			query.exclude.append(p)

	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		global_position = hit.position
		_on_surface_hit(hit.collider, hit.normal)
	else:
		global_position = to

	_fuse_timer -= delta
	if _fuse_timer <= 0.0 and tactical_data.tactical_type != TacticalData.TacticalType.MOLOTOV:
		_detonate()
	queue_redraw()


func _on_surface_hit(body: Node2D, hit_normal: Vector2) -> void:
	# Molotov detonates on first surface hit.
	if tactical_data.tactical_type == TacticalData.TacticalType.MOLOTOV:
		_detonate()
	# Other grenades bounce slightly off walls/ground but don't detonate.
	elif body is StaticBody2D:
		var normal := hit_normal.normalized()
		if normal == Vector2.ZERO:
			normal = -_velocity.normalized()
		_velocity = _velocity.bounce(normal) * 0.68
		# Push slightly out of the surface to avoid sticky re-collisions.
		global_position += normal * 0.5
		_bounce_count += 1


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
		var falloff := _calculate_damage_falloff(dist, radius)
		var dir_sign := 1 if body.global_position.x >= global_position.x else -1
		body.take_damage(tactical_data.damage * falloff, tactical_data.knockback * falloff, dir_sign)


func _explode_freeze() -> void:
	var radius := tactical_data.radius
	for body in _get_players_in_radius(radius):
		var dist := global_position.distance_to(body.global_position + Vector2(0, -32))
		var falloff := _calculate_damage_falloff(dist, radius)
		body.take_damage(tactical_data.damage * falloff, tactical_data.knockback * falloff, 0)
		if body.has_method("apply_freeze"):
			body.apply_freeze(tactical_data.duration)


func _spawn_fire_zone() -> void:
	var zone_scene := load("res://scenes/tactical/fire_zone.tscn")
	var zone: Node2D = zone_scene.instantiate()
	zone.global_position = global_position
	zone.init(tactical_data.damage, tactical_data.radius, tactical_data.duration, owner_id)
	get_tree().current_scene.add_child(zone)


func _calculate_damage_falloff(distance: float, radius: float) -> float:
	"""Calculate quadratic falloff: damage is strongest at center, drops off faster at edges."""
	var normalized_dist := clampf(distance / radius, 0.0, 1.0)
	# Quadratic falloff: 1 - x^2 creates dramatic reduction near edges
	# At 50% radius: 75% damage. At 75% radius: 44% damage. At 100% radius: 0% damage
	return (1.0 - normalized_dist * normalized_dist)


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
