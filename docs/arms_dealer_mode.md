# Arms Dealer Mode - Design Draft

## 1. Pitch
A round-based 1v1 economy mode where both players buy randomized weapons, tacticals, and utility between rounds using credits earned from performance.

Core fantasy:
- Win fights to build economy advantage.
- Out-buy and out-adapt your opponent.
- Make risky buys now or save for power spikes later.

---

## 2. High-Level Loop

```
Round Ends
  -> Economy Update (credits + streaks + bonuses)
    -> Buy Phase (time-limited random shop)
      -> Loadout Confirm
        -> Round Start
          -> Combat
            -> Repeat
```

Mode ends when one player reaches target round wins (same as standard mode unless overridden).

---

## 3. Win Condition
- First player to `rounds_to_win` wins the match.
- Optional mode variant: best-of-13 economy duel (first to 7).

---

## 4. Economy System

### 4.1 Starting Credits
- Both players start match with `800` credits.

### 4.2 End-of-Round Income
Each player gets base income plus bonuses:

- Base income (everyone): `+400`
- Round win bonus: `+300`
- Elimination bonus (if got kill this round): `+150`
- Underdog bonus (lost 2+ rounds in a row): `+200`
- Save streak bonus (if spent less than 300 this round): `+100`

Soft credit cap: `5000`.

### 4.3 Loss Streak Protection
- 2 losses in a row: `+150`
- 3+ losses in a row: `+250`

Purpose: avoid snowball lockout.

---

## 5. Buy Phase

### 5.1 Timer
- Buy phase duration: `12` seconds.
- If both players lock early, phase ends immediately.

### 5.2 Shop Offer Slots
Each player receives a private random shop each round:

- 3 Gun offers
- 1 Melee offer
- 1 Tactical offer
- 1 Utility offer

### 5.3 Refresh Rules
- Free reroll count: `1` per buy phase.
- Extra rerolls cost `150` credits each.

### 5.4 Offer Persistence
- Unpurchased offers expire next round.
- Optional variant: one "reserve slot" persists for 1 extra round.

---

## 6. Pricing Model

### 6.1 Gun Prices by Rarity
- Common: `300`
- Uncommon: `550`
- Rare: `850`
- Epic: `1200`
- Legendary: `1700`
- Mythic: `2300`
- Contraband: `3000`

### 6.2 Melee Prices
- Common: `250`
- Uncommon: `400`
- Rare: `600`
- Epic: `850`
- Legendary: `1150`
- Mythic: `1500`

### 6.3 Tactical Prices
- Frag / Flash Freeze / Molotov: `350`
- Med Kit: `400`
- Jetpack: `450`
- Shield / Confusion: `500`

### 6.4 Utility Prices
Utility are temporary one-round boosts:
- Quick Hands (faster reload/equip): `300`
- Armor Plate (+20 temp HP): `350`

---

## 7. Inventory and Purchase Rules
- Player can hold one gun, one melee, one tactical, one skill (skill remains character-based).
- Buying a new gun replaces current gun.
- Ammo is finite (normal reserve values), no infinite reserve rule.
- Dying wipes your bought loadout (gun/melee/tactical) for the next buy phase.
- Utility effects expire at round end.

Optional hardcore variant:
- Keep ammo state across rounds.

---

## 8. Shop Randomization Rules

### 8.1 Rarity Weight by Match Stage
Rarity odds scale with round index to increase match intensity.

Early rounds (1-3):
- Max rarity capped at Rare, with heavy Common/Uncommon weighting.

Mid rounds (4-7):
- Epic becomes common, Legendary appears later in this window.

Late rounds (8+):
- Mythic becomes possible; Contraband remains heavily restricted.

### 8.2 Duplicate Protection
- Prevent same exact gun from appearing in consecutive rounds unless rerolled.

### 8.3 Category Balance
- Ensure at least one non-shotgun and one precision option appears every two rounds.

---

## 9. UI/UX Requirements

## 9.1 Buy Panel Layout
Per player buy panel should display:
- Current credits
- Last round income breakdown
- Offer cards with item name, rarity color, price, short stat summary
- Reroll button and reroll cost
- Lock/Ready button

### 9.2 Feedback
- Cannot afford: red shake and denied sound.
- Successful buy: rarity-colored flash and confirm sound.
- Final second countdown pulse.

### 9.3 HUD During Combat
Show compact economy info:
- Current credits (small)
- Active utility icons with remaining duration (if any)

---

## 10. Balance Safeguards
- No Contraband before round 10.
- Legendary and above cannot appear more than one offer per player per round.
- Trailing player receives slightly better shop odds after 2-round deficit.
- Optional anti-stomp: winner economy tax (`-100` income after 3 consecutive wins).

---

## 11. Audio/Presentation Ideas
- Distinct buy phase start stinger.
- Shop hover sound keyed by rarity.
- Purchase confirmation sound tiered by rarity.
- Round start voice cue: "Deal closed. Fight." style line.

---

## 12. Implementation Plan (Suggested)

Phase 1 (MVP):
- Economy variables in match manager
- End-of-round payouts
- Basic buy UI with fixed offer count
- Purchase and replace loadout

Phase 2:
- Weighted rarity progression
- Rerolls and utility system
- Better feedback and animations

Phase 3:
- Shop fairness rules (duplicate protection, underdog odds)
- Optional variants and balance tuning table

---

## 13. Tunable Constants (for quick iteration)
- `START_CREDITS = 800`
- `BASE_INCOME = 400`
- `WIN_BONUS = 300`
- `KILL_BONUS = 150`
- `BUY_PHASE_TIME = 12.0`
- `FREE_REROLLS = 1`
- `REROLL_COST = 150`
- `CREDIT_CAP = 5000`

---

## 14. Open Questions
- Should players buy from shared shop or private shops?
- Should skill choice remain character-locked or be purchasable?
- Do we allow tactical stacking (carry 2) as a late-game luxury?
- Is utility visible to opponent pre-round or hidden?

---

## 15. Success Metrics
- Average match length remains close to core mode.
- Comeback rate increases versus standard elimination.
- Low frustration from economy snowball.
- High variety in seen loadouts across rounds.
