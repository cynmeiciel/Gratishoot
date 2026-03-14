class_name WeaponDB
extends RefCounted
## Static registry of all weapon definitions. Used by the spawner to pick random weapons.

static var _pool: Array[WeaponData] = []


static func get_pool() -> Array[WeaponData]:
	if _pool.is_empty():
		_build_pool()
	return _pool.duplicate()


static func get_by_name(wname: String) -> WeaponData:
	for w in get_pool():
		if w.weapon_name == wname:
			return w
	return null


static func get_pool_by_rarity(rarity: WeaponData.Rarity) -> Array[WeaponData]:
	var result: Array[WeaponData] = []
	for w in get_pool():
		if w.rarity == rarity:
			result.append(w)
	return result


static func _build_pool() -> void:
	# --- MELEE ---
	_add_melee({ "name": "Kitchen Knife",  "rarity": WeaponData.Rarity.COMMON,
		"dmg": 12,  "rate": 3.0, "kb": 180, "sec_dmg": 18, "sec_kb": 300, "sec_rate": 1.5,
		"range": 52.0, "equip": 0.20, "style": WeaponData.MeleeStyle.THRUST,
		"lunge1": 55.0, "lunge2": 88.0, "hitbox_y": -32.0, "sec_y": -2.0,
		"vis1": 0.10, "vis2": 0.13, "thickness": 2.4 })
	_add_melee({ "name": "Bayonet",         "rarity": WeaponData.Rarity.UNCOMMON,
		"dmg": 16,  "rate": 2.5, "kb": 220, "sec_dmg": 22, "sec_kb": 350, "sec_rate": 1.3,
		"range": 62.0, "equip": 0.20, "style": WeaponData.MeleeStyle.THRUST,
		"lunge1": 65.0, "lunge2": 105.0, "hitbox_y": -33.0, "sec_y": -2.0,
		"vis1": 0.11, "vis2": 0.15, "thickness": 2.8 })
	_add_melee({ "name": "Hook",            "rarity": WeaponData.Rarity.RARE,
		"dmg": 20, "rate": 2.2, "kb": 280, "sec_dmg": 30, "sec_kb": 420, "sec_rate": 1.0,
		"range": 58.0, "equip": 0.25, "style": WeaponData.MeleeStyle.SWEEP,
		"lunge1": 42.0, "lunge2": 72.0, "hitbox_y": -29.0, "sec_y": 2.0,
		"vis1": 0.12, "vis2": 0.16, "thickness": 3.0 })
	_add_melee({ "name": "Morning Star",    "rarity": WeaponData.Rarity.EPIC,
		"dmg": 40,  "rate": 1.2, "kb": 350, "sec_dmg": 38, "sec_kb": 500, "sec_rate": 0.8,
		"range": 64.0, "speed": 0.85, "equip": 0.30, "style": WeaponData.MeleeStyle.HEAVY,
		"lunge1": 28.0, "lunge2": 58.0, "hitbox_y": -34.0, "sec_y": -10.0,
		"vis1": 0.16, "vis2": 0.22, "thickness": 4.2 })
	_add_melee({ "name": "Butterfly Knife", "rarity": WeaponData.Rarity.LEGENDARY,
		"dmg": 35,  "rate": 2.5, "kb": 300, "sec_dmg": 45, "sec_kb": 450, "sec_rate": 2.0,
		"range": 50.0, "equip": 0.15, "style": WeaponData.MeleeStyle.SWEEP,
		"lunge1": 70.0, "lunge2": 115.0, "hitbox_y": -31.0, "sec_y": -2.0,
		"vis1": 0.10, "vis2": 0.14, "thickness": 3.0 })
	_add_melee({ "name": "Longsword",       "rarity": WeaponData.Rarity.MYTHIC,
		"dmg": 45,  "rate": 1.4, "kb": 450, "sec_dmg": 55, "sec_kb": 600, "sec_rate": 0.8,
		"range": 76.0, "speed": 0.8, "equip": 0.40, "style": WeaponData.MeleeStyle.HEAVY,
		"lunge1": 36.0, "lunge2": 70.0, "hitbox_y": -34.0, "sec_y": -12.0,
		"vis1": 0.17, "vis2": 0.24, "thickness": 4.6 })

	# --- PISTOL ---
	_add_gun({ "name": "M9",           "rarity": WeaponData.Rarity.COMMON,  "cat": WeaponData.GunCategory.PISTOL,
		"dmg": 13,  "rate": 3.2,  "kb": 190, "vel": 1500,
		"rec": 28,  "kick": 0.055, "reload": 0.88, "cap": 15, "reserve": 45,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.20 })
	_add_gun({ "name": "M1911",        "rarity": WeaponData.Rarity.COMMON,  "cat": WeaponData.GunCategory.PISTOL,
		"dmg": 14,  "rate": 3.0,  "kb": 205, "vel": 1550,
		"rec": 32,  "kick": 0.06,  "reload": 0.92, "cap": 8,  "reserve": 40,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.20 })
	_add_gun({ "name": "G18C",         "rarity": WeaponData.Rarity.COMMON,  "cat": WeaponData.GunCategory.PISTOL,
		"dmg": 10,  "rate": 10.0, "kb": 115, "vel": 1450,
		"rec": 20,  "kick": 0.028, "reload": 0.95, "cap": 18, "reserve": 54,
		"mode": WeaponData.FireMode.AUTO, "equip": 0.20 })
	_add_gun({ "name": "93R",          "rarity": WeaponData.Rarity.UNCOMMON, "cat": WeaponData.GunCategory.PISTOL,
		"dmg": 13,  "rate": 5.8,  "kb": 150, "vel": 1580,
		"rec": 26,  "kick": 0.04,  "reload": 0.92, "cap": 20, "reserve": 60,
		"mode": WeaponData.FireMode.BURST, "burst": 3, "equip": 0.20 })
	_add_gun({ "name": "USP",          "rarity": WeaponData.Rarity.UNCOMMON, "cat": WeaponData.GunCategory.PISTOL,
		"dmg": 16,  "rate": 3.0,  "kb": 215, "vel": 1625,
		"rec": 34,  "kick": 0.06,  "reload": 0.90, "cap": 12, "reserve": 36,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.20 })
	_add_gun({ "name": "Five SeveN",   "rarity": WeaponData.Rarity.EPIC,     "cat": WeaponData.GunCategory.PISTOL,
		"dmg": 18,  "rate": 4.0,  "kb": 200, "vel": 1800,
		"rec": 26,  "kick": 0.045, "reload": 0.86, "cap": 20, "reserve": 60,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.18 })
	_add_gun({ "name": "Tec-9",        "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.PISTOL,
		"dmg": 16,  "rate": 9.0,  "kb": 145, "vel": 1680,
		"rec": 24,  "kick": 0.032, "reload": 1.05, "cap": 24, "reserve": 72,
		"mode": WeaponData.FireMode.AUTO, "equip": 0.20 })
	_add_gun({ "name": "Colt Anaconda", "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.PISTOL,
		"dmg": 40,  "rate": 2.0,  "kb": 430, "vel": 1820,
		"rec": 100, "kick": 0.13,  "reload": 1.40, "cap": 6,  "reserve": 24,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.24 })
	_add_gun({ "name": "Desert Eagle", "rarity": WeaponData.Rarity.MYTHIC,  "cat": WeaponData.GunCategory.PISTOL,
		"dmg": 48,  "rate": 2.4,  "kb": 470, "vel": 1900,
		"rec": 118, "kick": 0.14,  "reload": 1.28, "cap": 7,  "reserve": 21,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.22 })

	# --- ASSAULT RIFLE ---
	_add_gun({ "name": "G36",    "rarity": WeaponData.Rarity.COMMON,    "cat": WeaponData.GunCategory.ASSAULT_RIFLE,
		"dmg": 15,  "rate": 10.0, "kb": 145, "vel": 1680,
		"rec": 36,  "kick": 0.042, "reload": 1.85, "cap": 30, "reserve": 90, "speed": 0.96,
		"mode": WeaponData.FireMode.AUTO, "equip": 0.35 })
	_add_gun({ "name": "M4A1",   "rarity": WeaponData.Rarity.COMMON,    "cat": WeaponData.GunCategory.ASSAULT_RIFLE,
		"dmg": 16,  "rate": 10.5, "kb": 150, "vel": 1700,
		"rec": 38,  "kick": 0.045, "reload": 1.8,  "cap": 30, "reserve": 90,  "speed": 0.95,
		"mode": WeaponData.FireMode.AUTO,   "equip": 0.35 })
	_add_gun({ "name": "SCAR-L", "rarity": WeaponData.Rarity.COMMON,    "cat": WeaponData.GunCategory.ASSAULT_RIFLE,
		"dmg": 17,  "rate": 9.6,  "kb": 165, "vel": 1725,
		"rec": 42,  "kick": 0.055, "reload": 1.95, "cap": 30, "reserve": 90, "speed": 0.93,
		"mode": WeaponData.FireMode.AUTO, "equip": 0.36 })
	_add_gun({ "name": "AK-47",  "rarity": WeaponData.Rarity.UNCOMMON,  "cat": WeaponData.GunCategory.ASSAULT_RIFLE,
		"dmg": 21,  "rate": 9.6,  "kb": 205, "vel": 1750,
		"rec": 52,  "kick": 0.085, "reload": 2.0,  "cap": 30, "reserve": 90,  "speed": 0.9,
		"mode": WeaponData.FireMode.AUTO,   "equip": 0.35 })
	_add_gun({ "name": "M416",   "rarity": WeaponData.Rarity.UNCOMMON,  "cat": WeaponData.GunCategory.ASSAULT_RIFLE,
		"dmg": 18,  "rate": 10.6, "kb": 165, "vel": 1780,
		"rec": 39,  "kick": 0.048, "reload": 1.8,  "cap": 30, "reserve": 90,  "speed": 0.94,
		"mode": WeaponData.FireMode.AUTO, "equip": 0.34 })
	_add_gun({ "name": "FAMAS",  "rarity": WeaponData.Rarity.UNCOMMON,  "cat": WeaponData.GunCategory.ASSAULT_RIFLE,
		"dmg": 17,  "rate": 12.8, "kb": 155, "vel": 1800,
		"rec": 40,  "kick": 0.05,  "reload": 1.7,  "cap": 30, "reserve": 90,  "speed": 0.95,
		"mode": WeaponData.FireMode.BURST,  "burst": 3, "equip": 0.32 })
	_add_gun({ "name": "AUG A3", "rarity": WeaponData.Rarity.EPIC,      "cat": WeaponData.GunCategory.ASSAULT_RIFLE,
		"dmg": 20,  "rate": 10.6, "kb": 175, "vel": 1880,
		"rec": 41,  "kick": 0.048, "reload": 1.75, "cap": 30, "reserve": 90,  "speed": 0.94,
		"mode": WeaponData.FireMode.AUTO,   "equip": 0.34 })
	_add_gun({ "name": "GROZA",  "rarity": WeaponData.Rarity.EPIC,      "cat": WeaponData.GunCategory.ASSAULT_RIFLE,
		"dmg": 23,  "rate": 11.0, "kb": 205, "vel": 1860,
		"rec": 49,  "kick": 0.07,  "reload": 1.9,  "cap": 30, "reserve": 90,  "speed": 0.9,
		"mode": WeaponData.FireMode.AUTO, "equip": 0.35 })
	_add_gun({ "name": "TAR-21", "rarity": WeaponData.Rarity.MYTHIC, "cat": WeaponData.GunCategory.ASSAULT_RIFLE,
		"dmg": 28,  "rate": 12.5, "kb": 225, "vel": 1950,
		"rec": 46,  "kick": 0.06,  "reload": 1.6,  "cap": 30, "reserve": 90,  "speed": 0.92,
		"mode": WeaponData.FireMode.AUTO,  "equip": 0.35 })

	# --- BATTLE RIFLE ---
	_add_gun({ "name": "M14",       "rarity": WeaponData.Rarity.EPIC,      "cat": WeaponData.GunCategory.BATTLE_RIFLE,
		"dmg": 34,  "rate": 10.0,  "kb": 360, "vel": 2800,
		"rec": 84,  "kick": 0.11,  "reload": 2.1,  "cap": 20, "reserve": 60,  "speed": 0.86,
		"mode": WeaponData.FireMode.AUTO, "equip": 0.48 })
	_add_gun({ "name": "SCAR-H",    "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.BATTLE_RIFLE,
		"dmg": 39,  "rate": 13.2,  "kb": 410, "vel": 3000,
		"rec": 95,  "kick": 0.12,  "reload": 2.2,  "cap": 20, "reserve": 60,  "speed": 0.84,
		"mode": WeaponData.FireMode.AUTO, "equip": 0.50 })
	_add_gun({ "name": "MCX Spear", "rarity": WeaponData.Rarity.MYTHIC,    "cat": WeaponData.GunCategory.BATTLE_RIFLE,
		"dmg": 42,  "rate": 13.8,  "kb": 430, "vel": 3250,
		"rec": 92,  "kick": 0.11,  "reload": 2.0,  "cap": 20, "reserve": 60,  "speed": 0.86,
		"mode": WeaponData.FireMode.AUTO, "equip": 0.48 })

	# --- SMG ---
	_add_gun({ "name": "Uzi",           "rarity": WeaponData.Rarity.COMMON,    "cat": WeaponData.GunCategory.SMG,
		"dmg": 10,  "rate": 15.5, "kb": 110, "vel": 1380,
		"rec": 19,  "kick": 0.03,  "reload": 1.25, "cap": 32, "reserve": 96,
		"mode": WeaponData.FireMode.AUTO,   "equip": 0.28 })
	_add_gun({ "name": "MP5K",         "rarity": WeaponData.Rarity.COMMON,    "cat": WeaponData.GunCategory.SMG,
		"dmg": 11,  "rate": 14.0, "kb": 120, "vel": 1450,
		"rec": 18,  "kick": 0.028, "reload": 1.3,  "cap": 30, "reserve": 90,
		"mode": WeaponData.FireMode.AUTO,   "equip": 0.30 })
	_add_gun({ "name": "PP-19 Bizon",  "rarity": WeaponData.Rarity.COMMON,    "cat": WeaponData.GunCategory.SMG,
		"dmg": 10,  "rate": 13.8, "kb": 112, "vel": 1400,
		"rec": 17,  "kick": 0.024, "reload": 1.65, "cap": 53, "reserve": 159,
		"mode": WeaponData.FireMode.AUTO,   "equip": 0.31 })
	_add_gun({ "name": "UMP45",        "rarity": WeaponData.Rarity.UNCOMMON,  "cat": WeaponData.GunCategory.SMG,
		"dmg": 15,  "rate": 10.6, "kb": 165, "vel": 1520,
		"rec": 28,  "kick": 0.04,  "reload": 1.45, "cap": 25, "reserve": 100,
		"mode": WeaponData.FireMode.AUTO,   "equip": 0.31 })
	_add_gun({ "name": "P90",           "rarity": WeaponData.Rarity.RARE,      "cat": WeaponData.GunCategory.SMG,
		"dmg": 13,  "rate": 15.0, "kb": 135, "vel": 1650,
		"rec": 20,  "kick": 0.026, "reload": 1.55, "cap": 50, "reserve": 150,
		"mode": WeaponData.FireMode.AUTO,   "equip": 0.31 })
	_add_gun({ "name": "MP7",           "rarity": WeaponData.Rarity.RARE,      "cat": WeaponData.GunCategory.SMG,
		"dmg": 14,  "rate": 16.2, "kb": 138, "vel": 1720,
		"rec": 19,  "kick": 0.024, "reload": 1.4,  "cap": 40, "reserve": 120,
		"mode": WeaponData.FireMode.AUTO,   "equip": 0.30 })
	_add_gun({ "name": "Kriss Vector", "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.SMG,
		"dmg": 19,  "rate": 18.5, "kb": 160, "vel": 1650,
		"rec": 16,  "kick": 0.022, "reload": 1.4,  "cap": 25, "reserve": 75,
		"mode": WeaponData.FireMode.AUTO,   "equip": 0.30 })
	_add_gun({ "name": "MP40",          "rarity": WeaponData.Rarity.MYTHIC,    "cat": WeaponData.GunCategory.SMG,
		"dmg": 18,  "rate": 13.5, "kb": 175, "vel": 1820,
		"rec": 22,  "kick": 0.03,  "reload": 1.35, "cap": 32, "reserve": 96,
		"mode": WeaponData.FireMode.AUTO,   "equip": 0.29 })

	# --- SHOTGUN ---
	_add_gun({ "name": "Remington M870", "rarity": WeaponData.Rarity.COMMON,    "cat": WeaponData.GunCategory.SHOTGUN,
		"dmg": 11,  "rate": 1.5,  "kb": 270, "vel": 1200,
		"rec": 82,  "kick": 0.10,  "reload": 2.2,  "cap": 5,  "reserve": 15,  "pellets": 6, "speed": 0.85,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.50 })
	_add_gun({ "name": "MAG-7",          "rarity": WeaponData.Rarity.COMMON,    "cat": WeaponData.GunCategory.SHOTGUN,
		"dmg": 12,  "rate": 1.7,  "kb": 275, "vel": 1250,
		"rec": 78,  "kick": 0.095, "reload": 2.0,  "cap": 5,  "reserve": 15,  "pellets": 6, "speed": 0.88,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.45 })
	_add_gun({ "name": "KS-23",          "rarity": WeaponData.Rarity.UNCOMMON,  "cat": WeaponData.GunCategory.SHOTGUN,
		"dmg": 16,  "rate": 1.2,  "kb": 340, "vel": 1200,
		"rec": 96,  "kick": 0.13,  "reload": 2.4,  "cap": 3,  "reserve": 12,  "pellets": 5, "speed": 0.8,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.50 })
	_add_gun({ "name": "KSG",            "rarity": WeaponData.Rarity.UNCOMMON,  "cat": WeaponData.GunCategory.SHOTGUN,
		"dmg": 11,  "rate": 1.9,  "kb": 280, "vel": 1280,
		"rec": 80,  "kick": 0.10,  "reload": 2.15, "cap": 10, "reserve": 30,  "pellets": 6, "speed": 0.84,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.47 })
	_add_gun({ "name": "SPAS-12",        "rarity": WeaponData.Rarity.RARE,      "cat": WeaponData.GunCategory.SHOTGUN,
		"dmg": 12,  "rate": 2.2,  "kb": 290, "vel": 1320,
		"rec": 88,  "kick": 0.105, "reload": 2.25, "cap": 8,  "reserve": 24,  "pellets": 7, "speed": 0.82,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.44 })
	_add_gun({ "name": "M1014",          "rarity": WeaponData.Rarity.RARE,      "cat": WeaponData.GunCategory.SHOTGUN,
		"dmg": 12,  "rate": 2.6,  "kb": 295, "vel": 1350,
		"rec": 90,  "kick": 0.11,  "reload": 2.35, "cap": 7,  "reserve": 21,  "pellets": 7, "speed": 0.8,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.43 })
	_add_gun({ "name": "AA-12",          "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.SHOTGUN,
		"dmg": 13,  "rate": 4.4,  "kb": 310, "vel": 1350,
		"rec": 96,  "kick": 0.12,  "reload": 2.5,  "cap": 8,  "reserve": 24,  "pellets": 8, "speed": 0.8,
		"mode": WeaponData.FireMode.AUTO,   "equip": 0.40 })
	_add_gun({ "name": "Benelli Vinci",  "rarity": WeaponData.Rarity.MYTHIC,    "cat": WeaponData.GunCategory.SHOTGUN,
		"dmg": 15,  "rate": 2.6,  "kb": 330, "vel": 1450,
		"rec": 100, "kick": 0.12,  "reload": 2.1,  "cap": 6,  "reserve": 18,  "pellets": 8, "speed": 0.82,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.42 })

	# --- SNIPER ---
	_add_gun({ "name": "Winchester",   "rarity": WeaponData.Rarity.RARE,      "cat": WeaponData.GunCategory.SNIPER,
		"dmg": 68,  "rate": 1.1,  "kb": 520, "vel": 3200,
		"rec": 132, "kick": 0.15,  "reload": 2.2,  "cap": 6,  "reserve": 18,  "speed": 0.82,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.56 })
	_add_gun({ "name": "Mosin Nagant", "rarity": WeaponData.Rarity.RARE,      "cat": WeaponData.GunCategory.SNIPER,
		"dmg": 75,  "rate": 0.95, "kb": 560, "vel": 3400,
		"rec": 150, "kick": 0.165, "reload": 2.5,  "cap": 5,  "reserve": 15,  "speed": 0.8,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.60 })
	_add_gun({ "name": "M1903",        "rarity": WeaponData.Rarity.RARE,      "cat": WeaponData.GunCategory.SNIPER,
		"dmg": 72,  "rate": 1.0,  "kb": 545, "vel": 3350,
		"rec": 146, "kick": 0.16,  "reload": 2.4,  "cap": 5,  "reserve": 20,  "speed": 0.82,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.58 })
	_add_gun({ "name": "Intervention", "rarity": WeaponData.Rarity.EPIC,      "cat": WeaponData.GunCategory.SNIPER,
		"dmg": 84,  "rate": 0.85, "kb": 630, "vel": 3900,
		"rec": 165, "kick": 0.18,  "reload": 2.8,  "cap": 5,  "reserve": 15,  "speed": 0.78,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.64 })
	_add_gun({ "name": "AWM",          "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.SNIPER,
		"dmg": 95,  "rate": 0.8,  "kb": 700, "vel": 4200,
		"rec": 180, "kick": 0.20,  "reload": 3.0,  "cap": 5,  "reserve": 10,  "speed": 0.75,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.65 })
	_add_gun({ "name": "BFG 50",       "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.SNIPER,
		"dmg": 150, "rate": 0.6,  "kb": 760, "vel": 4500,
		"rec": 220, "kick": 0.24,  "reload": 3.6,  "cap": 1,  "reserve": 3,  "speed": 0.7,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.74 })
	_add_gun({ "name": "Barrett M107", "rarity": WeaponData.Rarity.MYTHIC,    "cat": WeaponData.GunCategory.SNIPER,
		"dmg": 120, "rate": 0.72, "kb": 780, "vel": 4700,
		"rec": 210, "kick": 0.23,  "reload": 3.4,  "cap": 10, "reserve": 20,  "speed": 0.68,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.78 })

	# --- LMG ---
	_add_gun({ "name": "RPD",         "rarity": WeaponData.Rarity.COMMON,    "cat": WeaponData.GunCategory.LMG,
		"dmg": 14,  "rate": 11.4, "kb": 160, "vel": 1700,
		"rec": 48,  "kick": 0.06,  "reload": 3.4,  "cap": 75,  "reserve": 150, "speed": 0.74,
		"mode": WeaponData.FireMode.AUTO,  "equip": 0.66 })
	_add_gun({ "name": "M249",        "rarity": WeaponData.Rarity.COMMON, "cat": WeaponData.GunCategory.LMG,
		"dmg": 15,  "rate": 12.0, "kb": 170, "vel": 1750,
		"rec": 50,  "kick": 0.065, "reload": 3.5,  "cap": 100, "reserve": 200, "speed": 0.72,
		"mode": WeaponData.FireMode.AUTO,  "equip": 0.70 })
	_add_gun({ "name": "PKM",         "rarity": WeaponData.Rarity.COMMON,    "cat": WeaponData.GunCategory.LMG,
		"dmg": 17,  "rate": 10.6, "kb": 200, "vel": 1820,
		"rec": 58,  "kick": 0.075, "reload": 3.8,  "cap": 100, "reserve": 200, "speed": 0.68,
		"mode": WeaponData.FireMode.AUTO,  "equip": 0.74 })
	_add_gun({ "name": "Negev",       "rarity": WeaponData.Rarity.UNCOMMON,  "cat": WeaponData.GunCategory.LMG,
		"dmg": 15,  "rate": 14.5, "kb": 165, "vel": 1850,
		"rec": 56,  "kick": 0.07,  "reload": 3.9,  "cap": 100, "reserve": 200, "speed": 0.66,
		"mode": WeaponData.FireMode.AUTO,  "equip": 0.74 })
	_add_gun({ "name": "RPK",         "rarity": WeaponData.Rarity.RARE,      "cat": WeaponData.GunCategory.LMG,
		"dmg": 19,  "rate": 10.2, "kb": 225, "vel": 1960,
		"rec": 62,  "kick": 0.082, "reload": 3.5,  "cap": 75,  "reserve": 150, "speed": 0.7,
		"mode": WeaponData.FireMode.AUTO,  "equip": 0.72 })
	_add_gun({ "name": "MG3",         "rarity": WeaponData.Rarity.UNCOMMON,  "cat": WeaponData.GunCategory.LMG,
		"dmg": 14,  "rate": 17.0, "kb": 165, "vel": 1900,
		"rec": 60,  "kick": 0.078, "reload": 3.7,  "cap": 75,  "reserve": 150, "speed": 0.66,
		"mode": WeaponData.FireMode.AUTO,  "equip": 0.74 })
	_add_gun({ "name": "M60E4",       "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.LMG,
		"dmg": 19,  "rate": 10.8, "kb": 220, "vel": 2050,
		"rec": 64,  "kick": 0.082, "reload": 4.0,  "cap": 100, "reserve": 200, "speed": 0.66,
		"mode": WeaponData.FireMode.AUTO,  "equip": 0.78 })
	_add_gun({ "name": "M134 Minigun", "rarity": WeaponData.Rarity.MYTHIC, "cat": WeaponData.GunCategory.LMG,
		"dmg": 15,  "rate": 28.0, "kb": 145, "vel": 2100,
		"rec": 44,  "kick": 0.045, "reload": 4.5,  "cap": 200, "reserve": 400, "speed": 0.55,
		"mode": WeaponData.FireMode.AUTO,  "equip": 1.20 })

	# --- DMR ---
	_add_gun({ "name": "SR-25",      "rarity": WeaponData.Rarity.RARE,      "cat": WeaponData.GunCategory.DMR,
		"dmg": 32,  "rate": 3.8,  "kb": 290, "vel": 2450,
		"rec": 64,  "kick": 0.088, "reload": 1.8,  "cap": 20, "reserve": 60, "speed": 0.92,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.40 })
	_add_gun({ "name": "VSS Vintorez", "rarity": WeaponData.Rarity.RARE,      "cat": WeaponData.GunCategory.DMR,
		"dmg": 28,  "rate": 5.0,  "kb": 250, "vel": 1750,
		"rec": 40,  "kick": 0.055, "reload": 1.7,  "cap": 20, "reserve": 80, "speed": 0.95,
		"mode": WeaponData.FireMode.AUTO, "equip": 0.38 })
	_add_gun({ "name": "SKS",       "rarity": WeaponData.Rarity.RARE, "cat": WeaponData.GunCategory.DMR,
		"dmg": 34,  "rate": 3.3,  "kb": 300, "vel": 2500,
		"rec": 68,  "kick": 0.095, "reload": 1.8,  "cap": 10, "reserve": 30, "speed": 0.9,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.40 })
	_add_gun({ "name": "Mini-14",    "rarity": WeaponData.Rarity.EPIC,      "cat": WeaponData.GunCategory.DMR,
		"dmg": 38,  "rate": 4.0,  "kb": 320, "vel": 2700,
		"rec": 70,  "kick": 0.095, "reload": 1.7,  "cap": 20, "reserve": 60, "speed": 0.92,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.39 })
	_add_gun({ "name": "Mk12 SPR",   "rarity": WeaponData.Rarity.EPIC,      "cat": WeaponData.GunCategory.DMR,
		"dmg": 41,  "rate": 3.6,  "kb": 335, "vel": 2850,
		"rec": 74,  "kick": 0.1,   "reload": 1.85, "cap": 20, "reserve": 60, "speed": 0.9,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.41 })
	_add_gun({ "name": "Dragunov SVD", "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.DMR,
		"dmg": 52,  "rate": 2.8,  "kb": 410, "vel": 3100,
		"rec": 90,  "kick": 0.12,  "reload": 2.0,  "cap": 10, "reserve": 30, "speed": 0.84,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.46 })
	_add_gun({ "name": "M1 Garand", "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.DMR,
		"dmg": 48,  "rate": 2.9,  "kb": 390, "vel": 3000,
		"rec": 86,  "kick": 0.115, "reload": 2.0,  "cap": 8,  "reserve": 24, "speed": 0.85,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.45 })
	_add_gun({ "name": "Mk14",       "rarity": WeaponData.Rarity.MYTHIC,    "cat": WeaponData.GunCategory.DMR,
		"dmg": 56,  "rate": 4.4,  "kb": 430, "vel": 3350,
		"rec": 94,  "kick": 0.12,  "reload": 2.1,  "cap": 20, "reserve": 60, "speed": 0.82,
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.47 })


