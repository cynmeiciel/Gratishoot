extends CharacterBody2D

enum Character { TSUTAYA, AICHOK, SHRINK, INVISIBLE }

const SKILL_NAMES := {
	Character.TSUTAYA: "Dash",
	Character.AICHOK: "Life Steal",
	Character.SHRINK: "Shrink",
	Character.INVISIBLE: "Invisible",
}

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

# Melee combo system
var _melee_combo_active := false  # True if primary hit successfully, reduces secondary cooldown
const MELEE_COMBO_SPEEDUP := 0.6  # Secondary cooldown multiplier after successful hit

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
const AIM_PITCH_SPEED := 1.7  # rad/s
const AIM_PITCH_MAX := 1.55
const AIM_PISTOL_SPEED_MULT := 0.8
const PRECISION_AIM_ASSIST_MIN_DISTANCE := 120.0
const PRECISION_AIM_ASSIST_MAX_DISTANCE := 2400.0
const PRECISION_AIM_ASSIST_ANGLE_NEAR_DEG := 9.0
const PRECISION_AIM_ASSIST_ANGLE_FAR_DEG := 16.0
const PRECISION_AIM_ASSIST_NEAR_STRENGTH := 0.24
const PRECISION_AIM_ASSIST_FAR_STRENGTH := 0.62
const PRECISION_AIM_ASSIST_FALLBACK_DOT := 0.5

# Tactical item slot
var current_tactical: TacticalData = null
var is_tactical_aiming := false
var tactical_throw_strong := true
const TACTICAL_THROW_FORCE_STRONG := 2.5
const TACTICAL_THROW_FORCE_WEAK := 1.5
const TACTICAL_THROW_UP_STRONG := -300.0
const TACTICAL_THROW_UP_WEAK := -180.0

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
var shield_amount := 0.0
var shield_decay_rate := 0.0
var confusion_timer := 0.0

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
var is_network_controlled := false
var _net_actions: Dictionary = {}
var _net_prev_actions: Dictionary = {}
var _ai_shot_timer := 0.0
var _ai_melee_timer := 0.0
var _ai_jump_timer := 0.0
var _ai_strafe_dir := 1
var _ai_strafe_timer := 0.0
var _ai_stuck_timer := 0.0
var _ai_skill_timer := 0.0
var _ai_item_timer := 0.0
var _ai_last_pos := Vector2.ZERO
var opponent_player: CharacterBody2D = null


func _ready() -> void:
	_input_prefix = "p%d_" % player_id
	for action in ["left", "right", "jump", "crouch", "attack", "secondary", "sprint", "skill", "item", "reload"]:
		_ai_actions[action] = false
		_ai_prev_actions[action] = false
		_net_actions[action] = false
		_net_prev_actions[action] = false
	add_to_group("players")
	_init_skill()
	_projectile_scene = load("res://scenes/weapon/projectile.tscn")
	_damage_number_scene = load("res://scenes/ui/damage_number.tscn")
	_pickup_scene = load("res://scenes/weapon/weapon_pickup.tscn")
	_thrown_tactical_scene = load("res://scenes/tactical/thrown_tactical.tscn")
	_tactical_pickup_scene = load("res://scenes/tactical/tactical_pickup.tscn")
	hitbox_collision.disabled = true
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	if not damage_dealt.is_connected(_on_damage_dealt):
		damage_dealt.connect(_on_damage_dealt)


func _init_skill() -> void:
	set_skill_by_id(character)


func _on_damage_dealt(amount: float) -> void:
	if skill:
		skill.on_damage_dealt(self, amount)


func set_skill_by_id(skill_id: int) -> void:
	character = skill_id
	match skill_id:
		Character.TSUTAYA:
			skill = DashSkill.new()
		Character.AICHOK:
			skill = LifeStealSkill.new()
		Character.SHRINK:
			skill = ShrinkSkill.new()
		Character.INVISIBLE:
			skill = InvisibleSkill.new()
		_:
			skill = DashSkill.new()


func set_skill_by_name(skill_name: String) -> void:
	var clean := skill_name.strip_edges().to_lower()
	for sid in SKILL_NAMES.keys():
		if String(SKILL_NAMES[sid]).to_lower() == clean:
			set_skill_by_id(sid)
			return


