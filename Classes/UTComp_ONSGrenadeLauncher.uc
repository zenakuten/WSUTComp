class UTComp_ONSGrenadeLauncher extends ONSGrenadeLauncher
    HideDropDown
	CacheExempt;

var config bool bConfigInitialized;

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    //for each new version of ws utcomp, the weapon is considered a new
    //weapon due to different package name.  As a result a lot of custom config might be lost
    //like these custom weapon settings.  So on a new release, for first run of the weapon 
    //copy these config values from the stock weapon
    if(!bConfigInitialized && Level.NetMode != NM_DedicatedServer)
    {
        ExchangeFireModes=class'ONSGrenadeLauncher'.default.ExchangeFireModes;
        Priority=class'ONSGrenadeLauncher'.default.Priority;
        CustomCrosshair=class'ONSGrenadeLauncher'.default.CustomCrosshair;
        CustomCrosshairColor=class'ONSGrenadeLauncher'.default.CustomCrosshairColor;
        CustomCrosshairScale=class'ONSGrenadeLauncher'.default.CustomCrosshairScale;
        CustomCrosshairTextureName=class'ONSGrenadeLauncher'.default.CustomCrosshairTextureName;
        bConfigInitialized=true;
        StaticSaveConfig();
    }
}

defaultproperties
{
    PickupClass=class'UTComp_ONSGrenadePickup'
    FireModeClass(0)=class'UTComp_ONSGrenadeFire'
}