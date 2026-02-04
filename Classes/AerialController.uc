//=============================================================================
// AerialController - Changes to 3rd person view.
// http://come.to/MrEvil
//=============================================================================
// adapted for utcomp - snarf

class AerialController extends xPlayer;

//Behindview stuff:
var CrosshairEmitter AerialCrosshair;
var ConstantColor Transparency;
var bool bRememberBehindView;

replication
{
    reliable if(Role == ROLE_Authority)
        bRememberBehindView;
}

// Track user preference whenever they manually change camera
exec function BehindView(bool B)
{
    Super.BehindView(B);
    if(Vehicle(Pawn) == None)
        bRememberBehindView = B;
}

// Capture camera state when pawn dies
function PawnDied(Pawn P)
{
    if(P != None && Vehicle(P) == None)
        bRememberBehindView = bBehindView;
    
    Super.PawnDied(P);
}

// Override ClientRestart
function ClientRestart(Pawn NewPawn)
{
    // Save state before entering vehicle
    if(NewPawn != None && Vehicle(NewPawn) != None && Pawn != None && Vehicle(Pawn) == None)
        bRememberBehindView = bBehindView;
    
    Super.ClientRestart(NewPawn);
    
    // Restore camera after Super call completes
    if(Vehicle(NewPawn) == None && bRememberBehindView)
    {
        bBehindView = true;
        BehindView(true);
    }
}

function ChangedWeapon()
{
	Super.ChangedWeapon();
	UpdateCrosshairs();
}

function UpdateCrosshairs()
{
	if(Level.GetLocalPlayerController() != self)
		return;

	//Spawn a special crosshair.
	if(bBehindView && AerialCrosshair == None && Pawn != None)
		AerialCrosshair = Spawn(class'CrosshairEmitter', self);

	//Don't show normal crosshair if a special crosshair exists.
	//Notify crosshair that it may need to change style.
	if(AerialCrosshair != None)
	{
		myHUD.bCrosshairShow = false;
		AerialCrosshair.SetCrosshairStyle();
	}
}

//Camera positioning.
event PlayerCalcView(out actor ViewActor, out vector CameraLocation, out rotator CameraRotation)
{
	local vector HitLocation, Hitnormal, EndTrace, StartTrace;
	local float Distance;

	Super.PlayerCalcView(ViewActor, CameraLocation, CameraRotation);

    // Let vehicles use their standard camera system
    if(Vehicle(Pawn) != None)
        return;

	if(bBehindView)
	{
		//Slightly increase the height of the camera and stop it going through the roof.
		if(Trace(HitLocation, HitNormal, CameraLocation + (vect(0, 0, 65) >> CameraRotation), CameraLocation, false, vect(10, 10, 10)) != None)
			CameraLocation += (HitLocation - CameraLocation) - (10 * normal(HitLocation - CameraLocation));
		else
			CameraLocation += vect(0, 0, 64) >> CameraRotation;

		CalcBehindView(CameraLocation, CameraRotation, 0);

		if(AerialCrosshair == None)
			UpdateCrosshairs();
	}

	if(AerialCrosshair != None)
	{
		if(Pawn == None || (!bBehindView) || Pawn.IsA('Vehicle'))
		{
			AerialCrosshair.Destroy();
			myHUD.bCrosshairShow = myHUD.Default.bCrosshairShow;
			return;
		}

		StartTrace = Pawn.Location;
		StartTrace.Z += Pawn.BaseEyeHeight;

		EndTrace = StartTrace + vector(CameraRotation)*16384;

		if(Trace(HitLocation, HitNormal, EndTrace, StartTrace, true) == None)
        {
			HitLocation = EndTrace;
        }

		Distance = VSize(HitLocation - StartTrace);

        AerialCrosshair.SetLocation(HitLocation - vector(CameraRotation)*FMax(Distance/16, 16));
		AerialCrosshair.DistanceScale(VSize(AerialCrosshair.Location - StartTrace));

		//Ensure that both crosshairs cannot exist at the same time.
		myHUD.bCrosshairShow = false;
	}
	else if(myHUD != None)
		myHUD.bCrosshairShow = myHUD.Default.bCrosshairShow;
}

//Draw the crosshair on the screen. Let vehicles do their own crosshair.
simulated function RenderOverlays(canvas Canvas)
{
	if(AerialCrosshair != None && Vehicle(Pawn) == None)
		Canvas.DrawActor(AerialCrosshair, false, true);
}

