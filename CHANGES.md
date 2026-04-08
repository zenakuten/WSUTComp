# WSUTComp Netcode Overhaul — Project Status

**Date:** 2026-03-28
**Starting point:** WSUTComp V21 (UTCompOmni 1.71 fork)
**Current:** V24

---

## Summary of All Changes

### V22 — Netcode Core Fixes

#### 1. Ping Estimator Rewrite (`NewNet_PRI.uc`)
**Problem:** Naive `(2*old + new) / 3` weighted average with 3-second polling. A spike from 50ms to 200ms took 9-12 seconds to converge. During convergence, rewind amount was wrong — shots missed or hit around corners. First 8 pings used raw values causing early-game instability.

**Fix:**
- Median-of-5 sliding window (sorting network, no allocation)
- 0.5s polling instead of 3s — converges in ~2.5s
- 150ms hard cap on ping values
- Spike rejection: samples > 2.5x current median get clamped
- Removed unstable "first 8 pings use raw" behavior

**Files:** `NewNet_PRI.uc`, `MutUTComp.uc`, `UTComp_ServerReplicationInfo.uc`

#### 2. Damage Impulse Replication (`ModernPawn.uc`, `BS_xPlayer.uc`)
**Problem:** When server applied damage momentum (rockets, shock, shield gun self-damage), the client didn't know. Client kept predicting with old velocity. Next server correction caused a snap/hiccup. Under sustained fire, corrections compounded faster than they resolved.

**Fix:**
- `ModernPawn.TakeDamage()` captures velocity delta before/after `super.TakeDamage()`
- Sends `ClientDamageImpulse(velocityDelta)` reliable RPC to owning client
- Client applies impulse to `Pawn.Velocity` immediately
- Made reliable (not unreliable) so shield jump momentum survives lag spikes

**Impact:** Directly fixes the "invisible ceiling" on shield jumps during lag spikes, and the hiccup/snap when taking damage.

#### 3. Move Error Grace Period (`BS_xPlayer.uc`)
**Problem:** Even with the impulse RPC, moves already in-flight when damage occurs have stale velocity predictions, triggering server corrections.

**Fix:** Server records `LastDamageImpulseTime` when sending impulse. `ServerMove` skips position corrections for 200ms after damage, letting stale in-flight moves expire naturally.

**Files:** `BS_xPlayer.uc`, `ModernPawn.uc`

#### 4. Timer Clobbering Fix (5 projectile fire classes)
**Problem:** UT2004 only supports one timer per actor. If a player fired twice quickly, the second `SetTimer()` overwrote the first — the first fake projectile was lost.

**Fix:** Added `bFakeFirePending` flag. On re-fire, clears the stale flag (doesn't fire old effect with stale aim data — the timer delay is always shorter than any weapon's fire rate).

**Files:** `NewNet_RocketFire.uc`, `NewNet_FlakFire.uc`, `NewNet_FlakAltFire.uc`, `NewNet_BioFire.uc`, `NewNet_LinkAltFire.uc`

#### 5. LinkAltFire Copy-Paste Bug (`NewNet_LinkAltFire.uc`)
**Problem:** `TimeTravel()` referenced `NewNet_FlakCannon(Weapon).M` instead of `NewNet_LinkGun(Weapon).M`. Link gun alt-fire time travel silently failed — the mutator reference was never found.

#### 6. Forward-Iteration Removal Bug (`NewNet_LinkFire.uc`, `UTComp_LinkFire.uc`)
**Problem:** `LockingPawns` cleanup iterated forward while removing, skipping consecutive None entries.

**Fix:** Changed to backward iteration.

#### 7. RemoveOutdatedHistory O(n^2) (`PawnCollisionCopy.uc`)
**Problem:** Called `Remove(0,1)` in a while loop — each removal shifted the entire array.

**Fix:** Count removals first, single `Remove(0, count)` call. Also changed `AddHistory()` to use `Length++` instead of `Insert()` at end.

---

### V23 — Weapon Accuracy & Crash Fixes

#### 8. Y/Z Axis Assignment Bug (5 fire classes)
**Problem:** In `DoTimedClientFireEffect()`, all three view axes (X, Y, Z) were set to `OldXAxis`. Y and Z should have been `OldYAxis`/`OldZAxis`. This broke projectile spawn orientation for delayed fake projectiles on higher ping — spread was collapsed, spawn offsets were wrong.

**Files:** `NewNet_RocketFire.uc`, `NewNet_FlakFire.uc`, `NewNet_FlakAltFire.uc`, `NewNet_BioFire.uc`, `NewNet_LinkAltFire.uc`

#### 9. FakeProjectileManager None Guards (11 files)
**Problem:** Multiple locations called `FPM.GetFP()`, `FPM.AllowFakeProjectile()`, or `FPM.RegisterFakeProjectile()` after `FindFPM()` without checking if FPM was actually found. Crash if FakeProjectileManager doesn't exist.

