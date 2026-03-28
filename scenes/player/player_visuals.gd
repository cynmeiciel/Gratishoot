extends Node2D
## Handles all placeholder visual drawing for the player character.

const CROSSHAIR_RAY_MASK := 5  # Match projectile mask: World + Player, excludes one-way platforms.
const TACTICAL_PREDICTION_MASK := 3  # World + one-way platforms.
const TACTICAL_PREDICTION_STEPS := 72
const TACTICAL_PREDICTION_STEP_TIME := 1.0 / 60.0

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var player: CharacterBody2D = get_parent()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if player.is_dead:
		draw_line(Vector2(-12, -48), Vector2(12, -16), Color.RED, 3.0)
		draw_line(Vector2(-12, -16), Vector2(12, -48), Color.RED, 3.0)
		return
	var vis_alpha: float = player.get_visual_alpha()
	if vis_alpha <= 0.01:
		return

	var h: float = $"../StandingCollision".shape.size.y if not player.is_crouching else $"../CrouchingCollision".shape.size.y
	var body_color: Color = player.player_color
	if player._hit_stun_timer > 0.0:
		body_color = Color.WHITE
	body_color.a *= vis_alpha
	draw_rect(Rect2(-16, -h, 32, h), body_color)

	# Eye
	var eye_col := Color.WHITE
	eye_col.a *= vis_alpha
	draw_circle(Vector2(4.0 * player.facing_direction, -h + 12.0), 4.0, eye_col)

	# Aim line
	if player.is_aiming:
		var aim_dir := Vector2(player.facing_direction, 0.0).rotated(player.aim_pitch * player.facing_direction)
		var aim_start := Vector2(16.0 * player.facing_direction, -32.0)
		var aim_len := _get_aim_line_length()
		var aim_end := aim_start + aim_dir * aim_len
		draw_line(aim_start, aim_end, Color(1, 0.2, 0.2, 0.62), 1.5)

		# Scoped classes show an impact crosshair where the shot ray would land.
		if player.current_gun and (player.current_gun.gun_category == WeaponData.GunCategory.DMR or player.current_gun.gun_category == WeaponData.GunCategory.SNIPER):
			var crosshair_len := _get_scope_crosshair_length()
			var impact_global := _get_aim_impact_point_global(aim_start, aim_dir, crosshair_len)
			var impact_local := to_local(impact_global)
			_draw_impact_crosshair(impact_local)

	if player.is_tactical_aiming:
		_draw_tactical_prediction(h)

	# Attack visual
	if player._attack_visual_timer > 0.0:
		var m_range: float = player.FIST_RANGE
		var fist_y := -32.0
		var style := WeaponData.MeleeStyle.SWEEP
		var thickness := 3.0
		if player.current_melee:
			m_range = player.current_melee.melee_range
			fist_y = player.current_melee.melee_hitbox_y
			if player.attack_type == 2:
				fist_y += player.current_melee.melee_secondary_y_offset
			style = player.current_melee.melee_style
			thickness = player.current_melee.melee_visual_thickness
		var fist_x: float = m_range * player.facing_direction
		if player.current_melee:
			var wep_col: Color = player.current_melee.get_rarity_color()
			match style:
				WeaponData.MeleeStyle.THRUST:
					draw_line(Vector2(0, fist_y), Vector2(fist_x, fist_y), wep_col, thickness)
					# spear tip cue
					draw_circle(Vector2(fist_x, fist_y), 2.0 + thickness * 0.45, wep_col)
				WeaponData.MeleeStyle.HEAVY:
					# heavy overhead smash arc
					var arc_center := Vector2(0, fist_y)
					draw_arc(arc_center, m_range * 0.75, -1.8, -0.2, 18, wep_col, thickness + 1.2)
				WeaponData.MeleeStyle.SWEEP:
					# horizontal sweep
					draw_line(Vector2(0, fist_y), Vector2(fist_x, fist_y), wep_col, thickness)
					var sweep_mid := Vector2(fist_x * 0.6, fist_y - 3.0)
					draw_line(Vector2(0, fist_y), sweep_mid, wep_col * Color(1, 1, 1, 0.6), maxf(1.0, thickness - 1.0))
		else:
			var fist_size := 10.0 if player.attack_type == 1 else 14.0
			var fist_color := Color.WHITE if player.attack_type == 1 else Color(1.0, 0.8, 0.2)
			draw_circle(Vector2(fist_x, fist_y), fist_size, fist_color)

	# Equip timer visual
	if player._equip_timer > 0.0:
		var equip_total := 0.0
		if player.current_gun and player.current_gun.equip_time > 0.0:
			equip_total = player.current_gun.equip_time
		elif player.current_melee and player.current_melee.equip_time > 0.0:
			equip_total = player.current_melee.equip_time
		if equip_total > 0.0:
			var progress: float = 1.0 - (player._equip_timer / equip_total)
			draw_rect(Rect2(-16, 4, 32.0 * progress, 3), Color(0.5, 0.8, 1.0))

	_draw_reload_indicator(h)

	# Freeze overlay
	if player.is_frozen:
		draw_rect(Rect2(-18, -h - 2, 36, h + 2), Color(0.3, 0.7, 1.0, 0.35))

	if player.shield_amount > 0.0:
		var frac := clampf(player.shield_amount / 50.0, 0.0, 1.0)
		var shield_col := Color(0.36, 0.86, 1.0, 0.20 + 0.28 * frac)
		draw_arc(Vector2(0, -h * 0.58), 26.0 + 8.0 * (1.0 - frac), 0.0, TAU, 40, shield_col, 2.3)

	if player.confusion_timer > 0.0:
		var swirl := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
		draw_circle(Vector2(-8, -h - 8), 2.2, Color(0.95, 0.4, 1.0, 0.45 + 0.4 * swirl))
		draw_circle(Vector2(8, -h - 8), 2.2, Color(0.95, 0.4, 1.0, 0.45 + 0.4 * (1.0 - swirl)))

	# Jetpack flame
	if player.is_jetpacking:
		draw_circle(Vector2(-4, 2), 5.0, Color(1.0, 0.5, 0.0, 0.8))
		draw_circle(Vector2(4, 2), 5.0, Color(1.0, 0.5, 0.0, 0.8))
		draw_circle(Vector2(0, 6), 4.0, Color(1.0, 0.8, 0.2, 0.6))

	# Life steal glow
	if player.skill.is_active() and player.skill.get_skill_name() == "Life Steal":
		draw_rect(Rect2(-18, -h - 2, 36, h + 2), Color(0.8, 0.1, 0.3, 0.25))


