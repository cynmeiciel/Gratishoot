extends Area2D
## A tactical item lying on the ground, ready to be picked up.

var tactical_data: TacticalData


func init(data: TacticalData) -> void:
	tactical_data = data


func _draw() -> void:
	if not tactical_data:
		return
	var col := tactical_data.get_color()
	# Diamond shape for tactical items
	var points := PackedVector2Array([
		Vector2(0, -10), Vector2(10, 0), Vector2(0, 10), Vector2(-10, 0)
	])
	draw_colored_polygon(points, col)
	draw_polyline(points + PackedVector2Array([points[0]]), Color.WHITE, 1.5)
	# Label
	var font := ThemeDB.fallback_font
	var short := tactical_data.item_name.substr(0, 6)
	draw_string(font, Vector2(-12, 18), short, HORIZONTAL_ALIGNMENT_LEFT, 28, 7, col)
