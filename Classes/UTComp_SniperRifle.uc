

//-----------------------------------------------------------
//
//-----------------------------------------------------------
class UTComp_SniperRifle extends SniperRifle
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

// snarf - add none checks around instigator for weapon fire bug
simulated function BringUp(optional Weapon PrevWeapon)
{
    if(Instigator != None && Instigator.Controller != None)
    {
        if ( PlayerController(Instigator.Controller) != None )
        {
            LastFOV = PlayerController(Instigator.Controller).DesiredFOV;
            if ( Instigator.IsLocallyControlled() )
                GotoState('TickEffects');
        }
    }

    Super.BringUp(PrevWeapon);
}

// snarf - add none checks around instigator for weapon fire bug
simulated function bool PutDown()
{
    if(Instigator != None && Instigator.Controller != None)
    {
        if( Instigator.Controller.IsA( 'PlayerController' ) )
            PlayerController(Instigator.Controller).EndZoom();
    }

    if ( Super.PutDown() )
    {
		GotoState('');
		return true;
	}
	return false;
}

DefaultProperties
{
    FireModeClass(0) = class'UTComp_SniperFire'
    PickupClass=Class'UTComp_SniperRiflePickup'
}
