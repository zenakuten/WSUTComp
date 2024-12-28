Class UTComp_ONSPlayerReplicationInfo extends ONSPlayerReplicationInfo
	dependson(MutUTComp);

var float PendingVehicleHealBonus;
var float PendingVehicleDamageBonus;
var float PendingPallyShieldBonus;

var float LastVRequestTime;

// ===== Struct definitions for handling available vehicle info
struct SpawnFactoryInfo
{
	var ONSVehicleFactory Factory;
	var byte CurFactoryTeam;
	var class<Vehicle> VehicleClass;
	var bool bSpawned;
	var ONSPowerCore OwningCore; // Serverside only
};
// =====

// Note: As the match progresses some of these factories will become owned by the other team so the list will get big..probably best to leave it like that(?)
var array<SpawnFactoryInfo> ServerVSpawnList;
var array<SpawnFactoryInfo> ClientVSpawnList;
var bool bInitializedVSpawnList;
var byte LastInitialiseTeam;

var actor StartSpawn;
var actor TemporaryStartSpawn;

var MutUTComp MutatorOwner;

// To stop recursive calls of FindPlayerStart
var bool bLookingForStart;

// for scoreboard
var float NodeDamagePoints;
var float NodeHealPoints;
var int NodesConstructed;
var int NodesDestroyed;
var int NodesDestroyedConstructing;
var int CoresDestroyed;

replication
{
	reliable if (bNetDirty && Role == ROLE_Authority)
		StartSpawn;

	reliable if (Role == ROLE_Authority)
		ClientUpdateFactoryList, ClientUpdateFactoryListTeam, ClientUpdateFactoryClass;

	reliable if (Role == ROLE_Authority)
		NodeDamagePoints, NodeHealPoints, NodesConstructed, NodesDestroyed, NodesDestroyedConstructing, CoresDestroyed;

	reliable if (Role < ROLE_Authority)
		ONSPlusTeleportTo, ONSPlusSetStartCore, RequestVehicleInfoUpdate;

    reliable if(Role == ROLE_Authority)
        ClientResetLists;
}

function SetStartCore(ONSPowerCore Core, bool bTemporary)
{
    ONSPlusSetStartCore(Core, bTemporary);
}

function ONSPlusSetStartCore(actor Spawn, bool bTemporary, optional Controller Requester)
{
	if (Spawn == None || ONSPlusValidSpawnPoint(Spawn, True))
	{
		if (bTemporary)
		{
			TemporaryStartSpawn = Spawn;

			if (ONSPowerCore(Spawn) != none)
				TemporaryStartCore = ONSPowerCore(Spawn);
			else
				TemporaryStartCore = None;
		}
		else if (ONSPowerCore(Spawn) != none)
		{
			StartSpawn = Spawn;
			StartCore = ONSPowerCore(Spawn);
		}
		else if (Spawn == none)
		{
			StartSpawn = None;
			StartCore = None;
		}

		if (Spawn != none && Requester != none)
			Requester.ServerRestartPlayer();
	}
}

function bool ONSPlusValidSpawnPoint(out actor Spawn, optional bool bTryRedoSpawn)
{
	local int i;

	if (Team != none)
	{
		if (ONSVehicleFactory(Spawn) != none && ONSVehicleFactory(Spawn).TeamNum == Team.TeamIndex)
		{
			// Check that the vehicle hasn't been taken or destroyed, otherwise find the powernode that owns the factory and change the spawn to that
			if (ONSVehicleFactory(Spawn).LastSpawned != none && ONSVehicleFactory(Spawn).LastSpawned.bTeamLocked)
				return True;
			else if (bTryRedoSpawn)
				for (i=0; i<ServerVSpawnList.Length; i++)
					if (ServerVSpawnList[i].Factory == Spawn)
						Spawn = ServerVSpawnList[i].OwningCore;
		}

		if (ONSPowerCore(Spawn) != none && ONSOnslaughtGame(Level.Game).ValidSpawnPoint(ONSPowerCore(Spawn), Team.TeamIndex))
			return True;
	}

	return False;
}

function TeleportTo(ONSPowerCore Core)
{
    ONSPlusTeleportTo(Core);
}

