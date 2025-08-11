class UTComp_ClassicSniperRifle extends ClassicSniperRifle
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
        ExchangeFireModes=class'ClassicSniperRifle'.default.ExchangeFireModes;
        Priority=class'ClassicSniperRifle'.default.Priority;
        CustomCrosshair=class'ClassicSniperRifle'.default.CustomCrosshair;
        CustomCrosshairColor=class'ClassicSniperRifle'.default.CustomCrosshairColor;
        CustomCrosshairScale=class'ClassicSniperRifle'.default.CustomCrosshairScale;
        CustomCrosshairTextureName=class'ClassicSniperRifle'.default.CustomCrosshairTextureName;
        bConfigInitialized=true;
        StaticSaveConfig();
    }
}

defaultproperties
{
    BringUpTime=0.360000
    PutDownTime=0.330000

    PickupClass=Class'UTComp_ClassicSniperRiflePickup'    
    FireModeClass(0)=class'UTComp_ClassicSniperFire'
}