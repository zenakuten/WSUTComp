
class NewNet_ClassicSniperFire extends UTComp_ClassicSniperFire;

var float PingDT;
var bool bUseEnhancedNetCode;


function DoTrace(Vector Start, Rotator Dir)
{
    local Vector X,Y,Z, End, HitLocation, HitNormal, ArcEnd;
    local Actor Other;
    local SniperWallHitEffect S;
    local Pawn HeadShotPawn;
    local vector PawnHitLocation;

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
    TimeTravel(PingDT);
    if(PingDT <=0.0)
        Other = Weapon.Trace(HitLocation,HitNormal,End,Start,true);
    else
        Other = DoTimeTravelTrace(HitLocation, HitNormal, End, Start);

    if(Other!=None && Other.IsA('PawnCollisionCopy'))
    {
         PawnHitLocation = HitLocation + PawnCollisionCopy(Other).CopiedPawn.Location - Other.Location;
         Other=PawnCollisionCopy(Other).CopiedPawn;
    }
    else
    {
        PawnHitLocation = HitLocation;
    }
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
 			else if ( (Pawn(Other) != None) && Pawn(Other).IsHeadShot(HitLocation, X, 1.0))
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