function ONSPlusTeleportTo(actor Spawn)
{
	local actor OldStartSpawn;
	local ONSPowerCore OldStartCore, OwnerBase;

	if (ONSOnslaughtGame(level.game) == none)
		return;

	OwnerBase = GetCurrentNode();

	// Uncomment code here
	if (OwnerBase != None && ONSPlusValidSpawnPoint(Spawn, True) && (ONSPowerCore(Spawn) != none || ONSVehicleFactory(Spawn) != none))
	{
		OldStartSpawn = StartSpawn;
		OldStartCore = StartCore;

		StartSpawn = Spawn;

		if (ONSPowerCore(Spawn) != none)
			StartCore = ONSPowerCore(Spawn);
		else
			StartCore = None;

		// two tries
		if (!ONSPlusDoTeleport())
			ONSPlusDoTeleport();

		StartSpawn = OldStartSpawn;
		StartCore = OldStartCore;
	}
}

function bool DoTeleport()
{
    return ONSPlusDoTeleport();
}

function bool ONSPlusDoTeleport()
{
	local array<NavigationPoint> NewStart;
	local vector PrevLocation;
	local int TeamNum, i;

	if (Team != none)
		TeamNum = Team.TeamIndex;

	PrevLocation = Controller(Owner).Pawn.Location;

	//if (MutatorOwner.bAllowEnhancedRadar)
	if (true)
	{
		NewStart = ONSPlusFindPlayerStart(,True);
	}
	else
	{
		NewStart.Insert(0, 1);
		NewStart[0] = Level.Game.FindPlayerStart(Controller(Owner));
	}

	for (i=0; i<NewStart.Length; i++)
	{
		if (NewStart[i] != none && Controller(Owner).Pawn.SetLocation(NewStart[i].Location))
		{
			Controller(Owner).ClientSetRotation(NewStart[i].Rotation);

			if (xPawn(Controller(Owner).Pawn) != None)
				xPawn(Controller(Owner).Pawn).DoTranslocateOut(PrevLocation);

			Controller(Owner).Pawn.SetOverlayMaterial(TransMaterials[TeamNum], 1.0, false);
			Controller(Owner).Pawn.PlayTeleportEffect(false, false);

			return true;
		}
	}

	return false;
}

