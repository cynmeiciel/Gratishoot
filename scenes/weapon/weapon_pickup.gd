extends Area2D
## A weapon lying on the ground, ready to be picked up.

var weapon_data: WeaponData
var ammo_current: int = 0
var ammo_reserve: int = 0


func init(data: WeaponData) -> void:
	weapon_data = data
	if data.type == WeaponData.Type.GUN:
		ammo_current = data.capacity
		ammo_reserve = data.reserve_ammo


func _draw() -> void:
	if not weapon_data:
		return
	var col := weapon_data.get_rarity_color()
	# Breathing pulse effect
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.0035)
	var bob_offset := sin(Time.get_ticks_msec() * 0.004) * 3.0
	var t := Time.get_ticks_msec() * 0.001

	# Outer glow rings (layered effect) - now more dramatic
	var glow1_col := col * Color(1.0, 1.0, 1.0, 0.25 * pulse)
	var glow2_col := col * Color(1.0, 1.0, 1.0, 0.12)
	draw_rect(Rect2(-26, -18, 52, 36), glow1_col)
	draw_rect(Rect2(-24, -16, 48, 32), glow2_col)
	
	# Far outer halo
	var halo_radius := 28.0 + sin(t * 2.5) * 3.0
	for i in 3:
		var halo_alpha := (0.08 - i * 0.025) * (0.5 + 0.5 * sin(t * 1.8 + i))
		draw_arc(Vector2(0, bob_offset), halo_radius + i * 4, 0.0, TAU, 32, col * Color(1, 1, 1, halo_alpha), 1.2)
	
	# Radiating sparkles
	var spark_count := 8
	for i in spark_count:
		var angle := (TAU / spark_count) * i + t * 1.5
		var spark_dist := 35.0 + sin(t * 3.0 + i) * 5.0
		var spark_pos := Vector2(cos(angle), sin(angle)) * spark_dist
		var spark_size := 1.5 + sin(t * 4.0 + i * 0.8) * 0.8
		var spark_alpha := (0.6 + 0.4 * sin(t * 2.2 + i)) * pulse
		draw_circle(spark_pos, spark_size, col * Color(1, 1, 1, spark_alpha))

	# Main weapon box (increased from 24x16 to 40x26)
	var box_rect := Rect2(-20, -13 + bob_offset, 40, 26)
	draw_rect(box_rect, col)

	# Highlight edge (lighter top)
	draw_line(Vector2(-19, -12 + bob_offset), Vector2(19, -12 + bob_offset), Color(1, 1, 1, 0.4), 2.0)

	# Label with better styling
	var font := ThemeDB.fallback_font
	var short_name := weapon_data.weapon_name.substr(0, 6)
	# Label shadow for readability
	draw_string(font, Vector2(-17, 3 + bob_offset), short_name, HORIZONTAL_ALIGNMENT_LEFT, 24, 8, Color.BLACK * Color(1, 1, 1, 0.5))
	draw_string(font, Vector2(-18, 2 + bob_offset), short_name, HORIZONTAL_ALIGNMENT_LEFT, 24, 8, Color.WHITE)

	# Enhanced glow outline (thicker and brighter)
	draw_rect(box_rect.grow_individual(2, 2, 2, 2), col * 1.5, false, 2.2)
	draw_rect(box_rect.grow_individual(4, 4, 4, 4), col * 1.2, false, 1.0)
