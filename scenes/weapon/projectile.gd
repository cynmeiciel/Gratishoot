extends Area2D
## A bullet projectile that flies, deals damage on hit, and loses damage over distance.

var direction := Vector2.RIGHT
var speed := 800.0
var damage := 10.0
var knockback := 150.0
var owner_id: int = -1

var _start_position: Vector2
var _life_time := 0.0
const DAMAGE_FALLOFF_RATE := 0.35  # fraction of damage lost per second in flight
const MAX_DISTANCE := 1500.0


func _ready() -> void:
	add_to_group("projectiles")
	_start_position = global_position
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
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
		if _apply_hit(hit.collider):
			queue_free()
			return

	global_position = to
	var dist := global_position.distance_to(_start_position)
	if dist > MAX_DISTANCE:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if _apply_hit(body):
		queue_free()


func _apply_hit(body: Node2D) -> bool:
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
	return true


func _draw() -> void:
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.9, 0.3))