function array<NavigationPoint> ONSPlusFindPlayerStart(optional bool bSkipRules, optional bool bForceStartSpawn)
{
	local array<NavigationPoint> StartList;
	local float BestRating, NewRating;
	local byte TeamNum, EnemyTeam;
	local actor SelectedPC;
	local float CoreDistA, CoreDistB, ClosestDist;
	local int i, j;
	local ONSPowerCore OwnerCore;
	local bool bDoubleBreak;
	local controller C;

	bLookingForStart = True;
	
	if (!bSkipRules && Level.Game.GameRulesModifiers != None)
	{
		if (Team == none)
			Level.Game.GameRulesModifiers.FindPlayerStart(Controller(Owner));
		else
			Level.Game.GameRulesModifiers.FindPlayerStart(Controller(Owner), Team.TeamIndex);
	}

	if (Team == none)
	{
		bLookingForStart = False;
		return StartList;
	}

	// Assume player already has a team
	TeamNum = Team.TeamIndex;

	// Use the powercore the player selected (if it's valid)
	SelectedPC = TemporaryStartSpawn;

	TemporaryStartSpawn = None;
	TemporaryStartCore = None;


	if (SelectedPC == None || bForceStartSpawn)
	{
		SelectedPC = StartSpawn;

		if (SelectedPC != none && !ONSPlusValidSpawnPoint(SelectedPC))
			SelectedPC = None;
	}


	if (SelectedPC != none)
	{
		// Check if the spawnpoint is invalid
		if (!ONSPlusValidSpawnPoint(SelectedPC, True))
		{
			// If it's a vehicle factory then set the spawnpoint to the owning core, otherwise set it to none
			if (ONSVehicleFactory(SelectedPC) != none)
			{
				// Iterate the stored vehicle factory list and find the owning powercore/node
				for (i=0; i<ServerVSpawnList.Length; ++i)
				{
					if (SelectedPC != none && ServerVSpawnList[i].Factory == SelectedPC)
					{
						if (ServerVSpawnList[i].OwningCore != none
							&& ONSOnslaughtGame(Level.Game).ValidSpawnPoint(ServerVSpawnList[i].OwningCore, TeamNum))
							SelectedPC = ServerVSpawnList[i].OwningCore;
						else
							SelectedPC = None;

						break;
					}
				}
			}
			else
			{
				SelectedPC = None;
			}
		}
	}

	if (SelectedPC == None)
	{
		if (ONSOnslaughtGame(level.game).PowerCores[ONSOnslaughtGame(level.game).FinalCore[TeamNum]].PoweredBy(1 - TeamNum))
			SelectedPC = ONSOnslaughtGame(level.game).PowerCores[ONSOnslaughtGame(level.game).FinalCore[TeamNum]];

		if (SelectedPC == None)
		{
			// Find the Closest Controlled Node(s) to Enemy PowerCore.
			EnemyTeam = abs(TeamNum - 1);
			BestRating = 255;

			for (i=0; i<ONSOnslaughtGame(level.game).PowerCores.Length; i++)
			{
				if (ONSOnslaughtGame(level.game).ValidSpawnPoint(ONSOnslaughtGame(level.game).PowerCores[i], TeamNum))
				{
					NewRating = ONSOnslaughtGame(level.game).PowerCores[i].FinalCoreDistance[EnemyTeam];

					if (NewRating < BestRating)
					{
						BestRating = NewRating;
						SelectedPC = ONSOnslaughtGame(level.game).PowerCores[i];
					}
					else if (NewRating == BestRating) // If we have two nodes at equal link distance, we check geometric distance
					{
						CoreDistA = VSize(ONSOnslaughtGame(level.game).PowerCores[ONSOnslaughtGame(level.game).FinalCore[EnemyTeam]].Location
								- ONSOnslaughtGame(level.game).PowerCores[i].Location);

						CoreDistB = VSize(ONSOnslaughtGame(level.game).PowerCores[ONSOnslaughtGame(level.game).FinalCore[EnemyTeam]].Location
								- SelectedPC.Location);

						if (CoreDistA < CoreDistB)
							SelectedPC = ONSOnslaughtGame(level.game).PowerCores[i];
					}
				}
			}

			// If no valid power node found, set to power core.
			if (SelectedPC == None)
				SelectedPC = ONSOnslaughtGame(level.game).PowerCores[ONSOnslaughtGame(level.game).FinalCore[TeamNum]];
		}
	}

	// SelectedPC is either a powernode/core or a vehicle spawnpoint...if it's a vehicle spawn then find the closest playerstart
	if (SelectedPC != none && ONSPowerCore(SelectedPC) != none)
	{
		for (i=0; i<ONSPowerCore(SelectedPC).CloseActors.length; i++)
		{
			if (NavigationPoint(ONSPowerCore(SelectedPC).CloseActors[i]) != None)
			{
				NewRating = ONSOnslaughtGame(level.game).RatePlayerStart(NavigationPoint(ONSPowerCore(SelectedPC).CloseActors[i]), TeamNum, Controller(Owner));

				if (NewRating > BestRating)
				{
					BestRating = NewRating;
					StartList.Insert(0, 1);
					StartList[0] = NavigationPoint(ONSPowerCore(SelectedPC).closeActors[i]);
				}
			}
		}
	}
	else if (SelectedPC != none && ONSVehicleFactory(SelectedPC) != none)
	{
		// Iterate your teams powernodes
		for (i=0; i<ONSOnslaughtGame(level.game).PowerCores.Length; i++)
		{
			if (ONSOnslaughtGame(Level.Game).ValidSpawnPoint(ONSOnslaughtGame(level.game).PowerCores[i], TeamNum))
			{
				// Find the powernode that 'owns' the selected vehicle spawn
				for (j=0; j<ONSOnslaughtGame(level.game).PowerCores[i].CloseActors.Length; j++)
				{
					if (ONSOnslaughtGame(level.game).PowerCores[i].CloseActors[j] == SelectedPC)
					{
						OwnerCore = ONSOnslaughtGame(level.game).PowerCores[i];
						bDoubleBreak = True;

						break;
					}
				}

				if (bDoubleBreak)
				{
					bDoubleBreak = False;
					break;
				}
			}
		}


		ClosestDist = -1;

		// Found the owner-powernode, iterate it's playerstart list for the closest playerstart
		if (OwnerCore != none)
		{
			for (i=0; i<OwnerCore.CloseActors.Length; i++)
			{
				if (PlayerStart(OwnerCore.CloseActors[i]) != none && (VSize(OwnerCore.CloseActors[i].Location - SelectedPC.Location) < ClosestDist || ClosestDist == -1))
				{
					// I don't use the 'RatePlayerStart' function here so I need to do different checks to prevent players telefragging
					for (C=Level.ControllerList; C!=none; C=C.NextController)
					{
						if (C.bIsPlayer && C.Pawn != none && VSize(C.Pawn.Location - OwnerCore.CloseActors[i].Location) < C.Pawn.CollisionRadius + C.Pawn.CollisionHeight)
						{
							StartList[StartList.Length] = PlayerStart(OwnerCore.CloseActors[i]);

							bDoubleBreak = True;
							break;
						}
					}

					if (bDoubleBreak)
					{
						bDoubleBreak = False;
						continue;
					}

					// Checks are complete, spawn the player
					ClosestDist = VSize(OwnerCore.CloseActors[i].Location - SelectedPC.Location);
					StartList.Insert(0, 1);
					StartList[0] = PlayerStart(OwnerCore.CloseActors[i]);
				}
			}
		}
	}

	if (StartList.Length > 0 && PlayerStart(StartList[0]) == None && (SelectedPC == none ||
		(SelectedPC != ONSOnslaughtGame(level.game).PowerCores[ONSOnslaughtGame(level.game).FinalCore[TeamNum]]
		&& ONSPowerCore(SelectedPC) != none)))
	{
		// couldn't find a start at the requested node, so try powercore
		SelectedPC = ONSOnslaughtGame(level.game).PowerCores[ONSOnslaughtGame(level.game).FinalCore[TeamNum]];
		StartList.Length = 0;

		if (SelectedPC != none)
		{
			for (i=0; i<ONSPowerCore(SelectedPC).CloseActors.length; i++)
			{
				if (NavigationPoint(ONSPowerCore(SelectedPC).CloseActors[i]) != None)
				{
					NewRating = ONSOnslaughtGame(level.game).RatePlayerStart(NavigationPoint(ONSPowerCore(SelectedPC).CloseActors[i]), TeamNum, Controller(Owner));

					if (NewRating > BestRating)
					{
						BestRating = NewRating;
						StartList.Insert(0, 1);
						StartList[0] = NavigationPoint(ONSPowerCore(SelectedPC).CloseActors[i]);
					}
				}
			}
		}
	}

	bLookingForStart = False;
	return StartList;
}

