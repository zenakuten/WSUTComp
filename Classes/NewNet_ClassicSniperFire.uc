
class NewNet_ClassicSniperFire extends UTComp_ClassicSniperFire;

var float PingDT;
var bool bUseEnhancedNetCode;

// What the client sent with the shot, see NewNet_ClassicSniperRifle.NewNet_ServerStartFire
var bool bUseReplicatedInfo; // fire from the eye position the client sent (savedVec)
var bool bUseReplicatedRot;  // fire along the aim the client sent (savedRot)
var rotator savedRot;
var vector savedVec;
var bool bBelievesHit;       // the client's own trace along that aim hit a player or vehicle
var Actor BelievedHitActor;
var bool bFirstGo;           // the next trace is the one the client's belief is about
var float AverDT;

// Every shot ends the client's fire, so holding the button starts a new one per shot,
// each sending its own aim and stamp. Otherwise held fire would be aimed by the server.
function PlayFiring()
{
    super.PlayFiring();

    if(Level.NetMode == NM_Client && Instigator != None && Instigator.IsLocallyControlled()
        && BS_xPlayer(Level.GetLocalPlayerController()) != None
        && BS_xPlayer(Level.GetLocalPlayerController()).UseNewNet())
        Weapon.ClientStopFire(ThisModeNum);
}

function DoFireEffect()
{
    local Vector StartTrace;
    local Rotator R, Aim;

    if(!bUseEnhancedNetCode)
    {
        super.DoFireEffect();
        return;
    }

    Instigator.MakeNoise(1.0);

    if(bUseReplicatedRot)
    {
        if(bUseReplicatedInfo)
            StartTrace = savedVec;
        else
            StartTrace = Instigator.Location + Instigator.EyePosition();
        R = SavedRot;
        if(Instigator.PointOfView())
        {
            Aim = AdjustAim(StartTrace, AimError);
            R = rotator(vector(Aim) + VRand()*FRand()*Spread);
        }
    }
    else
    {
        // the to-hit trace always starts right in front of the eye
        StartTrace = Instigator.Location + Instigator.EyePosition();
        Aim = AdjustAim(StartTrace, AimError);
        R = rotator(vector(Aim) + VRand()*FRand()*Spread);
        // the client's belief was about its own ray, not this one
        bFirstGo = false;
    }
    bUseReplicatedInfo = false;
    bUseReplicatedRot = false;

    DoTrace(StartTrace, R);
}

// Lag-compensated trace at PingDT-Delta, with the hit mapped from a collision copy
// onto the real pawn
function Actor RewoundTrace(float Delta, out vector HitLocation, out vector HitNormal, out vector PawnHitLocation, vector End, vector Start)
{
    local Actor Other;

    TimeTravel(PingDT - Delta);
    if(PingDT - Delta <= 0.0)
        Other = Weapon.Trace(HitLocation, HitNormal, End, Start, true);
    else
        Other = DoTimeTravelTrace(HitLocation, HitNormal, End, Start);

    if(Other != None && Other.IsA('PawnCollisionCopy'))
    {
        PawnHitLocation = HitLocation + PawnCollisionCopy(Other).CopiedPawn.Location - Other.Location;
        Other = PawnCollisionCopy(Other).CopiedPawn;
    }
    else
        PawnHitLocation = HitLocation;
    return Other;
}

