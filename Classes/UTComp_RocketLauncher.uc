
//-----------------------------------------------------------
//
//-----------------------------------------------------------
class UTComp_RocketLauncher extends RocketLauncher
    HideDropDown
    CacheExempt;

var bool bCantFire;

replication
{
    reliable if( Role==ROLE_Authority )
        LockOut, UnLock;
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    //these weapon settings are per class config, stored under [Package.Class], so nothing the
    //player sets on the stock weapon ever reaches this subclass.  we are also CacheExempt, so
    //we are left out of the .ucl records the stock weapon/crosshair menu lists, meaning they
    //never get set on us directly either.  take them from the stock weapon on every spawn -
    //keeping our own saved copy meant each new package name orphaned the player's settings
    if(Level.NetMode != NM_DedicatedServer)
    {
        ExchangeFireModes=class'RocketLauncher'.default.ExchangeFireModes;
        Priority=class'RocketLauncher'.default.Priority;
        CustomCrosshair=class'RocketLauncher'.default.CustomCrosshair;
        CustomCrosshairColor=class'RocketLauncher'.default.CustomCrosshairColor;
        CustomCrosshairScale=class'RocketLauncher'.default.CustomCrosshairScale;
        CustomCrosshairTextureName=class'RocketLauncher'.default.CustomCrosshairTextureName;
    }
}


simulated function LockOut()
{
    bCantFire=true;
}

simulated function UnLock()
{
    bCantFire=false;
}

simulated function bool ReadyToFire(int Mode)
{
    if(bCantFire)
        return false;
    return super.ReadyToFire(mode);
}

function Projectile SpawnProjectile(Vector Start, Rotator Dir)
{
    local SeekingRocketProj Rocket;
    local bot B;

    bBreakLock = true;

    // decide if bot should be locked on
    B = Bot(Instigator.Controller);
    if ( (B != None) && (B.Skill > 2 + 5 * FRand()) && (FRand() < 0.6) && (B.Target != None)
        && (B.Target == B.Enemy) && (VSize(B.Enemy.Location - B.Pawn.Location) > 2000 + 2000 * FRand())
        && (Level.TimeSeconds - B.LastSeenTime < 0.4) && (Level.TimeSeconds - B.AcquireTime > 1.5) )
    {
        bLockedOn = true;
        SeekTarget = B.Enemy;
    }

    Rocket = Spawn(class'UTComp_RocketProj',,, Start, Dir);
    if (bLockedOn && SeekTarget != None)
    {
        if (Rocket != none)
            Rocket.Seeking = SeekTarget;
        if ( B != None )
        {
            bLockedOn = false;
            SeekTarget = None;
        }
    }

    return Rocket;
}


simulated function bool PutDown()
{
    // fix for when you switch weapons while charging rox but before they fire
    // causing switch to fail
    if(Level.TimeSeconds < FireMode[1].NextFireTime && FireMode[1].Load == 1)
        StopFire(1);

    return super.PutDown();
}

DefaultProperties
{
    PickupClass=Class'UTComp_RocketLauncherPickup'
    FireModeClass(0)=class'UTComp_RocketFire'
    FireModeClass(1)=class'UTComp_RocketMultiFire'
}
