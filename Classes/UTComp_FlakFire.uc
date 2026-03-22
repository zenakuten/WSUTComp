

class UTComp_FlakFire extends FlakFire;

event ModeDoFire()
{
    local UTComp_PRI uPRI;
    if(weapon.owner.IsA('xPawn') && xPawn(Weapon.Owner).Controller!=None)
    {
        uPRI=class'UTComp_Util'.static.GetUTCompPRIFor(xPawn(Weapon.Owner).Controller);
        if(uPRI!=None)
            uPRI.NormalWepStatsPrim[7]+=9;
    }
    Super.ModeDoFire();
}

// Give SS_Line style different behavior.  Default flak is SS_Random.  Weapon config 
// allows changing SpreadStyle 
//             - - - 
// SS_Line =   - - - 
//             - - - 
function DoFireEffect()
{
    local Vector StartProj, StartTrace, X,Y,Z;
    local Rotator R, Aim;
    local Vector HitLocation, HitNormal;
    local Actor Other;
    local int p, oddeven;
    local int SpawnCount, SpawnPerLine;
    local float theta;

    Instigator.MakeNoise(1.0);
    Weapon.GetViewAxes(X,Y,Z);

    StartTrace = Instigator.Location + Instigator.EyePosition();// + X*Instigator.CollisionRadius;
    StartProj = StartTrace + X*ProjSpawnOffset.X;
    if ( !Weapon.WeaponCentered() )
	    StartProj = StartProj + Weapon.Hand * Y*ProjSpawnOffset.Y + Z*ProjSpawnOffset.Z;

    // check if projectile would spawn through a wall and adjust start location accordingly
    Other = Weapon.Trace(HitLocation, HitNormal, StartProj, StartTrace, false);
    if (Other != None)
    {
        StartProj = HitLocation;
    }
    
    Aim = AdjustAim(StartProj, AimError);

    SpawnCount = Max(1, ProjPerFire * int(Load));
	SpawnPerLine = SpawnCount / 3; // three lines
	oddeven = 0;
	if(ProjPerFire % 2 == 0)
		oddeven = 1;

    switch (SpreadStyle)
    {
    case SS_Random:
        X = Vector(Aim);
        for (p = 0; p < SpawnCount; p++)
        {
            R.Yaw = Spread * (FRand()-0.5);
            R.Pitch = Spread * (FRand()-0.5);
            R.Roll = Spread * (FRand()-0.5);
            SpawnProjectile(StartProj, Rotator(X >> R));
        }
        break;
    case SS_Line:
		/*
        for (p = 0; p < SpawnCount; p++)
        {
            theta = Spread*PI/32768*(p - float(SpawnCount-1)/2.0);
            X.X = Cos(theta);
            X.Y = Sin(theta);
            X.Z = 0.0;
            SpawnProjectile(StartProj, Rotator(X >> Aim));
        }
		*/
        for (p = 0; p < SpawnPerLine; p++)
        {
            theta = Spread*PI/32768*(p - float(SpawnPerLine-1)/2.0);
            X.X = Cos(theta);
            X.Y = Sin(theta);
            X.Z = 0.0;
			R = Rotator(X >> Aim);
			R.Pitch -= 200;
            SpawnProjectile(StartProj, R);
        }
        for (p = 0; p < SpawnPerLine+oddeven; p++)
        {
            theta = Spread*PI/32768*(p - float(SpawnPerLine+oddeven-1)/2.0);
            X.X = Cos(theta);
            X.Y = Sin(theta);
            X.Z = 0.0;
			R = Rotator(X >> Aim);
            SpawnProjectile(StartProj, R);
        }
        for (p = 0; p < SpawnPerLine; p++)
        {
            theta = Spread*PI/32768*(p - float(SpawnPerLine-1)/2.0);
            X.X = Cos(theta);
            X.Y = Sin(theta);
            X.Z = 0.0;
			R = Rotator(X >> Aim);
			R.Pitch += 200;
            SpawnProjectile(StartProj, R);
        }
        break;
    default:
        SpawnProjectile(StartProj, Aim);
    }
}

defaultproperties
{
    ProjectileClass=Class'UTComp_FlakChunk'
}
