

//-----------------------------------------------------------
//
//-----------------------------------------------------------
class UTComp_MiniGun extends MiniGun
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
        ExchangeFireModes=class'MiniGun'.default.ExchangeFireModes;
        Priority=class'MiniGun'.default.Priority;
        CustomCrosshair=class'MiniGun'.default.CustomCrosshair;
        CustomCrosshairColor=class'MiniGun'.default.CustomCrosshairColor;
        CustomCrosshairScale=class'MiniGun'.default.CustomCrosshairScale;
        CustomCrosshairTextureName=class'MiniGun'.default.CustomCrosshairTextureName;
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

DefaultProperties
{
    FireModeClass(0)=class'UTComp_MiniGunFire'
    FireModeClass(1)=class'UTComp_MiniGunAltFire'
    PickupClass=Class'UTComp_MiniGunPickup'
}
