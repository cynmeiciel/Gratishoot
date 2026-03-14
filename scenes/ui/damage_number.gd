extends Node2D
## Small floating damage number that rises, fades, and removes itself.

var amount: float = 0.0
var text_color: Color = Color(1.0, 0.92, 0.92)

var _lifetime := 0.75
var _time := 0.0
var _velocity := Vector2.ZERO


func init(value: float, color: Color = Color(1.0, 0.92, 0.92)) -> void:
	amount = value
	text_color = color
	_velocity = Vector2(randf_range(-18.0, 18.0), randf_range(-70.0, -52.0))


func _ready() -> void:
	add_to_group("ephemeral_fx")
	z_index = 100
	scale = Vector2.ONE * 0.9


func _process(delta: float) -> void:
	_time += delta
	if _time >= _lifetime:
		queue_free()
		return

	global_position += _velocity * delta
	_velocity.y += 120.0 * delta

	var t := _time / _lifetime
	modulate.a = 1.0 - t
	var pop := 1.0 + sin(minf(t * PI, PI)) * 0.18
	scale = Vector2.ONE * pop
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var text := str(int(round(amount)))
	var size := 14
	var width := 64
	var baseline := 0.0
	var outline := Color(0.08, 0.02, 0.02, 0.95)
	for off in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		draw_string(font, off + Vector2(-32.0, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, width, size, outline)
	draw_string(font, Vector2(-32.0, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, width, size, text_color)
