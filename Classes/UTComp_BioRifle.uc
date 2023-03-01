
class UTComp_BioRifle extends BioRifle
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
    FireModeClass(0)=class'UTComp_BioFire'
    FireModeClass(1)=class'UTComp_BioChargedFire'
    PickupClass=Class'UTComp_BioRiflePickup'
}
