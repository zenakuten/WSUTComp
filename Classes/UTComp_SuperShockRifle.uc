class UTComp_SuperShockRifle extends SuperShockRifle
    HideDropDown
	CacheExempt;

var bool bCantFire;
var float  FOVAdj;
var float  MaxZoomLevel;
var() bool zoomed;
var transient float LastFOV;
var UTComp_EliteScope ScopeClass;
var UTComp_Scope CurrentScope;
var config bool bConfigInitialized;

replication
{
    reliable if( Role==ROLE_Authority )
        LockOut, UnLock;
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    MaxZoomLevel = ( 90 * 8.3 - 90 ) / ( 8.3 * 88 );

    //for each new version of ws utcomp, the weapon is considered a new
    //weapon due to different package name.  As a result a lot of custom config might be lost
    //like these custom weapon settings.  So on a new release, for first run of the weapon 
    //copy these config values from the stock weapon
    if(!bConfigInitialized && Level.NetMode != NM_DedicatedServer)
    {
        ExchangeFireModes=class'SuperShockRifle'.default.ExchangeFireModes;
        Priority=class'SuperShockRifle'.default.Priority;
        CustomCrosshair=class'SuperShockRifle'.default.CustomCrosshair;
        CustomCrosshairColor=class'SuperShockRifle'.default.CustomCrosshairColor;
        CustomCrosshairScale=class'SuperShockRifle'.default.CustomCrosshairScale;
        CustomCrosshairTextureName=class'SuperShockRifle'.default.CustomCrosshairTextureName;
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

simulated function BringUp(optional Weapon PrevWeapon)
{
    if ( PlayerController(Instigator.Controller) != None )
    {
        LastFOV = PlayerController(Instigator.Controller).DesiredFOV;
    }
    if (CurrentScope != None) CurrentScope.BringUp(PrevWeapon);
    Super.BringUp(PrevWeapon);
}

simulated function bool PutDown()
{
    if (CurrentScope != None) CurrentScope.PutDown();
    return Super.PutDown();
}

simulated function SetScope()
{
    CurrentScope = Spawn(class'UTComp_EliteScope', Self);
}

simulated event RenderOverlays(Canvas C)
{
    local float ZoomLevel;
    if (PlayerController(Instigator.Controller) == None) return;
    if (CurrentScope == None) SetScope();

    if (zoomed && FOVAdj != 0.0 && !PlayerController(Instigator.Controller).bZooming) {
        ZoomLevel = PlayerController(Instigator.Controller).ZoomLevel;
        ZoomLevel += FOVAdj;
        if (ZoomLevel > MaxZoomLevel) ZoomLevel = MaxZoomLevel;
        if (ZoomLevel <= 0.0) {
            PlayerController(Instigator.Controller).ZoomLevel = 0;
            PlayerController(Instigator.Controller).EndZoom();
            zoomed=false;
        } else {
            PlayerController(Instigator.Controller).DesiredFOV = FClamp(90.0 - (ZoomLevel * 88.0), 1, 170);
            PlayerController(Instigator.Controller).ZoomLevel = ZoomLevel;
        }
        FOVAdj = 0.0;
    }

    if (LastFOV > PlayerController(Instigator.Controller).DesiredFOV) {
        PlaySound(Sound'WeaponSounds.LightningGun.LightningZoomIn', SLOT_Misc,,, ,,false);
    } else if (LastFOV < PlayerController(Instigator.Controller).DesiredFOV) {
        PlaySound(Sound'WeaponSounds.LightningGun.LightningZoomOut', SLOT_Misc,, ,,,false);   
    }
    LastFOV = PlayerController(Instigator.Controller).DesiredFOV;

    if (PlayerController(Instigator.Controller).DesiredFOV == PlayerController(Instigator.Controller).DefaultFOV) {
        Super.RenderOverlays(C);
        CurrentScope.RenderNormal(C);
        zoomed = false;
    } else {
        SetLocation( Instigator.Location + Instigator.CalcDrawOffset(self) );
        SetRotation( Instigator.GetViewRotation() );
        CurrentScope.RenderZoom(C);
        zoomed = true;
    }
}

simulated event ClientStartFire(int Mode)
{
    if (mode == 1) {
        FireMode[mode].bIsFiring = true;
        if (Instigator.Controller.IsA( 'PlayerController' )) {
            PlayerController(Instigator.Controller).ToggleZoomWithMax(MaxZoomLevel);
        }
    } else {
        Super.ClientStartFire(mode);
    }
}

simulated function ClientStopFire(int mode)
{
    if (mode == 1) {
        FireMode[mode].bIsFiring = false;
        if(Instigator.Controller.IsA( 'PlayerController' )) {
            PlayerController(Instigator.Controller).StopZoom();
        }
    } else {
        Super.ClientStopFire(mode);
    }
}

exec function ZOOMIN()
{
  FOVAdj = +0.025;
}

exec function ZOOMOUT()
{
  FOVAdj = -0.025;
}


DefaultProperties
{
    FireModeClass(0)=class'UTComp_SuperShockBeamFire'
    FireModeClass(1)=class'UTComp_Zoom'
}
