extends CharacterBody2D

enum Character { TSUTAYA, AICHOK }

@export var player_id: int = 1
@export var player_color: Color = Color(0.2, 0.6, 1.0)
@export var character: Character = Character.TSUTAYA

signal died(player_id: int)
signal damage_dealt(amount: float)

# Movement
const SPEED := 200.0
const SPRINT_SPEED := 300.0
const JUMP_VELOCITY := -580.0
const DECELERATION := 1200.0
const MAX_AIR_JUMPS := 1

# Stamina
const STAMINA_MAX := 100.0
const STAMINA_DRAIN := 30.0
const STAMINA_REGEN := 20.0
var stamina := STAMINA_MAX
var stamina_depleted := false

# HP
const HP_MAX := 100.0
const HP_REGEN_DELAY := 2.0   # seconds after last hit before regen begins
const HP_REGEN_RATE  := 8.0   # HP per second during regen
var hp := HP_MAX
var _regen_timer := 0.0

# Combat — bare fist defaults
const FIST_DAMAGE := 8.0
const FIST_SECONDARY_DAMAGE := 12.0
const FIST_KNOCKBACK := 250.0
const FIST_SECONDARY_KNOCKBACK := 400.0
const FIST_RANGE := 40.0
const ATTACK_COOLDOWN := 0.35
const SECONDARY_COOLDOWN := 0.6
const HIT_STUN_DURATION := 0.2
const SPAWN_INVULN_DURATION := 0.6

var _attack_timer := 0.0
var _hit_stun_timer := 0.0
var _spawn_invuln_timer := 0.0
var is_attacking := false
var attack_type := 0  # 0=none, 1=primary, 2=secondary
var _attack_visual_timer := 0.0
const ATTACK_VISUAL_DURATION := 0.15

# Weapon — separate slots for gun and melee
var current_gun: WeaponData = null
var current_melee: WeaponData = null
var ammo_current: int = 0
var ammo_reserve: int = 0
var is_reloading := false
var _reload_timer := 0.0
var _equip_timer := 0.0
var _burst_remaining := 0
var _burst_timer := 0.0

# Aim mode (guns only)
var is_aiming := false
var aim_pitch := 0.0  # radians, 0 = straight, negative = up, positive = down
const AIM_PITCH_SPEED := 1.3  # rad/s
const AIM_PITCH_MAX := 1.5
const AIM_PISTOL_SPEED_MULT := 0.8

# Tactical item slot
var current_tactical: TacticalData = null

# Freeze debuff
var is_frozen := false
var _freeze_timer := 0.0

# Jetpack
var is_jetpacking := false
var _jetpack_timer := 0.0
var _jetpack_force := -500.0

# Character skill (see scripts/skills/)
var skill: BaseSkill

# Projectile scene
var _projectile_scene: PackedScene
var _damage_number_scene: PackedScene
var _pickup_scene: PackedScene
var _thrown_tactical_scene: PackedScene
var _tactical_pickup_scene: PackedScene

# State
var is_crouching := false
var is_sprinting := false
var facing_direction := 1  # 1 = right, -1 = left
var is_dead := false

# Coyote time (grace jump after walking off an edge)
const COYOTE_TIME := 0.12
var _coyote_timer := 0.0
var _air_jumps_left := MAX_AIR_JUMPS

# Descend through one-way platforms
const DESCEND_TAP_WINDOW := 0.3
var _descend_timer := 0.0
var _descend_tap_count := 0

# Node references
@onready var standing_collision: CollisionShape2D = $StandingCollision
@onready var crouching_collision: CollisionShape2D = $CrouchingCollision
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_collision: CollisionShape2D = $Hitbox/HitboxShape
@onready var pickup_area: Area2D = $PickupArea

var _input_prefix: String
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# AI control
var is_ai_controlled := false
var ai_target: CharacterBody2D = null
var _ai_actions: Dictionary = {}
var _ai_prev_actions: Dictionary = {}
var _ai_shot_timer := 0.0
var _ai_melee_timer := 0.0
var _ai_jump_timer := 0.0
var _ai_strafe_dir := 1
var _ai_strafe_timer := 0.0
var _ai_stuck_timer := 0.0
var _ai_skill_timer := 0.0
var _ai_item_timer := 0.0
var _ai_last_pos := Vector2.ZERO


