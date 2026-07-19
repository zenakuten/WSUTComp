# Ping Compensation (Enhanced Net Code) in WSUTComp

This document explains how the WSUTComp "NewNet" weapons implement **ping
compensation** (a.k.a. lag compensation / "unlagged"), and walks through exactly
what happens when a client in a client/server game pulls the trigger and
`NewNet_ClientStartFire` runs.

The worked example uses the **Shock Rifle primary (hitscan beam)** because it is
the simplest to follow, but every `NewNet_*` weapon uses the same pattern
(`NewNet_MiniGun`, `NewNet_SniperRifle`, `NewNet_FlakCannon`, etc.). The relevant
source lives in `WSUTComp/Classes/`.

---

## 1. The problem ping compensation solves

In stock UT2004 the client fires "in the blind": it presses fire, tells the
server, and the server does the hit trace using the **current** positions of all
players *at the moment the packet arrives*. Because the client's packet took
`ping/2` to arrive — and the client was already rendering everyone else
`ping/2 + interpolation` in the past — the target the player aimed at is no
longer where the server thinks it is. High-ping players have to lead their
targets and still get "no-regs" (shots that visibly hit but do no damage).

**Ping compensation fixes this by rewinding the world on the server.** When the
server receives a fire command it:

1. Figures out *how far in the past* the firing client was looking (`PingDT`).
2. Moves a lightweight collision proxy for every player back to where that
   player actually was at that past moment.
3. Runs the hit trace against those rewound proxies.
4. Applies damage to the *real* pawn, then restores everything.

This makes "what you see is what you get": if your crosshair was on an enemy on
your screen, the shot hits, regardless of ping.

---

## 2. The cast of classes

