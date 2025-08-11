

//-----------------------------------------------------------
//
//-----------------------------------------------------------
class UTComp_ShockRifle extends ShockRifle
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
        ExchangeFireModes=class'ShockRifle'.default.ExchangeFireModes;
        Priority=class'ShockRifle'.default.Priority;
        CustomCrosshair=class'ShockRifle'.default.CustomCrosshair;
        CustomCrosshairColor=class'ShockRifle'.default.CustomCrosshairColor;
        CustomCrosshairScale=class'ShockRifle'.default.CustomCrosshairScale;
        CustomCrosshairTextureName=class'ShockRifle'.default.CustomCrosshairTextureName;
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
    FireModeClass(0)=class'UTComp_ShockBeamFire'
    FireModeClass(1)=class'UTComp_ShockProjFire'
    PickupClass=Class'UTComp_ShockRiflePickup'
}