static func get_skill_options() -> PackedStringArray:
	return PackedStringArray(["Dash", "Life Steal", "Shrink", "Invisible"])


func set_ai_control(enabled: bool, target: CharacterBody2D) -> void:
	is_ai_controlled = enabled
	is_network_controlled = false
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


func set_network_control(enabled: bool) -> void:
	is_network_controlled = enabled
	if enabled:
		is_ai_controlled = false
	for action in _net_actions.keys():
		_net_actions[action] = false
		_net_prev_actions[action] = false


func apply_network_input(input_state: Dictionary) -> void:
	if not is_network_controlled:
		return
	for action in _net_actions.keys():
		_net_actions[action] = bool(input_state.get(action, false))


func _action_name(suffix: String) -> String:
	return _input_prefix + suffix


func _is_pressed(suffix: String) -> bool:
	if is_ai_controlled:
		return bool(_ai_actions.get(suffix, false))
	if is_network_controlled:
		return bool(_net_actions.get(suffix, false))
	return Input.is_action_pressed(_action_name(suffix))


func _is_just_pressed(suffix: String) -> bool:
	if is_ai_controlled:
		var now := bool(_ai_actions.get(suffix, false))
		var prev := bool(_ai_prev_actions.get(suffix, false))
		return now and not prev
	if is_network_controlled:
		var net_now := bool(_net_actions.get(suffix, false))
		var net_prev := bool(_net_prev_actions.get(suffix, false))
		return net_now and not net_prev
	return Input.is_action_just_pressed(_action_name(suffix))


func _get_axis(neg_suffix: String, pos_suffix: String) -> float:
	var swap_lr := confusion_timer > 0.0 and (
		(neg_suffix == "left" and pos_suffix == "right")
		or (neg_suffix == "right" and pos_suffix == "left")
	)
	if swap_lr:
		var tmp := neg_suffix
		neg_suffix = pos_suffix
		pos_suffix = tmp
	if is_ai_controlled or is_network_controlled:
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
	if opponent_player == null or opponent_player == self:
		opponent_player = _resolve_opponent_player()
	if is_ai_controlled:
		_update_ai_input(delta)
	if is_network_controlled:
		for k in _net_prev_actions.keys():
			_net_prev_actions[k] = _net_actions[k]

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
	_handle_tactical(delta)
	_handle_skill(delta)
	_handle_freeze(delta)
	_handle_jetpack(delta)
	_handle_tactical_pickup()
	_handle_weapon_pickup()
	_handle_regen(delta)
	move_and_slide()


# --- Timers ---

func _update_timers(delta: float) -> void:
	if shield_amount > 0.0:
		shield_amount = maxf(0.0, shield_amount - shield_decay_rate * delta)
	if confusion_timer > 0.0:
		confusion_timer = maxf(0.0, confusion_timer - delta)
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
	if is_tactical_aiming:
		return
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
	if is_aiming or is_tactical_aiming:
		return
	var was_crouching := is_crouching
	is_crouching = _is_pressed("crouch") and is_on_floor()
	if is_crouching != was_crouching:
		standing_collision.disabled = is_crouching
		crouching_collision.disabled = not is_crouching


# --- Descend through one-way platforms (double-tap crouch) ---

func _handle_descend(delta: float) -> void:
	if is_aiming or is_tactical_aiming:
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
	if is_aiming or is_tactical_aiming:
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
	if is_crouching:
		if is_tactical_aiming:
			_exit_tactical_aim()
		if is_aiming:
			is_aiming = false
			_burst_remaining = 0
		return

	if is_tactical_aiming:
		if ((is_ai_controlled or is_network_controlled) and _is_pressed("left")) or _is_just_pressed("left"):
			facing_direction = -1
		elif ((is_ai_controlled or is_network_controlled) and _is_pressed("right")) or _is_just_pressed("right"):
			facing_direction = 1
		var tactical_pitch_input := _get_axis("jump", "crouch")
		aim_pitch = clampf(aim_pitch + tactical_pitch_input * AIM_PITCH_SPEED * delta, -AIM_PITCH_MAX, AIM_PITCH_MAX)
		return

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
		if ((is_ai_controlled or is_network_controlled) and _is_pressed("left")) or _is_just_pressed("left"):
			facing_direction = -1
		elif ((is_ai_controlled or is_network_controlled) and _is_pressed("right")) or _is_just_pressed("right"):
			facing_direction = 1
		# Adjust pitch
		var pitch_input := _get_axis("jump", "crouch")
		aim_pitch = clampf(aim_pitch + pitch_input * AIM_PITCH_SPEED * delta, -AIM_PITCH_MAX, AIM_PITCH_MAX)
	elif is_aiming:
		is_aiming = false
		_burst_remaining = 0


