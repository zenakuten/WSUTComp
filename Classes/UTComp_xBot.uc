

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

function FightEnemy(bool bCanCharge, float EnemyStrength)
{
    if(Pawn != None && Pawn.Weapon == None)
        return;
    
    super.FightEnemy(bCanCharge, EnemyStrength);
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

    // fix none access
    if(Pawn != None && Pawn.Weapon == None)
        return;

	if ( !bFrustrated && !Squad.MustKeepEnemy(Enemy) )
	{
		RetreatThreshold = Aggressiveness;
		if ( Pawn.Weapon.CurrentRating > 0.5 )
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
		if ( Pawn.Weapon.AIRating < 0.5 )
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