| Class | Role | Runs on |
| --- | --- | --- |
| **`MutUTComp`** | The orchestrator. Keeps the master server clock (`ClientTimeStamp`), the ring buffer of timestamps (`StampArray`), the average frame delta (`AverDT`), and the linked list of collision proxies (`PCC`). | Server (authority) + client (mutator exists on both) |
| **`NewNet_ShockRifle`** (and every other `NewNet_*` weapon) | Implements the client-predicted fire path and the server RPCs. | Client + server |
| **`NewNet_ShockBeamFire`** (the weapon's `FireMode`) | Does the actual rewound trace and damage on the server; does the cosmetic-only trace on the client. Holds `PingDT`, `bBelievesHit`, etc. | Client + server |
| **`TimeStamp_Controller`** / **`TimeStamp_Pawn`** | A dummy controller+pawn pair whose only job is to carry the server's frame counter to every client cheaply. The counter is encoded in the pawn's **rotation** (which replicates automatically) and decoded on the client. | Server encodes, client decodes |
| **`TimeStamp`** (a.k.a. `StampInfo`) | A `ReplicationInfo` that replicates `AverDT` (average server tick length) to clients. | Server → client |
| **`PawnCollisionCopy`** | A collision-only proxy of a single pawn/vehicle. Records a short history of positions and can "time travel" its collision cylinder/mesh back to any recent moment. **Server only.** | Server |

---

## 3. The shared clock: how client and server agree on "when"

Ping compensation needs client and server to share a common notion of time so the
server can translate "the client fired while looking at state X" into "rewind N
seconds". WSUTComp does this without a dedicated time packet, using two tricks.

### 3.1 The server clock and ring buffer (`MutUTComp.Tick`, server)

Every server tick (`MutUTComp.uc:781`):

```unrealscript
ClientTimeStamp += DeltaTime;          // master server clock (seconds)
counter += 1;                          // integer tick counter
StampArray[counter % 256] = ClientTimeStamp;   // ring buffer: stamp -> server time
AverDT = (9.0*AverDT + DeltaTime) * 0.1;       // smoothed average frame time
SetPawnStamp();                        // publish 'counter' to clients (below)
```

`StampArray` is a 256-entry ring buffer mapping a **stamp byte** (`counter % 256`)
to the server clock value at that tick. `GetStamp(stamp)` (`MutUTComp.uc:850`)
reads it back.

### 3.2 Publishing the counter via a pawn's rotation (`SetPawnStamp`, server)

Rather than replicate a variable directly, the counter is smuggled to clients
inside the rotation of `TimeStamp_Pawn` (which is `bAlwaysRelevant`, so its
rotation replicates to everyone). `SetPawnStamp` (`MutUTComp.uc:827`) encodes:

```unrealscript
R.Yaw   = (counter % 256) * 256;   // low byte  of counter
R.Pitch = (counter / 256) * 256;   // high byte of counter
countercontroller.Pawn.SetRotation(R);
```

### 3.3 Decoding on the client (`TimeStamp_Pawn.Tick`, client)

On the client the replicated pawn decodes the counter and, importantly, tracks
`DT` — how long it has been since the currently-known stamp last changed. That
`DT` is the client's local extrapolation past the last received server state
(`TimeStamp_Pawn.uc:26`):

```unrealscript
NewTimeStamp = (Rotation.Yaw + Rotation.Pitch*256) / 256;   // reconstruct counter
DT += deltatime;
if (NewTimeStamp > TimeStamp || TimeStamp - NewTimeStamp > 5000)
{
    TimeStamp = NewTimeStamp;   // a fresh stamp arrived...
    DT = 0.00;                  // ...reset the "time since this stamp" accumulator
}
```

So at any instant the client knows:
- `TimeStamp` — the most recent server stamp byte it has received, and
- `DT` — how many seconds have elapsed locally since that stamp arrived.

`AverDT` (average server frame length) is replicated separately by the
`TimeStamp` / `StampInfo` `ReplicationInfo` (`TimeStamp.uc`).

---

## 4. The position history (`PawnCollisionCopy`, server)

For every player pawn (and driven vehicle) the server spawns a
`PawnCollisionCopy` when the pawn is created — see
`MutUTComp.ModifyPlayer` → `SpawnCollisionCopy` (`MutUTComp.uc:543`). The copies
are held as a linked list off `MutUTComp.PCC`.

Each copy is a collision-only actor (all its `bCollide*` flags default **off** —
`PawnCollisionCopy.uc:424`) so it never interferes with normal physics. Every
server tick it records one history sample (`PawnCollisionCopy.AddHistory`,
`PawnCollisionCopy.uc:374`):

```unrealscript
PawnHistory[i].Location  = CopiedPawn.Location;
PawnHistory[i].Rotation  = CopiedPawn.Rotation;
PawnHistory[i].bCrouched = CopiedPawn.bIsCrouched;
PawnHistory[i].TimeStamp = M.ClientTimeStamp;   // tagged with the server clock
```

It also feeds three `InterpCurve`s (X/Y/Z of location keyed on server time) so a
rewound position can be smoothly interpolated *between* recorded ticks rather than
snapping to the nearest sample. Samples older than `MAX_HISTORY_LENGTH`
(default **0.35 s**) are pruned (`RemoveOutdatedHistory`), which caps how far the
server is willing to rewind — this bounds the maximum ping supported by netcode. 

---

## 5. Firing, step by step

### 5.1 Client: `ClientStartFire` → `NewNet_ClientStartFire`

When the local player presses fire, the engine calls the weapon's
`ClientStartFire`. The NewNet weapon checks whether enhanced net code should be
used at all (`NewNet_ShockRifle.uc:38`):

```unrealscript
simulated event ClientStartFire(int Mode)
{
    if (Level.NetMode != NM_Client
        || !BS_xPlayer(...).UseNewNet()
        || NewNet_ShockBeamFire(FireMode[Mode]) == None)
        super.ClientStartFire(Mode);      // fall back to stock behavior
    else
        NewNet_ClientStartFire(Mode);     // enhanced path
}
```

`NewNet_ClientStartFire` (`NewNet_ShockRifle.uc:46`) is where the client-side work
happens. On a listen-server-hosted local player (`Role == ROLE_Authority`) it just
calls `StartFire` directly. On a **remote client** (`Role < ROLE_Authority`) it:

1. **Fires locally & immediately for responsiveness.** It calls
   `DoInstantFireEffect()` so the shooter sees the beam and hears the shot with
   zero delay — a purely cosmetic client-side trace (`DoClientTrace`), no damage.

2. **Captures the exact aim and muzzle position:**
   ```unrealscript
   R.Pitch = Controller.Rotation.Pitch;
   R.Yaw   = Controller.Rotation.Yaw;
   Start   = Pawn(Owner).Location + Pawn(Owner).EyePosition();   // packed into V
   ```

3. **Reads the current shared clock** from the `TimeStamp_Pawn`:
   ```unrealscript
   Stamp = T.TimeStamp;   // latest server stamp the client has seen
   // T.DT is how long ago that stamp arrived
   ```

4. **Does a local "did I hit someone?" trace** (favor-the-shooter hint):
   ```unrealscript
   A = Trace(HN, HL, Start + Vector(Rotation)*40000.0, Start, true);
   if (A is xPawn or Vehicle) b = true;   // "I believe I hit actor A"
   ```

5. **Sends the fire command to the server:**
   ```unrealscript
   NewNet_ServerStartFire(Mode, Stamp, T.DT, R, V, b, A);
   ```
   This is a `reliable` server RPC (`NewNet_ShockRifle.uc:25`). It carries the
   aim (`R`), muzzle start (`V`), the client's clock reference (`Stamp` + `T.DT`),
   and the shooter's hit belief (`b`, `A`).

   (If the weapon isn't actually ready to fire yet — a rare edge case — it instead
   sends the lighter-weight `NewNet_OldServerStartFire(Mode, Stamp, T.DT)`.)

### 5.2 Server: `NewNet_ServerStartFire` computes the rewind amount

On the server, `NewNet_ServerStartFire` (`NewNet_ShockRifle.uc:183`) validates the
weapon, then computes **`PingDT`** — the number of seconds to roll the world back
(`NewNet_ShockRifle.uc:198`):

```unrealscript
PingDT = M.ClientTimeStamp            // server time NOW
       - M.GetStamp(ClientTimeStamp)  // server time WHEN that stamp was generated
       - DT                           // client had extrapolated DT past that stamp
       + 0.5 * M.AverDT;              // half-a-tick centering correction
```

Reading it left to right:
`M.ClientTimeStamp - M.GetStamp(Stamp)` is how much server time has elapsed since
the world state the client was reacting to was produced. Subtracting the client's
local extrapolation `DT` and adding half an average tick centers the estimate on
the exact instant the player was looking at when they clicked. **`PingDT` is
essentially the player's effective latency for this shot.**

It then stashes the shot parameters and the shooter's belief onto the fire mode
and enables the enhanced path:

```unrealscript
FireMode.PingDT             = PingDT;
FireMode.bUseEnhancedNetCode = true;
FireMode.AverDT             = M.AverDT;
FireMode.bBelievesHit       = b;   FireMode.BelievedHitActor = A;
FireMode.bFirstGo           = true;
FireMode.SavedVec           = V;   FireMode.SavedRot = R;      // replicated aim
FireMode.bUseReplicatedInfo = IsReasonable(SavedVec);          // sanity-check start
StartFire(Mode);   // proceed into the normal fire pipeline
```

`IsReasonable` (`NewNet_ShockRifle.uc:243`) rejects a client-supplied muzzle
position that is implausibly far from where the server thinks the pawn is (anti-
cheat / desync guard); if unreasonable the server falls back to its own eye
position.

### 5.3 Server: the rewound trace (`NewNet_ShockBeamFire.DoTrace`)

`StartFire` eventually drives the fire mode to `DoFireEffect` → **`DoTrace`**
(`NewNet_ShockBeamFire.uc:40`), which is where the actual lag compensation
happens.

**a) Rewind everyone** (`TimeTravel`, `NewNet_ShockBeamFire.uc:316`):
```unrealscript
for (PCC = M.PCC; PCC != None; PCC = PCC.Next)
    PCC.TimeTravelPawn(PingDT);
```
Each `PawnCollisionCopy.TimeTravelPawn` (`PawnCollisionCopy.uc:138`) computes the
target time `StampDT = M.ClientTimeStamp - PingDT`, finds the two history samples
that bracket it, evaluates the X/Y/Z `InterpCurve`s at `StampDT` to get a smoothly
interpolated position, moves the proxy there (adjusting crouch collision size),
and **enables collision** on the proxy for the duration of the trace.

