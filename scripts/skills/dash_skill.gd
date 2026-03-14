class_name DashSkill
extends BaseSkill
## Tsutaya's Instant Dash — teleport forward in facing direction, stopping at walls.

const DASH_DISTANCE := 180.0


func get_skill_name() -> String:
	return "Dash"


func get_color() -> Color:
	return Color.CYAN


func activate(player: CharacterBody2D) -> void:
	super.activate(player)
	var target := player.global_position + Vector2(DASH_DISTANCE * player.facing_direction, 0)
	var space := player.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		player.global_position + Vector2(0, -32),
		target + Vector2(0, -32),
		player.collision_mask
	)
	query.exclude = [player.get_rid()]
	var result := space.intersect_ray(query)
	if result:
		player.global_position.x = result.position.x - 16.0 * player.facing_direction
	else:
		player.global_position = target
