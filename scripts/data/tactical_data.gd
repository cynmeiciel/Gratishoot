class_name TacticalData
extends Resource

enum TacticalType { FRAG_GRENADE, FLASH_FREEZE, MOLOTOV, MED_KIT, JETPACK }

@export var item_name: String = ""
@export var tactical_type: TacticalType = TacticalType.FRAG_GRENADE

# Grenade stats
@export var throw_speed: float = 500.0
@export var fuse_time: float = 1.5          # seconds before detonation
@export var radius: float = 80.0            # effect radius in pixels
@export var damage: float = 40.0            # for frag
@export var knockback: float = 400.0
@export var duration: float = 0.0           # for lingering effects (molotov, freeze)

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
}

func get_color() -> Color:
	return ITEM_COLORS.get(tactical_type, Color.WHITE)


static func make_frag() -> TacticalData:
	var d := TacticalData.new()
	d.item_name = "Frag Grenade"
	d.tactical_type = TacticalType.FRAG_GRENADE
	d.throw_speed = 500.0
	d.fuse_time = 1.5
	d.radius = 100.0
	d.damage = 45.0
	d.knockback = 450.0
	return d


static func make_flash_freeze() -> TacticalData:
	var d := TacticalData.new()
	d.item_name = "Flash Freeze"
	d.tactical_type = TacticalType.FLASH_FREEZE
	d.throw_speed = 450.0
	d.fuse_time = 1.2
	d.radius = 90.0
	d.damage = 5.0
	d.knockback = 50.0
	d.duration = 2.5       # freeze duration
	return d


static func make_molotov() -> TacticalData:
	var d := TacticalData.new()
	d.item_name = "Molotov"
	d.tactical_type = TacticalType.MOLOTOV
	d.throw_speed = 400.0
	d.fuse_time = 0.0      # bursts on impact
	d.radius = 100.0
	d.damage = 8.0          # damage per tick
	d.knockback = 30.0
	d.duration = 3.0        # fire lasts 3 seconds
	return d


static func make_med_kit() -> TacticalData:
	var d := TacticalData.new()
	d.item_name = "Med Kit"
	d.tactical_type = TacticalType.MED_KIT
	d.heal_amount = 35.0
	return d


static func make_jetpack() -> TacticalData:
	var d := TacticalData.new()
	d.item_name = "Jetpack"
	d.tactical_type = TacticalType.JETPACK
	d.flight_duration = 1.2
	d.flight_force = -600.0
	return d


static func get_all_tacticals() -> Array[TacticalData]:
	return [make_frag(), make_flash_freeze(), make_molotov(), make_med_kit(), make_jetpack()]
