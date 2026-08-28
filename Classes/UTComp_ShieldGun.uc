
//-----------------------------------------------------------
//
//-----------------------------------------------------------
class UTComp_ShieldGun extends ShieldGun
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
        ExchangeFireModes=class'ShieldGun'.default.ExchangeFireModes;
        Priority=class'ShieldGun'.default.Priority;
        CustomCrosshair=class'ShieldGun'.default.CustomCrosshair;
        CustomCrosshairColor=class'ShieldGun'.default.CustomCrosshairColor;
        CustomCrosshairScale=class'ShieldGun'.default.CustomCrosshairScale;
        CustomCrosshairTextureName=class'ShieldGun'.default.CustomCrosshairTextureName;
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

}
