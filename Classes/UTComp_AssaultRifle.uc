
//-----------------------------------------------------------
//
//-----------------------------------------------------------
class UTComp_AssaultRifle extends AssaultRifle
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

    //for each new version of wsutcomp, the weapon is considered a new
    //weapon due to different package name.  As a result a lot of custom config might be lost
    //like these custom weapon settings.  So on a new release, for first run of the weapon 
    //copy these config values from the stock weapon
    if(!bConfigInitialized && Level.NetMode != NM_DedicatedServer)
    {
        ExchangeFireModes=class'AssaultRifle'.default.ExchangeFireModes;
        Priority=class'AssaultRifle'.default.Priority;
        CustomCrosshair=class'AssaultRifle'.default.CustomCrosshair;
        CustomCrosshairColor=class'AssaultRifle'.default.CustomCrosshairColor;
        CustomCrosshairScale=class'AssaultRifle'.default.CustomCrosshairScale;
        CustomCrosshairTextureName=class'AssaultRifle'.default.CustomCrosshairTextureName;
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
    FireModeClass(0)=class'UTComp_AssaultFire'
    FireModeClass(1)=class'UTComp_AssaultGrenade'
    PickupClass=Class'UTComp_AssaultRiflePickup'
}
