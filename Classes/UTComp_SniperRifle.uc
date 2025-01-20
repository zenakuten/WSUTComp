

//-----------------------------------------------------------
//
//-----------------------------------------------------------
class UTComp_SniperRifle extends SniperRifle
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
        ExchangeFireModes=class'SniperRifle'.default.ExchangeFireModes;
        Priority=class'SniperRifle'.default.Priority;
        CustomCrosshair=class'SniperRifle'.default.CustomCrosshair;
        CustomCrosshairColor=class'SniperRifle'.default.CustomCrosshairColor;
        CustomCrosshairScale=class'SniperRifle'.default.CustomCrosshairScale;
        CustomCrosshairTextureName=class'SniperRifle'.default.CustomCrosshairTextureName;
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
