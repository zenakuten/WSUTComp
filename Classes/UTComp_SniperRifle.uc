

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

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    //these weapon settings are per class config, stored under [Package.Class], so nothing the
    //player sets on the stock weapon ever reaches this subclass.  we are also CacheExempt, so
    //we are left out of the .ucl records the stock weapon/crosshair menu lists, meaning they
    //never get set on us directly either.  take them from the stock weapon on every spawn -
    //keeping our own saved copy meant each new package name orphaned the player's settings
    if(Level.NetMode != NM_DedicatedServer)
    {
        ExchangeFireModes=class'SniperRifle'.default.ExchangeFireModes;
        Priority=class'SniperRifle'.default.Priority;
        CustomCrosshair=class'SniperRifle'.default.CustomCrosshair;
        CustomCrosshairColor=class'SniperRifle'.default.CustomCrosshairColor;
        CustomCrosshairScale=class'SniperRifle'.default.CustomCrosshairScale;
        CustomCrosshairTextureName=class'SniperRifle'.default.CustomCrosshairTextureName;
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