// Handle the list of vehicle factories and their current vehicle
function UpdateFactoryList(ONSVehicleFactory SubjectFactory)
{
	local int i, ListPos;
	local bool bInList, bDoubleBreak;
	local NavigationPoint n;

	if (ONSOnslaughtGame(level.game) == none)
		return;

	// Check if this factory is already in the list, if it is then check if its status has changed...if the status has then replicate the update (if factories not, replicate it)
	for (i=0; i<ServerVSpawnList.Length; i++)
	{
		// Factory already in list
		if (ServerVSpawnList[i].Factory == SubjectFactory)
		{
			// Check if factories 'status' HASN'T changed (the vehicles bTeamLocked value determines this)
			if ((ServerVSpawnList[i].bSpawned && SubjectFactory.LastSpawned != none && SubjectFactory.LastSpawned.bTeamLocked) ||
				!ServerVSpawnList[i].bSpawned && (SubjectFactory.LastSpawned == none || !SubjectFactory.LastSpawned.bTeamLocked))
				return;
			else
			{
				ServerVSpawnList[i].bSpawned = SubjectFactory.LastSpawned != none && SubjectFactory.LastSpawned.bTeamLocked;
				bInList = True;
				ListPos = i;

				break;
			}
		}
	}


	// At this point we have determined that either the factory is not in the list or their is a new update, replicate it
	if (!bInList)
	{
		ListPos = ServerVSpawnList.Length;
		ServerVSpawnList.Length = ServerVSpawnList.Length + 1;

		ServerVSpawnList[ListPos].Factory = SubjectFactory;
		ServerVSpawnList[ListPos].bSpawned = SubjectFactory.LastSpawned != none && SubjectFactory.LastSpawned.bTeamLocked;


		// Store the owning power node/core
		for (n=Level.NavigationPointList; n!=none; n=n.NextNavigationPoint)
		{
			if (ONSPowerCore(n) != none)
			{
				for (i=0; i<ONSPowerCore(n).CloseActors.Length; ++i)
				{
					if (ONSPowerCore(n).CloseActors[i] == SubjectFactory)
					{
						ServerVSpawnList[ListPos].OwningCore = ONSPowerCore(n);

						bDoubleBreak = True;
						break;
					}
				}

				if (bDoubleBreak)
				{
					bDoubleBreak = False;
					break;
				}
			}
		}
	}

	// Replication
	ClientUpdateFactoryList(SubjectFactory, ServerVSpawnList[ListPos].bSpawned);


	// bInList is usefull in that you can do an initial replication of once-off values
	if (!bInList)
		ClientUpdateFactoryClass(SubjectFactory, SubjectFactory.VehicleClass);
}