# --- Horizontal movement ---

func _handle_movement(_delta: float) -> void:
	var can_move_while_aiming := (is_aiming and current_gun and current_gun.gun_category == WeaponData.GunCategory.PISTOL) or is_tactical_aiming
	if is_crouching or _hit_stun_timer > 0.0 or (is_aiming and not can_move_while_aiming):
		velocity.x = move_toward(velocity.x, 0.0, DECELERATION * _delta)
		return

	var direction := _get_axis("left", "right")
	var speed_mult := current_gun.moving_speed_mult if current_gun else 1.0
	# Apply melee weapon speed penalty (HEAVY weapons slow you down)
	if current_melee and not current_gun:
		speed_mult = current_melee.moving_speed_mult
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
	if is_tactical_aiming:
		return
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
			var sec_cooldown := current_melee.get_secondary_cooldown()
			# Apply combo speedup: if primary hit connected, secondary is faster
			if _melee_combo_active:
				sec_cooldown *= MELEE_COMBO_SPEEDUP
				_melee_combo_active = false
			_perform_melee_attack(2, current_melee.secondary_damage,
				current_melee.secondary_knockback,
				sec_cooldown, current_melee.melee_range)
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
	AudioManager.play_sfx_varied("melee_swing", -3.0, 0.94, 1.08)
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

	var aim_assist := _get_precision_aim_assist(shoot_dir)
	shoot_dir = aim_assist.direction
	var spread_scale: float = aim_assist.spread_scale

	for i in current_gun.pellets:
		var bullet: Area2D = _projectile_scene.instantiate()
		bullet.global_position = global_position + Vector2(10.0 * facing_direction, -32.0)
		bullet.call("apply_rarity_color", current_gun.get_rarity_color())
		var spread_radians := deg_to_rad(current_gun.spread * spread_scale)
		var spread := randf_range(-spread_radians, spread_radians) if spread_radians > 0.0 else 0.0
		bullet.direction = shoot_dir.rotated(spread).normalized()
		bullet.speed = current_gun.velocity
		bullet.damage = current_gun.damage
		bullet.knockback = current_gun.knockback
		bullet.gravity = current_gun.projectile_gravity
		bullet.vertical_boost = current_gun.projectile_upward_boost
		bullet.explosive_radius = current_gun.explosive_radius
		bullet.spread_on_impact = current_gun.spread_on_impact
		bullet.homing_turn_rate_deg = current_gun.projectile_homing_turn_rate
		bullet.homing_range = current_gun.projectile_homing_range
		bullet.homing_delay = current_gun.projectile_homing_delay
		bullet.homing_fov_deg = current_gun.projectile_homing_fov
		bullet.homing_duration = current_gun.projectile_homing_duration
		bullet.owner_id = player_id
		get_tree().current_scene.add_child(bullet)

	AudioManager.play_sfx_varied(_gun_sfx_event(current_gun), -1.5, 0.96, 1.04)

	# Recoil pushback on player
	velocity.x -= current_gun.recoil * facing_direction

	# Auto-reload when the magazine is emptied by this shot.
	if ammo_current <= 0 and ammo_reserve > 0:
		_start_reload()


func _get_precision_aim_assist(base_dir: Vector2) -> Dictionary:
	if not GameState.aim_assist_enabled:
		return {"direction": base_dir.normalized(), "spread_scale": 1.0}
	if current_gun == null or not is_aiming or not _is_precision_class(current_gun):
		return {"direction": base_dir.normalized(), "spread_scale": 1.0}

	var corrected_dir := base_dir.normalized()
	var spread_scale := 0.78
	var target_info := _find_precision_assist_target(corrected_dir)
	if target_info.is_empty():
		return {"direction": corrected_dir, "spread_scale": spread_scale}

	var target_dir: Vector2 = target_info["direction"]
	var distance: float = target_info["distance"]
	var t := clampf(
		inverse_lerp(PRECISION_AIM_ASSIST_MIN_DISTANCE, PRECISION_AIM_ASSIST_MAX_DISTANCE, distance),
		0.0,
		1.0
	)
	var assist_strength := lerpf(PRECISION_AIM_ASSIST_NEAR_STRENGTH, PRECISION_AIM_ASSIST_FAR_STRENGTH, t)
	corrected_dir = corrected_dir.slerp(target_dir, assist_strength).normalized()
	spread_scale = lerpf(0.78, 0.58, t)
	return {"direction": corrected_dir, "spread_scale": spread_scale}


