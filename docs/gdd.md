# Gratishoot — Game Design Document

## 1. Overview

| Item            | Detail                                              |
| --------------- | --------------------------------------------------- |
| **Title**       | Gratishoot                                          |
| **Engine**      | Godot 4.x                                           |
| **Genre**       | 2D Platformer / Arena Shooter                       |
| **Players**     | 2 (local multiplayer, 1v1)                          |
| **Art Style**   | Fun, exaggerated — inspired by classic Flash games  |
| **Platform**    | PC (keyboard)                                       |

**One-line pitch:** A chaotic 1v1 local arena platformer where players spawn with bare fists, scramble to loot randomly spawning weapons and items, and blast each other to win rounds.

---

## 2. Game Flow

```
Title Screen
    └─► Match Setup (select characters, set rounds-to-win)
            └─► Round Start (players spawn with bare fists)
                    └─► Gameplay Loop
                    │     • Weapons & items spawn randomly on the map
                    │     • Players loot, fight, and use abilities
                    │     • A player dies when HP reaches 0
                    └─► Round End (winner gets +1 round win)
                            └─► if round wins < target → next round
                            └─► if round wins ≥ target → Victory Screen
```

---

## 3. Core Mechanics

### 3.1 Health & Winning

- Each player has an **HP bar**.
- Reduce the opponent's HP to **0** to win the round.
- First player to reach **X round wins** (configured in match setup) achieves **victory**.

### 3.2 Movement & Physics

Standard 2D platformer physics:

| Action         | Description                                                                 |
| -------------- | --------------------------------------------------------------------------- |
| **Move**       | Walk left/right on the ground.                                              |
| **Jump**       | Variable-height jump. Can jump through thin (one-way) platforms from below. |
| **Descend**    | Double-tap down to drop through thin/one-way platforms.                     |
| **Crouch**     | Hold down to crouch: reduces hitbox, hides behind objects, **cannot move**. |
| **Sprint**     | Move faster; drains **stamina** over time.                                  |

### 3.3 Combat

Players start each round with **bare fists** (default melee).

#### Melee Weapons
| Input              | Action                                     |
| ------------------ | ------------------------------------------ |
| Attack             | Primary melee strike.                      |
| Secondary          | Secondary melee strike (different pattern). |
| Crouch + Attack    | **Force-drop** current weapon and pick up a nearby weapon. |

#### Guns
| Input              | Action                                                                                          |
| ------------------ | ----------------------------------------------------------------------------------------------- |
| Attack             | Shoot in the current facing direction.                                                          |
| Secondary (Aim)    | Enter **aim mode**: equips the gun, **prevents all movement**. While aiming:                    |
|                    | • Left/Right inputs change **facing direction** (left or right).                                |
|                    | • Up/Down inputs adjust **pitch** (aim angle up/down) and compensate for **gun recoil**. |
| Reload             | Reload the gun's magazine.                                                                      |
| Crouch + Attack    | **Force-drop** current weapon and pick up a nearby weapon.                                      |

### 3.4 Weapon Spawning & Rarities

Weapons (melee and guns) spawn at random locations on the map at random intervals. Each weapon has a **rarity** tier that determines its power:

| Rarity     | Indication         | Power Level |
| ---------- | ------------------- | ----------- |
| Common     | white               | Low         |
| Uncommon   | green               | Medium      |
| Rare       | blue                | High        |
| Epic       | purple              | Very High   |
| Legendary  | gold                | Extreme     |
| Mythic     | red                 | Maximum     |

Every gun category is balanced so that all are viable options — no single type dominates.

**There is no "range" stat.** Effective range is determined by projectile velocity: the longer a projectile travels, the more damage reduction it suffers.

> Full weapon list, categories, and stat definitions: see [weapons.md](weapons.md).

### 3.5 Tactical Items

Tactical items spawn alongside weapons and are consumed on use.

| Item               | Effect                                        |
| ------------------ | --------------------------------------------- |
| Frag Grenade       | Thrown explosive, area damage after delay.     |
| Flash Freeze       | Thrown, freezes/slows targets in the area.     |
| Molotov            | Thrown, creates a burning area on the ground.  |
| Med Kit            | Restores a portion of HP.                     |
| One-time Jetpack   | Brief vertical flight, single use.            |
| *(more TBD)*       |                                               |

### 3.6 Characters & Active Skills

Each character has a **unique active skill** with a cooldown (or limited charges).

| Character   | Skill           | Description                                          |
| ----------- | --------------- | ---------------------------------------------------- |
| Tsutaya     | Instant Dash    | Teleport a short distance in the facing direction.   |
| Aichok     | Life Steal      | Next attack(s) heal the player for a portion of damage dealt. |
| *(more TBD)* |                |                                                      |

### 3.7 Stamina

- Sprinting drains stamina.
- Stamina regenerates when not sprinting.
- 100% stamina allows sprinting; 0% stamina prevents sprinting until fully regenerated.

---

## 4. Controls

### 4.1 Player 1 — Keyboard Left Side

| Key(s)      | Action                                            |
| ----------- | ------------------------------------------------- |
| **W**       | Jump                                              |
| **S**       | Crouch (hold) / Descend through platform (double-tap) |
| **A / D**   | Move left / right                                 |
| **G**       | Attack (melee strike / shoot gun)                 |
| **H**       | Secondary attack (melee) / Aim mode (gun)         |
| **J**       | Sprint                                            |
| **T**       | Use active skill (character ability)              |
| **Y**       | Use tactical item                                 |
| **U**       | Reload                                            |

**While aiming (H held with gun equipped):**

| Key   | Action                          |
| ----- | ------------------------------- |
| A / D | Change facing direction         |
| W / S | Adjust aim pitch up/down & recoil |

### 4.2 Player 2 — Arrow Keys + Numpad

| Key(s)              | Action                                            |
| -------------------- | ------------------------------------------------- |
| **Up Arrow**         | Jump                                              |
| **Down Arrow**       | Crouch (hold) / Descend through platform (double-tap) |
| **Left / Right Arrow** | Move left / right                              |
| **Num 1**            | Attack (melee strike / shoot gun)                 |
| **Num 2**            | Secondary attack (melee) / Aim mode (gun)         |
| **Num 3**            | Sprint                                            |
| **Num 4**            | Use active skill (character ability)              |
| **Num 5**            | Use tactical item                                 |
| **Num 6**            | Reload                                            |

> Key bindings should be **remappable** in settings.

---

## 5. Map Design

- 2D side-view arenas with platforms (solid and **thin/one-way**).
- Objects and cover to crouch behind.
- Multiple **spawn points** for weapons, items, and players.
- Map variety TBD (themes, hazards, sizes).

---

## 6. Art & Audio Direction

- **Art:** Bright, cartoony, simple and minimal — channeling the look and humor of Flash-era web games. Expressive character animations, over-the-top weapon effects, screenshake on hits.

---

## 7. Open Questions / TBD

- [x] Full weapon list and categories — see [weapons.md](weapons.md).
- [ ] Per-weapon stat values (damage, fire rate, capacity, etc.).
- [ ] Rarity distribution weights and visual indicators.
- [ ] Complete character roster and skill details (cooldowns, costs, balance).
- [ ] Stamina values (max, drain rate, regen rate).
- [ ] HP values and damage scaling.
- [ ] Map list and layout concepts.
- [ ] Spawn timing and frequency for weapons/items.
- [ ] Bare-fist damage and melee combo details.
- [ ] UI/HUD layout (HP bars, ammo, stamina, skill cooldown, round score).
- [ ] Online multiplayer (future scope?).
- [ ] Controller/gamepad support.