// This function is very similar to the above function
function UpdateFactoryListTeam(ONSVehicleFactory SubjectFactory, byte NewTeam)
{
	local int i, ListPos;
	local bool bInList;

	if (ONSOnslaughtGame(level.game) == none)
		return;

	for (i=0; i<ServerVSpawnList.Length; i++)
	{
		if (ServerVSpawnList[i].Factory == SubjectFactory)
		{
			ServerVSpawnList[i].CurFactoryTeam = NewTeam;
			bInList = True;
			ListPos = i;

			break;
		}
	}

	if (!bInList)
	{
		ListPos = ServerVSpawnList.Length;
		ServerVSpawnList.Length = ServerVSpawnList.Length + 1;

		ServerVSpawnList[ListPos].Factory = SubjectFactory;
		ServerVSpawnList[ListPos].CurFactoryTeam = NewTeam;
	}

	ClientUpdateFactoryListTeam(SubjectFactory, NewTeam);
}

simulated function ClientUpdateFactoryList(ONSVehicleFactory SubjectFactory, bool bNewlySpawned)
{
	local int i, ListPos;

	// Check if factory is already in the list
	for (i=0; i<ClientVSpawnList.Length; i++)
	{
		// Already in list, update and return
		if (ClientVSpawnList[i].Factory == SubjectFactory)
		{
			ClientVSpawnList[i].bSpawned = bNewlySpawned;
			return;
		}
	}

	// Factory not in list, add it and set its value
	ListPos = ClientVSpawnList.Length;
	ClientVSpawnList.Length = ClientVSpawnList.Length + 1;

	ClientVSpawnList[ListPos].Factory = SubjectFactory;
	ClientVSpawnList[ListPos].bSpawned = bNewlySpawned;
}

// Very similar to above function
simulated function ClientUpdateFactoryListTeam(ONSVehicleFactory SubjectFactory, byte NewTeam)
{
	local int i, ListPos;

	for (i=0; i<ClientVSpawnList.Length; i++)
	{
		if (ClientVSpawnList[i].Factory == SubjectFactory)
		{
			ClientVSpawnList[i].CurFactoryTeam = NewTeam;
			return;
		}
	}

	ListPos = ClientVSpawnList.Length;
	ClientVSpawnList.Length = ClientVSpawnList.Length + 1;

	ClientVSpawnList[ListPos].Factory = SubjectFactory;
	ClientVSpawnList[ListPos].CurFactoryTeam = NewTeam;
}

// Again, similar to above function
simulated function ClientUpdateFactoryClass(ONSVehicleFactory SubjectFactory, class<Vehicle> InitialVehicleClass)
{
	local int i, ListPos;

	for (i=0; i<ClientVSpawnList.Length; i++)
	{
		if (ClientVSpawnList[i].Factory == SubjectFactory)
		{
			ClientVSpawnList[i].VehicleClass = InitialVehicleClass;
			return;
		}
	}

	ListPos = ClientVSpawnList.Length;
	ClientVSpawnList.Length = ClientVSpawnList.Length + 1;

	ClientVSpawnList[ListPos].Factory = SubjectFactory;
	ClientVSpawnList[ListPos].VehicleClass = InitialVehicleClass;
}

