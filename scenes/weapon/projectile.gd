extends Area2D
## A bullet projectile that flies, deals damage on hit, and loses damage over distance.

var direction := Vector2.RIGHT
var speed := 800.0
var damage := 10.0
var knockback := 150.0
var owner_id: int = -1
#var gravity := 0.0
var vertical_boost := 0.0
var explosive_radius := 0.0
var spread_on_impact := false
var homing_turn_rate_deg := 0.0
var homing_range := 0.0
var homing_delay := 0.0
var homing_fov_deg := 0.0
var homing_duration := 0.0
var split_generation := 0  # prevent infinite recursion
var main_color: Color = Color(1.0, 0.78, 0.22, 1.0)
var accent_color: Color = Color(1.0, 0.95, 0.75, 1.0)

var _start_position: Vector2
var _life_time := 0.0
var _velocity := Vector2.ZERO
var _trail_points: PackedVector2Array = PackedVector2Array()
var _has_hit := false
var _homing_target: CharacterBody2D = null
const DAMAGE_FALLOFF_RATE := 0.85  # fraction of damage lost per second in flight
const MAX_DISTANCE := 5000.0
const TRAIL_POINTS_MAX := 10
const PLAYER_HIT_PADDING := 4.0
const PLAYER_LAYER_MASK := 4
var _projectile_radius := 3.0


func apply_rarity_color(rarity_color: Color) -> void:
	main_color = rarity_color
	accent_color = rarity_color.lerp(Color.WHITE, 0.65)


func _ready() -> void:
	add_to_group("projectiles")
	_start_position = global_position
	var shape_node := get_node_or_null("Shape") as CollisionShape2D
	if shape_node and shape_node.shape is CircleShape2D:
		_projectile_radius = (shape_node.shape as CircleShape2D).radius
	_velocity = direction.normalized() * speed + Vector2(0.0, vertical_boost)
	if _velocity.length() > 0.0:
		direction = _velocity.normalized()
	_trail_points.append(global_position)


func _physics_process(delta: float) -> void:
	if _has_hit:
		return
	_life_time += delta
	_update_homing(delta)
	var from := global_position
	_velocity.y += gravity * delta
	var to := from + _velocity * delta
	if _velocity.length() > 0.0:
		direction = _velocity.normalized()

	# Sweep test prevents high-speed bullets from tunneling through targets.
	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.hit_from_inside = true
	query.collision_mask = collision_mask
	query.exclude = [self]
	for p in get_tree().get_nodes_in_group("players"):
		if p.player_id == owner_id:
			query.exclude.append(p)

	var ray_hit := get_world_2d().direct_space_state.intersect_ray(query)
	var player_hit := _find_player_sweep_hit(from, to)
	var hit := _pick_nearest_hit(from, ray_hit, player_hit)
	if not hit.is_empty():
		global_position = hit.position
		if _apply_hit(hit.collider, hit.position, hit.normal):
			_has_hit = true
			queue_free()
			return

	global_position = to
	_trail_points.append(global_position)
	if _trail_points.size() > TRAIL_POINTS_MAX:
		_trail_points.remove_at(0)
	queue_redraw()
	var dist := global_position.distance_to(_start_position)
	if dist > MAX_DISTANCE:
		queue_free()


