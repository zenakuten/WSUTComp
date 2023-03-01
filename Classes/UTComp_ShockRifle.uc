

//-----------------------------------------------------------
//
//-----------------------------------------------------------
class UTComp_ShockRifle extends ShockRifle
    HideDropDown
	CacheExempt;

var bool bCantFire;

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

DefaultProperties
{
    FireModeClass(0)=class'UTComp_ShockBeamFire'
    FireModeClass(1)=class'UTComp_ShockProjFire'
    PickupClass=Class'UTComp_ShockRiflePickup'
}
