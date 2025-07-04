class UTComp_ShockProjectile extends TeamColorShockProjectile;

#exec AUDIO IMPORT FILE=Sounds\Impressive.wav        GROUP=Sounds
#exec AUDIO IMPORT FILE=Sounds\MostImpressive.wav    GROUP=Sounds

var Sound ImpressiveSound;
var Sound MostImpressiveSound;

var class<WeaponDamageType> ComboRadiusDamageType;

// copy from projectile -> hurt radius, return true if anybody killed
simulated function bool HurtRadiusEx( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation )
{
	local actor Victims;
	local float damageScale, dist;
	local vector dir;
    local bool bKilledPlayer;
    local float prevHealth;

	if ( bHurtEntry )
		return false;

	bHurtEntry = true;
    bKilledPlayer = false;
	foreach VisibleCollidingActors( class 'Actor', Victims, DamageRadius, HitLocation )
	{
		// don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
		if( (Victims != self) && (Hurtwall != Victims) && (Victims.Role == ROLE_Authority) && !Victims.IsA('FluidSurfaceInfo') )
		{
            if(Pawn(Victims) != None)
                prevHealth = Pawn(Victims).Health;

			dir = Victims.Location - HitLocation;
			dist = FMax(1,VSize(dir));
			dir = dir/dist;
			damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);
			if ( Instigator == None || Instigator.Controller == None )
				Victims.SetDelayedDamageInstigatorController( InstigatorController );
			if ( Victims == LastTouched )
				LastTouched = None;
			Victims.TakeDamage
			(
				damageScale * DamageAmount,
				Instigator,
				Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,
				(damageScale * Momentum * dir),
				DamageType
			);
			if (Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
				Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, InstigatorController, DamageType, Momentum, HitLocation);

            if(Pawn(Victims) != None && Pawn(Victims).Health <= 0 && prevHealth > 0 && Victims != Instigator)
                bKilledPlayer = true;

		}
	}
	if ( (LastTouched != None) && (LastTouched != self) && (LastTouched.Role == ROLE_Authority) && !LastTouched.IsA('FluidSurfaceInfo') )
	{
		Victims = LastTouched;
		LastTouched = None;
		dir = Victims.Location - HitLocation;
		dist = FMax(1,VSize(dir));
		dir = dir/dist;
		damageScale = FMax(Victims.CollisionRadius/(Victims.CollisionRadius + Victims.CollisionHeight),1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius));
		if ( Instigator == None || Instigator.Controller == None )
			Victims.SetDelayedDamageInstigatorController(InstigatorController);

        if(Pawn(Victims) != None)
            prevHealth = Pawn(Victims).Health;

		Victims.TakeDamage
		(
			damageScale * DamageAmount,
			Instigator,
			Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,
			(damageScale * Momentum * dir),
			DamageType
		);
		if (Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
			Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, InstigatorController, DamageType, Momentum, HitLocation);

        if(Pawn(Victims) != None && Pawn(Victims).Health <= 0 && prevHealth > 0.0 && Victims != Instigator)
            bKilledPlayer = true;
	}

	bHurtEntry = false;

    return bKilledPlayer;
}

function SuperExplosion()
{
	local actor HitActor;
	local vector HitLocation, HitNormal;
    local TeamColorShockCombo combo;
    local Vector Dir, InstDir;
    local float dot;
    local bool bKilledPlayer;
    local bool bIsImpressive;
    local bool bMostImpressive;

	bKilledPlayer = HurtRadiusEx(ComboDamage, ComboRadius, ComboRadiusDamageType, ComboMomentumTransfer, Location );

	//Spawn(class'ShockCombo');
	combo = Spawn(class'TeamColorShockCombo');
    if(combo != None)
    {
        combo.TeamNum = TeamNum;
    }

    HitActor = Trace(HitLocation, HitNormal,Location - Vect(0,0,120), Location,false);
	if( HitActor != None)
	{
    	if ( (Level.NetMode != NM_DedicatedServer) && EffectIsRelevant(Location,false) )
        {
			Spawn(class'ComboDecal',self,,HitLocation, rotator(vect(0,0,-1)));
        }
	}

    if(bKilledPlayer)
    {
        bIsImpressive=false;
        bMostImpressive=false;
        Dir=Normal(Velocity);
        InstDir=Vector(Instigator.Controller.Rotation);
        dot = InstDir Dot Dir;

        //impressive if at angle
        if(dot > 0.0 && dot < 0.94)
            bIsImpressive = true;

        //impressive if air and dodge speed 
        if(Instigator.Physics == PHYS_Falling && VSize(Instigator.Velocity) > Instigator.GroundSpeed * 1.2)
        {
            if(bIsImpressive)
                bMostImpressive=true;

            bIsImpressive = true;
        }
    
        if(BS_xPlayer(Instigator.Controller) != None)
        {
            if(bMostImpressive)
                BS_xPlayer(Instigator.Controller).ClientReceiveAward(MostImpressiveSound,0.5, 2.0);
            else if(bIsImpressive)
                BS_xPlayer(Instigator.Controller).ClientReceiveAward(ImpressiveSound,0.5, 2.0);
        }
    }

	PlaySound(ComboSound, SLOT_None,1.0,,800);
    DestroyTrails();
    Destroy();
}

event TakeDamage( int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType)
{
    local UTComp_PRI uPRI;
    if (EventInstigator != None && EventInstigator.Controller!=None)
        uPRI=class'UTComp_Util'.static.GetUTCompPRIFor(EventInstigator.Controller);

    if (DamageType == ComboDamageType)
    {
        Instigator = EventInstigator;
        SuperExplosion();

        if(uPRI != None)
        {
            uPRI.NormalWepStatsPrim[0]+=1;
	        uPRI.NormalWepStatsAlt[10]-=1;
	        uPRI.NormalWepStatsPrim[10]-=1;
	    }
        if( EventInstigator.Weapon != None )
        {
			EventInstigator.Weapon.ConsumeAmmo(0, ComboAmmoCost, true);
            Instigator = EventInstigator;
        }
    }
}

defaultproperties
{
    ComboRadiusDamageType=class'DamTypeShockCombo'
     ImpressiveSound=Sound'Sounds.Impressive'
     MostImpressiveSound=Sound'Sounds.MostImpressive'    
}
