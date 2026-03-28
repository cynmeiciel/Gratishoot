class_name WeaponData
extends Resource

enum Type { MELEE, GUN }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHIC, CONTRABAND }
enum GunCategory { NONE, PISTOL, ASSAULT_RIFLE, BATTLE_RIFLE, SMG, LMG, SHOTGUN, SNIPER, DMR }
enum FireMode { SINGLE, BURST, AUTO }
enum MeleeStyle { THRUST, SWEEP, HEAVY }

@export var weapon_name: String = ""
@export var type: Type = Type.MELEE
@export var rarity: Rarity = Rarity.COMMON
@export var gun_category: GunCategory = GunCategory.NONE

# Common stats
@export var damage: float = 10.0
@export var fire_rate: float = 2.0           # attacks or shots per second
@export var knockback: float = 200.0
@export var equip_time: float = 0.3
@export var moving_speed_mult: float = 1.0   # multiplier on player speed

# Melee stats
@export var melee_range: float = 45.0
@export var secondary_damage: float = 15.0
@export var secondary_knockback: float = 350.0
@export var secondary_fire_rate: float = 1.2
@export var melee_style: MeleeStyle = MeleeStyle.SWEEP
@export var melee_lunge_primary: float = 35.0
@export var melee_lunge_secondary: float = 65.0
@export var melee_hitbox_y: float = -32.0
@export var melee_secondary_y_offset: float = -4.0
@export var melee_primary_visual_time: float = 0.12
@export var melee_secondary_visual_time: float = 0.16
@export var melee_visual_thickness: float = 3.0

# Gun stats
@export var velocity: float = 800.0          # projectile speed (px/s)
@export var spread: float = 2.0              # random shot angle in degrees (+/-)
@export var recoil: float = 30.0             # backward push on player
@export var recoil_kick: float = 0.05        # aim pitch rise per shot (radians)
@export var sfx_event: String = ""          # AudioManager event key for this gun's firing sound
@export var reload_time: float = 1.5
@export var capacity: int = 12
@export var reserve_ammo: int = 36
@export var pellets: int = 1                 # >1 for shotguns
@export var fire_mode: FireMode = FireMode.SINGLE
@export var burst_count: int = 3              # shots per burst (only used in BURST mode)


static var RARITY_COLORS: Dictionary = {
	Rarity.COMMON: Color.WHITE,
	Rarity.UNCOMMON: Color.GREEN,
	Rarity.RARE: Color(0.3, 0.5, 1.0),
	Rarity.EPIC: Color(0.6, 0.2, 0.9),
	Rarity.LEGENDARY: Color(1.0, 0.84, 0.0),
	Rarity.MYTHIC: Color(1.0, 0.15, 0.15),
	Rarity.CONTRABAND: Color(0.12, 1.0, 0.92),
}


func get_rarity_color() -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)


func get_attack_cooldown() -> float:
	return 1.0 / fire_rate if fire_rate > 0.0 else 0.5


func get_secondary_cooldown() -> float:
	return 1.0 / secondary_fire_rate if secondary_fire_rate > 0.0 else 0.8