**b) Two-phase trace** (`DoTimeTravelTrace`, `NewNet_ShockBeamFire.uc:263`).
A single trace can't cleanly mix static world geometry with the rewound proxies,
so it does two:
1. Trace world geometry / non-predicted actors to find the first solid wall
   (`IsPredicted` in `MutUTComp.uc:652` treats xPawns and driven vehicles as
   "predicted", i.e. represented by proxies, so they're skipped here).
2. Trace only `PawnCollisionCopy` actors, but stopped at that wall, so you can't
   shoot a rewound player through geometry.

If a proxy is hit, the hit point is translated from the proxy back onto the real
pawn's *current* location so effects line up, and `Other` is set to the real
pawn (`NewNet_ShockBeamFire.uc:76`):
```unrealscript
PawnHitLocation = HitLocation + PawnCollisionCopy(Other).CopiedPawn.Location - Other.Location;
Other = PawnCollisionCopy(Other).CopiedPawn;
```

**c) Favor-the-shooter reconciliation** (`bBelievesHit`,
`NewNet_ShockBeamFire.uc:86`). The server's rewound trace at `PingDT` is the
**baseline** result. `bBelievesHit` does **not** override it — it is only a *hint*
that, when it disagrees with the baseline, triggers a bounded re-search at slightly
different rewind offsets `PingDT ± f` over a small window
(`abs(f) < 0.04 + 2.0*AverDT` seconds, ~40 ms plus a couple of ticks). This runs
only on the first segment of the shot (`bFirstGo && ReflectNum == 0`), so beam
reflections use the plain baseline trace with no belief reconciliation.

