class UTComp_ONSGrenadeLauncher extends ONSGrenadeLauncher
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
        ExchangeFireModes=class'ONSGrenadeLauncher'.default.ExchangeFireModes;
        Priority=class'ONSGrenadeLauncher'.default.Priority;
        CustomCrosshair=class'ONSGrenadeLauncher'.default.CustomCrosshair;
        CustomCrosshairColor=class'ONSGrenadeLauncher'.default.CustomCrosshairColor;
        CustomCrosshairScale=class'ONSGrenadeLauncher'.default.CustomCrosshairScale;
        CustomCrosshairTextureName=class'ONSGrenadeLauncher'.default.CustomCrosshairTextureName;
    }
}

defaultproperties
{
    PickupClass=class'UTComp_ONSGrenadePickup'
    FireModeClass(0)=class'UTComp_ONSGrenadeFire'
}