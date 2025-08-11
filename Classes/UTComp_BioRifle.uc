
class UTComp_BioRifle extends BioRifle
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
        ExchangeFireModes=class'BioRifle'.default.ExchangeFireModes;
        Priority=class'BioRifle'.default.Priority;
        CustomCrosshair=class'BioRifle'.default.CustomCrosshair;
        CustomCrosshairColor=class'BioRifle'.default.CustomCrosshairColor;
        CustomCrosshairScale=class'BioRifle'.default.CustomCrosshairScale;
        CustomCrosshairTextureName=class'BioRifle'.default.CustomCrosshairTextureName;
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
    FireModeClass(0)=class'UTComp_BioFire'
    FireModeClass(1)=class'UTComp_BioChargedFire'
    PickupClass=Class'UTComp_BioRiflePickup'
}
