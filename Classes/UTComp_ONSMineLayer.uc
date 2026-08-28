
class UTComp_ONSMineLayer extends ONSMineLayer
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
        ExchangeFireModes=class'ONSMineLayer'.default.ExchangeFireModes;
        Priority=class'ONSMineLayer'.default.Priority;
        CustomCrosshair=class'ONSMineLayer'.default.CustomCrosshair;
        CustomCrosshairColor=class'ONSMineLayer'.default.CustomCrosshairColor;
        CustomCrosshairScale=class'ONSMineLayer'.default.CustomCrosshairScale;
        CustomCrosshairTextureName=class'ONSMineLayer'.default.CustomCrosshairTextureName;
    }
}


defaultproperties
{
    PickupClass=class'UTComp_ONSMineLayerPickup'
    FireModeClass(0)=class'UTComp_ONSMineThrowFire'
}