func _find_player_sweep_hit(from: Vector2, to: Vector2) -> Dictionary:
	var motion := to - from
	if motion.length_squared() <= 0.0001:
		return {}

	var shape := CircleShape2D.new()
	shape.radius = _projectile_radius + PLAYER_HIT_PADDING

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, from)
	params.motion = motion
	params.collide_with_areas = false
	params.collide_with_bodies = true
	params.collision_mask = PLAYER_LAYER_MASK
	params.exclude = [self]
	for p in get_tree().get_nodes_in_group("players"):
		if p.player_id == owner_id:
			params.exclude.append(p)

	var results := get_world_2d().direct_space_state.intersect_shape(params, 8)
	if results.is_empty():
		return {}

	var best_hit := {}
	var best_dist := INF
	for result in results:
		var p := result.collider as CharacterBody2D
		if p == null or p.player_id == owner_id or p.is_dead:
			continue

		var crouching := bool(p.get("is_crouching"))
		var half_w := 15.0
		var half_h := 16.5 if crouching else 32.0
		var center := p.global_position + Vector2(0.0, -16.5 if crouching else -32.0)

		var closest := Geometry2D.get_closest_point_to_segment(center, from, to)
		var dx := maxf(absf(closest.x - center.x) - half_w, 0.0)
		var dy := maxf(absf(closest.y - center.y) - half_h, 0.0)
		if (dx * dx + dy * dy) > (PLAYER_HIT_PADDING * PLAYER_HIT_PADDING):
			continue

		var hit_dist := from.distance_to(closest)
		if hit_dist < best_dist:
			best_dist = hit_dist
			var normal := (closest - center).normalized()
			if normal == Vector2.ZERO:
				normal = -direction.normalized()
			best_hit = {
				"collider": p,
				"position": closest,
				"normal": normal,
			}
	return best_hit


func _pick_nearest_hit(from: Vector2, hit_a: Dictionary, hit_b: Dictionary) -> Dictionary:
	if hit_a.is_empty():
		return hit_b
	if hit_b.is_empty():
		return hit_a
	var da := from.distance_to(hit_a.position)
	var db := from.distance_to(hit_b.position)
	return hit_a if da <= db else hit_b


func _update_homing(delta: float) -> void:
	if homing_turn_rate_deg <= 0.0 or homing_range <= 0.0:
		return
	if _life_time < homing_delay:
		return

	# Re-evaluate target continuously for stronger, responsive homing.
	_homing_target = _find_homing_target()
	if _homing_target == null:
		return

	var target_center := _homing_target.global_position + Vector2(0.0, -32.0)
	var to_target := target_center - global_position
	var dist := to_target.length()
	if dist <= 0.001 or dist > homing_range:
		_homing_target = null
		return

	var cur_dir := _velocity.normalized() if _velocity.length() > 0.0 else direction.normalized()
	var desired_dir := to_target / dist
	var max_turn := deg_to_rad(homing_turn_rate_deg) * delta
	var turn := clampf(cur_dir.angle_to(desired_dir), -max_turn, max_turn)
	var new_dir := cur_dir.rotated(turn).normalized()
	var mag := _velocity.length()
	if mag <= 0.0:
		mag = speed
	_velocity = new_dir * mag
	direction = new_dir


func _find_homing_target() -> CharacterBody2D:
	var cur_dir := _velocity.normalized() if _velocity.length() > 0.0 else direction.normalized()
	var fov_cos := cos(deg_to_rad(homing_fov_deg))
	var best: CharacterBody2D = null
	var best_dist := homing_range

	for node in get_tree().get_nodes_in_group("players"):
		var p := node as CharacterBody2D
		if p == null or p.player_id == owner_id or p.is_dead:
			continue
		var aim_point := p.global_position + Vector2(0.0, -32.0)
		var to_target := aim_point - global_position
		var dist := to_target.length()
		if dist <= 0.001 or dist > homing_range:
			continue
		var dir_to_target := to_target / dist
		if cur_dir.dot(dir_to_target) < fov_cos:
			continue

		# Require line of sight for lock so cover can break homing.
		var query := PhysicsRayQueryParameters2D.create(global_position, aim_point)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		query.collision_mask = collision_mask
		query.exclude = [self]
		for other in get_tree().get_nodes_in_group("players"):
			if other.player_id == owner_id:
				query.exclude.append(other)
		var hit := get_world_2d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.collider != p:
			continue

		if dist < best_dist:
			best_dist = dist
			best = p

	return best