Neither flag alone decides the outcome. The four combinations:

| Client `bBelievesHit` | Baseline rewound trace | Outcome |
| --- | --- | --- |
| **true** (actor `A`) | already hit `A` | agreement → **HIT**, no re-search |
| **false** | missed all pawns | agreement → **MISS**, no re-search |
| **true** (actor `A`) | did *not* hit `A` (`:86`) | re-search window for `A`; any offset that hits `A` → **switch to HIT on `A`**; never reproduced in window → keep baseline (**no hit on `A`**) |
| **false** | *did* hit a pawn (`:126`) | re-search window for a None/non-pawn result; any offset that misses → **discard the hit (MISS)**; every offset still hits a pawn → **hit stands** |

So the two disagreement cases are symmetric, and both are gated by the same window:

- **Believed-hit but server missed** (`:86`) — the server searches to *recover* the
  hit. It accepts `A` only if some offset within the window actually lands on `A`;
  otherwise the baseline miss stands. Bias: grant the shooter's claimed hit, but
  only if it's reachable within the tolerance.
- **Believed-miss but server hit** (`:126`) — the server searches to *cancel* the
  phantom hit. The moment any offset in the window misses all players it discards
  the hit; the hit only survives if the target was hit at *every* sampled offset.
  Bias: honor the shooter's "I missed" as long as a miss is reachable.

Beyond the `±(0.04 + 2·AverDT)` window the client's belief is treated as
untrustworthy and the server's own rewound trace wins. That bound is also what keeps
the belief flag from being an exploit: a client can't claim a hit on someone who was
never near the beam at any plausible offset, and can't shrug off a hit that was solid
across the whole window.

**d) Restore the world** (`UnTimeTravel`, `NewNet_ShockBeamFire.uc:328`): every
proxy's collision is turned back off. Damage is applied to the real `Other` via
`TakeDamage`, and the authoritative beam effect is replicated to other clients.

The net result: the server evaluated the shot against the world **as the shooter
actually saw it**, then applied the outcome to the live game state.

