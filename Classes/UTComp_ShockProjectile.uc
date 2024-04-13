class UTComp_ShockProjectile extends TeamColorShockProjectile;

var class<WeaponDamageType> ComboRadiusDamageType;

function SuperExplosion()
{
	local actor HitActor;
	local vector HitLocation, HitNormal;
    local TeamColorShockCombo combo;

	HurtRadius(ComboDamage, ComboRadius, ComboRadiusDamageType, ComboMomentumTransfer, Location );

	//Spawn(class'ShockCombo');
	combo = Spawn(class'TeamColorShockCombo');
    if(combo != None)
    {
        combo.TeamNum = TeamNum;
    }

	if ( (Level.NetMode != NM_DedicatedServer) && EffectIsRelevant(Location,false) )
	{
		HitActor = Trace(HitLocation, HitNormal,Location - Vect(0,0,120), Location,false);
		if ( HitActor != None )
			Spawn(class'ComboDecal',self,,HitLocation, rotator(vect(0,0,-1)));
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
}