func _apply_hit(body: Node2D, hit_position: Vector2, hit_normal: Vector2 = Vector2.ZERO) -> bool:
	if _has_hit:
		return false
	if body is CharacterBody2D and body.player_id == owner_id:
		return false
	if explosive_radius > 0.0:
		_explode(hit_position)
		return true
	# Spread on impact: split into 3 projectiles on wall/floor hit (not on players)
	if spread_on_impact and split_generation < 1 and body is StaticBody2D:
		_split_on_impact(hit_position, hit_normal)
		return true
	if body is CharacterBody2D and body.has_method("take_damage"):
		if body.player_id == owner_id:
			return false
		var falloff := maxf(1.0 - DAMAGE_FALLOFF_RATE * _life_time, 0.4)
		var actual_damage := damage * falloff
		var dir_sign := 1 if direction.x >= 0.0 else -1
		body.take_damage(actual_damage, knockback, dir_sign)
		# Notify owner of damage dealt (used by skills like Life Steal)
		for p in body.get_tree().get_nodes_in_group("players"):
			if p.player_id == owner_id:
				p.damage_dealt.emit(actual_damage)
				break
	_spawn_impact_fx(hit_position)
	return true


func _explode(hit_position: Vector2) -> void:
	var any_hit := false
	for body in get_tree().get_nodes_in_group("players"):
		if not (body is CharacterBody2D) or not body.has_method("take_damage"):
			continue
		if body.player_id == owner_id:
			continue
		var target_center: Vector2 = body.global_position + Vector2(0.0, -32.0)
		var dist := hit_position.distance_to(target_center)
		if dist > explosive_radius:
			continue
		var falloff := _calculate_explosive_falloff(dist, explosive_radius)
		if falloff <= 0.0:
			continue
		var dir_sign := 1 if body.global_position.x >= hit_position.x else -1
		if is_equal_approx(body.global_position.x, hit_position.x):
			dir_sign = 1 if direction.x >= 0.0 else -1
		var actual_damage := damage * falloff
		var actual_knockback := knockback * falloff
		body.take_damage(actual_damage, actual_knockback, dir_sign)
		any_hit = true
		for p in body.get_tree().get_nodes_in_group("players"):
			if p.player_id == owner_id:
				p.damage_dealt.emit(actual_damage)
				break
	# Always show explosion for explosive weapons, regardless of hits
	_spawn_explosion_fx(hit_position)


func _calculate_explosive_falloff(distance: float, radius: float) -> float:
	var normalized_dist := clampf(distance / radius, 0.0, 1.0)
	return 1.0 - normalized_dist * normalized_dist


func _split_on_impact(hit_position: Vector2, hit_normal: Vector2) -> void:
	"""Split projectiles based on reflected heading and collision tangent.
	This is symmetric on left/right collisions and consistent on any surface normal."""
	var incoming := _velocity.normalized() if _velocity.length() > 0.0 else direction.normalized()
	var normal := hit_normal.normalized()
	if normal == Vector2.ZERO:
		normal = -incoming

	# Main reflected direction from surface.
	var reflected := incoming.bounce(normal).normalized()
	# Surface tangent to build mirrored side shots around the reflected path.
	var tangent := Vector2(-normal.y, normal.x).normalized()
	var side_blend := 0.55
	var spread_directions := [
		reflected,
		(reflected + tangent * side_blend).normalized(),
		(reflected - tangent * side_blend).normalized(),
	]

	# Spawn slightly away from collision point to avoid immediate re-collision with the same wall.
	var spawn_pos := hit_position + normal * 2.0

	for spread_dir in spread_directions:
		var child: Area2D = _projectile_scene.instantiate()
		child.global_position = spawn_pos
		child.call("apply_rarity_color", main_color)
		
		child.direction = spread_dir.normalized()
		child.speed = speed * 0.7  # Reduced speed for splits
		child.damage = damage * 0.65  # Reduced damage for splits
		child.knockback = knockback * 0.65
		child.explosive_radius = explosive_radius
		child.spread_on_impact = spread_on_impact
		child.split_generation = split_generation + 1
		child.owner_id = owner_id
		get_tree().current_scene.add_child(child)


