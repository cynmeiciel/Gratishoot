extends Area2D
## A tactical item lying on the ground, ready to be picked up.

var tactical_data: TacticalData


func init(data: TacticalData) -> void:
	tactical_data = data


func _draw() -> void:
	if not tactical_data:
		return
	var col := tactical_data.get_color()
	# Breathing pulse and rotation effect
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.0035)
	var rotation_sin := sin(Time.get_ticks_msec() * 0.003)
	var bob_offset := sin(Time.get_ticks_msec() * 0.004) * 4.0
	var t := Time.get_ticks_msec() * 0.001

	# Outer glow rings (larger tactical visual presence) - more dramatic
	var glow_col := col * Color(1.0, 1.0, 1.0, 0.18 * pulse)
	draw_circle(Vector2(0, bob_offset), 22.0, glow_col)
	draw_circle(Vector2(0, bob_offset), 19.0, Color(1, 1, 1, 0.08))
	
	# Concentric pulsing halos
	for h in 3:
		var halo_radius := 26.0 + h * 6.0
		var halo_pulse := sin(t * 2.0 - h * PI / 3.0)
		var halo_alpha := 0.08 * (0.5 + 0.5 * halo_pulse)
		draw_arc(Vector2(0, bob_offset), halo_radius, 0.0, TAU, 40, col * Color(1, 1, 1, halo_alpha), 1.5)
	
	# Orbiting sparkles around diamond
	var sparkle_count := 12
	for s in sparkle_count:
		var orbit_angle := (TAU / sparkle_count) * s + t * 2.0
		var orbit_radius := 32.0 + sin(t * 3.5 + s) * 6.0
		var sparkle_pos := Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius
		var sparkle_size := 1.2 + sin(t * 3.8 + s * 0.6) * 0.6
		var sparkle_alpha := (0.5 + 0.5 * sin(t * 2.5 + s)) * pulse
		draw_circle(sparkle_pos, sparkle_size, col * Color(1, 1, 1, sparkle_alpha))

	# Enlarged diamond shape (increased from 20x20 to 32x32)
	var scale_factor := 1.0 + rotation_sin * 0.08  # Slight wobble
	var points := PackedVector2Array([
		Vector2(0, -15 * scale_factor), 
		Vector2(15 * scale_factor, 0), 
		Vector2(0, 15 * scale_factor), 
		Vector2(-15 * scale_factor, 0)
	])
	# Offset all points by bob
	for i in range(points.size()):
		points[i].y += bob_offset

	# Inner core glow
	draw_circle(Vector2(0, bob_offset), 10.0, col * Color(1, 1, 1, 0.3))

	# Main polygon
	draw_colored_polygon(points, col)

	# Enhanced outline with highlights
	draw_polyline(points + PackedVector2Array([points[0]]), Color.WHITE * Color(1, 1, 1, 0.7), 2.2)
	# Inner highlight (scaled down diamond)
	var inner_points := PackedVector2Array([
		Vector2(0, -9 * scale_factor),
		Vector2(9 * scale_factor, 0),
		Vector2(0, 9 * scale_factor),
		Vector2(-9 * scale_factor, 0),
		Vector2(0, -9 * scale_factor)
	])
	for i in range(inner_points.size()):
		inner_points[i].y += bob_offset
	draw_polyline(inner_points, Color.WHITE, 1.0)

	# Label with better styling
	var font := ThemeDB.fallback_font
	var short := tactical_data.item_name.substr(0, 6)
	# Label shadow
	draw_string(font, Vector2(-14, 22 + bob_offset), short, HORIZONTAL_ALIGNMENT_LEFT, 28, 7, Color.BLACK * Color(1, 1, 1, 0.4))
	draw_string(font, Vector2(-15, 21 + bob_offset), short, HORIZONTAL_ALIGNMENT_LEFT, 28, 7, col * Color(1, 1, 1, 1.2))