func _draw_reload_indicator(body_height: float) -> void:
	if not player.is_reloading or player.current_gun == null:
		return
	var reload_total := maxf(player.current_gun.reload_time, 0.001)
	var progress := clampf(1.0 - (player._reload_timer / reload_total), 0.0, 1.0)

	var t := Time.get_ticks_msec() * 0.001
	var pulse := sin(t * 8.0) * 1.2
	var center := Vector2(0.0, -body_height - 20.0)
	var radius := 11.0 + pulse

	# Outer background ring.
	draw_arc(center, radius, 0.0, TAU, 40, Color(0.07, 0.1, 0.14, 0.8), 3.0)
	# Progress ring sweeps clockwise from top.
	draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 40, Color(0.32, 0.88, 1.0, 0.95), 3.2)
	# Inner core glow for readability.
	draw_circle(center, 2.2, Color(0.72, 0.94, 1.0, 0.9))


func _get_aim_line_length() -> float:
	if not player.current_gun:
		return 80.0
	match player.current_gun.gun_category:
		WeaponData.GunCategory.PISTOL:
			return 95.0
		WeaponData.GunCategory.SMG:
			return 82.0
		WeaponData.GunCategory.SHOTGUN:
			return 70.0
		WeaponData.GunCategory.ASSAULT_RIFLE:
			return 125.0
		WeaponData.GunCategory.LMG:
			return 118.0
		WeaponData.GunCategory.BATTLE_RIFLE:
			return 152.0
		WeaponData.GunCategory.DMR:
			return 200.0
		WeaponData.GunCategory.SNIPER:
			return 240.0
		_:
			return 100.0