func get_precision_assist_status() -> Dictionary:
	if not GameState.aim_assist_enabled:
		return {"active": false, "reason": "DISABLED", "distance": 0.0}
	if current_gun == null:
		return {"active": false, "reason": "NO GUN", "distance": 0.0}
	if not is_aiming:
		return {"active": false, "reason": "NOT AIMING", "distance": 0.0}
	if not _is_precision_class(current_gun):
		return {"active": false, "reason": "NON-PRECISION", "distance": 0.0}

	var base_dir := Vector2(facing_direction, 0.0).rotated(aim_pitch * facing_direction).normalized()
	var target_info := _find_precision_assist_target(base_dir)
	if target_info.is_empty():
		return {"active": false, "reason": "NO TARGET", "distance": 0.0}

	return {
		"active": true,
		"reason": "ACTIVE",
		"distance": float(target_info.get("distance", 0.0))
	}


func _is_precision_class(w: WeaponData) -> bool:
	return w.gun_category == WeaponData.GunCategory.SNIPER \
		or w.gun_category == WeaponData.GunCategory.DMR


func _find_precision_assist_target(base_dir: Vector2) -> Dictionary:
	var muzzle := global_position + Vector2(20.0 * facing_direction, -32.0)
	var target := opponent_player
	if target == null or target == self or ("is_dead" in target and target.is_dead):
		target = _resolve_opponent_player()
		opponent_player = target
	if target == null:
		return {}

	var aim_point := target.global_position + Vector2(0.0, -32.0)
	var to_target := aim_point - muzzle
	var distance := to_target.length()
	if distance < PRECISION_AIM_ASSIST_MIN_DISTANCE or distance > PRECISION_AIM_ASSIST_MAX_DISTANCE:
		return {}

	var t := clampf(
		inverse_lerp(PRECISION_AIM_ASSIST_MIN_DISTANCE, PRECISION_AIM_ASSIST_MAX_DISTANCE, distance),
		0.0,
		1.0
	)
	var cone_angle := lerpf(PRECISION_AIM_ASSIST_ANGLE_NEAR_DEG, PRECISION_AIM_ASSIST_ANGLE_FAR_DEG, t)
	var max_angle_cos := cos(deg_to_rad(cone_angle))

	var dir_to_target := to_target / distance
	var facing_alignment := base_dir.dot(dir_to_target)
	if facing_alignment >= max_angle_cos:
		return {"direction": dir_to_target, "distance": distance}

	# Soft fallback for quick reticle movement: target still in front.
	if facing_alignment > PRECISION_AIM_ASSIST_FALLBACK_DOT:
		return {"direction": dir_to_target, "distance": distance}

	return {}


func _resolve_opponent_player() -> CharacterBody2D:
	for node in get_tree().get_nodes_in_group("players"):
		var p := node as CharacterBody2D
		if p != null and p != self:
			return p
	return null


# --- Tactical items ---

func _handle_tactical(_delta: float) -> void:
	if current_tactical == null or is_dead:
		if is_tactical_aiming:
			_exit_tactical_aim()
		return

	if is_crouching:
		if is_tactical_aiming:
			_exit_tactical_aim()
		return

	if _is_throwable_tactical(current_tactical):
		if is_ai_controlled:
			if _is_just_pressed("item"):
				_throw_equipped_tactical()
			return

		if _is_just_pressed("item"):
			if not is_tactical_aiming:
				_enter_tactical_aim()
			else:
				_exit_tactical_aim()

		if is_tactical_aiming:
			if _is_just_pressed("attack"):
				_throw_equipped_tactical()
			elif _is_just_pressed("reload"):
				_toggle_tactical_throw_force()
		return

	if _is_just_pressed("item"):
		_use_tactical()


