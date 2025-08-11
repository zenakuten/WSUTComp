
class UTComp_FlakCannon extends FlakCannon
    HideDropDown
	CacheExempt;

var bool bCantFire;
var config bool bConfigInitialized;

replication
{
    reliable if( Role==ROLE_Authority )
        LockOut, UnLock;
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    //for each new version of ws utcomp, the weapon is considered a new
    //weapon due to different package name.  As a result a lot of custom config might be lost
    //like these custom weapon settings.  So on a new release, for first run of the weapon 
    //copy these config values from the stock weapon
    if(!bConfigInitialized && Level.NetMode != NM_DedicatedServer)
    {
        ExchangeFireModes=class'FlakCannon'.default.ExchangeFireModes;
        Priority=class'FlakCannon'.default.Priority;
        CustomCrosshair=class'FlakCannon'.default.CustomCrosshair;
        CustomCrosshairColor=class'FlakCannon'.default.CustomCrosshairColor;
        CustomCrosshairScale=class'FlakCannon'.default.CustomCrosshairScale;
        CustomCrosshairTextureName=class'FlakCannon'.default.CustomCrosshairTextureName;
        bConfigInitialized=true;
        StaticSaveConfig();
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
    FireModeClass(0)=class'UTComp_FlakFire'
    FireModeClass(1)=class'UTComp_FlakAltFire'
    PickupClass=Class'UTComp_FlakCannonPickup'
}