//Overriden to allow up/down aiming.
//Why the hell did they lock it in the first place?! Stupid Epic!
function rotator AdjustAim(FireProperties FiredAmmunition, vector projStart, int aimerror)
{
    local vector FireDir, AimSpot, HitNormal, HitLocation, OldAim, AimOffset;
    local actor BestTarget;
    local float bestAim, bestDist, projspeed;
    local actor HitActor;
    local bool bNoZAdjust, bLeading;
    local rotator AimRot;

    FireDir = vector(Rotation);
    if ( FiredAmmunition.bInstantHit )
        HitActor = Trace(HitLocation, HitNormal, projStart + 10000 * FireDir, projStart, true);
    else
        HitActor = Trace(HitLocation, HitNormal, projStart + 4000 * FireDir, projStart, true);
    if ( (HitActor != None) && HitActor.bProjTarget )
    {
        BestTarget = HitActor;
        bNoZAdjust = true;
        OldAim = HitLocation;
        BestDist = VSize(BestTarget.Location - Pawn.Location);
    }
    else
    {
        // adjust aim based on FOV
        bestAim = 0.90;
        if ( (Level.NetMode == NM_Standalone) && bAimingHelp )
        {
            bestAim = 0.93;
            if ( FiredAmmunition.bInstantHit )
                bestAim = 0.97;
            if ( FOVAngle < DefaultFOV - 8 )
                bestAim = 0.99;
        }
        else if ( FiredAmmunition.bInstantHit )
                bestAim = 1.0;
        BestTarget = PickTarget(bestAim, bestDist, FireDir, projStart, FiredAmmunition.MaxRange);
        if ( BestTarget == None )
        {
		//Commenting out this bit fixes the locked rotation.
            //if (bBehindView)
            //    return Pawn.Rotation;
           // else
            // snarf - fix for vehicles
            if (bBehindView && Vehicle(Pawn) != None)
                return Pawn.Rotation;
            else
				return Rotation;
        }
        OldAim = projStart + FireDir * bestDist;
    }
	InstantWarnTarget(BestTarget,FiredAmmunition,FireDir);
	ShotTarget = Pawn(BestTarget);
    if ( !bAimingHelp || (Level.NetMode != NM_Standalone) )
    {
	//Commenting out this bit fixes the locked rotation.
        //if (bBehindView)
        //    return Pawn.Rotation;
        //else
        // snarf - fix for vehicles
        if (bBehindView && Vehicle(Pawn) != None)
            return Pawn.Rotation;
        else
            return Rotation;
    }

    // aim at target - help with leading also
    if ( !FiredAmmunition.bInstantHit )
    {
        projspeed = FiredAmmunition.ProjectileClass.default.speed;
        BestDist = vsize(BestTarget.Location + BestTarget.Velocity * FMin(1, 0.02 + BestDist/projSpeed) - projStart);
        bLeading = true;
        FireDir = BestTarget.Location + BestTarget.Velocity * FMin(1, 0.02 + BestDist/projSpeed) - projStart;
        AimSpot = projStart + bestDist * Normal(FireDir);
        // if splash damage weapon, try aiming at feet - trace down to find floor
        if ( FiredAmmunition.bTrySplash
            && ((BestTarget.Velocity != vect(0,0,0)) || (BestDist > 1500)) )
        {
            HitActor = Trace(HitLocation, HitNormal, AimSpot - BestTarget.CollisionHeight * vect(0,0,2), AimSpot, false);
            if ( (HitActor != None)
                && FastTrace(HitLocation + vect(0,0,4),projstart) )
                return rotator(HitLocation + vect(0,0,6) - projStart);
        }
    }
    else
    {
        FireDir = BestTarget.Location - projStart;
        AimSpot = projStart + bestDist * Normal(FireDir);
    }
    AimOffset = AimSpot - OldAim;

    // adjust Z of shooter if necessary
    if ( bNoZAdjust || (bLeading && (Abs(AimOffset.Z) < BestTarget.CollisionHeight)) )
        AimSpot.Z = OldAim.Z;
    else if ( AimOffset.Z < 0 )
        AimSpot.Z = BestTarget.Location.Z + 0.4 * BestTarget.CollisionHeight;
    else
        AimSpot.Z = BestTarget.Location.Z - 0.7 * BestTarget.CollisionHeight;

    if ( !bLeading )
    {
        // if not leading, add slight random error ( significant at long distances )
        if ( !bNoZAdjust )
        {
            AimRot = rotator(AimSpot - projStart);
            if ( FOVAngle < DefaultFOV - 8 )
                AimRot.Yaw = AimRot.Yaw + 200 - Rand(400);
            else
                AimRot.Yaw = AimRot.Yaw + 375 - Rand(750);
            return AimRot;
        }
    }
    else if ( !FastTrace(projStart + 0.9 * bestDist * Normal(FireDir), projStart) )
    {
        FireDir = BestTarget.Location - projStart;
        AimSpot = projStart + bestDist * Normal(FireDir);
    }

    return rotator(AimSpot - projStart);
}

simulated event Destroyed()
{
	//Restore crosshair settings.
	if(myHUD != None)
		myHUD.bCrosshairShow = myHUD.Default.bCrosshairShow;

	if(AerialCrosshair != None)
		AerialCrosshair.Destroy();

	Super.Destroyed();
}

defaultproperties
{
}