function DoTrace(Vector Start, Rotator Dir)
{
    local Vector X,Y,Z, End, HitLocation, HitNormal, ArcEnd;
    local Actor Other, AltOther;
    local SniperWallHitEffect S;
    local Pawn HeadShotPawn;
    local vector PawnHitLocation, AltHitLocation, AltHitNormal, AltPawnHitLocation;
    local float f;

    if(!bUseEnhancedNetCode)
    {
        super.DoTrace(Start,Dir);
        return;
    }

    Weapon.GetViewAxes(X, Y, Z);
    if ( Weapon.WeaponCentered() )
        ArcEnd = (Instigator.Location +
			Weapon.EffectOffset.X * X +
			1.5 * Weapon.EffectOffset.Z * Z);
	else
        ArcEnd = (Instigator.Location +
			Instigator.CalcDrawOffset(Weapon) +
			Weapon.EffectOffset.X * X +
			Weapon.Hand * Weapon.EffectOffset.Y * Y +
			Weapon.EffectOffset.Z * Z);

    X = class'BS_xPlayer'.static.AimVector(Dir); // nearest, not down: see BS_xPlayer.AlignToView
    End = Start + TraceRange * X;

    Other = RewoundTrace(0.0, HitLocation, HitNormal, PawnHitLocation, End, Start);

    // When the server disagrees with what the client's own trace found, look a little
    // either side of the rewind time for the client's answer (same window as the
    // lightning gun and shock rifle)
    if(bFirstGo)
    {
        if(bBelievesHit && Other != BelievedHitActor)
        {
            f = 0.01;
            while(abs(f) < (0.04 + 2.0*AverDT))
            {
                AltOther = RewoundTrace(f, AltHitLocation, AltHitNormal, AltPawnHitLocation, End, Start);
                if(AltOther == BelievedHitActor)
                {
                    Other = AltOther;
                    HitLocation = AltHitLocation;
                    HitNormal = AltHitNormal;
                    PawnHitLocation = AltPawnHitLocation;
                    break;
                }
                if(f > 0.00)
                    f = -1.0*f;
                else
                    f = -1.0*f+0.01;
            }
        }
        else if(!bBelievesHit && Other != None && (Other.IsA('xPawn') || Other.IsA('Vehicle')))
        {
            f = 0.01;
            while(abs(f) < (0.04 + 2.0*AverDT))
            {
                AltOther = RewoundTrace(f, AltHitLocation, AltHitNormal, AltPawnHitLocation, End, Start);
                if(AltOther == None || !(AltOther.IsA('xPawn') || AltOther.IsA('Vehicle')))
                {
                    Other = AltOther;
                    HitLocation = AltHitLocation;
                    HitNormal = AltHitNormal;
                    PawnHitLocation = AltPawnHitLocation;
                    break;
                }
                if(f > 0.00)
                    f = -1.0*f;
                else
                    f = -1.0*f+0.01;
            }
        }
    }
    bFirstGo = false;
    UnTimeTravel();

    if ( (Level.NetMode != NM_Standalone) || (PlayerController(Instigator.Controller) == None) )
		Weapon.Spawn(class'TracerProjectile',Instigator.Controller,,Start,Dir);
    if ( Other != None && (Other != Instigator) )
    {
        if ( !Other.bWorldGeometry )
        {
            if (Vehicle(Other) != None)
                HeadShotPawn = Vehicle(Other).CheckForHeadShot(PawnHitLocation, X, 1.0);

            if (HeadShotPawn != None)
                HeadShotPawn.TakeDamage(DamageMax * HeadShotDamageMult, Instigator, PawnHitLocation, Momentum*X, DamageTypeHeadShot);
            // PawnHitLocation, not HitLocation: the head test is against the real pawn,
            // and HitLocation is on the rewound copy, which can be a body-width away
 			else if ( (Pawn(Other) != None) && Pawn(Other).IsHeadShot(PawnHitLocation, X, 1.0))
                Other.TakeDamage(DamageMax * HeadShotDamageMult, Instigator, PawnHitLocation, Momentum*X, DamageTypeHeadShot);
            else
                Other.TakeDamage(DamageMax, Instigator, PawnHitLocation, Momentum*X, DamageType);
        }
        else
				HitLocation = HitLocation + 2.0 * HitNormal;
    }
    else
    {
        HitLocation = End;
        HitNormal = Normal(Start - End);
    }

    if ( (HitNormal != Vect(0,0,0)) && (HitScanBlockingVolume(Other) == None) )
    {
		S = Weapon.Spawn(class'SniperWallHitEffect',,, HitLocation, rotator(-1 * HitNormal));
		if ( S != None )
			S.FireStart = Start;
	}
}

// Lag-compensated trace, see MutUTComp.TimeTravelTrace
function Actor DoTimeTravelTrace(Out vector Hitlocation, out vector HitNormal, vector End, vector Start)
{
    return NewNet_ClassicSniperRifle(Weapon).M.TimeTravelTrace(Weapon, Instigator, HitLocation, HitNormal, End, Start);
}

function TimeTravel(float delta)
{
    if(NewNet_ClassicSniperRifle(Weapon).M == none)
        foreach Weapon.DynamicActors(class'MutUTComp',NewNet_ClassicSniperRifle(Weapon).M)
            break;

    NewNet_ClassicSniperRifle(Weapon).M.TimeTravelCopies(Delta, Instigator);
}

function UnTimeTravel()
{
    NewNet_ClassicSniperRifle(Weapon).M.UnTimeTravelCopies();
}

DefaultProperties
{

}
