

//-----------------------------------------------------------
//
//-----------------------------------------------------------
class UTComp_LinkGun extends LinkGun
    HideDropDown
	CacheExempt;

var bool bCantFire;
var array<pawn> LockingPawns;

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
        ExchangeFireModes=class'LinkGun'.default.ExchangeFireModes;
        Priority=class'LinkGun'.default.Priority;
        CustomCrosshair=class'LinkGun'.default.CustomCrosshair;
        CustomCrosshairColor=class'LinkGun'.default.CustomCrosshairColor;
        CustomCrosshairScale=class'LinkGun'.default.CustomCrosshairScale;
        CustomCrosshairTextureName=class'LinkGun'.default.CustomCrosshairTextureName;
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

simulated function UTComp_ServerReplicationInfo GetRepInfo()
{
    local UTComp_ServerReplicationInfo RepInfo;
    foreach DynamicActors(class'UTComp_ServerReplicationInfo', RepInfo)
        break;

    return RepInfo;
}

DefaultProperties
{
    FireModeClass(0)=class'UTComp_LinkAltFire'
    FireModeClass(1)=class'UTComp_LinkFire'
    PickupClass=Class'UTComp_LinkGunPickup'
}