---

## 6. NewNet projectiles ("fake projectiles")

Everything above describes **hitscan** weapons (shock beam, minigun, sniper,
assault, link beam): the trace is instantaneous, so the server can rewind, trace,
and resolve the hit in the same frame the fire command arrives.

**Projectile** weapons — shock combo ball, bio globs, flak chunks/shells, link
plasma, rockets — can't work that way. The projectile takes time to travel, so the
outcome isn't known at fire time, and you can't just rewind-and-trace. NewNet
solves this with two cooperating tricks: **client-side fake projectiles** for
instant visual feedback, and **server-side forward extrapolation** so the real
projectile is born already advanced by the shooter's latency. The relevant classes
are `FakeProjectileManager`, the `NewNet_Fake_*` projectiles, and the `NewNet_PRI`
ping estimator.

### 6.1 Client: spawn a fake immediately

When a remote client fires a projectile weapon, the fire mode's client effect
(e.g. `NewNet_ShockProjFire.DoClientFireEffect` → `SpawnFakeProjectile`,
`NewNet_ShockProjFire.uc:78`) spawns a **fake projectile** right away —
`NewNet_Fake_ShockProjectile`, `NewNet_Fake_BioGlob`, `NewNet_Fake_FlakChunk`,
etc. Fakes are **cosmetic only**: they don't collide with players
(`bCollideActors=False`), deal no damage, and exist purely so the shooter sees the
projectile leave the barrel with zero delay. The real, authoritative projectile is
still spawned by the server.

### 6.2 The `FakeProjectileManager`

Each client has one hidden `FakeProjectileManager` (spawned by `MutUTComp.Tick`
on the client, `MutUTComp.uc:812`). It is the bookkeeping actor that lets a real
projectile find "its" fake later. It holds an array of `{FP, index}` records
(`FakeProjectileManager.uc`):

- `RegisterFakeProjectile(p, index)` — record a spawned fake.
- `AllowFakeProjectile(class, index)` — dedup guard: refuse a second fake for the
  same shot (matched by class **and** index), since a fire effect can fire more
  than once.
- `GetFP(class, index)` / `GetClosestFP(class, index, loc)` — look up the fake to
  reconcile a newly-arrived real projectile against. `GetClosestFP` breaks ties by
  proximity when several fakes of the same class share an index (e.g. a lingering
  fake from a previous shot), keeping the reconciliation delta small.
- `CleanUpProjectiles` / `RemoveProjectile` — prune destroyed or already-reconciled
  fakes.

The **`index`** comes from a per-weapon counter (`CurIndex`, replicated to the
owning client — see `NewNet_BioRifle`/`NewNet_LinkGun`). It disambiguates multiple
in-flight projectiles of the same class so each real projectile matches its own
fake and not a neighbor's.

### 6.3 Latency source: `NewNet_PRI.PredictedPing`

Fakes and forward-extrapolation use `NewNet_PRI.PredictedPing` — a smoothed
round-trip ping measured by a dedicated ping/pong `LinkedReplicationInfo`
(`NewNet_PRI.uc`), tweened over `PingTweenTime` (3 s) and seeded from the first 8
samples. This is a **separate** latency estimate from the collision-copy clock used
by hitscan (`PingDT`); projectile prediction needs the client's own round-trip
estimate because the client must extrapolate before the server ever responds.

### 6.4 Server: forward-extrapolate the real projectile

When the server spawns the real projectile (`SpawnProjectile` in the fire mode,
e.g. `NewNet_BioFire.uc:19`; for rockets it's in the weapon,
`NewNet_RocketLauncher.uc:300+`), it does **not** simply spawn it at the muzzle.
Instead it simulates the projectile's flight forward by `PingDT` in small
`PROJ_TIMESTEP` (~0.02 s) steps. At each step it rewinds the collision copies to
the matching moment (`TimeTravel(pingDT - g)`) and traces that segment:

- If the projectile would already have struck something during those first
  `PingDT` seconds, it spawns the real projectile at that hit point (and the hit is
  resolved there).
