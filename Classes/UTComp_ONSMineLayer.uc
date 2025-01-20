
class UTComp_ONSMineLayer extends ONSMineLayer
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
        ExchangeFireModes=class'ONSMineLayer'.default.ExchangeFireModes;
        Priority=class'ONSMineLayer'.default.Priority;
        CustomCrosshair=class'ONSMineLayer'.default.CustomCrosshair;
        CustomCrosshairColor=class'ONSMineLayer'.default.CustomCrosshairColor;
        CustomCrosshairScale=class'ONSMineLayer'.default.CustomCrosshairScale;
        CustomCrosshairTextureName=class'ONSMineLayer'.default.CustomCrosshairTextureName;
        bConfigInitialized=true;
        StaticSaveConfig();
    }
}


defaultproperties
{
    PickupClass=class'UTComp_ONSMineLayerPickup'
    FireModeClass(0)=class'UTComp_ONSMineThrowFire'
}