func _ready() -> void:
	_input_prefix = "p%d_" % player_id
	for action in ["left", "right", "jump", "crouch", "attack", "secondary", "sprint", "skill", "item", "reload"]:
		_ai_actions[action] = false
		_ai_prev_actions[action] = false
	add_to_group("players")
	_init_skill()
	_projectile_scene = load("res://scenes/weapon/projectile.tscn")
	_damage_number_scene = load("res://scenes/ui/damage_number.tscn")
	_pickup_scene = load("res://scenes/weapon/weapon_pickup.tscn")
	_thrown_tactical_scene = load("res://scenes/tactical/thrown_tactical.tscn")
	_tactical_pickup_scene = load("res://scenes/tactical/tactical_pickup.tscn")
	hitbox_collision.disabled = true
	hitbox.body_entered.connect(_on_hitbox_body_entered)


func _init_skill() -> void:
	match character:
		Character.TSUTAYA:
			skill = DashSkill.new()
		Character.AICHOK:
			skill = LifeStealSkill.new()
	damage_dealt.connect(func(amount: float): skill.on_damage_dealt(self, amount))


func set_ai_control(enabled: bool, target: CharacterBody2D) -> void:
	is_ai_controlled = enabled
	ai_target = target
	for action in _ai_actions.keys():
		_ai_actions[action] = false
		_ai_prev_actions[action] = false
	_ai_shot_timer = 0.0
	_ai_melee_timer = 0.0
	_ai_jump_timer = 0.0
	_ai_strafe_dir = 1 if randf() < 0.5 else -1
	_ai_strafe_timer = randf_range(0.35, 0.9)
	_ai_stuck_timer = 0.0
	_ai_skill_timer = randf_range(1.0, 2.4)
	_ai_item_timer = randf_range(1.5, 3.0)
	_ai_last_pos = global_position


func _action_name(suffix: String) -> String:
	return _input_prefix + suffix


func _is_pressed(suffix: String) -> bool:
	if is_ai_controlled:
		return bool(_ai_actions.get(suffix, false))
	return Input.is_action_pressed(_action_name(suffix))


func _is_just_pressed(suffix: String) -> bool:
	if is_ai_controlled:
		var now := bool(_ai_actions.get(suffix, false))
		var prev := bool(_ai_prev_actions.get(suffix, false))
		return now and not prev
	return Input.is_action_just_pressed(_action_name(suffix))


func _get_axis(neg_suffix: String, pos_suffix: String) -> float:
	if is_ai_controlled:
		var neg := 1.0 if _is_pressed(neg_suffix) else 0.0
		var pos := 1.0 if _is_pressed(pos_suffix) else 0.0
		return pos - neg
	return Input.get_axis(_action_name(neg_suffix), _action_name(pos_suffix))