func _use_tactical() -> void:
	var tac := current_tactical
	_exit_tactical_aim()
	AudioManager.play_sfx_varied("use_tactical", -2.0, 0.95, 1.05)
	match tac.tactical_type:
		TacticalData.TacticalType.FRAG_GRENADE, \
		TacticalData.TacticalType.FLASH_FREEZE:
			_throw_tactical(tac)
		TacticalData.TacticalType.MOLOTOV:
			_throw_tactical(tac)
		TacticalData.TacticalType.MED_KIT:
			hp = minf(hp + tac.heal_amount, HP_MAX)
			AudioManager.play_sfx_varied("use_medkit", -1.0, 0.98, 1.05)
		TacticalData.TacticalType.JETPACK:
			is_jetpacking = true
			_jetpack_timer = tac.flight_duration
			_jetpack_force = tac.flight_force
			AudioManager.play_sfx_varied("use_jetpack", -1.0, 0.98, 1.03)
		TacticalData.TacticalType.SHIELD:
			activate_shield(tac.shield_amount, tac.duration)
		TacticalData.TacticalType.CONFUSION:
			var target := _resolve_opponent_player()
			if target and target.has_method("apply_confusion"):
				target.apply_confusion(tac.duration)
	_consume_tactical_charge()


func _enter_tactical_aim() -> void:
	if is_crouching or current_tactical == null or not _is_throwable_tactical(current_tactical):
		return
	is_tactical_aiming = true
	is_aiming = false
	_burst_remaining = 0
	aim_pitch = 0.0


func _exit_tactical_aim() -> void:
	is_tactical_aiming = false


func _toggle_tactical_throw_force() -> void:
	tactical_throw_strong = not tactical_throw_strong
	AudioManager.play_sfx_varied("ui_click", -8.0, 0.96, 1.04)


func _throw_equipped_tactical() -> void:
	if current_tactical == null or not _is_throwable_tactical(current_tactical):
		return
	var tac: TacticalData = current_tactical
	# Capture aimed throw velocity BEFORE clearing current_tactical
	var throw_velocity := get_tactical_throw_velocity()
	_exit_tactical_aim()
	AudioManager.play_sfx_varied("use_tactical", -2.0, 0.95, 1.05)
	_throw_tactical(tac, throw_velocity)
	_consume_tactical_charge()


func _consume_tactical_charge() -> void:
	if current_tactical == null:
		return
	current_tactical.charges = maxi(current_tactical.charges - 1, 0)
	if current_tactical.charges <= 0:
		current_tactical = null


func _is_throwable_tactical(tac: TacticalData) -> bool:
	if tac == null:
		return false
	return tac.tactical_type == TacticalData.TacticalType.FRAG_GRENADE \
		or tac.tactical_type == TacticalData.TacticalType.FLASH_FREEZE \
		or tac.tactical_type == TacticalData.TacticalType.MOLOTOV


func get_tactical_throw_velocity() -> Vector2:
	if not is_tactical_aiming or current_tactical == null or not _is_throwable_tactical(current_tactical):
		return Vector2.ZERO
	var dir := Vector2(facing_direction, 0.0).rotated(aim_pitch * facing_direction).normalized()
	var force_mult := TACTICAL_THROW_FORCE_STRONG if tactical_throw_strong else TACTICAL_THROW_FORCE_WEAK
	var upward := TACTICAL_THROW_UP_STRONG if tactical_throw_strong else TACTICAL_THROW_UP_WEAK
	return dir * (current_tactical.throw_speed * force_mult) + Vector2(0.0, upward)


func is_tactical_throw_strong() -> bool:
	return tactical_throw_strong


func activate_shield(amount: float, decay_duration: float) -> void:
	shield_amount = maxf(amount, 0.0)
	if decay_duration > 0.0:
		shield_decay_rate = shield_amount / decay_duration
	else:
		shield_decay_rate = 0.0


func apply_confusion(duration: float) -> void:
	confusion_timer = maxf(confusion_timer, duration)


func get_visual_alpha() -> float:
	if skill:
		return clampf(skill.get_visual_alpha(), 0.0, 1.0)
	return 1.0


