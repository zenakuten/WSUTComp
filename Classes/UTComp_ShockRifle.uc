

//-----------------------------------------------------------
//
//-----------------------------------------------------------
class UTComp_ShockRifle extends ShockRifle
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
        ExchangeFireModes=class'ShockRifle'.default.ExchangeFireModes;
        Priority=class'ShockRifle'.default.Priority;
        CustomCrosshair=class'ShockRifle'.default.CustomCrosshair;
        CustomCrosshairColor=class'ShockRifle'.default.CustomCrosshairColor;
        CustomCrosshairScale=class'ShockRifle'.default.CustomCrosshairScale;
        CustomCrosshairTextureName=class'ShockRifle'.default.CustomCrosshairTextureName;
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

simulated event RenderOverlays( Canvas Canvas )
{
	// I am hardcoding this fix, no special shockrifle rendering 
	super(Weapon).RenderOverlays(Canvas);
}

DefaultProperties
{
    FireModeClass(0)=class'UTComp_ShockBeamFire'
    FireModeClass(1)=class'UTComp_ShockProjFire'
    PickupClass=Class'UTComp_ShockRiflePickup'
}
