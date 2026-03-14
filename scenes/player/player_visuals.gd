extends Node2D
## Handles all placeholder visual drawing for the player character.

const CROSSHAIR_RAY_MASK := 5  # Match projectile mask: World + Player, excludes one-way platforms.

@onready var player: CharacterBody2D = get_parent()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if player.is_dead:
		draw_line(Vector2(-12, -48), Vector2(12, -16), Color.RED, 3.0)
		draw_line(Vector2(-12, -16), Vector2(12, -48), Color.RED, 3.0)
		return

	var h := 64.0 if not player.is_crouching else 32.0
	var body_color: Color = player.player_color
	if player._hit_stun_timer > 0.0:
		body_color = Color.WHITE
	draw_rect(Rect2(-16, -h, 32, h), body_color)

	# Eye
	draw_circle(Vector2(4.0 * player.facing_direction, -h + 12.0), 4.0, Color.WHITE)

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

	# Freeze overlay
	if player.is_frozen:
		draw_rect(Rect2(-18, -h - 2, 36, h + 2), Color(0.3, 0.7, 1.0, 0.35))

	# Jetpack flame
	if player.is_jetpacking:
		draw_circle(Vector2(-4, 2), 5.0, Color(1.0, 0.5, 0.0, 0.8))
		draw_circle(Vector2(4, 2), 5.0, Color(1.0, 0.5, 0.0, 0.8))
		draw_circle(Vector2(0, 6), 4.0, Color(1.0, 0.8, 0.2, 0.6))

	# Life steal glow
	if player.skill.is_active():
		draw_rect(Rect2(-18, -h - 2, 36, h + 2), Color(0.8, 0.1, 0.3, 0.25))


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
	draw_circle(pos, 3.0, c * Color(1, 1, 1, 0.2))
	draw_line(pos + Vector2(-8, 0), pos + Vector2(-3, 0), c, 1.4)
	draw_line(pos + Vector2(3, 0), pos + Vector2(8, 0), c, 1.4)
	draw_line(pos + Vector2(0, -8), pos + Vector2(0, -3), c, 1.4)
	draw_line(pos + Vector2(0, 3), pos + Vector2(0, 8), c, 1.4)