function RequestVehicleInfoUpdate()
{
	local int i;

	if (Role == ROLE_Authority && ONSOnslaughtGame(level.game) != none && Level.TimeSeconds - LastVRequestTime > 3.0)
	{
		LastVRequestTime = Level.TimeSeconds;

		for (i=0; i<ServerVSpawnList.Length; ++i)
		{
			if (ServerVSpawnList[i].Factory.TeamNum != ServerVSpawnList[i].CurFactoryTeam)
				UpdateFactoryListTeam(ServerVSpawnList[i].Factory, ServerVSpawnList[i].Factory.TeamNum);

			if (Team != none && ServerVSpawnList[i].Factory.TeamNum == Team.TeamIndex)
				if (ServerVSpawnList[i].bSpawned != (ServerVSpawnList[i].Factory.LastSpawned != none && ServerVSpawnList[i].Factory.LastSpawned.bTeamLocked)
				&& (ServerVSpawnList[i].Factory.BuildEffect == none || ServerVSpawnList[i].Factory.LastSpawned != none))
					UpdateFactoryList(ServerVSpawnList[i].Factory);
		}
	}
}

function AddVehicleHealBonus(float Bonus)
{
	PendingVehicleHealBonus += Bonus;

	if (PendingVehicleHealBonus >= 1.0)
	{
		Level.Game.ScoreObjective(self, PendingVehicleHealBonus);
		Level.Game.ScoreEvent(self, PendingVehicleHealBonus, "heal_vehicle");
		PendingVehicleHealBonus = Max(0.0, PendingVehicleHealBonus - 1.0);
	}
}

function AddVehicleDamageBonus(float Bonus)
{
	PendingVehicleDamageBonus += Bonus;

	if (PendingVehicleDamageBonus >= 1.0)
	{
		Level.Game.ScoreObjective(self, PendingVehicleDamageBonus);
		Level.Game.ScoreEvent(self, PendingVehicleDamageBonus, "hurt_vehicle");
		PendingVehicleDamageBonus = Max(0.0, PendingVehicleDamageBonus - 1.0);
	}
}

function AddPallyShieldBonus(float Bonus)
{
	PendingPallyShieldBonus += Bonus;

	if (PendingPallyShieldBonus >= 1.0)
	{
		Level.Game.ScoreObjective(self, PendingPallyShieldBonus);
		Level.Game.ScoreEvent(self, PendingPallyShieldBonus, "pally_absorb");
		PendingPallyShieldBonus = Max(0.0, PendingPallyShieldBonus - 1.0);
	}
}

function ServerClearPowerLinks()
{
	local int i;
	local ONSOnslaughtGame Game;

	if (PlayerController(Owner) == None || (Owner != Level.GetLocalPlayerController() && !bAdmin))
		return;

	Game = ONSOnslaughtGame(Level.Game);

	while (Game.PowerLinks.length > 0)
		ServerRemovePowerLink(Game.PowerLinks[i].Nodes[0].Node, Game.PowerLinks[i].Nodes[1].Node);
}

// Shambler: Upon request, added some code to switch preferred spawn at round change when people select the power core (and to reset it when people only select a node)
function Reset()
{
	Super.Reset();

	// Is this role check even needed?
	if (Role == ROLE_Authority && ONSOnslaughtGame(Level.Game).bSwapSidesAfterReset)
	{
		if (StartCore == StartSpawn && StartCore != none && ONSPowerNode(StartCore) == none)
		{
			if (StartCore == ONSOnslaughtGame(Level.Game).PowerCores[ONSOnslaughtGame(Level.Game).FinalCore[0]])
				StartCore = ONSOnslaughtGame(Level.Game).PowerCores[ONSOnslaughtGame(Level.Game).FinalCore[1]];
			else
				StartCore = ONSOnslaughtGame(Level.Game).PowerCores[ONSOnslaughtGame(Level.Game).FinalCore[0]];

			StartSpawn = StartCore;
		}
		else
		{
			StartCore = none;
			StartSpawn = none;
		}
	}
}

// This is the only hook we have after the engine caps the client net speed
simulated function ClientPrepareToReceivePowerLinks()
{
    local PlayerController PC;
    super.ClientPrepareToReceivePowerLinks();

    PC = Level.GetLocalPlayerController();
    if(PC != None && BS_xPlayer(PC) != None)
    {
        BS_XPlayer(PC).SetInitialNetSpeed();
    }
}

function AddHealBonus(float Bonus)
{
    super.AddHealBonus(Bonus);
    NodeHealPoints += Bonus;
}

simulated function ClientResetLists()
{
    ServerVSpawnList.Length = 0;
    ClientVSpawnList.Length = 0;
}

defaultproperties
{
}
