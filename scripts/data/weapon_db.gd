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
		"dmg": 12,  "rate": 4.0, "kb": 160, "sec_dmg": 16, "sec_kb": 260, "sec_rate": 3.2,
		"range": 45.0, "equip": 0.15, "style": WeaponData.MeleeStyle.THRUST,
		"lunge1": 25.0, "lunge2": 35.0, "hitbox_y": -32.0, "sec_y": -2.0,
		"vis1": 0.08, "vis2": 0.10, "thickness": 2.2, "speed": 1.05 })
	_add_melee({ "name": "Bayonet",         "rarity": WeaponData.Rarity.UNCOMMON,
		"dmg": 16,  "rate": 3.3, "kb": 200, "sec_dmg": 20, "sec_kb": 320, "sec_rate": 2.2,
		"range": 55.0, "equip": 0.18, "style": WeaponData.MeleeStyle.THRUST,
		"lunge1": 35.0, "lunge2": 55.0, "hitbox_y": -33.0, "sec_y": -2.0,
		"vis1": 0.09, "vis2": 0.12, "thickness": 2.6, "speed": 1.02 })
	_add_melee({ "name": "Hook",            "rarity": WeaponData.Rarity.RARE,
		"dmg": 20, "rate": 2.2, "kb": 290, "sec_dmg": 28, "sec_kb": 400, "sec_rate": 1.5,
		"range": 60.0, "equip": 0.22, "style": WeaponData.MeleeStyle.SWEEP,
		"lunge1": 48.0, "lunge2": 75.0, "hitbox_y": -29.0, "sec_y": 0.0,
		"vis1": 0.12, "vis2": 0.16, "thickness": 3.1, "speed": 1.0 })
	_add_melee({ "name": "Morning Star",    "rarity": WeaponData.Rarity.EPIC,
		"dmg": 40,  "rate": 1.1, "kb": 400, "sec_dmg": 36, "sec_kb": 550, "sec_rate": 0.65,
		"range": 68.0, "speed": 0.80, "equip": 0.35, "style": WeaponData.MeleeStyle.HEAVY,
		"lunge1": 45.0, "lunge2": 85.0, "hitbox_y": -34.0, "sec_y": -12.0,
		"vis1": 0.16, "vis2": 0.24, "thickness": 4.4 })
	_add_melee({ "name": "Butterfly Knife", "rarity": WeaponData.Rarity.LEGENDARY,
		"dmg": 35,  "rate": 2.8, "kb": 310, "sec_dmg": 42, "sec_kb": 430, "sec_rate": 2.4,
		"range": 56.0, "equip": 0.12, "style": WeaponData.MeleeStyle.SWEEP,
		"lunge1": 55.0, "lunge2": 92.0, "hitbox_y": -31.0, "sec_y": -1.0,
		"vis1": 0.10, "vis2": 0.13, "thickness": 2.9, "speed": 1.04 })
	_add_melee({ "name": "Longsword",       "rarity": WeaponData.Rarity.MYTHIC,
		"dmg": 45,  "rate": 1.2, "kb": 480, "sec_dmg": 52, "sec_kb": 620, "sec_rate": 0.6,
		"range": 78.0, "speed": 0.77, "equip": 0.42, "style": WeaponData.MeleeStyle.HEAVY,
		"lunge1": 55.0, "lunge2": 95.0, "hitbox_y": -34.0, "sec_y": -14.0,
		"vis1": 0.17, "vis2": 0.26, "thickness": 4.8 })

	# --- PISTOL ---
	_add_gun({ "name": "M9",           "rarity": WeaponData.Rarity.COMMON,  "cat": WeaponData.GunCategory.PISTOL,
		"dmg": 13,  "rate": 7.2,  "kb": 190, "vel": 1600,
		"rec": 28,  "kick": 0.055, "reload": 0.68, "cap": 15, "reserve": 45,
		"spread": 3.2,
		"sfx": "gun_m9",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.20 })
	_add_gun({ "name": "M1911",        "rarity": WeaponData.Rarity.COMMON,  "cat": WeaponData.GunCategory.PISTOL,
		"dmg": 15,  "rate": 7.0,  "kb": 205, "vel": 1750,
		"rec": 32,  "kick": 0.06,  "reload": 0.62, "cap": 8,  "reserve": 40,
		"spread": 3,
		"sfx": "gun_m1911",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.20 })
	_add_gun({ "name": "G18C",         "rarity": WeaponData.Rarity.COMMON,  "cat": WeaponData.GunCategory.PISTOL,
		"dmg": 6,  "rate": 30.0, "kb": 115, "vel": 1450,
		"rec": 20,  "kick": 0.028, "reload": 0.75, "cap": 18, "reserve": 90,
		"spread": 5.6,
		"sfx": "gun_g18c",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.20 })
	_add_gun({ "name": "93R",          "rarity": WeaponData.Rarity.UNCOMMON, "cat": WeaponData.GunCategory.PISTOL,
		"dmg": 11,  "rate": 19.8,  "kb": 150, "vel": 1580,
		"rec": 26,  "kick": 0.04,  "reload": 0.92, "cap": 21, "reserve": 63,
		"spread": 3,
		"sfx": "gun_93r",
		"mode": WeaponData.FireMode.BURST, "burst": 3, "equip": 0.20 })
	_add_gun({ "name": "USP",          "rarity": WeaponData.Rarity.UNCOMMON, "cat": WeaponData.GunCategory.PISTOL,
		"dmg": 16,  "rate": 9.0,  "kb": 215, "vel": 1925,
		"rec": 34,  "kick": 0.06,  "reload": 0.90, "cap": 12, "reserve": 72,
		"spread": 1.9,
		"sfx": "gun_usp",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.20 })
	_add_gun({ "name": "Five SeveN",   "rarity": WeaponData.Rarity.EPIC,     "cat": WeaponData.GunCategory.PISTOL,
		"dmg": 20,  "rate": 9.0,  "kb": 200, "vel": 2300,
		"rec": 26,  "kick": 0.045, "reload": 0.86, "cap": 20, "reserve": 60,
		"spread": 1.7,
		"sfx": "gun_five_seven",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.18 })
	_add_gun({ "name": "Tec-9",        "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.PISTOL,
		"dmg": 15,  "rate": 25.0,  "kb": 145, "vel": 1680,
		"rec": 24,  "kick": 0.032, "reload": 1.05, "cap": 13, "reserve": 104,
		"spread": 3.8,
		"sfx": "gun_tec_9",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.20 })
	_add_gun({ "name": "Colt Anaconda", "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.PISTOL,
		"dmg": 55,  "rate": 2.0,  "kb": 430, "vel": 2820,
		"rec": 100, "kick": 0.13,  "reload": 1.40, "cap": 6,  "reserve": 24,
		"spread": 1.3,
		"sfx": "gun_colt_anaconda",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.24 })
	_add_gun({ "name": "Desert Eagle", "rarity": WeaponData.Rarity.MYTHIC,  "cat": WeaponData.GunCategory.PISTOL,
		"dmg": 50,  "rate": 3.4,  "kb": 470, "vel": 4600,
		"rec": 118, "kick": 0.14,  "reload": 1.28, "cap": 7,  "reserve": 21,
		"spread": 1.1,
		"sfx": "gun_desert_eagle",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.22 })

	# --- ASSAULT RIFLE ---
	_add_gun({ "name": "G36",    "rarity": WeaponData.Rarity.COMMON,    "cat": WeaponData.GunCategory.ASSAULT_RIFLE,
		"dmg": 15,  "rate": 10.0, "kb": 145, "vel": 2680,
		"rec": 36,  "kick": 0.042, "reload": 1.85, "cap": 30, "reserve": 90, "speed": 0.96,
		"spread": 3.1,
		"sfx": "gun_g36",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.35 })
	_add_gun({ "name": "M4A1",   "rarity": WeaponData.Rarity.COMMON,    "cat": WeaponData.GunCategory.ASSAULT_RIFLE,
		"dmg": 16,  "rate": 10.5, "kb": 150, "vel": 2600,
		"rec": 38,  "kick": 0.025, "reload": 1.8,  "cap": 30, "reserve": 90,  "speed": 0.95,
		"spread": 2.8,
		"sfx": "gun_m4a1",
		"mode": WeaponData.FireMode.AUTO,   "equip": 0.35 })
	_add_gun({ "name": "SCAR-L", "rarity": WeaponData.Rarity.COMMON,    "cat": WeaponData.GunCategory.ASSAULT_RIFLE,
		"dmg": 17,  "rate": 9.6,  "kb": 165, "vel": 2625,
		"rec": 42,  "kick": 0.055, "reload": 1.95, "cap": 30, "reserve": 90, "speed": 0.93,
		"spread": 2.6,
		"sfx": "gun_scar_l",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.36 })
	_add_gun({ "name": "AK-47",  "rarity": WeaponData.Rarity.UNCOMMON,  "cat": WeaponData.GunCategory.ASSAULT_RIFLE,
		"dmg": 21,  "rate": 9.6,  "kb": 205, "vel": 3050,
		"rec": 52,  "kick": 0.085, "reload": 2.0,  "cap": 30, "reserve": 90,  "speed": 0.9,
		"spread": 3.4,
		"sfx": "gun_ak_47",
		"mode": WeaponData.FireMode.AUTO,   "equip": 0.35 })
	_add_gun({ "name": "M416",   "rarity": WeaponData.Rarity.UNCOMMON,  "cat": WeaponData.GunCategory.ASSAULT_RIFLE,
		"dmg": 18,  "rate": 10.6, "kb": 165, "vel": 2780,
		"rec": 39,  "kick": 0.048, "reload": 1.8,  "cap": 30, "reserve": 90,  "speed": 0.94,
		"spread": 2.5,
		"sfx": "gun_m416",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.34 })
	_add_gun({ "name": "FAMAS",  "rarity": WeaponData.Rarity.UNCOMMON,  "cat": WeaponData.GunCategory.ASSAULT_RIFLE,
		"dmg": 18,  "rate": 14.8, "kb": 155, "vel": 3000,
		"rec": 40,  "kick": 0.05,  "reload": 1.7,  "cap": 30, "reserve": 90,  "speed": 0.95,
		"spread": 3,
		"sfx": "gun_famas",
		"mode": WeaponData.FireMode.BURST,  "burst": 3, "equip": 0.32 })
	_add_gun({ "name": "AUG A3", "rarity": WeaponData.Rarity.EPIC,      "cat": WeaponData.GunCategory.ASSAULT_RIFLE,
		"dmg": 20,  "rate": 10.6, "kb": 175, "vel": 3180,
		"rec": 41,  "kick": 0.048, "reload": 1.75, "cap": 30, "reserve": 90,  "speed": 0.94,
		"spread": 2.3,
		"sfx": "gun_aug_a3",
		"mode": WeaponData.FireMode.AUTO,   "equip": 0.34 })
	_add_gun({ "name": "GROZA",  "rarity": WeaponData.Rarity.EPIC,      "cat": WeaponData.GunCategory.ASSAULT_RIFLE,
		"dmg": 23,  "rate": 11.0, "kb": 205, "vel": 2960,
		"rec": 49,  "kick": 0.07,  "reload": 1.9,  "cap": 30, "reserve": 90,  "speed": 0.9,
		"spread": 3.1,
		"sfx": "gun_groza",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.35 })
	_add_gun({ "name": "TAR-21", "rarity": WeaponData.Rarity.MYTHIC, "cat": WeaponData.GunCategory.ASSAULT_RIFLE,
		"dmg": 27,  "rate": 12.5, "kb": 225, "vel": 3350,
		"rec": 46,  "kick": 0.06,  "reload": 1.6,  "cap": 30, "reserve": 90,  "speed": 0.92,
		"spread": 2.7,
		"sfx": "gun_tar_21",
		"mode": WeaponData.FireMode.AUTO,  "equip": 0.35 })
	_add_gun({ "name": "VX-Null Carbine", "rarity": WeaponData.Rarity.CONTRABAND, "cat": WeaponData.GunCategory.ASSAULT_RIFLE,
		"dmg": 20,  "rate": 13.2, "kb": 280, "vel": 3800,
		"rec": 28,  "kick": 0.035, "reload": 1.4,  "cap": 30, "reserve": 90, "speed": 0.96,
		"spread": 1.3,
		"sfx": "gun_vx_null_carbine",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.30,
		"split": true })

	# --- BATTLE RIFLE ---
	_add_gun({ "name": "M14",       "rarity": WeaponData.Rarity.EPIC,      "cat": WeaponData.GunCategory.BATTLE_RIFLE,
		"dmg": 34,  "rate": 10.0,  "kb": 360, "vel": 3300,
		"rec": 84,  "kick": 0.11,  "reload": 2.1,  "cap": 20, "reserve": 60,  "speed": 0.86,
		"spread": 2,
		"sfx": "gun_m14",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.48 })
	_add_gun({ "name": "SCAR-H",    "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.BATTLE_RIFLE,
		"dmg": 39,  "rate": 13.2,  "kb": 410, "vel": 3800,
		"rec": 95,  "kick": 0.12,  "reload": 2.2,  "cap": 20, "reserve": 60,  "speed": 0.84,
		"spread": 2.3,
		"sfx": "gun_scar_h",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.50 })
	_add_gun({ "name": "MCX Spear", "rarity": WeaponData.Rarity.MYTHIC,    "cat": WeaponData.GunCategory.BATTLE_RIFLE,
		"dmg": 40,  "rate": 13.8,  "kb": 430, "vel": 4050,
		"rec": 92,  "kick": 0.11,  "reload": 2.0,  "cap": 20, "reserve": 60,  "speed": 0.86,
		"spread": 1.8,
		"sfx": "gun_mcx_spear",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.48 })

	# --- SMG ---
	_add_gun({ "name": "Uzi",           "rarity": WeaponData.Rarity.COMMON,    "cat": WeaponData.GunCategory.SMG,
		"dmg": 8,  "rate": 20.5, "kb": 110, "vel": 2080,
		"rec": 19,  "kick": 0.03,  "reload": 1.25, "cap": 32, "reserve": 192,
		"spread": 10,
		"sfx": "gun_uzi",
		"mode": WeaponData.FireMode.AUTO,   "equip": 0.28 })
	_add_gun({ "name": "MP5K",         "rarity": WeaponData.Rarity.COMMON,    "cat": WeaponData.GunCategory.SMG,
		"dmg": 11,  "rate": 14.0, "kb": 120, "vel": 1850,
		"rec": 18,  "kick": 0.028, "reload": 1.3,  "cap": 30, "reserve": 90,
		"spread": 4.1,
		"sfx": "gun_mp5k",
		"mode": WeaponData.FireMode.AUTO,   "equip": 0.30 })
	_add_gun({ "name": "PP-19 Bizon",  "rarity": WeaponData.Rarity.COMMON,    "cat": WeaponData.GunCategory.SMG,
		"dmg": 10,  "rate": 13.8, "kb": 112, "vel": 1400,
		"rec": 17,  "kick": 0.024, "reload": 1.65, "cap": 53, "reserve": 159,
		"spread": 3.9,
		"sfx": "gun_pp_19_bizon",
		"mode": WeaponData.FireMode.AUTO,   "equip": 0.31 })
	_add_gun({ "name": "UMP45",        "rarity": WeaponData.Rarity.UNCOMMON,  "cat": WeaponData.GunCategory.SMG,
		"dmg": 15,  "rate": 10.6, "kb": 165, "vel": 1820,
		"rec": 28,  "kick": 0.04,  "reload": 1.45, "cap": 25, "reserve": 100,
		"spread": 3.2,
		"sfx": "gun_ump45",
		"mode": WeaponData.FireMode.AUTO,   "equip": 0.31 })
	_add_gun({ "name": "P90",           "rarity": WeaponData.Rarity.RARE,      "cat": WeaponData.GunCategory.SMG,
		"dmg": 13,  "rate": 15.0, "kb": 135, "vel": 1750,
		"rec": 20,  "kick": 0.026, "reload": 1.55, "cap": 50, "reserve": 150,
		"spread": 3.4,
		"sfx": "gun_p90",
		"mode": WeaponData.FireMode.AUTO,   "equip": 0.31 })
	_add_gun({ "name": "MP7",           "rarity": WeaponData.Rarity.RARE,      "cat": WeaponData.GunCategory.SMG,
		"dmg": 14,  "rate": 16.2, "kb": 138, "vel": 2320,
		"rec": 19,  "kick": 0.024, "reload": 1.4,  "cap": 30, "reserve": 90,
		"spread": 3.1,
		"sfx": "gun_mp7",
		"mode": WeaponData.FireMode.AUTO,   "equip": 0.30 })
	_add_gun({ "name": "Sterling L2A3", "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.SMG,
		"dmg": 23,  "rate": 10.0, "kb": 160, "vel": 2050,
		"rec": 10,  "kick": 0.042, "reload": 1.7,  "cap": 34, "reserve": 102,
		"spread": 1.0,
		"sfx": "gun_sterling_l2a3",
		"mode": WeaponData.FireMode.AUTO,   "equip": 0.30 })
	_add_gun({ "name": "Kriss Vector", "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.SMG,
		"dmg": 15,  "rate": 18.5, "kb": 160, "vel": 2650,
		"rec": 7,  "kick": 0.012, "reload": 1.4,  "cap": 33, "reserve": 99,
		"spread": 1.7,
		"sfx": "gun_kriss_vector",
		"mode": WeaponData.FireMode.AUTO,   "equip": 0.30 })
	_add_gun({ "name": "MP40",          "rarity": WeaponData.Rarity.MYTHIC,    "cat": WeaponData.GunCategory.SMG,
		"dmg": 21,  "rate": 10.5, "kb": 175, "vel": 2920,
		"rec": 19,  "kick": 0.03,  "reload": 1.35, "cap": 32, "reserve": 96,
		"spread": 2.4,
		"sfx": "gun_mp40",
		"mode": WeaponData.FireMode.AUTO,   "equip": 0.29 })

	# --- SHOTGUN ---
	_add_gun({ "name": "Remington M870", "rarity": WeaponData.Rarity.COMMON,    "cat": WeaponData.GunCategory.SHOTGUN,
		"dmg": 11,  "rate": 1.5,  "kb": 270, "vel": 1300,
		"rec": 82,  "kick": 0.10,  "reload": 2.2,  "cap": 5,  "reserve": 15,  "pellets": 5, "speed": 0.85,
		"spread": 9,
		"sfx": "gun_remington_m870",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.50 })
	_add_gun({ "name": "MAG-7",          "rarity": WeaponData.Rarity.COMMON,    "cat": WeaponData.GunCategory.SHOTGUN,
		"dmg": 12,  "rate": 1.7,  "kb": 275, "vel": 1110,
		"rec": 78,  "kick": 0.095, "reload": 2.0,  "cap": 5,  "reserve": 15,  "pellets": 6, "speed": 0.88,
		"spread": 9.8,
		"sfx": "gun_mag_7",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.45 })
	_add_gun({ "name": "KS-23",          "rarity": WeaponData.Rarity.UNCOMMON,  "cat": WeaponData.GunCategory.SHOTGUN,
		"dmg": 16,  "rate": 1.2,  "kb": 340, "vel": 1200,
		"rec": 96,  "kick": 0.13,  "reload": 2.4,  "cap": 3,  "reserve": 12,  "pellets": 6, "speed": 0.8,
		"spread": 8.8,
		"sfx": "gun_ks_23",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.50 })
	_add_gun({ "name": "KSG",            "rarity": WeaponData.Rarity.UNCOMMON,  "cat": WeaponData.GunCategory.SHOTGUN,
		"dmg": 11,  "rate": 1.9,  "kb": 280, "vel": 1280,
		"rec": 80,  "kick": 0.10,  "reload": 2.15, "cap": 10, "reserve": 30,  "pellets": 6, "speed": 0.84,
		"spread": 9.4,
		"sfx": "gun_ksg",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.47 })
	_add_gun({ "name": "SPAS-12",        "rarity": WeaponData.Rarity.RARE,      "cat": WeaponData.GunCategory.SHOTGUN,
		"dmg": 13,  "rate": 2.2,  "kb": 290, "vel": 1820,
		"rec": 88,  "kick": 0.105, "reload": 2.25, "cap": 8,  "reserve": 24,  "pellets": 7, "speed": 0.82,
		"spread": 3.1,
		"sfx": "gun_spas_12",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.44 })
	_add_gun({ "name": "M1014",          "rarity": WeaponData.Rarity.RARE,      "cat": WeaponData.GunCategory.SHOTGUN,
		"dmg": 13,  "rate": 2.9,  "kb": 295, "vel": 1350,
		"rec": 90,  "kick": 0.11,  "reload": 2.35, "cap": 7,  "reserve": 21,  "pellets": 7, "speed": 0.8,
		"spread": 8.7,
		"sfx": "gun_m1014",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.43 })
	_add_gun({ "name": "M3K",          "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.SHOTGUN,
		"dmg": 11,  "rate": 1.3,  "kb": 310, "vel": 2450,
		"rec": 46,  "kick": 0.4,  "reload": 1.5,  "cap": 9,  "reserve": 27,  "pellets": 9, "speed": 0.95,
		"spread": 2.3,
		"sfx": "gun_m3k",
		"mode": WeaponData.FireMode.SINGLE,   "equip": 0.40 })
	_add_gun({ "name": "AA-12",          "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.SHOTGUN,
		"dmg": 6,  "rate": 4.9,  "kb": 310, "vel": 850,
		"rec": 96,  "kick": 0.12,  "reload": 3.5,  "cap": 20,  "reserve": 100,  "pellets": 15, "speed": 0.8,
		"spread": 13.0,
		"sfx": "gun_aa_12",
		"mode": WeaponData.FireMode.AUTO,   "equip": 0.40 })
	_add_gun({ "name": "Benelli Vinci",  "rarity": WeaponData.Rarity.MYTHIC,    "cat": WeaponData.GunCategory.SHOTGUN,
		"dmg": 12,  "rate": 1.5,  "kb": 330, "vel": 1950,
		"rec": 100, "kick": 0.12,  "reload": 2.1,  "cap": 6,  "reserve": 18,  "pellets": 15, "speed": 0.9,
		"spread": 7.2,
		"sfx": "gun_benelli_vinci",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.42 })

	# --- SNIPER ---
	_add_gun({ "name": "Winchester",   "rarity": WeaponData.Rarity.RARE,      "cat": WeaponData.GunCategory.SNIPER,
		"dmg": 55,  "rate": 1.5,  "kb": 520, "vel": 7320,
		"rec": 132, "kick": 0.15,  "reload": 2.2,  "cap": 6,  "reserve": 18,  "speed": 0.82,
		"spread": 0.5,
		"sfx": "gun_winchester",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.56 })
	_add_gun({ "name": "Mosin Nagant", "rarity": WeaponData.Rarity.RARE,      "cat": WeaponData.GunCategory.SNIPER,
		"dmg": 75,  "rate": 0.95, "kb": 560, "vel": 7400,
		"rec": 150, "kick": 0.165, "reload": 2.5,  "cap": 5,  "reserve": 15,  "speed": 0.8,
		"spread": 0.3,
		"sfx": "gun_mosin_nagant",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.60 })
	_add_gun({ "name": "M1903",        "rarity": WeaponData.Rarity.RARE,      "cat": WeaponData.GunCategory.SNIPER,
		"dmg": 72,  "rate": 1.2,  "kb": 545, "vel": 7350,
		"rec": 146, "kick": 0.16,  "reload": 2.4,  "cap": 5,  "reserve": 20,  "speed": 0.82,
		"spread": 0.6,
		"sfx": "gun_m1903",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.58 })
	_add_gun({ "name": "Intervention", "rarity": WeaponData.Rarity.EPIC,      "cat": WeaponData.GunCategory.SNIPER,
		"dmg": 84,  "rate": 0.85, "kb": 630, "vel": 7900,
		"rec": 165, "kick": 0.18,  "reload": 2.8,  "cap": 5,  "reserve": 15,  "speed": 0.78,
		"spread": 0.3,
		"sfx": "gun_intervention",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.64 })
	_add_gun({ "name": "AWM",          "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.SNIPER,
		"dmg": 95,  "rate": 0.8,  "kb": 700, "vel": 8200,
		"rec": 180, "kick": 0.20,  "reload": 3.0,  "cap": 5,  "reserve": 10,  "speed": 0.75,
		"spread": 0.2,
		"sfx": "gun_awm",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.65 })
	_add_gun({ "name": "BFG 50",       "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.SNIPER,
		"dmg": 150, "rate": 0.6,  "kb": 760, "vel": 9500,
		"rec": 220, "kick": 0.24,  "reload": 3.6,  "cap": 1,  "reserve": 3,  "speed": 0.7,
		"spread": 0.2,
		"sfx": "gun_bfg_50",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.74 })
	_add_gun({ "name": "Barrett M107", "rarity": WeaponData.Rarity.MYTHIC,    "cat": WeaponData.GunCategory.SNIPER,
		"dmg": 120, "rate": 0.72, "kb": 780, "vel": 9700,
		"rec": 210, "kick": 0.23,  "reload": 3.4,  "cap": 10, "reserve": 20,  "speed": 0.68,
		"spread": 0.1,
		"sfx": "gun_barrett_m107",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.78 })

	# --- LMG ---
	_add_gun({ "name": "RPD",         "rarity": WeaponData.Rarity.COMMON,    "cat": WeaponData.GunCategory.LMG,
		"dmg": 14,  "rate": 11.4, "kb": 160, "vel": 2700,
		"rec": 78,  "kick": 0.06,  "reload": 3.4,  "cap": 75,  "reserve": 150, "speed": 0.74,
		"spread": 10.7,
		"sfx": "gun_rpd",
		"mode": WeaponData.FireMode.AUTO,  "equip": 0.66 })
	_add_gun({ "name": "M249",        "rarity": WeaponData.Rarity.COMMON, "cat": WeaponData.GunCategory.LMG,
		"dmg": 15,  "rate": 12.0, "kb": 170, "vel": 2750,
		"rec": 80,  "kick": 0.065, "reload": 3.5,  "cap": 100, "reserve": 200, "speed": 0.72,
		"spread": 15,
		"sfx": "gun_m249",
		"mode": WeaponData.FireMode.AUTO,  "equip": 0.70 })
	_add_gun({ "name": "PKM",         "rarity": WeaponData.Rarity.COMMON,    "cat": WeaponData.GunCategory.LMG,
		"dmg": 17,  "rate": 10.6, "kb": 200, "vel": 2820,
		"rec": 78,  "kick": 0.075, "reload": 3.8,  "cap": 100, "reserve": 200, "speed": 0.68,
		"spread": 14.2,
		"sfx": "gun_pkm",
		"mode": WeaponData.FireMode.AUTO,  "equip": 0.74 })
	_add_gun({ "name": "Negev",       "rarity": WeaponData.Rarity.UNCOMMON,  "cat": WeaponData.GunCategory.LMG,
		"dmg": 15,  "rate": 14.5, "kb": 165, "vel": 2850,
		"rec": 56,  "kick": 0.07,  "reload": 3.9,  "cap": 100, "reserve": 200, "speed": 0.66,
		"spread": 15.2,
		"sfx": "gun_negev",
		"mode": WeaponData.FireMode.AUTO,  "equip": 0.74 })
	_add_gun({ "name": "RPK",         "rarity": WeaponData.Rarity.RARE,      "cat": WeaponData.GunCategory.LMG,
		"dmg": 19,  "rate": 10.2, "kb": 225, "vel": 2960,
		"rec": 52,  "kick": 0.082, "reload": 3.5,  "cap": 75,  "reserve": 150, "speed": 0.7,
		"spread": 13.9,
		"sfx": "gun_rpk",
		"mode": WeaponData.FireMode.AUTO,  "equip": 0.72 })
	_add_gun({ "name": "MG3",         "rarity": WeaponData.Rarity.UNCOMMON,  "cat": WeaponData.GunCategory.LMG,
		"dmg": 14,  "rate": 17.0, "kb": 165, "vel": 2900,
		"rec": 50,  "kick": 0.078, "reload": 3.7,  "cap": 75,  "reserve": 150, "speed": 0.66,
		"spread": 12.5,
		"sfx": "gun_mg3",
		"mode": WeaponData.FireMode.AUTO,  "equip": 0.74 })
	_add_gun({ "name": "M60E4",       "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.LMG,
		"dmg": 19,  "rate": 10.8, "kb": 220, "vel": 3050,
		"rec": 44,  "kick": 0.082, "reload": 4.0,  "cap": 100, "reserve": 200, "speed": 0.66,
		"spread": 12.1,
		"sfx": "gun_m60e4",
		"mode": WeaponData.FireMode.AUTO,  "equip": 0.78 })
	_add_gun({ "name": "M134 Minigun", "rarity": WeaponData.Rarity.MYTHIC, "cat": WeaponData.GunCategory.LMG,
		"dmg": 15,  "rate": 28.0, "kb": 145, "vel": 2100,
		"rec": 44,  "kick": 0.045, "reload": 4.5,  "cap": 200, "reserve": 400, "speed": 0.55,
		"spread": 11.2,
		"sfx": "gun_m134_minigun",
		"mode": WeaponData.FireMode.AUTO,  "equip": 1.20 })

	# --- DMR ---
	_add_gun({ "name": "SR-25",      "rarity": WeaponData.Rarity.RARE,      "cat": WeaponData.GunCategory.DMR,
		"dmg": 32,  "rate": 3.8,  "kb": 290, "vel": 6450,
		"rec": 64,  "kick": 0.088, "reload": 1.8,  "cap": 20, "reserve": 60, "speed": 0.92,
		"spread": 0.6,
		"sfx": "gun_sr_25",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.40 })
	_add_gun({ "name": "VSS Vintorez", "rarity": WeaponData.Rarity.RARE,      "cat": WeaponData.GunCategory.DMR,
		"dmg": 26,  "rate": 4.8,  "kb": 250, "vel": 4750,
		"rec": 40,  "kick": 0.055, "reload": 2.7,  "cap": 10, "reserve": 80, "speed": 0.95,
		"spread": 2.0,
		"sfx": "gun_vss_vintorez",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.38 })
	_add_gun({ "name": "SKS",       "rarity": WeaponData.Rarity.RARE, "cat": WeaponData.GunCategory.DMR,
		"dmg": 34,  "rate": 3.3,  "kb": 300, "vel": 7500,
		"rec": 68,  "kick": 0.095, "reload": 1.8,  "cap": 10, "reserve": 30, "speed": 0.9,
		"spread": 0.4,
		"sfx": "gun_sks",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.40 })
	_add_gun({ "name": "Mini-14",    "rarity": WeaponData.Rarity.EPIC,      "cat": WeaponData.GunCategory.DMR,
		"dmg": 30,  "rate": 7.0,  "kb": 320, "vel": 7700,
		"rec": 70,  "kick": 0.095, "reload": 1.7,  "cap": 20, "reserve": 60, "speed": 0.92,
		"spread": 0.5,
		"sfx": "gun_mini_14",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.39 })
	_add_gun({ "name": "Mk12 SPR",   "rarity": WeaponData.Rarity.EPIC,      "cat": WeaponData.GunCategory.DMR,
		"dmg": 30,  "rate": 6.6,  "kb": 335, "vel": 7850,
		"rec": 74,  "kick": 0.1,   "reload": 1.85, "cap": 20, "reserve": 60, "speed": 0.9,
		"spread": 0.4,
		"sfx": "gun_mk12_spr",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.41 })
	_add_gun({ "name": "Dragunov SVD", "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.DMR,
		"dmg": 52,  "rate": 2.8,  "kb": 410, "vel": 8100,
		"rec": 90,  "kick": 0.12,  "reload": 2.0,  "cap": 10, "reserve": 30, "speed": 0.84,
		"spread": 0.2,
		"sfx": "gun_dragunov_svd",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.46 })
	_add_gun({ "name": "M1 Garand", "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.DMR,
		"dmg": 48,  "rate": 2.9,  "kb": 390, "vel": 8000,
		"rec": 86,  "kick": 0.115, "reload": 2.0,  "cap": 8,  "reserve": 24, "speed": 0.85,
		"spread": 0.4,
		"sfx": "gun_m1_garand",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.45 })
	_add_gun({ "name": "Mk14",       "rarity": WeaponData.Rarity.MYTHIC,    "cat": WeaponData.GunCategory.DMR,
		"dmg": 53,  "rate": 4.4,  "kb": 430, "vel": 9350,
		"rec": 94,  "kick": 0.12,  "reload": 2.1,  "cap": 20, "reserve": 60, "speed": 0.82,
		"spread": 0.3,
		"sfx": "gun_mk14",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.47 })


	# --- EXPANSION GUNS ---
	_add_gun({ "name": "Sawed Off", "rarity": WeaponData.Rarity.UNCOMMON, "cat": WeaponData.GunCategory.PISTOL,
		"dmg": 7, "rate": 2.0, "kb": 250, "vel": 650,
		"rec": 62, "kick": 0.085, "reload": 1.2, "cap": 2, "reserve": 16, "pellets": 12,
		"spread": 16.4, "sfx": "gun_sawed_off",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.23 })
	_add_gun({ "name": "Skorpion", "rarity": WeaponData.Rarity.RARE, "cat": WeaponData.GunCategory.PISTOL,
		"dmg": 13, "rate": 19.0, "kb": 100, "vel": 1700,
		"rec": 20, "kick": 0.029, "reload": 1.0, "cap": 10, "reserve": 20,
		"spread": 2.8, "sfx": "gun_skorpion",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.22 })
	_add_gun({ "name": "Saiga-12U", "rarity": WeaponData.Rarity.RARE, "cat": WeaponData.GunCategory.PISTOL,
		"dmg": 7, "rate": 4.0, "kb": 300, "vel": 1050,
		"rec": 22, "kick": 0.085, "reload": 1.5, "cap": 5, "reserve": 15, "pellets": 10,
		"spread": 10.4, "sfx": "gun_saiga_12u",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.23 })
	_add_gun({ "name": "OTs-38", "rarity": WeaponData.Rarity.RARE, "cat": WeaponData.GunCategory.PISTOL,
		"dmg": 25, "rate": 6.0, "kb": 310, "vel": 2550,
		"rec": 64, "kick": 0.095, "reload": 1.35, "cap": 5, "reserve": 25,
		"spread": 1.2, "sfx": "gun_ots_38",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.22 })
	_add_gun({ "name": "CZ-75", "rarity": WeaponData.Rarity.EPIC, "cat": WeaponData.GunCategory.PISTOL,
		"dmg": 17, "rate": 18.0, "kb": 150, "vel": 1980,
		"rec": 25, "kick": 0.038, "reload": 0.95, "cap": 12, "reserve": 24,
		"spread": 2.6, "sfx": "gun_cz_75",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.19 })
	_add_gun({ "name": "AMT AutoMag", "rarity": WeaponData.Rarity.EPIC, "cat": WeaponData.GunCategory.PISTOL,
		"dmg": 42, "rate": 2.1, "kb": 380, "vel": 3000,
		"rec": 86, "kick": 0.115, "reload": 1.45, "cap": 8, "reserve": 24,
		"spread": 1.0, "sfx": "gun_amt_automag",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.24 })

	_add_gun({ "name": "AN-94", "rarity": WeaponData.Rarity.RARE, "cat": WeaponData.GunCategory.ASSAULT_RIFLE,
		"dmg": 19, "rate": 11.4, "kb": 175, "vel": 3200,
		"rec": 40, "kick": 0.048, "reload": 1.75, "cap": 30, "reserve": 90, "speed": 0.94,
		"spread": 2.4, "sfx": "gun_an_94",
		"mode": WeaponData.FireMode.BURST, "burst": 2, "equip": 0.34 })
	_add_gun({ "name": "M16A4", "rarity": WeaponData.Rarity.RARE, "cat": WeaponData.GunCategory.ASSAULT_RIFLE,
		"dmg": 20, "rate": 12.8, "kb": 185, "vel": 3320,
		"rec": 44, "kick": 0.056, "reload": 1.9, "cap": 30, "reserve": 90, "speed": 0.92,
		"spread": 2.2, "sfx": "gun_m16a4",
		"mode": WeaponData.FireMode.BURST, "burst": 3, "equip": 0.36 })
	_add_gun({ "name": "FN FAL", "rarity": WeaponData.Rarity.RARE, "cat": WeaponData.GunCategory.ASSAULT_RIFLE,
		"dmg": 24, "rate": 7.2, "kb": 235, "vel": 3550,
		"rec": 62, "kick": 0.082, "reload": 2.0, "cap": 20, "reserve": 80, "speed": 0.88,
		"spread": 2.0, "sfx": "gun_fn_fal",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.38 })
	_add_gun({ "name": "Honey Badger", "rarity": WeaponData.Rarity.EPIC, "cat": WeaponData.GunCategory.ASSAULT_RIFLE,
		"dmg": 21, "rate": 11.2, "kb": 175, "vel": 2900,
		"rec": 36, "kick": 0.044, "reload": 1.75, "cap": 30, "reserve": 90, "speed": 0.95,
		"spread": 2.5, "sfx": "gun_honey_badger",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.33 })
	_add_gun({ "name": "STV-380", "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.ASSAULT_RIFLE,
		"dmg": 24, "rate": 11.6, "kb": 215, "vel": 3400,
		"rec": 50, "kick": 0.068, "reload": 1.85, "cap": 30, "reserve": 90, "speed": 0.90,
		"spread": 2.9, "sfx": "gun_stv_380",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.36 })
	_add_gun({ "name": "ARX 160", "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.ASSAULT_RIFLE,
		"dmg": 24, "rate": 9.5, "kb": 200, "vel": 3320,
		"rec": 30, "kick": 0.032, "reload": 1.8, "cap": 30, "reserve": 90, "speed": 0.94,
		"spread": 2.3, "sfx": "gun_arx_160",
		"mode": WeaponData.FireMode.AUTO, "burst": 3, "equip": 0.35 })

	_add_gun({ "name": "CETME", "rarity": WeaponData.Rarity.EPIC, "cat": WeaponData.GunCategory.BATTLE_RIFLE,
		"dmg": 36, "rate": 8.9, "kb": 380, "vel": 3500,
		"rec": 90, "kick": 0.12, "reload": 2.25, "cap": 20, "reserve": 60, "speed": 0.83,
		"spread": 1.9, "sfx": "gun_cetme",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.50 })

	_add_gun({ "name": "MP5", "rarity": WeaponData.Rarity.UNCOMMON, "cat": WeaponData.GunCategory.SMG,
		"dmg": 13, "rate": 12.8, "kb": 135, "vel": 1950,
		"rec": 20, "kick": 0.028, "reload": 1.35, "cap": 30, "reserve": 90,
		"spread": 2.8, "sfx": "gun_mp5",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.30 })
	_add_gun({ "name": "MAC10", "rarity": WeaponData.Rarity.UNCOMMON, "cat": WeaponData.GunCategory.SMG,
		"dmg": 11, "rate": 18.0, "kb": 120, "vel": 1700,
		"rec": 22, "kick": 0.033, "reload": 1.25, "cap": 30, "reserve": 90,
		"spread": 4.6, "sfx": "gun_mac10",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.28 })
	_add_gun({ "name": "MP9", "rarity": WeaponData.Rarity.RARE, "cat": WeaponData.GunCategory.SMG,
		"dmg": 12, "rate": 19.5, "kb": 128, "vel": 1880,
		"rec": 21, "kick": 0.030, "reload": 1.30, "cap": 30, "reserve": 90,
		"spread": 3.9, "sfx": "gun_mp9",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.29 })
	_add_gun({ "name": "Thompson", "rarity": WeaponData.Rarity.EPIC, "cat": WeaponData.GunCategory.SMG,
		"dmg": 17, "rate": 11.0, "kb": 170, "vel": 2050,
		"rec": 29, "kick": 0.042, "reload": 1.60, "cap": 30, "reserve": 120, "speed": 0.88,
		"spread": 3.0, "sfx": "gun_thompson",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.33 })
	_add_gun({ "name": "PPSH-41", "rarity": WeaponData.Rarity.EPIC, "cat": WeaponData.GunCategory.SMG,
		"dmg": 11, "rate": 16.4, "kb": 135, "vel": 2000,
		"rec": 24, "kick": 0.034, "reload": 1.70, "cap": 71, "reserve": 142, "speed": 0.87,
		"spread": 2.7, "sfx": "gun_ppsh_41",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.34 })
	_add_gun({ "name": "AUG PARA", "rarity": WeaponData.Rarity.EPIC, "cat": WeaponData.GunCategory.SMG,
		"dmg": 16, "rate": 12.2, "kb": 160, "vel": 2150,
		"rec": 27, "kick": 0.036, "reload": 1.45, "cap": 32, "reserve": 96,
		"spread": 2.9, "sfx": "gun_aug_para",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.31 })

	_add_gun({ "name": "M60", "rarity": WeaponData.Rarity.UNCOMMON, "cat": WeaponData.GunCategory.LMG,
		"dmg": 18, "rate": 9.8, "kb": 225, "vel": 2900,
		"rec": 98, "kick": 0.088, "reload": 4.2, "cap": 100, "reserve": 200, "speed": 0.62,
		"spread": 14.0, "sfx": "gun_m60",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.80 })
	_add_gun({ "name": "M1918 BAR", "rarity": WeaponData.Rarity.RARE, "cat": WeaponData.GunCategory.LMG,
		"dmg": 24, "rate": 7.0, "kb": 280, "vel": 3200,
		"rec": 112, "kick": 0.105, "reload": 2.9, "cap": 20, "reserve": 80, "speed": 0.78,
		"spread": 13.1, "sfx": "gun_m1918_bar",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.68 })
	_add_gun({ "name": "M240", "rarity": WeaponData.Rarity.RARE, "cat": WeaponData.GunCategory.LMG,
		"dmg": 21, "rate": 9.4, "kb": 245, "vel": 3120,
		"rec": 104, "kick": 0.095, "reload": 4.0, "cap": 100, "reserve": 200, "speed": 0.64,
		"spread": 14.3, "sfx": "gun_m240",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.76 })
	_add_gun({ "name": "M2HB", "rarity": WeaponData.Rarity.EPIC, "cat": WeaponData.GunCategory.LMG,
		"dmg": 33, "rate": 7.4, "kb": 420, "vel": 3600,
		"rec": 180, "kick": 0.16, "reload": 4.8, "cap": 80, "reserve": 160, "speed": 0.48,
		"spread": 15.0, "sfx": "gun_m2hb",
		"mode": WeaponData.FireMode.AUTO, "equip": 1.05 })
	_add_gun({ "name": "MG42", "rarity": WeaponData.Rarity.EPIC, "cat": WeaponData.GunCategory.LMG,
		"dmg": 15, "rate": 19.5, "kb": 175, "vel": 3150,
		"rec": 102, "kick": 0.090, "reload": 4.2, "cap": 100, "reserve": 200, "speed": 0.62,
		"spread": 15.8, "sfx": "gun_mg42",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.82 })
	_add_gun({ "name": "LSAT", "rarity": WeaponData.Rarity.EPIC, "cat": WeaponData.GunCategory.LMG,
		"dmg": 18, "rate": 12.6, "kb": 210, "vel": 3250,
		"rec": 88, "kick": 0.074, "reload": 3.6, "cap": 100, "reserve": 200, "speed": 0.68,
		"spread": 14.2, "sfx": "gun_lsat",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.74 })
	_add_gun({ "name": "MG34", "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.LMG,
		"dmg": 17, "rate": 16.8, "kb": 185, "vel": 3320,
		"rec": 96, "kick": 0.084, "reload": 3.9, "cap": 75, "reserve": 150, "speed": 0.65,
		"spread": 14.8, "sfx": "gun_mg34",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.79 })

	_add_gun({ "name": "Verp-12", "rarity": WeaponData.Rarity.EPIC, "cat": WeaponData.GunCategory.SHOTGUN,
		"dmg": 8, "rate": 4.0, "kb": 300, "vel": 1500,
		"rec": 88, "kick": 0.105, "reload": 2.3, "cap": 8, "reserve": 24, "pellets": 8, "speed": 0.82,
		"spread": 9.3, "sfx": "gun_verp_12",
		"mode": WeaponData.FireMode.AUTO, "equip": 0.42 })
	_add_gun({ "name": "M30", "rarity": WeaponData.Rarity.EPIC, "cat": WeaponData.GunCategory.SHOTGUN,
		"dmg": 13, "rate": 11.0, "kb": 360, "vel": 2000,
		"rec": 202, "kick": 0.13, "reload": 2.25, "cap": 2, "reserve": 20, "pellets": 11, "speed": 0.80,
		"spread": 9.6, "sfx": "gun_m30",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.50 })

	_add_gun({ "name": "Steyr Scout", "rarity": WeaponData.Rarity.EPIC, "cat": WeaponData.GunCategory.SNIPER,
		"dmg": 60, "rate": 1.5, "kb": 560, "vel": 7600,
		"rec": 138, "kick": 0.05, "reload": 2.2, "cap": 10, "reserve":30, "speed": 0.95,
		"spread": 0.15, "sfx": "gun_steyr_scout",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.58 })
	_add_gun({ "name": "VSK-94", "rarity": WeaponData.Rarity.EPIC, "cat": WeaponData.GunCategory.SNIPER,
		"dmg": 70, "rate": 1.8, "kb": 500, "vel": 7000,
		"rec": 108, "kick": 0.12, "reload": 2.1, "cap": 10, "reserve": 30, "speed": 0.90,
		"spread": 0.55, "sfx": "gun_vsk_94",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.52 })

	_add_gun({ "name": "L1A1 SLR", "rarity": WeaponData.Rarity.EPIC, "cat": WeaponData.GunCategory.DMR,
		"dmg": 42, "rate": 3.4, "kb": 350, "vel": 7800,
		"rec": 80, "kick": 0.105, "reload": 1.95, "cap": 20, "reserve": 60, "speed": 0.88,
		"spread": 0.45, "sfx": "gun_l1a1_slr",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.43 })

	# --- OTHER (EXPLOSIVE LAUNCHERS) ---
	# M79 uses a ballistic arc, but launches harder and faster than thrown tacticals.
	_add_gun({ "name": "M79 Thumper", "rarity": WeaponData.Rarity.MYTHIC, "cat": WeaponData.GunCategory.LAUNCHER,
		"dmg": 120, "rate": 0.95, "kb": 640, "vel": 1850,
		"rec": 145, "kick": 0.17, "reload": 2.1, "cap": 1, "reserve": 10, "speed": 0.78,
		"spread": 0.45, "sfx": "gun_m79_thumper",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.55,
		"exp_radius": 190.0, "grav": 1980.0, "up_boost": -220.0 })
	# RPG-7 flies in a mostly normal trajectory (minimal drop) and explodes on impact.
	_add_gun({ "name": "RPG-7", "rarity": WeaponData.Rarity.MYTHIC, "cat": WeaponData.GunCategory.LAUNCHER,
		"dmg": 135, "rate": 0.72, "kb": 760, "vel": 2800,
		"rec": 565, "kick": 2.0, "reload": 4.1, "cap": 1, "reserve": 4, "speed": 0.5,
		"spread": 0.22, "sfx": "gun_rpg_7",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.62,
		"exp_radius": 210.0, "grav": 120.0, "up_boost": 0.0 })
	# Homing launcher with intentionally limited steering, short lock window, and narrow cone.
	_add_gun({ "name": "MML-8 Hound", "rarity": WeaponData.Rarity.LEGENDARY, "cat": WeaponData.GunCategory.LAUNCHER,
		"dmg": 95, "rate": 3.16, "kb": 610, "vel": 550,
		"rec": 220, "kick": 0.45, "reload": 2.9, "cap": 2, "reserve": 10, "speed": 0.64,
		"spread": 0.5, "sfx": "gun_mml_8_hound",
		"mode": WeaponData.FireMode.SINGLE, "equip": 0.54,
		"exp_radius": 155.0, "grav": 85.0, "up_boost": -16.0,
		"home_turn": 160.0, "home_range": 1500.0, "home_delay": 0.06, "home_fov": 72.0, "home_time": 0.0 })


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
	w.spread            = p["spread"]
	w.sfx_event         = p["sfx"]
	w.recoil            = p.get("rec",     30.0)
	w.recoil_kick       = p.get("kick",    0.05)
	w.reload_time       = p.get("reload",   2.0)
	w.capacity          = p.get("cap",       30)
	w.reserve_ammo      = p.get("reserve",   90)
	w.pellets           = p.get("pellets",    1)
	w.explosive_radius  = p.get("exp_radius", 0.0)
	w.projectile_gravity = p.get("grav", 0.0)
	w.projectile_upward_boost = p.get("up_boost", 0.0)
	w.spread_on_impact  = p.get("split", false)
	w.projectile_homing_turn_rate = p.get("home_turn", 0.0)
	w.projectile_homing_range = p.get("home_range", 0.0)
	w.projectile_homing_delay = p.get("home_delay", 0.0)
	w.projectile_homing_fov = p.get("home_fov", 0.0)
	w.projectile_homing_duration = p.get("home_time", 0.0)
	w.moving_speed_mult = p.get("speed",     1.0)
	w.fire_mode         = p.get("mode",  WeaponData.FireMode.SINGLE)
	w.burst_count       = p.get("burst",      3)
	w.equip_time        = p.get("equip",    0.35)
	_pool.append(w)
