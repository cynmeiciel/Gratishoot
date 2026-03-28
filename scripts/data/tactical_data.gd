class_name TacticalData
extends Resource

enum TacticalType { FRAG_GRENADE, FLASH_FREEZE, MOLOTOV, MED_KIT, JETPACK, SHIELD, CONFUSION }

@export var item_name: String = ""
@export var tactical_type: TacticalType = TacticalType.FRAG_GRENADE
@export var charges: int = 1  # Number of uses remaining

# Grenade stats
@export var throw_speed: float = 500.0
@export var fuse_time: float = 1.5          # seconds before detonation
@export var radius: float = 80.0            # effect radius in pixels
@export var damage: float = 40.0            # for frag
@export var knockback: float = 400.0
@export var duration: float = 0.0           # for lingering effects (molotov, freeze)
@export var shield_amount: float = 0.0

# Med Kit
@export var heal_amount: float = 35.0

# Jetpack
@export var flight_duration: float = 1.2    # seconds of flight
@export var flight_force: float = -600.0    # upward velocity

static var ITEM_COLORS: Dictionary = {
	TacticalType.FRAG_GRENADE: Color(0.5, 0.5, 0.5),
	TacticalType.FLASH_FREEZE: Color(0.4, 0.8, 1.0),
	TacticalType.MOLOTOV: Color(1.0, 0.5, 0.1),
	TacticalType.MED_KIT: Color(0.2, 1.0, 0.3),
	TacticalType.JETPACK: Color(1.0, 0.9, 0.2),
	TacticalType.SHIELD: Color(0.45, 0.85, 1.0),
	TacticalType.CONFUSION: Color(0.95, 0.45, 1.0),
}

func get_color() -> Color:
	return ITEM_COLORS.get(tactical_type, Color.WHITE)


static func make_frag() -> TacticalData:
	var d := TacticalData.new()
	d.item_name = "Frag Grenade"
	d.tactical_type = TacticalType.FRAG_GRENADE
	d.throw_speed = 500.0
	d.fuse_time = 1.5
	d.radius = 230.0
	d.damage = 110.0
	d.knockback = 450.0
	d.charges = 3
	return d


static func make_flash_freeze() -> TacticalData:
	var d := TacticalData.new()
	d.item_name = "Flash Freeze"
	d.tactical_type = TacticalType.FLASH_FREEZE
	d.throw_speed = 450.0
	d.fuse_time = 1.2
	d.radius = 230.0
	d.damage = 5.0
	d.knockback = 50.0
	d.duration = 2.5       # freeze duration
	d.charges = 3
	return d


static func make_molotov() -> TacticalData:
	var d := TacticalData.new()
	d.item_name = "Molotov"
	d.tactical_type = TacticalType.MOLOTOV
	d.throw_speed = 400.0
	d.fuse_time = 0.0      # bursts on impact
	d.radius = 300.0
	d.damage = 15.0          # damage per tick
	d.knockback = 30.0
	d.duration = 4.0        # fire lasts 3 seconds
	d.charges = 3
	return d


static func make_med_kit() -> TacticalData:
	var d := TacticalData.new()
	d.item_name = "Med Kit"
	d.tactical_type = TacticalType.MED_KIT
	d.heal_amount = 55.0
	d.charges = 1
	return d


static func make_jetpack() -> TacticalData:
	var d := TacticalData.new()
	d.item_name = "Jetpack"
	d.tactical_type = TacticalType.JETPACK
	d.flight_duration = 1.2
	d.flight_force = -600.0
	d.charges = 1
	return d


static func make_shield() -> TacticalData:
	var d := TacticalData.new()
	d.item_name = "Shield"
	d.tactical_type = TacticalType.SHIELD
	d.shield_amount = 50.0
	d.duration = 9.0
	d.charges = 1
	return d


static func make_confusion() -> TacticalData:
	var d := TacticalData.new()
	d.item_name = "Confusion"
	d.tactical_type = TacticalType.CONFUSION
	d.radius = 0.0
	d.duration = 4.0
	d.charges = 1
	return d


static func get_all_tacticals() -> Array[TacticalData]:
	return [
		make_frag(),
		make_flash_freeze(),
		make_molotov(),
		make_med_kit(),
		make_jetpack(),
		make_shield(),
		make_confusion()
	]
