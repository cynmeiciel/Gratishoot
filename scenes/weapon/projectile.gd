extends Area2D
## A bullet projectile that flies, deals damage on hit, and loses damage over distance.

var direction := Vector2.RIGHT
var speed := 800.0
var damage := 10.0
var knockback := 150.0
var owner_id: int = -1
var main_color: Color = Color(1.0, 0.78, 0.22, 1.0)
var accent_color: Color = Color(1.0, 0.95, 0.75, 1.0)

var _start_position: Vector2
var _life_time := 0.0
var _trail_points: PackedVector2Array = PackedVector2Array()
var _has_hit := false
const DAMAGE_FALLOFF_RATE := 0.85  # fraction of damage lost per second in flight
const MAX_DISTANCE := 10000.0
const TRAIL_POINTS_MAX := 10


func apply_rarity_color(rarity_color: Color) -> void:
	main_color = rarity_color
	accent_color = rarity_color.lerp(Color.WHITE, 0.65)


func _ready() -> void:
	add_to_group("projectiles")
	_start_position = global_position
	_trail_points.append(global_position)


func _physics_process(delta: float) -> void:
	if _has_hit:
		return
	_life_time += delta
	var from := global_position
	var to := from + direction * speed * delta

	# Sweep test prevents high-speed bullets from tunneling through targets.
	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = collision_mask
	query.exclude = [self]
	for p in get_tree().get_nodes_in_group("players"):
		if p.player_id == owner_id:
			query.exclude.append(p)

	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		global_position = hit.position
		if _apply_hit(hit.collider, hit.position):
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


func _apply_hit(body: Node2D, hit_position: Vector2) -> bool:
	if _has_hit:
		return false
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