**Files:** `NewNet_RocketProj.uc`, `NewNet_LinkProjectile.uc`, `NewNet_ShockProjectile.uc`, `NewNet_SeekingRocketProj.uc`, `NewNet_FlakChunk.uc`, `NewNet_RocketFire.uc`, `NewNet_FlakFire.uc`, `NewNet_FlakAltFire.uc`, `NewNet_BioFire.uc`, `NewNet_LinkAltFire.uc`, `NewNet_RocketMultiFire.uc`

#### 10. Rewind Delta Smoothing — Added Then Removed
**What happened:** Initially added per-PCC smoothing (max 10ms change per `TimeTravelPawn` call) to prevent position jumps during ping fluctuation. Discovered it broke:
- Shock beam correction search (searches +/-40ms in 20ms steps — smoothing prevented reaching target offsets)
- Flak multi-chunk traces (9 chunks caused accumulated drift)

**Resolution:** Removed entirely. PCCs are invisible server-side trace actors, not rendered. The ping estimator median filter provides smoothing at the right layer (client ping measurement, not server trace positioning).

#### 11. Server-Side Rewind Cap (`PawnCollisionCopy.uc`)
**Problem:** High ping players rewinding low ping players 150-200ms+ back caused "shot around corners" — the target had moved well past that position on their screen.

**Fix (V22):** Cap rewind at 75ms (half of 150ms RTT target) in `TimeTravelPawn`.

**Fix (V24):** Increased MAX_REWIND from 75ms to 240ms. The original 75ms cap was based on the assumption that PingDT represented half-RTT, but the actual PingDT formula (`M.ClientTimeStamp - M.GetStamp(ClientTimeStamp) - DT + 0.5*M.AverDT`) calculates the **full RTT** — the stamp byte round-trips server→client→server. This meant players at 75-100ms ping were losing 0-25ms of rewind, causing hitscan unregs on moving targets (25ms at dodge speed = 30 UU, exceeding the 25 UU collision radius). The 240ms cap covers the full player population while the existing 150ms ping cap in the estimator naturally limits abuse.

#### 12. Reliable ClientDamageImpulse (`BS_xPlayer.uc`)
**Problem:** The unreliable RPC could be dropped during lag spikes — exactly when it's needed most (shield jumps).

**Fix:** Moved from unreliable to reliable replication. Bandwidth impact negligible (~32 bytes per damage event, ~2-3/sec peak).

#### 13. Stale Fake Projectile on Weapon Switch-Back
**Problem:** Fire rocket → switch weapon → switch back → fire again. The `bFakeFirePending` flag was still true with stale aim/position data from the first shot. Spawned a ghost fake projectile from the old position.

**Fix:** Clear `bFakeFirePending` instead of calling `DoTimedClientFireEffect()` with stale data.

---

### Build Infrastructure

- `make.ini` updated: paths point to `C:\UT2004` for base assets
- `build.bat` works with System folder at `F:\Projects\CODE projects\WSUTComp\System\`
- `UT2004.ini` in System folder updated with asset paths for post-build steps (`ucc compress`, `ucc dumpint`)
- WS3SPN build setup created locally (make.ini + build.bat)
- WS3SPN local fixes: `DrawSpriteTileWidget` → `DrawSpriteWidget`, `DrawNumericTileWidget` → `DrawNumericWidget` (engine version compatibility)

---

## Current State

**Both packages compile clean** (0 errors, 0 warnings):
- `WSUTComp.u` — 6.3MB
- `WS3SPN.u` — 16.7MB (compiled against updated WSUTComp)

**Ready for in-game testing.** Deploy both `.u` files to server.

---

## What To Watch For In Testing

1. **Ping stability** — should stabilize faster, capped at 150ms display
2. **Damage hiccup** — taking hits (especially sustained minigun/link) should not cause position snaps
3. **Shield jumps** — should feel consistent even during lag spikes, no "invisible ceiling"
4. **Flak consistency** — spread should match between what you see and where damage lands
5. **Projectile weapons on higher ping** — fake projectiles should spawn at correct orientation
6. **High ping players (150ms+)** — should need to lead shots slightly more, but low ping players shouldn't get "shot around corners"
7. **Weapon switch** — no ghost projectiles from stale fire data
8. **Link gun alt** — should now actually do time travel traces (was silently broken before)

---

## Known Limitations / Future Work

- **RandSeed replication timing (flak)** — client fake chunks may use seed values that don't match the server's. Visual only, doesn't affect damage. Would require reworking seed synchronization.
- **Grace period scope** — 200ms blanket suppression of corrections after damage. Could be tightened to only suppress velocity corrections, not all position corrections.
- **150ms ping cap** — players above 150ms get clamped fake projectile timing. Hitscan is unaffected. Acceptable per design direction.
- **No server-side aim validation** — server trusts client savedRot/savedVec. Pre-existing, not addressed.
- **Versioned package naming** — for release, WSUTComp folder needs renaming to `WSUTComp_vXX` and both packages recompiled.