- Otherwise it spawns the real projectile at the extrapolated position with the
  extrapolated velocity/direction.

So a high-ping player's projectile is **born already `ping` seconds into its
flight**, roughly where the shooter's fake already is. This forward rewind is
clamped by `MAX_PROJECTILE_FUDGE` (per weapon — 0.075 s for most, 0.275 s for
rockets), a tighter cap than hitscan compensation.

### 6.5 Client: the real projectile replaces the fake

The real projectile replicates to clients. On the owning shooter's client,
`NewNet_ShockProjectile.PostNetBeginPlay` → `DoPostNet` (`NewNet_ShockProjectile.uc:24`):

1. `CheckOwned()` — only the local shooter reconciles; other clients just render
   the normally-replicated real projectile.
2. `CheckForFakeProj()` — ask the `FakeProjectileManager` for the matching fake.
   If found: snap the real projectile to the fake's **current** location, record
   the delta between that and where the server says it should be, delete the fake,
   then over `INTERP_TIME` (0.7 s) smoothly slide the real projectile from the
   fake's position to the server position (`FakeInterp`) so there is no visible
   pop.
3. If **no** fake is found (e.g. it already expired), just nudge the real
   projectile forward by `PredictedPing * Velocity` so it still starts roughly
   where the shooter expected.

Fakes and reals are made to ignore each other during flight (e.g.
`NewNet_Fake_ShockProjectile.ProcessTouch` ignores `NewNet_ShockProjectile`, and
vice-versa) so they never detonate one another.

### 6.6 Hitscan vs. projectile at a glance

| | Hitscan | Projectile |
| --- | --- | --- |
| Client feedback | instant cosmetic trace (`DoInstantFireEffect`) | instant **fake projectile** |
| Latency used | `PingDT` (collision-copy clock) | `PredictedPing` (`NewNet_PRI`) + `PingDT` server-side |
| Server technique | rewind world, trace once | forward-extrapolate real projectile through rewound world, step by step |
| Reconciliation | favor-the-shooter re-trace (`bBelievesHit`) | real projectile snaps to fake, then `FakeInterp` |
| Compensation cap | `MAX_HISTORY_LENGTH` (0.35 s) | `MAX_PROJECTILE_FUDGE` (0.075 s; 0.275 s rockets) |
| Bookkeeping | `PawnCollisionCopy` list | `FakeProjectileManager` |

---

## 7. Call-flow diagram

```
        CLIENT (Role < ROLE_Authority)                    SERVER (ROLE_Authority)
        ==============================                    =======================

 player presses fire
        │
        ▼
 ClientStartFire(Mode)                               MutUTComp.Tick (every tick):
   └─ UseNewNet? ── no ──► super (stock)               ClientTimeStamp += dt
        │ yes                                           StampArray[counter%256]=clock
        ▼                                               AverDT smoothed
 NewNet_ClientStartFire(Mode)                          SetPawnStamp() ─┐ encodes counter
   • DoInstantFireEffect()  (instant local beam,                      │ into TimeStamp_Pawn
     cosmetic only, no damage)                                        │ rotation
   • capture aim R, muzzle V                                          ▼
   • Stamp = T.TimeStamp  (from TimeStamp_Pawn) ◄───── replicated ─── TimeStamp_Pawn.Rotation
     DT    = T.DT                                       (bAlwaysRelevant)
   • local Trace ⇒ b, A ("I believe I hit A")
        │                                              PawnCollisionCopy.Tick (every tick):
        │  NewNet_ServerStartFire(                       AddHistory(): record location
        │      Mode, Stamp, DT, R, V, b, A)              tagged with ClientTimeStamp
        └──────────  reliable RPC  ───────────────────►
                                                       NewNet_ServerStartFire()
                                                         PingDT = ClientTimeStamp
                                                                - GetStamp(Stamp)
                                                                - DT + 0.5*AverDT
                                                         store PingDT, aim, bBelievesHit
                                                         StartFire ─► DoFireEffect ─► DoTrace
                                                             │
                                                             ▼
                                                         TimeTravel(PingDT):
                                                           each PawnCollisionCopy moves
                                                           back to StampDT =
                                                           ClientTimeStamp - PingDT
                                                           (InterpCurve), collision ON
                                                             │
                                                             ▼
                                                         DoTimeTravelTrace:
                                                           1) trace world/geometry
                                                           2) trace proxies up to wall
                                                           reconcile vs bBelievesHit
                                                             │
                                                             ▼
                                                         hit ⇒ map proxy→real pawn
                                                         Other.TakeDamage(...)
                                                         UnTimeTravel (collision OFF)
                                                         replicate beam effect ──► all clients
```

