class UTComp_ClassicSniperRifle extends ClassicSniperRifle
    HideDropDown
	CacheExempt;

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
        ExchangeFireModes=class'ClassicSniperRifle'.default.ExchangeFireModes;
        Priority=class'ClassicSniperRifle'.default.Priority;
        CustomCrosshair=class'ClassicSniperRifle'.default.CustomCrosshair;
        CustomCrosshairColor=class'ClassicSniperRifle'.default.CustomCrosshairColor;
        CustomCrosshairScale=class'ClassicSniperRifle'.default.CustomCrosshairScale;
        CustomCrosshairTextureName=class'ClassicSniperRifle'.default.CustomCrosshairTextureName;
    }
}

defaultproperties
{
    BringUpTime=0.360000
    PutDownTime=0.330000

    PickupClass=Class'UTComp_ClassicSniperRiflePickup'    
    FireModeClass(0)=class'UTComp_ClassicSniperFire'
}