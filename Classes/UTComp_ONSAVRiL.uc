class UTComp_ONSAVRiL extends ONSAVRiL
    HideDropDown
	CacheExempt;

var config bool bConfigInitialized;

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    //for each new version of wsutcomp, the weapon is considered a new
    //weapon due to different package name.  As a result a lot of custom config might be lost
    //like these custom weapon settings.  So on a new release, for first run of the weapon 
    //copy these config values from the stock weapon
    if(!bConfigInitialized && Level.NetMode != NM_DedicatedServer)
    {
        ExchangeFireModes=class'ONSAVRiL'.default.ExchangeFireModes;
        Priority=class'ONSAVRiL'.default.Priority;
        CustomCrosshair=class'ONSAVRiL'.default.CustomCrosshair;
        CustomCrosshairColor=class'ONSAVRiL'.default.CustomCrosshairColor;
        CustomCrosshairScale=class'ONSAVRiL'.default.CustomCrosshairScale;
        CustomCrosshairTextureName=class'ONSAVRiL'.default.CustomCrosshairTextureName;
        bConfigInitialized=true;
        StaticSaveConfig();
    }
}

defaultproperties
{
    FireModeClass(0)=class'UTComp_ONSAVRiLFire'
    PickupClass=class'UTComp_ONSAVRiLPickup'
}