func _throw_tactical(tac: TacticalData, aimed_velocity: Vector2 = Vector2.ZERO) -> void:
	var thrown: Area2D = _thrown_tactical_scene.instantiate()
	thrown.global_position = global_position + Vector2(16.0 * facing_direction, -32.0)
	var initial_velocity: Vector2
	if aimed_velocity != Vector2.ZERO:
		# Use the aimed velocity (from tactical aiming)
		initial_velocity = aimed_velocity
	else:
		# Fallback for non-aimed throws (AI, quick throw)
		initial_velocity = Vector2(facing_direction, 0.0) * tac.throw_speed + Vector2(0.0, TACTICAL_THROW_UP_WEAK)
	var thrown_tac := tac.duplicate(true) as TacticalData
	thrown.init(thrown_tac, initial_velocity, player_id)
	get_tree().current_scene.add_child(thrown)


func _handle_tactical_pickup() -> void:
	if current_tactical != null or is_dead:
		return
	for area in pickup_area.get_overlapping_areas():
		if area.has_method("init") and area.get("tactical_data") != null:
			current_tactical = area.tactical_data
			area.queue_free()
			AudioManager.play_sfx_varied("pickup_tactical", -3.0, 0.97, 1.05)
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
	if is_tactical_aiming:
		return
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
	AudioManager.play_sfx_varied("reload", -3.0, 0.98, 1.04)


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
	AudioManager.play_sfx_varied("pickup_weapon", -2.0, 0.96, 1.05)


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
			AudioManager.play_sfx_varied("pickup_weapon", -2.0, 0.97, 1.05)
			break
		elif data.type == WeaponData.Type.MELEE and current_melee == null:
			current_melee = data
			_equip_timer = data.equip_time
			area.queue_free()
			AudioManager.play_sfx_varied("pickup_weapon", -2.0, 0.97, 1.05)
			break


func _drop_gun(spawn_pickup: bool = true) -> void:
	if current_gun == null:
		return
	if GameState.game_mode == GameState.MODE_ARMS_DEALER:
		spawn_pickup = false
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
	if GameState.game_mode == GameState.MODE_ARMS_DEALER:
		spawn_pickup = false
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
	AudioManager.play_sfx_varied("melee_hit", -2.5, 0.95, 1.07)
	
	# Melee combo: after successful hit with primary, secondary is faster
	if attack_type == 1:
		_melee_combo_active = true


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
	if skill:
		skill.on_owner_damaged(self, amount)
	if shield_amount > 0.0 and amount > 0.0:
		var absorbed := minf(shield_amount, amount)
		shield_amount -= absorbed
		amount -= absorbed
	if amount <= 0.0:
		return
	hp -= amount
	_spawn_damage_number(amount)
	AudioManager.play_sfx_varied("hurt", -4.0, 0.96, 1.05)
	_regen_timer = HP_REGEN_DELAY  # reset regen delay on every hit
	_hit_stun_timer = HIT_STUN_DURATION
	velocity.x = knockback_force * direction
	velocity.y = -150.0
	if hp <= 0.0:
		hp = 0.0
		_die()


func _die() -> void:
	is_dead = true
	AudioManager.play_sfx_varied("death", -2.0, 0.96, 1.02)
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
	is_tactical_aiming = false
	shield_amount = 0.0
	shield_decay_rate = 0.0
	confusion_timer = 0.0
	scale = Vector2.ONE
	is_frozen = false
	_freeze_timer = 0.0
	is_jetpacking = false
	_jetpack_timer = 0.0
	skill.reset()


func _gun_sfx_event(gun: WeaponData) -> String:
	if gun.sfx_event != "":
		return gun.sfx_event
	match gun.gun_category:
		WeaponData.GunCategory.PISTOL:
			return "gun_pistol"
		WeaponData.GunCategory.ASSAULT_RIFLE, WeaponData.GunCategory.BATTLE_RIFLE:
			return "gun_rifle"
		WeaponData.GunCategory.SMG:
			return "gun_smg"
		WeaponData.GunCategory.LMG:
			return "gun_lmg"
		WeaponData.GunCategory.SHOTGUN:
			return "gun_shotgun"
		WeaponData.GunCategory.SNIPER:
			return "gun_sniper"
		WeaponData.GunCategory.DMR:
			return "gun_dmr"
		_:
			return "gun_rifle"
