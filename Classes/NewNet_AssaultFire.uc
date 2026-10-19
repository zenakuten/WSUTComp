class NewNet_AssaultFire extends UTComp_AssaultFire;

var float PingDT;
var bool bUseEnhancedNetCode;

function DoTrace(Vector Start, Rotator Dir)
{
    local Vector X, End, HitLocation, HitNormal, RefNormal;
    local Actor Other;
    local int Damage;
    local bool bDoReflect;
    local int ReflectNum;
    local vector PawnHitLocation;

    if(!bUseEnhancedNetCode)
    {
        super.DoTrace(Start,Dir);
        return;
    }

	MaxRange();

    ReflectNum = 0;
    TimeTravel(pingDT);
    while (true)
    {
        bDoReflect = false;
        X = Vector(Dir);
        End = Start + TraceRange * X;

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

        if ( Other != None && (Other != Instigator || ReflectNum > 0) )
        {
            if (bReflective && Other.IsA('xPawn') && xPawn(Other).CheckReflect(PawnHitLocation, RefNormal, DamageMin*0.25))
            {
                bDoReflect = true;
                HitNormal = Vect(0,0,0);
            }
            else if ( !Other.bWorldGeometry )
            {
				Damage = DamageMin;
				if ( (DamageMin != DamageMax) && (FRand() > 0.5) )
					Damage += Rand(1 + DamageMax - DamageMin);
                Damage = Damage * DamageAtten;

				// Update hit effect except for pawns (blood) other than vehicles.
               	if ( Other.IsA('Vehicle') || (!Other.IsA('Pawn') && !Other.IsA('HitScanBlockingVolume')) )
					WeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other, PawnHitLocation, HitNormal);

               	Other.TakeDamage(Damage, Instigator, PawnHitLocation, Momentum*X, DamageType);
                HitNormal = Vect(0,0,0);
            }
            else if ( WeaponAttachment(Weapon.ThirdPersonActor) != None )
				WeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other,PawnHitLocation,HitNormal);
        }
        else
        {
            HitLocation = End;
            HitNormal = Vect(0,0,0);
			WeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other,PawnHitLocation,HitNormal);
        }

        SpawnBeamEffect(Start, Dir, HitLocation, HitNormal, ReflectNum);

        if (bDoReflect && ++ReflectNum < 4)
        {
            //Log("reflecting off"@Other@Start@HitLocation);
            Start = HitLocation;
            Dir = Rotator(RefNormal); //Rotator( X - 2.0*RefNormal*(X dot RefNormal) );
        }
        else
        {
            break;
        }
    }
    UnTimeTravel();
}

// Lag-compensated trace, see MutUTComp.TimeTravelTrace
function Actor DoTimeTravelTrace(Out vector Hitlocation, out vector HitNormal, vector End, vector Start)
{
    return NewNet_AssaultRifle(Weapon).M.TimeTravelTrace(Weapon, Instigator, HitLocation, HitNormal, End, Start);
}

function TimeTravel(float delta)
{
    if(NewNet_AssaultRifle(Weapon).M == none)
        foreach Weapon.DynamicActors(class'MutUTComp',NewNet_AssaultRifle(Weapon).M)
            break;

    NewNet_AssaultRifle(Weapon).M.TimeTravelCopies(Delta, Instigator);
}

function UnTimeTravel()
{
    NewNet_AssaultRifle(Weapon).M.UnTimeTravelCopies();
}

DefaultProperties
{

}
