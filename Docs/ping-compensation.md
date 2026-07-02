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
`NewNet_ShockBeamFire.uc:86`). On the first trace of the shot (`bFirstGo`), if the
server's result disagrees with what the client *believed*:
- Client believed it hit `A`, but the server missed it → the server re-traces at
  slightly different rewind offsets `PingDT ± f` over a small window
  (`0.04 + 2.0*AverDT` seconds). If any offset reproduces the client's hit, that
  result is accepted. This recovers legitimate hits lost to interpolation jitter.
- The mirror case (client believed it *missed* but the server would hit) is also
  reconciled, so a shot the shooter clearly missed isn't turned into a phantom
  hit.

**d) Restore the world** (`UnTimeTravel`, `NewNet_ShockBeamFire.uc:328`): every
proxy's collision is turned back off. Damage is applied to the real `Other` via
`TakeDamage`, and the authoritative beam effect is replicated to other clients.

The net result: the server evaluated the shot against the world **as the shooter
actually saw it**, then applied the outcome to the live game state.

---

## 6. Call-flow diagram

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

## 7. Key formulas & constants recap

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

## 8. Where to look in the source

| Concern | File / function |
| --- | --- |
| Master clock, ring buffer, `AverDT`, proxy list | `MutUTComp.uc` — `Tick` (`:760`), `SetPawnStamp` (`:827`), `GetStamp` (`:850`), `SpawnCollisionCopy` (`:627`) |
| Client fire entry & server RPCs | `NewNet_ShockRifle.uc` — `ClientStartFire` (`:38`), `NewNet_ClientStartFire` (`:46`), `NewNet_ServerStartFire` (`:183`) |
| Rewound trace, damage, reconciliation | `NewNet_ShockBeamFire.uc` — `DoTrace` (`:40`), `DoTimeTravelTrace` (`:263`), `TimeTravel`/`UnTimeTravel` (`:316`/`:328`) |
| Per-pawn history & time travel | `PawnCollisionCopy.uc` — `AddHistory` (`:374`), `TimeTravelPawn` (`:138`), `GoToPawn` (`:110`) |
| Clock transport pawn/controller | `TimeStamp_Pawn.uc`, `TimeStamp_Controller.uc` |
| `AverDT` replication | `TimeStamp.uc` |

Every other `NewNet_*` weapon (minigun, sniper, flak, link, rocket, bio, assault)
follows this identical client-predict / server-rewind structure; only the trace
or projectile spawn in the fire mode differs.