var _projectile_scene := preload("res://scenes/weapon/projectile.tscn")


func _draw() -> void:
	# Draw additive-looking trail from oldest to newest points.
	if _trail_points.size() >= 2:
		for i in range(_trail_points.size() - 1):
			var from := to_local(_trail_points[i])
			var to := to_local(_trail_points[i + 1])
			var t := float(i + 1) / float(_trail_points.size())
			var col := main_color.lerp(accent_color, t)
			col.a = 0.12 + 0.52 * t
			draw_line(from, to, col, 1.2 + 3.8 * t, true)
			# Thin hot core inside the trail.
			var core := accent_color
			core.a = 0.22 + 0.55 * t
			draw_line(from, to, core, 0.8 + 1.2 * t, true)

	var pulse := 0.85 + 0.15 * sin(Time.get_ticks_msec() * 0.025)
	var perp := Vector2(-direction.y, direction.x)
	var glow := main_color
	glow.a = 0.28 * pulse
	draw_circle(Vector2.ZERO, 7.0, glow)
	var body := main_color.lerp(accent_color, 0.35)
	body.a = 0.78 * pulse
	draw_circle(Vector2.ZERO, 4.3, body)
	var core_color := accent_color
	core_color.a = 0.96
	draw_circle(Vector2.ZERO, 2.2, core_color)

	# Directional spark streaks to emphasize speed.
	var streak := direction.normalized() * 8.0
	var side := perp.normalized() * 2.1
	var spark := accent_color
	spark.a = 0.8
	draw_line(Vector2.ZERO - side, Vector2.ZERO - streak - side, spark, 1.5, true)
	draw_line(Vector2.ZERO + side, Vector2.ZERO - streak + side, spark, 1.1, true)


func _spawn_impact_fx(hit_position: Vector2) -> void:
	AudioManager.play_sfx_2d("bullet_impact", hit_position, -4.0, randf_range(0.95, 1.08))
	var fx := GPUParticles2D.new()
	fx.position = hit_position
	fx.one_shot = true
	fx.emitting = true
	fx.explosiveness = 1.0
	fx.amount = 14
	fx.lifetime = 0.18
	fx.local_coords = false
	fx.z_index = 20

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 1.0
	mat.direction = Vector3(direction.x, direction.y, 0.0)
	mat.spread = 40.0
	mat.initial_velocity_min = 120.0
	mat.initial_velocity_max = 320.0
	mat.scale_min = 0.65
	mat.scale_max = 1.25
	mat.color = main_color.lerp(accent_color, 0.35)
	mat.gravity = Vector3.ZERO
	fx.process_material = mat

	get_tree().current_scene.add_child(fx)
	fx.finished.connect(func() -> void:
		fx.queue_free()
	)


func _spawn_explosion_fx(hit_position: Vector2) -> void:
	AudioManager.play_sfx_2d("bullet_impact", hit_position, -1.0, randf_range(0.80, 0.95))
	var fx := GPUParticles2D.new()
	fx.position = hit_position
	fx.one_shot = true
	fx.emitting = true
	fx.explosiveness = 1.0
	fx.amount = 72  # Increased from 40
	fx.lifetime = 0.42  # Increased from 0.28
	fx.local_coords = false
	fx.z_index = 24

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 3.5  # Increased from 2.0
	mat.spread = 180.0
	mat.initial_velocity_min = 240.0  # Increased from 180.0
	mat.initial_velocity_max = 520.0  # Increased from 420.0
	mat.scale_min = 1.1  # Increased from 0.8
	mat.scale_max = 2.2  # Increased from 1.7
	mat.color = main_color.lerp(Color(1.0, 0.72, 0.22), 0.55)
	mat.gravity = Vector3(0.0, 60.0, 0.0)  # Slightly reduced gravity for longer hang time
	fx.process_material = mat

	get_tree().current_scene.add_child(fx)
	fx.finished.connect(func() -> void:
		fx.queue_free()
	)
