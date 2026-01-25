

class UTComp_xBot extends xBot;

function SetPawnClass(string inClass, string inCharacter)
{
    local class<UTComp_xPawn> pClass;

    if ( inClass != "" )
	{
		pClass = class<UTComp_xPawn>(DynamicLoadObject(inClass, class'Class'));
		if (pClass != None)
			PawnClass = pClass;
	}
    PawnSetupRecord = class'xUtil'.static.FindPlayerRecord(inCharacter);
    PlayerReplicationInfo.SetCharacterName(inCharacter);
}

function ExecuteWhatToDoNext()
{
	bHasFired = false;
	GoalString = "WhatToDoNext at "$Level.TimeSeconds;
	if ( Pawn == None )
	{
		//warn(GetHumanReadableName()$" WhatToDoNext with no pawn");
		return;
	}
	//else if ( (Pawn.Weapon == None) && (Vehicle(Pawn) == None) )
	//	warn(GetHumanReadableName()$" WhatToDoNext with no weapon, "$Pawn$" health "$Pawn.health);

	if ( Enemy == None )
	{
		if ( Level.Game.TooManyBots(self) )
		{
			if ( Pawn != None )
			{
				if ( (Vehicle(Pawn) != None) && (Vehicle(Pawn).Driver != None) )
					Vehicle(Pawn).Driver.KilledBy(Vehicle(Pawn).Driver);
				else
				{
					Pawn.Health = 0;
					Pawn.Died( self, class'Suicided', Pawn.Location );
				}
			}
			Destroy();
			return;
		}
		BlockedPath = None;
		bFrustrated = false;
		if (Target == None || (Pawn(Target) != None && Pawn(Target).Health <= 0))
			StopFiring();
	}

	if ( ScriptingOverridesAI() && ShouldPerformScript() )
		return;
	if (Pawn.Physics == PHYS_None)
		Pawn.SetMovementPhysics();
	if ( (Pawn.Physics == PHYS_Falling) && DoWaitForLanding() )
		return;
	if ( (StartleActor != None) && !StartleActor.bDeleteMe && (VSize(StartleActor.Location - Pawn.Location) < StartleActor.CollisionRadius)  )
	{
		Startle(StartleActor);
		return;
	}
	bIgnoreEnemyChange = true;
	if ( (Enemy != None) && ((Enemy.Health <= 0) || (Enemy.Controller == None)) )
		LoseEnemy();
	if ( Enemy == None )
		Squad.FindNewEnemyFor(self,false);
	else if ( !Squad.MustKeepEnemy(Enemy) && !EnemyVisible() )
	{
		// decide if should lose enemy
		if ( Squad.IsDefending(self) )
		{
			if ( LostContact(4) )
				LoseEnemy();
		}
		else if ( LostContact(7) )
			LoseEnemy();
	}
	bIgnoreEnemyChange = false;
	if ( AssignSquadResponsibility() )
	{
		// might have gotten out of vehicle and been killed
		if ( Pawn == None )
			return;
		SwitchToBestWeapon();
		return;
	}
	if ( ShouldPerformScript() )
		return;
	if ( Enemy != None )
		ChooseAttackMode();
	else
	{
		GoalString = "WhatToDoNext Wander or Camp at "$Level.TimeSeconds;
		WanderOrCamp(true);
	}
	SwitchToBestWeapon();
}