func _update_ai_input(delta: float) -> void:
	for k in _ai_prev_actions.keys():
		_ai_prev_actions[k] = _ai_actions[k]
	for k in _ai_actions.keys():
		_ai_actions[k] = false

	if ai_target == null or ai_target.is_dead:
		for p in get_tree().get_nodes_in_group("players"):
			if p != self and not p.is_dead:
				ai_target = p
				break
	if ai_target == null:
		return

	var to_target := ai_target.global_position - global_position
	var dist_x := absf(to_target.x)
	var dist_y := to_target.y
	var desired_dir := -1 if to_target.x < 0.0 else 1
	var hp_frac := hp / HP_MAX

	var has_gun := current_gun != null and ammo_current > 0
	var melee_range := current_melee.melee_range if current_melee else FIST_RANGE
	var in_melee := dist_x <= melee_range + 22.0
	var preferred_range := 220.0
	if current_gun:
		match current_gun.gun_category:
			WeaponData.GunCategory.SMG, WeaponData.GunCategory.PISTOL:
				preferred_range = 170.0
			WeaponData.GunCategory.SHOTGUN:
				preferred_range = 115.0
			WeaponData.GunCategory.ASSAULT_RIFLE:
				preferred_range = 230.0
			WeaponData.GunCategory.BATTLE_RIFLE, WeaponData.GunCategory.DMR:
				preferred_range = 300.0
			WeaponData.GunCategory.SNIPER:
				preferred_range = 420.0
			WeaponData.GunCategory.LMG:
				preferred_range = 260.0

	# Movement planner: chase, hold spacing, or retreat when low.
	var move_dir := 0
	if has_gun and not in_melee:
		if hp_frac < 0.28 and dist_x < preferred_range * 0.8:
			move_dir = -desired_dir
		elif dist_x > preferred_range + 45.0:
			move_dir = desired_dir
		elif dist_x < preferred_range - 65.0:
			move_dir = -desired_dir
		else:
			_ai_strafe_timer -= delta
			if _ai_strafe_timer <= 0.0:
				_ai_strafe_dir = -_ai_strafe_dir if randf() < 0.68 else desired_dir
				_ai_strafe_timer = randf_range(0.25, 0.65)
			move_dir = _ai_strafe_dir
	else:
		if dist_x > melee_range + 10.0:
			move_dir = desired_dir

	if move_dir < 0:
		_ai_actions["left"] = true
	elif move_dir > 0:
		_ai_actions["right"] = true

	if move_dir != 0 and dist_x > preferred_range + 90.0 and not is_aiming:
		_ai_actions["sprint"] = true

	# Aim and fire logic.
	var should_aim := has_gun and not in_melee and dist_x < preferred_range * 2.25 and absf(dist_y) < 360.0
	if should_aim:
		_ai_actions["secondary"] = true
		# Hold facing toward target while aiming.
		if desired_dir < 0:
			_ai_actions["left"] = true
		else:
			_ai_actions["right"] = true

		# Predictive aim: lead moving targets based on projectile speed.
		var muzzle := global_position + Vector2(20.0 * facing_direction, -32.0)
		var predicted_target := ai_target.global_position + Vector2(0, -32)
		var bullet_speed := maxf(current_gun.velocity, 1.0)
		var travel_time := clampf(muzzle.distance_to(predicted_target) / bullet_speed, 0.0, 0.45)
		predicted_target += ai_target.velocity * travel_time

		var to_predicted := predicted_target - muzzle
		var horizontal := maxf(absf(to_predicted.x), 1.0)
		var desired_pitch := atan2(to_predicted.y, horizontal) * facing_direction
		desired_pitch = clampf(desired_pitch, -AIM_PITCH_MAX, AIM_PITCH_MAX)
		var pitch_error := desired_pitch - aim_pitch

		# Reuse jump/crouch virtual inputs to steer aim pitch smoothly.
		if pitch_error > 0.03:
			_ai_actions["crouch"] = true
		elif pitch_error < -0.03:
			_ai_actions["jump"] = true

		_ai_shot_timer -= delta
		if _ai_shot_timer <= 0.0:
			var aim_tolerance := 0.11
			match current_gun.gun_category:
				WeaponData.GunCategory.SHOTGUN:
					aim_tolerance = 0.22
				WeaponData.GunCategory.SMG, WeaponData.GunCategory.PISTOL:
					aim_tolerance = 0.15
				WeaponData.GunCategory.ASSAULT_RIFLE, WeaponData.GunCategory.LMG:
					aim_tolerance = 0.12
				WeaponData.GunCategory.BATTLE_RIFLE, WeaponData.GunCategory.DMR:
					aim_tolerance = 0.085
				WeaponData.GunCategory.SNIPER:
					aim_tolerance = 0.055
				_:
					aim_tolerance = 0.11

			# Be stricter at long range so AI doesn't dump ammo wildly.
			aim_tolerance *= clampf(1.25 - dist_x / 700.0, 0.55, 1.25)
			if absf(pitch_error) <= aim_tolerance:
				_ai_actions["attack"] = true
			var cadence := current_gun.get_attack_cooldown()
			if current_gun.fire_mode == WeaponData.FireMode.AUTO:
				cadence = maxf(0.05, cadence * 0.8)
			_ai_shot_timer = maxf(cadence, 0.06)
	elif in_melee:
		_ai_melee_timer -= delta
		if _ai_melee_timer <= 0.0:
			_ai_actions["attack"] = true
			if randf() < 0.28:
				_ai_actions["secondary"] = true
			_ai_melee_timer = randf_range(0.2, 0.46)
	elif current_gun and ammo_current <= 0 and ammo_reserve > 0:
		_ai_actions["reload"] = true

	# Jump planning: target altitude and stuck-resolution hops.
	_ai_jump_timer -= delta
	if _ai_jump_timer <= 0.0 and (dist_y < -85.0 or (_ai_stuck_timer > 0.42 and is_on_floor())):
		_ai_actions["jump"] = true
		_ai_jump_timer = randf_range(0.45, 0.95)
		_ai_stuck_timer = 0.0

	if move_dir != 0 and is_on_floor() and absf(global_position.x - _ai_last_pos.x) < 1.6:
		_ai_stuck_timer += delta
	else:
		_ai_stuck_timer = maxf(0.0, _ai_stuck_timer - delta * 1.4)
	_ai_last_pos = global_position

	# Opportunistic skill/item use.
	_ai_skill_timer -= delta
	if _ai_skill_timer <= 0.0 and skill and skill.is_ready() and (in_melee or dist_x < 280.0):
		_ai_actions["skill"] = true
		_ai_skill_timer = randf_range(2.8, 5.8)

	_ai_item_timer -= delta
	if _ai_item_timer <= 0.0 and current_tactical and dist_x < 300.0 and absf(dist_y) < 120.0:
		_ai_actions["item"] = true
		_ai_item_timer = randf_range(4.5, 8.0)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if is_ai_controlled:
		_update_ai_input(delta)

	_update_timers(delta)
	_apply_gravity(delta)
	_handle_descend(delta)
	_handle_jump()
	_handle_crouch()
	_handle_sprint(delta)
	_handle_aim(delta)
	_handle_movement(delta)
	_handle_attack()
	_handle_reload()
	_handle_tactical()
	_handle_skill(delta)
	_handle_freeze(delta)
	_handle_jetpack(delta)
	_handle_tactical_pickup()
	_handle_weapon_pickup()
	_handle_regen(delta)
	move_and_slide()


