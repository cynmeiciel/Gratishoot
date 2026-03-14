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
	# Weapon box
	draw_rect(Rect2(-12, -8, 24, 16), col)
	# Small label
	var font := ThemeDB.fallback_font
	var short_name := weapon_data.weapon_name.substr(0, 6)
	draw_string(font, Vector2(-10, 4), short_name, HORIZONTAL_ALIGNMENT_LEFT, 24, 8, Color.BLACK)
	# Glow outline
	draw_rect(Rect2(-13, -9, 26, 18), col * 1.3, false, 1.5)