function ChooseAttackMode()
{
	local float EnemyStrength, WeaponRating, RetreatThreshold;

	GoalString = " ChooseAttackMode last seen "$(Level.TimeSeconds - LastSeenTime);
	// should I run away?
	if ( (Squad == None) || (Enemy == None) || (Pawn == None) )
		log("HERE 1 Squad "$Squad$" Enemy "$Enemy$" pawn "$Pawn);
	EnemyStrength = RelativeStrength(Enemy);

	if ( Vehicle(Pawn) != None )
	{
		VehicleFightEnemy(true, EnemyStrength);
		return;
	}

	if ( !bFrustrated && !Squad.MustKeepEnemy(Enemy) )
	{
		RetreatThreshold = Aggressiveness;
        // fix none access
		if ( Pawn.Weapon != None && Pawn.Weapon.CurrentRating > 0.5 )
			RetreatThreshold = RetreatThreshold + 0.35 - skill * 0.05;
		if ( EnemyStrength > RetreatThreshold )
		{
			GoalString = "Retreat";
			if ( (PlayerReplicationInfo.Team != None) && (FRand() < 0.05) )
				SendMessage(None, 'Other', GetMessageIndex('INJURED'), 15, 'TEAM');
			DoRetreat();
			return;
		}
	}
	if ( (Squad.PriorityObjective(self) == 0) && (Skill + Tactics > 2) && ((EnemyStrength > -0.3) || (Pawn.Weapon.AIRating < 0.5)) )
	{
        if(Pawn.Weapon != None)
        {
            if (Pawn.Weapon.AIRating < 0.5 )
            {
                if ( EnemyStrength > 0.3 )
                    WeaponRating = 0;
                else
                    WeaponRating = Pawn.Weapon.CurrentRating/2000;
            }
            else if ( EnemyStrength > 0.3 )
                WeaponRating = Pawn.Weapon.CurrentRating/2000;
            else
                WeaponRating = Pawn.Weapon.CurrentRating/1000;
        }
        else
        {
            WeaponRating=0;
        }

		// fallback to better pickup?
		if ( FindInventoryGoal(WeaponRating) )
		{
			if ( InventorySpot(RouteGoal) == None )
				GoalString = "fallback - inventory goal is not pickup but "$RouteGoal;
			else
				GoalString = "Fallback to better pickup "$InventorySpot(RouteGoal).markedItem$" hidden "$InventorySpot(RouteGoal).markedItem.bHidden;
			GotoState('FallBack');
			return;
		}
	}
	GoalString = "ChooseAttackMode FightEnemy";
	FightEnemy(true, EnemyStrength);
}

