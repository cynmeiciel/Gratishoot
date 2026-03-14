extends Camera2D
## Dynamic camera based on two-player distance with map limits.

# Width n Height
var _W: float
var _H: float
const WMIN_ZOOM_DIST := 1000.0
var HMIN_ZOOM_DIST: float
const MARGIN := 450.0

# Fallback stage dimensions for arenas that do not expose WIDTH/HEIGHT.
@export var stage_width := 3400.0
@export var stage_height := 980.0
@export var world_left := 0.0
@export var world_top := 0.0
@export var world_right := 3400.0
@export var world_bottom := 980.0
@export var world_padding := 50.0

@onready var player_1: CharacterBody2D = get_node_or_null("../Player1")
@onready var player_2: CharacterBody2D = get_node_or_null("../Player2")


func get_new_pos() -> Vector2:
	return (player_1.global_position + player_2.global_position) * 0.5


# Get the fancy zoom so that both players can have their spots
func get_new_zoom() -> Vector2:
	var p_dist_vec: Vector2 = (player_1.global_position - player_2.global_position).abs()
	var dist_x := maxf(p_dist_vec.x, 1.0)
	var dist_y := maxf(p_dist_vec.y, 1.0)
	var _zoom: float

	if dist_x > dist_y * (_W / _H):
		_zoom = clampf(_W / dist_x, _W / stage_width, _W / WMIN_ZOOM_DIST)
	else:
		_zoom = clampf(_H / dist_y, _H / stage_height, _H / HMIN_ZOOM_DIST)

	return Vector2(_zoom, _zoom)


# Set the limits. This method should be reusable for every map/stage
func _ready() -> void:
	await owner.ready
	# Keep world bounds in sync with stage dimensions by default.
	if world_right <= world_left:
		world_right = world_left + stage_width
	if world_bottom <= world_top:
		world_bottom = world_top + stage_height

	limit_left = int(world_left - world_padding)
	limit_top = int(world_top - world_padding)
	limit_right = int(world_right + world_padding)
	limit_bottom = int(world_bottom + world_padding)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if player_1 == null or player_2 == null:
		return

	_W = get_viewport_rect().size.x - MARGIN
	_H = get_viewport_rect().size.y - MARGIN
	if _W <= 1.0 or _H <= 1.0:
		return

	HMIN_ZOOM_DIST = WMIN_ZOOM_DIST * _H / _W
	position = get_new_pos()
	zoom = get_new_zoom()
