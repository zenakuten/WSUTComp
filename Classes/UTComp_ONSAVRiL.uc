class UTComp_ONSAVRiL extends ONSAVRiL
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
        ExchangeFireModes=class'ONSAVRiL'.default.ExchangeFireModes;
        Priority=class'ONSAVRiL'.default.Priority;
        CustomCrosshair=class'ONSAVRiL'.default.CustomCrosshair;
        CustomCrosshairColor=class'ONSAVRiL'.default.CustomCrosshairColor;
        CustomCrosshairScale=class'ONSAVRiL'.default.CustomCrosshairScale;
        CustomCrosshairTextureName=class'ONSAVRiL'.default.CustomCrosshairTextureName;
    }
}

defaultproperties
{
    FireModeClass(0)=class'UTComp_ONSAVRiLFire'
    PickupClass=class'UTComp_ONSAVRiLPickup'
}