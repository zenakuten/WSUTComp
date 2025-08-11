

//-----------------------------------------------------------
//
//-----------------------------------------------------------
class UTComp_LinkGun extends LinkGun
    HideDropDown
	CacheExempt;

var bool bCantFire;
var config bool bConfigInitialized;
var array<pawn> LockingPawns;

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
        ExchangeFireModes=class'LinkGun'.default.ExchangeFireModes;
        Priority=class'LinkGun'.default.Priority;
        CustomCrosshair=class'LinkGun'.default.CustomCrosshair;
        CustomCrosshairColor=class'LinkGun'.default.CustomCrosshairColor;
        CustomCrosshairScale=class'LinkGun'.default.CustomCrosshairScale;
        CustomCrosshairTextureName=class'LinkGun'.default.CustomCrosshairTextureName;
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

simulated function UTComp_ServerReplicationInfo GetRepInfo()
{
    local UTComp_ServerReplicationInfo RepInfo;
    foreach DynamicActors(class'UTComp_ServerReplicationInfo', RepInfo)
        break;

    return RepInfo;
}

DefaultProperties
{
    FireModeClass(0)=class'UTComp_LinkAltFire'
    FireModeClass(1)=class'UTComp_LinkFire'
    PickupClass=Class'UTComp_LinkGunPickup'
}
