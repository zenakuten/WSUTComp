

//-----------------------------------------------------------
//
//-----------------------------------------------------------
class UTComp_LinkGun extends LinkGun
    HideDropDown
	CacheExempt;

var bool bCantFire;
var array<pawn> LockingPawns;

replication
{
reliable if( Role==ROLE_Authority )
    LockOut, UnLock;
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