# --- Timers ---

func _update_timers(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer -= delta
	if _attack_visual_timer > 0.0:
		_attack_visual_timer -= delta
		if _attack_visual_timer <= 0.0:
			hitbox_collision.disabled = true
			is_attacking = false
	if _hit_stun_timer > 0.0:
		_hit_stun_timer -= delta
	if _spawn_invuln_timer > 0.0:
		_spawn_invuln_timer -= delta
	if _equip_timer > 0.0:
		_equip_timer -= delta
	if is_reloading:
		_reload_timer -= delta
		if _reload_timer <= 0.0:
			_finish_reload()
	if _burst_remaining > 0:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_shoot()
			_burst_remaining -= 1
			if _burst_remaining > 0 and current_gun:
				_burst_timer = current_gun.get_attack_cooldown()


# --- Gravity ---

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		_air_jumps_left = MAX_AIR_JUMPS
		if _coyote_timer <= 0.0:
			_coyote_timer = COYOTE_TIME
		return
	_coyote_timer -= delta
	if _coyote_timer < 0.0:
		_coyote_timer = 0.0
	velocity.y += _gravity * delta


# --- Jump ---

func _handle_jump() -> void:
	var pistol_aiming := is_aiming and current_gun and current_gun.gun_category == WeaponData.GunCategory.PISTOL
	if is_aiming and not pistol_aiming:
		return
	var can_jump := is_on_floor() or _coyote_timer > 0.0
	if not _is_just_pressed("jump") or is_crouching:
		return

	if can_jump:
		_coyote_timer = 0.0
		velocity.y = JUMP_VELOCITY
	elif _air_jumps_left > 0:
		_air_jumps_left -= 1
		velocity.y = JUMP_VELOCITY


# --- Crouch ---

func _handle_crouch() -> void:
	if is_aiming:
		return
	var was_crouching := is_crouching
	is_crouching = _is_pressed("crouch") and is_on_floor()
	if is_crouching != was_crouching:
		standing_collision.disabled = is_crouching
		crouching_collision.disabled = not is_crouching


# --- Descend through one-way platforms (double-tap crouch) ---

func _handle_descend(delta: float) -> void:
	if is_aiming:
		return
	if _descend_tap_count > 0:
		_descend_timer -= delta
		if _descend_timer <= 0.0:
			_descend_tap_count = 0

	if _is_just_pressed("crouch"):
		_descend_tap_count += 1
		_descend_timer = DESCEND_TAP_WINDOW
		if _descend_tap_count >= 2:
			_descend_tap_count = 0
			set_collision_mask_value(2, false)
			get_tree().create_timer(0.2).timeout.connect(
				func(): set_collision_mask_value(2, true)
			)


# --- Sprint & Stamina ---

func _handle_sprint(delta: float) -> void:
	if is_aiming:
		is_sprinting = false
		return
	var wants_sprint := _is_pressed("sprint")

	if stamina_depleted:
		is_sprinting = false
		stamina += STAMINA_REGEN * delta
		if stamina >= STAMINA_MAX:
			stamina = STAMINA_MAX
			stamina_depleted = false
	elif wants_sprint and not is_crouching:
		is_sprinting = true
		stamina -= STAMINA_DRAIN * delta
		if stamina <= 0.0:
			stamina = 0.0
			stamina_depleted = true
	else:
		is_sprinting = false
		stamina = minf(stamina + STAMINA_REGEN * delta, STAMINA_MAX)


# --- Aim mode (gun only) ---

func _handle_aim(delta: float) -> void:
	if current_gun == null:
		if is_aiming:
			is_aiming = false
			aim_pitch = 0.0
		return

	if _is_pressed("secondary"):
		if not is_aiming:
			aim_pitch = 0.0
		is_aiming = true
		# Change facing direction while aiming
		if (is_ai_controlled and _is_pressed("left")) or _is_just_pressed("left"):
			facing_direction = -1
		elif (is_ai_controlled and _is_pressed("right")) or _is_just_pressed("right"):
			facing_direction = 1
		# Adjust pitch
		var pitch_input := _get_axis("jump", "crouch")
		aim_pitch = clampf(aim_pitch + pitch_input * AIM_PITCH_SPEED * delta, -AIM_PITCH_MAX, AIM_PITCH_MAX)
	elif is_aiming:
		is_aiming = false
		_burst_remaining = 0


# --- Horizontal movement ---

func _handle_movement(_delta: float) -> void:
	var can_move_while_aiming := is_aiming and current_gun and current_gun.gun_category == WeaponData.GunCategory.PISTOL
	if is_crouching or _hit_stun_timer > 0.0 or (is_aiming and not can_move_while_aiming):
		velocity.x = move_toward(velocity.x, 0.0, DECELERATION * _delta)
		return

	var direction := _get_axis("left", "right")
	var speed_mult := current_gun.moving_speed_mult if current_gun else 1.0
	if can_move_while_aiming:
		speed_mult *= AIM_PISTOL_SPEED_MULT
	if direction:
		facing_direction = 1 if direction > 0.0 else -1
		var base_speed := SPRINT_SPEED if is_sprinting else SPEED
		velocity.x = direction * base_speed * speed_mult
	else:
		velocity.x = move_toward(velocity.x, 0.0, DECELERATION * _delta)


# --- Attack ---

func _handle_attack() -> void:
	if _attack_timer > 0.0 or _hit_stun_timer > 0.0 or _equip_timer > 0.0:
		return

	# Crouch + Attack = force-drop current weapon and pick up nearby
	if is_crouching and _is_just_pressed("attack"):
		_swap_weapon()
		return

	# --- Shooting (gun while aiming) ---
	if is_aiming and current_gun:
		match current_gun.fire_mode:
			WeaponData.FireMode.SINGLE:
				if _is_just_pressed("attack"):
					_shoot()
			WeaponData.FireMode.BURST:
				if _is_just_pressed("attack") and _burst_remaining <= 0:
					_shoot()
					_burst_remaining = current_gun.burst_count - 1
					if _burst_remaining > 0:
						_burst_timer = current_gun.get_attack_cooldown()
			WeaponData.FireMode.AUTO:
				if _is_pressed("attack"):
					_shoot()
		return

	# --- Melee (uses melee weapon slot, or bare fists if empty) ---
	if _is_just_pressed("attack"):
		if current_melee:
			_perform_melee_attack(1, current_melee.damage, current_melee.knockback,
				current_melee.get_attack_cooldown(), current_melee.melee_range)
		else:
			_perform_melee_attack(1, FIST_DAMAGE, FIST_KNOCKBACK, ATTACK_COOLDOWN, FIST_RANGE)

	elif _is_just_pressed("secondary"):
		if current_melee:
			_perform_melee_attack(2, current_melee.secondary_damage,
				current_melee.secondary_knockback,
				current_melee.get_secondary_cooldown(), current_melee.melee_range)
		else:
			_perform_melee_attack(2, FIST_SECONDARY_DAMAGE, FIST_SECONDARY_KNOCKBACK,
				SECONDARY_COOLDOWN, FIST_RANGE)
		# Gun secondary = aim mode (handled in _handle_aim)


func _perform_melee_attack(type: int, dmg: float, kb: float, cooldown: float, m_range: float) -> void:
	attack_type = type
	is_attacking = true
	_attack_timer = cooldown

	var hitbox_y := -32.0
	var lunge := 0.0
	if current_melee:
		if type == 1:
			_attack_visual_timer = current_melee.melee_primary_visual_time
			lunge = current_melee.melee_lunge_primary
		else:
			_attack_visual_timer = current_melee.melee_secondary_visual_time
			lunge = current_melee.melee_lunge_secondary
		hitbox_y = current_melee.melee_hitbox_y
		if type == 2:
			hitbox_y += current_melee.melee_secondary_y_offset
	else:
		_attack_visual_timer = ATTACK_VISUAL_DURATION
		if type == 2:
			lunge = 18.0

	hitbox_collision.position = Vector2(m_range * facing_direction, hitbox_y)
	hitbox_collision.disabled = false
	hitbox.set_meta("damage", dmg)
	hitbox.set_meta("knockback", kb)
	hitbox.set_meta("direction", facing_direction)
	if lunge > 0.0:
		velocity.x += lunge * facing_direction


func _shoot() -> void:
	if not current_gun or is_reloading:
		return
	if ammo_current <= 0:
		_start_reload()
		return
	ammo_current -= 1
	_attack_timer = current_gun.get_attack_cooldown()

	var shoot_dir := Vector2(facing_direction, 0.0)
	if is_aiming:
		shoot_dir = Vector2(facing_direction, 0.0).rotated(aim_pitch * facing_direction)
		aim_pitch = clampf(aim_pitch - current_gun.recoil_kick, -AIM_PITCH_MAX, AIM_PITCH_MAX)

	for i in current_gun.pellets:
		var bullet: Area2D = _projectile_scene.instantiate()
		bullet.global_position = global_position + Vector2(20.0 * facing_direction, -32.0)
		var spread := 0.0
		if current_gun.pellets > 1:
			spread = randf_range(-0.15, 0.15)
		bullet.direction = shoot_dir.rotated(spread).normalized()
		bullet.speed = current_gun.velocity
		bullet.damage = current_gun.damage
		bullet.knockback = current_gun.knockback
		bullet.owner_id = player_id
		get_tree().current_scene.add_child(bullet)

	# Recoil pushback on player
	velocity.x -= current_gun.recoil * facing_direction

	# Auto-reload when the magazine is emptied by this shot.
	if ammo_current <= 0 and ammo_reserve > 0:
		_start_reload()


# --- Tactical items ---

func _handle_tactical() -> void:
	if current_tactical == null or is_dead:
		return
	if _is_just_pressed("item"):
		_use_tactical()


func _use_tactical() -> void:
	var tac := current_tactical
	current_tactical = null
	match tac.tactical_type:
		TacticalData.TacticalType.FRAG_GRENADE, \
		TacticalData.TacticalType.FLASH_FREEZE:
			_throw_tactical(tac)
		TacticalData.TacticalType.MOLOTOV:
			_throw_tactical(tac)
		TacticalData.TacticalType.MED_KIT:
			hp = minf(hp + tac.heal_amount, HP_MAX)
		TacticalData.TacticalType.JETPACK:
			is_jetpacking = true
			_jetpack_timer = tac.flight_duration
			_jetpack_force = tac.flight_force


func _throw_tactical(tac: TacticalData) -> void:
	var thrown: Area2D = _thrown_tactical_scene.instantiate()
	thrown.global_position = global_position + Vector2(16.0 * facing_direction, -32.0)
	var dir := Vector2(facing_direction, 0.0)
	if is_aiming:
		dir = Vector2(facing_direction, 0.0).rotated(aim_pitch * facing_direction)
	thrown.init(tac, dir, player_id)
	get_tree().current_scene.add_child(thrown)


func _handle_tactical_pickup() -> void:
	if current_tactical != null or is_dead:
		return
	for area in pickup_area.get_overlapping_areas():
		if area.has_method("init") and area.get("tactical_data") != null:
			current_tactical = area.tactical_data
			area.queue_free()
			break


# --- Character skill ---

func _handle_skill(delta: float) -> void:
	skill.process(delta)
	if _is_just_pressed("skill") and skill.is_ready():
		skill.activate(self)


# --- Freeze debuff ---

func apply_freeze(duration: float) -> void:
	is_frozen = true
	_freeze_timer = duration


func _handle_freeze(delta: float) -> void:
	if not is_frozen:
		return
	_freeze_timer -= delta
	if _freeze_timer <= 0.0:
		is_frozen = false
		return
	# Slow the player while frozen
	velocity.x *= 0.3
	velocity.y = minf(velocity.y, 0.0)  # prevent jumping effectively


# --- Jetpack ---

func _handle_jetpack(delta: float) -> void:
	if not is_jetpacking:
		return
	_jetpack_timer -= delta
	if _jetpack_timer <= 0.0:
		is_jetpacking = false
		return
	velocity.y = _jetpack_force


# --- Reload ---

func _handle_reload() -> void:
	if current_gun == null:
		return
	if _is_just_pressed("reload") and not is_reloading:
		_start_reload()


func _finish_reload() -> void:
	is_reloading = false
	if current_gun == null:
		return
	var needed := current_gun.capacity - ammo_current
	var available := mini(needed, ammo_reserve)
	ammo_current += available
	ammo_reserve -= available


func _start_reload() -> void:
	if current_gun == null or is_reloading:
		return
	if ammo_current >= current_gun.capacity or ammo_reserve <= 0:
		return
	is_reloading = true
	_reload_timer = current_gun.reload_time


# --- Weapon pickup / drop ---

func _swap_weapon() -> void:
	var nearest: Node2D = null
	var nearest_dist := 60.0
	for area in pickup_area.get_overlapping_areas():
		if area.has_method("init") and area.get("weapon_data") != null:
			var d := global_position.distance_to(area.global_position)
			if d < nearest_dist:
				nearest_dist = d
				nearest = area

	if not nearest:
		return

	var data: WeaponData = nearest.weapon_data
	if data.type == WeaponData.Type.GUN:
		# Swapping guns consumes the old one instead of dropping it on the map.
		_drop_gun(false)
		current_gun = data
		ammo_current = nearest.ammo_current
		ammo_reserve = nearest.ammo_reserve
		_equip_timer = data.equip_time
	else:
		# Swapping melee consumes the old one instead of dropping it on the map.
		_drop_melee(false)
		current_melee = data
		_equip_timer = data.equip_time
	nearest.queue_free()


func _handle_weapon_pickup() -> void:
	if is_dead:
		return
	for area in pickup_area.get_overlapping_areas():
		if not (area.has_method("init") and area.get("weapon_data") != null):
			continue
		var data: WeaponData = area.weapon_data
		if data.type == WeaponData.Type.GUN and current_gun == null:
			current_gun = data
			ammo_current = area.ammo_current
			ammo_reserve = area.ammo_reserve
			_equip_timer = data.equip_time
			area.queue_free()
			break
		elif data.type == WeaponData.Type.MELEE and current_melee == null:
			current_melee = data
			_equip_timer = data.equip_time
			area.queue_free()
			break


func _drop_gun(spawn_pickup: bool = true) -> void:
	if current_gun == null:
		return
	if spawn_pickup:
		var pickup: Area2D = _pickup_scene.instantiate()
		pickup.global_position = global_position + Vector2(0, -20)
		get_tree().current_scene.add_child(pickup)
		pickup.init(current_gun)
		pickup.ammo_current = ammo_current
		pickup.ammo_reserve = ammo_reserve
	current_gun = null
	ammo_current = 0
	ammo_reserve = 0
	is_aiming = false
	aim_pitch = 0.0
	is_reloading = false
	_burst_remaining = 0


func _drop_melee(spawn_pickup: bool = true) -> void:
	if current_melee == null:
		return
	if spawn_pickup:
		var pickup: Area2D = _pickup_scene.instantiate()
		pickup.global_position = global_position + Vector2(0, -20)
		get_tree().current_scene.add_child(pickup)
		pickup.init(current_melee)
	current_melee = null


func equip_weapon(data: WeaponData, a_current: int = 0, a_reserve: int = 0) -> void:
	if data.type == WeaponData.Type.GUN:
		current_gun = data
		ammo_current = a_current
		ammo_reserve = a_reserve
	else:
		current_melee = data
	_equip_timer = data.equip_time


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body == self or not body.has_method("take_damage"):
		return
	var dmg: float = hitbox.get_meta("damage")
	var kb: float = hitbox.get_meta("knockback")
	var dir: int = hitbox.get_meta("direction")
	body.take_damage(dmg, kb, dir)
	damage_dealt.emit(dmg)


# --- Damage ---

# --- HP Regen ---

func _handle_regen(delta: float) -> void:
	if hp >= HP_MAX or _hit_stun_timer > 0.0:
		return
	if _regen_timer > 0.0:
		_regen_timer -= delta
		return
	hp = minf(hp + HP_REGEN_RATE * delta, HP_MAX)


func _spawn_damage_number(amount: float) -> void:
	if _damage_number_scene == null or amount <= 0.0:
		return
	var popup: Node2D = _damage_number_scene.instantiate()
	popup.global_position = global_position + Vector2(randf_range(-8.0, 8.0), -52.0)
	var severity := clampf(amount / 45.0, 0.0, 1.0)
	var color := Color(1.0, 0.95 - severity * 0.35, 0.95 - severity * 0.55)
	popup.init(amount, color)
	get_tree().current_scene.add_child(popup)


func take_damage(amount: float, knockback_force: float, direction: int) -> void:
	if is_dead or _spawn_invuln_timer > 0.0:
		return
	hp -= amount
	_spawn_damage_number(amount)
	_regen_timer = HP_REGEN_DELAY  # reset regen delay on every hit
	_hit_stun_timer = HIT_STUN_DURATION
	velocity.x = knockback_force * direction
	velocity.y = -150.0
	if hp <= 0.0:
		hp = 0.0
		_die()


func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	hitbox_collision.disabled = true
	standing_collision.disabled = true
	crouching_collision.disabled = true
	died.emit(player_id)


func configure_for_match(character_id: int, new_color: Color) -> void:
	character = character_id
	player_color = new_color
	_init_skill()


func reset(spawn_position: Vector2) -> void:
	hp = HP_MAX
	_regen_timer = 0.0
	_coyote_timer = 0.0
	_air_jumps_left = MAX_AIR_JUMPS
	stamina = STAMINA_MAX
	stamina_depleted = false
	is_dead = false
	is_crouching = false
	is_sprinting = false
	is_attacking = false
	is_aiming = false
	aim_pitch = 0.0
	is_reloading = false
	_reload_timer = 0.0
	_equip_timer = 0.0
	_burst_remaining = 0
	_burst_timer = 0.0
	attack_type = 0
	_attack_timer = 0.0
	_attack_visual_timer = 0.0
	_hit_stun_timer = 0.0
	_spawn_invuln_timer = SPAWN_INVULN_DURATION
	velocity = Vector2.ZERO
	global_position = spawn_position
	standing_collision.disabled = false
	crouching_collision.disabled = true
	hitbox_collision.disabled = true
	current_gun = null
	current_melee = null
	ammo_current = 0
	ammo_reserve = 0
	current_tactical = null
	is_frozen = false
	_freeze_timer = 0.0
	is_jetpacking = false
	_jetpack_timer = 0.0
	skill.reset()