---

## 8. Key formulas & constants recap

- **Rewind amount:**
  `PingDT = ClientTimeStamp − GetStamp(Stamp) − DT + 0.5·AverDT`
  (server-now minus the age of the state the client saw, ≈ the shooter's latency).
- **Rewind target time:** `StampDT = ClientTimeStamp − PingDT`, positions
  interpolated from `PawnCollisionCopy.PawnHistory` via `InterpCurve`.
- **Max rewind:** `PawnCollisionCopy.MAX_HISTORY_LENGTH = 0.35 s` — older history
  is discarded, capping compensation for very high pings.
- **Favor-the-shooter window:** `0.04 + 2·AverDT` seconds of ± search around
  `PingDT` to reconcile the client's hit belief with the server trace.
- **Clock transport:** server frame counter encoded in `TimeStamp_Pawn` rotation
  (Yaw = low byte, Pitch = high byte); `AverDT` replicated via the `TimeStamp`
  `ReplicationInfo`.

---

## 9. Where to look in the source

| Concern | File / function |
| --- | --- |
| Master clock, ring buffer, `AverDT`, proxy list | `MutUTComp.uc` — `Tick` (`:760`), `SetPawnStamp` (`:827`), `GetStamp` (`:850`), `SpawnCollisionCopy` (`:627`) |
| Client fire entry & server RPCs | `NewNet_ShockRifle.uc` — `ClientStartFire` (`:38`), `NewNet_ClientStartFire` (`:46`), `NewNet_ServerStartFire` (`:183`) |
| Rewound trace, damage, reconciliation | `NewNet_ShockBeamFire.uc` — `DoTrace` (`:40`), `DoTimeTravelTrace` (`:263`), `TimeTravel`/`UnTimeTravel` (`:316`/`:328`) |
| Per-pawn history & time travel | `PawnCollisionCopy.uc` — `AddHistory` (`:374`), `TimeTravelPawn` (`:138`), `GoToPawn` (`:110`) |
| Clock transport pawn/controller | `TimeStamp_Pawn.uc`, `TimeStamp_Controller.uc` |
| `AverDT` replication | `TimeStamp.uc` |
| Fake-projectile bookkeeping | `FakeProjectileManager.uc` — `RegisterFakeProjectile`, `AllowFakeProjectile`, `GetFP`/`GetClosestFP` |
| Client fake spawn | `NewNet_ShockProjFire.uc` — `DoClientFireEffect` (`:22`), `SpawnFakeProjectile` (`:78`); fakes `NewNet_Fake_*.uc` |
| Server forward-extrapolation | `NewNet_BioFire.uc` — `SpawnProjectile` (`:19`); `NewNet_RocketLauncher.uc` — `SpawnProjectile` (`:300+`) |
| Real→fake reconciliation | `NewNet_ShockProjectile.uc` — `DoPostNet` (`:24`), `CheckForFakeProj` (`:64`), `FakeInterp` (`:110`) |
| Projectile ping estimate | `NewNet_PRI.uc` — `PredictedPing` (ping/pong) |

The hitscan `NewNet_*` weapons (minigun, sniper, assault, link beam, shock/super
shock beam) share the client-predict / server-rewind structure of §5; only the
trace in the fire mode differs. The **projectile** weapons (shock combo, bio, flak,
link plasma, rockets) instead use the fake-projectile / forward-extrapolation
scheme of §6.