static func _add_melee(p: Dictionary) -> void:
	var w := WeaponData.new()
	w.type = WeaponData.Type.MELEE
	w.weapon_name        = p["name"]
	w.rarity             = p["rarity"]
	w.damage             = p.get("dmg",      10.0)
	w.fire_rate          = p.get("rate",      2.0)
	w.knockback          = p.get("kb",       200.0)
	w.secondary_damage   = p.get("sec_dmg",  15.0)
	w.secondary_knockback = p.get("sec_kb",  300.0)
	w.secondary_fire_rate = p.get("sec_rate", 1.0)
	w.melee_range        = p.get("range",    45.0)
	w.melee_style        = p.get("style", WeaponData.MeleeStyle.SWEEP)
	w.melee_lunge_primary = p.get("lunge1", 35.0)
	w.melee_lunge_secondary = p.get("lunge2", 65.0)
	w.melee_hitbox_y     = p.get("hitbox_y", -32.0)
	w.melee_secondary_y_offset = p.get("sec_y", -4.0)
	w.melee_primary_visual_time = p.get("vis1", 0.12)
	w.melee_secondary_visual_time = p.get("vis2", 0.16)
	w.melee_visual_thickness = p.get("thickness", 3.0)
	w.moving_speed_mult  = p.get("speed",     1.0)
	w.equip_time         = p.get("equip",     0.25)
	_pool.append(w)


static func _add_gun(p: Dictionary) -> void:
	var w := WeaponData.new()
	w.type = WeaponData.Type.GUN
	w.weapon_name       = p["name"]
	w.rarity            = p["rarity"]
	w.gun_category      = p["cat"]
	w.damage            = p.get("dmg",     10.0)
	w.fire_rate         = p.get("rate",     5.0)
	w.knockback         = p.get("kb",     150.0)
	w.velocity          = p.get("vel",    800.0)
	w.recoil            = p.get("rec",     30.0)
	w.recoil_kick       = p.get("kick",    0.05)
	w.reload_time       = p.get("reload",   2.0)
	w.capacity          = p.get("cap",       30)
	w.reserve_ammo      = p.get("reserve",   90)
	w.pellets           = p.get("pellets",    1)
	w.moving_speed_mult = p.get("speed",     1.0)
	w.fire_mode         = p.get("mode",  WeaponData.FireMode.SINGLE)
	w.burst_count       = p.get("burst",      3)
	w.equip_time        = p.get("equip",    0.35)
	_pool.append(w)
