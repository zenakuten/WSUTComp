class UTComp_ClassicSniperRifle extends ClassicSniperRifle
    HideDropDown
	CacheExempt;

defaultproperties
{
    BringUpTime=0.360000
    PutDownTime=0.330000

    PickupClass=Class'UTComp_ClassicSniperRiflePickup'    
    FireModeClass(0)=class'UTComp_ClassicSniperFire'
}