func _get_scope_crosshair_length() -> float:
	if not player.current_gun:
		return 1000.0
	match player.current_gun.gun_category:
		WeaponData.GunCategory.DMR:
			return 1400.0
		WeaponData.GunCategory.SNIPER:
			return 1900.0
		_:
			return 1000.0


func _get_aim_impact_point_global(aim_start_local: Vector2, aim_dir: Vector2, max_length: float) -> Vector2:
	var from := to_global(aim_start_local)
	var to := from + aim_dir * max_length
	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.collision_mask = CROSSHAIR_RAY_MASK
	query.exclude = [player]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		return hit.position
	return to


func _draw_impact_crosshair(pos: Vector2) -> void:
	var c := Color(1.0, 0.25, 0.25, 0.85)
	draw_circle(pos, 7.0, c * Color(1, 1, 1, 0.2))
	draw_line(pos + Vector2(-20, 0), pos + Vector2(-7, 0), c, 1.4)
	draw_line(pos + Vector2(7, 0), pos + Vector2(20, 0), c, 1.4)
	draw_line(pos + Vector2(0, -20), pos + Vector2(0, -7), c, 1.4)
	draw_line(pos + Vector2(0, 7), pos + Vector2(0, 20), c, 1.4)


func _draw_tactical_prediction(body_height: float) -> void:
	if player.current_tactical == null:
		return
	var velocity: Vector2 = player.get_tactical_throw_velocity()
	if velocity == Vector2.ZERO:
		return

	var tac_color: Color = player.current_tactical.get_color()
	var point_color := tac_color
	point_color.a = 0.55
	var path_color := tac_color
	path_color.a = 0.75

	var from_global := to_global(Vector2(16.0 * player.facing_direction, -32.0))
	var prev_global := from_global
	var landing_global := Vector2.ZERO
	var has_landing := false

	for i in TACTICAL_PREDICTION_STEPS:
		velocity.y += _gravity * TACTICAL_PREDICTION_STEP_TIME
		var next_global := prev_global + velocity * TACTICAL_PREDICTION_STEP_TIME

		var query := PhysicsRayQueryParameters2D.create(prev_global, next_global)
		query.collide_with_bodies = true
		query.collide_with_areas = false
		query.collision_mask = TACTICAL_PREDICTION_MASK
		query.exclude = [player]
		var hit := get_world_2d().direct_space_state.intersect_ray(query)

		var from_local := to_local(prev_global)
		if not hit.is_empty():
			var hit_local := to_local(hit.position)
			draw_line(from_local, hit_local, path_color, 1.8, true)
			draw_circle(hit_local, 2.4, point_color)
			landing_global = hit.position
			has_landing = true
			break

		var to_local_point := to_local(next_global)
		var t := float(i + 1) / float(TACTICAL_PREDICTION_STEPS)
		var segment := path_color
		segment.a *= 0.35 + 0.65 * (1.0 - t)
		draw_line(from_local, to_local_point, segment, 1.3 + 0.7 * (1.0 - t), true)
		draw_circle(to_local_point, 1.8, point_color)
		prev_global = next_global

	if has_landing:
		var landing_local := to_local(landing_global)
		var ring_color := tac_color
		ring_color.a = 0.18
		draw_circle(landing_local, 5.0, Color(1, 1, 1, 0.9))
		draw_arc(landing_local, player.current_tactical.radius, 0.0, TAU, 42, ring_color, 1.8)
		# Vertical hint line helps visibility in busy scenes.
		draw_line(landing_local + Vector2(0, -10), landing_local + Vector2(0, -24 - body_height * 0.08), Color(1, 1, 1, 0.42), 1.0)