function FightEnemy(bool bCanCharge, float EnemyStrength)
{
	local vector X,Y,Z;
	local float enemyDist;
	local float AdjustedCombatStyle;
	local bool bFarAway, bOldForcedCharge;

	if ( (Squad == None) || (Enemy == None) || (Pawn == None) )
		log("HERE 3 Squad "$Squad$" Enemy "$Enemy$" pawn "$Pawn);

	if ( Vehicle(Pawn) != None )
	{
		VehicleFightEnemy(bCanCharge, EnemyStrength);
		return;
	}
	if ( (Enemy == FailedHuntEnemy) && (Level.TimeSeconds == FailedHuntTime) )
	{
		GoalString = "FAILED HUNT - HANG OUT";
		if ( EnemyVisible() )
			bCanCharge = false;
		else if ( FindInventoryGoal(0) )
		{
			SetAttractionState();
			return;
		}
		else
		{
			WanderOrCamp(true);
			return;
		}
	}

	bOldForcedCharge = bMustCharge;
	bMustCharge = false;
	enemyDist = VSize(Pawn.Location - Enemy.Location);
    AdjustedCombatStyle = CombatStyle;
    if(Pawn != None && Pawn.Weapon != None)
        AdjustedCombatStyle = CombatStyle + Pawn.Weapon.SuggestAttackStyle();
	Aggression = 1.5 * FRand() - 0.8 + 2 * AdjustedCombatStyle - 0.5 * EnemyStrength
				+ FRand() * (Normal(Enemy.Velocity - Pawn.Velocity) Dot Normal(Enemy.Location - Pawn.Location));
	if ( Enemy.Weapon != None )
		Aggression += 2 * Enemy.Weapon.SuggestDefenseStyle();
	if ( enemyDist > MAXSTAKEOUTDIST )
		Aggression += 0.5;
	if ( (Pawn.Physics == PHYS_Walking) || (Pawn.Physics == PHYS_Falling) )
	{
		if (Pawn.Location.Z > Enemy.Location.Z + TACTICALHEIGHTADVANTAGE)
			Aggression = FMax(0.0, Aggression - 1.0 + AdjustedCombatStyle);
		else if ( (Skill < 4) && (enemyDist > 0.65 * MAXSTAKEOUTDIST) )
		{
			bFarAway = true;
			Aggression += 0.5;
		}
		else if (Pawn.Location.Z < Enemy.Location.Z - Pawn.CollisionHeight) // below enemy
			Aggression += CombatStyle;
	}

	if ( !EnemyVisible() )
	{
		if ( Squad.MustKeepEnemy(Enemy) )
		{
			GoalString = "Hunt priority enemy";
			GotoState('Hunting');
			return;
		}
		GoalString = "Enemy not visible";
		if ( !bCanCharge )
		{
			GoalString = "Stake Out - no charge";
			DoStakeOut();
		}

		else if ( Squad.IsDefending(self) && LostContact(4) && ClearShot(LastSeenPos, false) )
		{
			GoalString = "Stake Out "$LastSeenPos;
			DoStakeOut();
		}
		else if ( (((Aggression < 1) && !LostContact(3+2*FRand())) || IsSniping()) && CanStakeOut() )
		{
			GoalString = "Stake Out2";
			DoStakeOut();
		}
		else
		{
			GoalString = "Hunt";
			GotoState('Hunting');
		}
		return;
	}

	// see enemy - decide whether to charge it or strafe around/stand and fire
	BlockedPath = None;
	Target = Enemy;

	if( (Pawn.Weapon != None && Pawn.Weapon.bMeleeWeapon) || (bCanCharge && bOldForcedCharge) )
	{
		GoalString = "Charge";
		DoCharge();
		return;
	}
	if ( Pawn.RecommendLongRangedAttack() )
	{
		GoalString = "Long Ranged Attack";
		DoRangedAttackOn(Enemy);
		return;
	}

	if ( bCanCharge && (Skill < 5) && bFarAway && (Aggression > 1) && (FRand() < 0.5) )
	{
		GoalString = "Charge closer";
		DoCharge();
		return;
	}

	if ( (Pawn.Weapon != None && Pawn.Weapon.RecommendRangedAttack()) || IsSniping() || ((FRand() > 0.17 * (skill + Tactics - 1)) && !DefendMelee(enemyDist)) )
	{
		GoalString = "Ranged Attack";
		DoRangedAttackOn(Enemy);
		return;
	}

	if ( bCanCharge )
	{
		if ( Aggression > 1 )
		{
			GoalString = "Charge 2";
			DoCharge();
			return;
		}
	}
	GoalString = "Do tactical move";
	if ( (Pawn.Weapon != None && !Pawn.Weapon.RecommendSplashDamage()) && (FRand() < 0.7) && (3*Jumpiness + FRand()*Skill > 3) )
	{
		GetAxes(Pawn.Rotation,X,Y,Z);
		GoalString = "Try to Duck ";
		if ( FRand() < 0.5 )
		{
			Y *= -1;
			TryToDuck(Y, true);
		}
		else
			TryToDuck(Y, false);
	}
	DoTacticalMove();
}


simulated function Destroyed()
{
    local LinkedReplicationInfo LPRI, Next;

    if(PlayerReplicationInfo != None)
    {
        LPRI = PlayerReplicationInfo.CustomReplicationInfo;
        while(LPRI != None)
        {
            Next = LPRI.NextReplicationInfo;
            LPRI.Destroy();
            LPRI = Next;
        }

        PlayerReplicationInfo.CustomReplicationInfo = None;
        PlayerReplicationInfo.Destroy();
        PlayerReplicationInfo = None;
    }

    super.Destroyed();
}


defaultproperties
{
}
