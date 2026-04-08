class ModernPawn extends xPawn;
var int DyingTimer;

// ============================================================================
// Smoothed render offset for server correction hitching.
// When the engine snaps the pawn to a server-corrected position, the logical
// Location is updated instantly (correct for physics/collision/aim), but the
// VISUAL representation (mesh + first-person camera) lags behind and decays
// back to zero over CorrectionHalfLife. Eliminates the visible hitch from
// damage impulses, shock combos, rockets, etc.
// ============================================================================
var vector VisualOffset;              // current render offset applied to mesh
var vector LastPhysicsLocation;       // actor Location from previous frame
var bool   bVisualOffsetInitialized;  // set false on spawn, true after first Tick

// Client-side config (pulled from UTComp_ServerReplicationInfo on spawn)
var float  CorrectionHalfLife;        // seconds; smaller = faster decay
var float  CorrectionJumpThreshold;   // min jump (UU) to activate smoothing
var float  MaxVisualOffset;           // cap — bigger jumps are treated as teleports
var bool   bEnableCorrectionSmoothing;// master toggle
var bool   bSmoothCameraOffset;       // first-person camera smoothing

simulated function PostBeginPlay()
{
    local UTComp_ServerReplicationInfo RepInfo;

    Super.PostBeginPlay();

    // Pull config from replicated server info (client-side)
    if (Level.NetMode != NM_DedicatedServer)
    {
        foreach DynamicActors(class'UTComp_ServerReplicationInfo', RepInfo)
        {
            bEnableCorrectionSmoothing = RepInfo.bEnableCorrectionSmoothing;
            CorrectionHalfLife         = RepInfo.CorrectionHalfLife;
            CorrectionJumpThreshold    = RepInfo.CorrectionJumpThreshold;
            MaxVisualOffset            = RepInfo.MaxVisualOffset;
            bSmoothCameraOffset        = RepInfo.bSmoothCameraOffset;
            break;
        }
    }
}

simulated function Tick(float DeltaTime)
{
    local vector PositionDelta;
    local float  DeltaSize;
    local float  DecayFactor;

    Super.Tick(DeltaTime);

    if (Level.NetMode != NM_DedicatedServer && PlayerController(Controller) == None)
    {
        // Trick the client that we're always on screen so it does not stop
        // updating animations.
        LastRenderTime = Level.TimeSeconds;
    }

    // Smoothed render offset — client only, skip our own local pawn
    // (local pawn uses prediction; only remote/corrected pawns snap visibly).
    // Actually we DO want it on the local pawn too, because ClientAdjustPosition
    // snaps the local pawn on corrections. But first-person camera smoothing
    // only matters for the local pawn.
    if (Level.NetMode == NM_Client && bEnableCorrectionSmoothing)
    {
        if (!bVisualOffsetInitialized)
        {
            LastPhysicsLocation = Location;
            bVisualOffsetInitialized = true;
        }
        else if (DeltaTime > 0.0)
        {
            // Detect position jump: delta between last frame's location and this
            // frame's location, MINUS what the pawn would have moved under normal
            // velocity. We approximate by treating anything over the threshold as
            // a correction (normal movement frame-to-frame is small).
            PositionDelta = LastPhysicsLocation - Location;
            DeltaSize = VSize(PositionDelta);

            // Engine-side: we'd ideally subtract Velocity*DeltaTime to isolate the
            // correction from normal movement. But a pawn moving 1000 UU/s at 60fps
            // only moves 16 UU/frame, well under a reasonable threshold (~40 UU).
            if (DeltaSize > CorrectionJumpThreshold && DeltaSize < MaxVisualOffset)
            {
                // Pawn visually stays where it WAS, then smoothly slides to new pos
                VisualOffset += PositionDelta;

                // Clamp accumulated offset to MaxVisualOffset
                if (VSize(VisualOffset) > MaxVisualOffset)
                    VisualOffset = Normal(VisualOffset) * MaxVisualOffset;
            }

            // Frame-rate independent exponential decay
            // Each half-life, offset halves. 0.5 ^ (dt/halflife)
            if (CorrectionHalfLife > 0.0)
            {
                DecayFactor = 0.5 ** (DeltaTime / CorrectionHalfLife);
                VisualOffset *= DecayFactor;
            }
            else
            {
                VisualOffset = vect(0,0,0);
            }

            // Apply as PrePivot — offsets mesh rendering without moving actor origin
            if (VSize(VisualOffset) > 0.5)
                PrePivot = VisualOffset;
            else
            {
                PrePivot = vect(0,0,0);
                VisualOffset = vect(0,0,0);
            }
        }

        LastPhysicsLocation = Location;
    }
}

// First-person camera offset — slides camera with the mesh so the player
// does not see themselves snap during correction.
simulated function vector EyePosition()
{
    if (bEnableCorrectionSmoothing && bSmoothCameraOffset && VSize(VisualOffset) > 0.1)
        return Super.EyePosition() + VisualOffset;
    return Super.EyePosition();
}


State Dying
{
    simulated function Timer()
	{
		local KarmaParamsSkel skelParams;

        // since we are setting LastRenderTime, this breaks PlayerCanSeeMe (native and final)
        // resulting in dead pawns floating around.  Add an 8 sec safety catch,
        // after 8 sec always destroy
        DyingTimer++;
		if ( !PlayerCanSeeMe() || DyingTimer >= 8 )
        {
			Destroy();
        }
        // If we are running out of life, bute we still haven't come to rest, force the de-res.
        // unless pawn is the viewtarget of a player who used to own it
        else if ( LifeSpan <= DeResTime && bDeRes == false )
        {
			skelParams = KarmaParamsSkel(KParams);

			// check not viewtarget
			if ( (PlayerController(OldController) != None) && (PlayerController(OldController).ViewTarget == self)
				&& (Viewport(PlayerController(OldController).Player) != None) )
			{
				skelParams.bKImportantRagdoll = true;
				LifeSpan = FMax(LifeSpan,DeResTime + 2.0);
				SetTimer(1.0, false);
				return;
			}
			else
			{
				skelParams.bKImportantRagdoll = false;
			}
            // spawn derez
            StartDeRes();
        }
		else
        {
			SetTimer(1.0, false);
        }
	}
}

// Damage impulse replication DISABLED — engine handles corrections natively.
// ModernPawn smooths the visual result via PrePivot + EyePosition override.
function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
    super.TakeDamage(Damage, instigatedBy, hitlocation, momentum, damageType);
}

defaultproperties
{
    DyingTimer=0
    bVisualOffsetInitialized=false
    // Fallback defaults — overridden by ServerReplicationInfo values on spawn
    bEnableCorrectionSmoothing=true
    CorrectionHalfLife=0.050
    CorrectionJumpThreshold=30.0
    MaxVisualOffset=400.0
    bSmoothCameraOffset=true
}
