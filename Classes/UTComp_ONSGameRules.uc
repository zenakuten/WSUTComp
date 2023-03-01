
Class UTComp_ONSGameRules extends GameRules;

//var ONSPlusGameReplicationInfo OPGRI;
//var ONSPlusMutator MutatorOwner;

var GameReplicationInfo OPGRI;
var MutUTComp MutatorOwner;

var array<UTComp_ONSTriggerHook> NodeMonitors;
var array<UTComp_ONSTriggerHook> VehicleSpawnMonitors;

var array<GameObjective.ScorerRecord> SavedScorers;

var bool bGrabResult;
var int PreIsolated;

// var float DamageScoreQuota;
var float IsolateBonusPctPerNode;

delegate NotifyUpdateLinkStateHook(ONSPowerCore Node);

// Nasty hacks to monitor when a node is destroyed (for the bonus score you get when isolating nodes), also added code for the enhanced radar map
function OPInitialise()
{
	local NavigationPoint n;
	local array<Name> IteratedNames, VFIteratedNames;
	local int i, j;
	local bool bContinue;
	local ONSVehicleFactory VF;

	if (MutatorOwner == none)
	{
        MutatorOwner=MutUTComp(Owner);
	}

	if (MutatorOwner == none)
	{
		Log("ERROR: UTComp_ONSGameRules.MutatorOwner IS NONE IN OPInitialise", 'UTCompError');
		return;
	}

	if (ONSOnslaughtGame(level.game) == none)
		return;

    IsolateBonusPctPerNode=MutatorOwner.RepInfo.NodeIsolateBonusPct;

	// Setup the node monitors
	if (true)
	{
		for (n=Level.NavigationPointList; n!=none; n=n.NextNavigationPoint)
		{
            if(ONSPowerCore(n) != none)
            {
                // snarf
                // event is triggered when node is damaged, used for hit sound
                ONSPowerCore(n).TakeDamageEvent = 'UTComp_ONSNodeDamaged';
                ONSPowerCore(n).DamageEventThreshold = 8;                 
            }

			if (ONSPowerNode(n) != none)
			{
                //setup new score (snarf)
                ONSPowerNode(n).Score = MutatorOwner.RepInfo.PowerNodeScore;

                //setup newnet stuff
                if(MutatorOwner != None && MutatorOwner.RepInfo != None && MutatorOwner.RepInfo.bEnableEnhancedNetCode)
                {
                    //TODO make PawnCollisionCopy work with actors
                    //MutatorOwner.SpawnCollisionCopy(n);
                }

				NotifyUpdateLinkStateHook = ONSPowerNode(n).UpdateLinkState;

				// Hook the nodes NotifyUpdateLinks delegate
				ONSPowerNode(n).UpdateLinkState = UpdateLinkStateHook;


				// Give the node an event name if it doesn't already have one
				if (ONSPowerNode(n).DestroyedEventName == '')
					ONSPowerNode(n).DestroyedEventName = 'UTComp_ONSNodeDestroyed';

				for (i=0; i<IteratedNames.Length; i++)
				{
					if (IteratedNames[i] == ONSPowerCore(n).DestroyedEventName)
					{
						bContinue = True;
						break;
					}
				}

				if (bContinue)
				{
					bContinue = False;
					continue;
				}


				// If the code reaches this point then a new DestroyedEventName has been found, add the current name to the list and spawn a trigger hook
				IteratedNames[IteratedNames.Length] = ONSPowerCore(n).DestroyedEventName;

				//NodeMonitors[NodeMonitors.Length] = Spawn(Class'ONSPlusTriggerHook');
				NodeMonitors[NodeMonitors.Length] = Spawn(Class'UTComp_ONSTriggerHook');
				NodeMonitors[NodeMonitors.Length-1].Master = Self;
				NodeMonitors[NodeMonitors.Length-1].Tag = ONSPowerCore(n).DestroyedEventName;
			}
            else if(ONSPowerCore(n) != none)
            {
                // setup power core score (snarf)
                ONSPowerCore(n).Score = MutatorOwner.RepInfo.PowerCoreScore;
            }
		}
	}

	// Setup the vehicle factory monitors
	//if (MutatorOwner.bAllowEnhancedRadar)
	if (true)
	{
		foreach AllActors(Class'ONSVehicleFactory', VF)
		{
			if (VF.Event == '')
				//VF.Event = 'ONSPlusVehicleSpawned';
				VF.Event = 'UTComp_ONSVehicleSpawned';

			for (j=0; j<VFIteratedNames.Length; j++)
			{
				if (VFIteratedNames[j] == VF.Event)
				{
					bContinue = True;
					break;
				}
			}

			if (bContinue)
			{
				bContinue = False;
				continue;
			}

			// If the code reaches this point then a new Event (for vehiclespawns) has been found, add the current name to the list and spawn a trigger hook
			VFIteratedNames[VFIteratedNames.Length] = VF.Event;

			//VehicleSpawnMonitors[VehicleSpawnMonitors.Length] = Spawn(Class'ONSPlusTriggerHook');
			VehicleSpawnMonitors[VehicleSpawnMonitors.Length] = Spawn(Class'UTComp_ONSTriggerHook');
			//VehicleSpawnMonitors[VehicleSpawnMonitors.Length-1].GRIMaster = ONSPlusGameReplicationInfo(level.game.GameReplicationInfo);
			VehicleSpawnMonitors[VehicleSpawnMonitors.Length-1].GRIMaster = level.game.GameReplicationInfo;
			VehicleSpawnMonitors[VehicleSpawnMonitors.Length-1].Tag = VF.Event;
		}
	}
}

// snarf attempt to fix the after round shenanigans
function bool CheckScore(PlayerReplicationInfo Scorer)
{
    local PlayerController PC;
    local Controller C;
    local ONSOnslaughtGame ONS;
    local int deadCore;
    local bool retval;

    retval = false;
    if(NextGameRules != none)
        retval = NextGameRules.CheckScore(Scorer);

    deadCore = -1;
    ONS = ONSOnslaughtGame(Level.Game);
    if(ONS != none && ONS.PowerCores[ONS.FinalCore[0]].Health <= 0)
        deadCore = 0;
    else if(ONS != none && ONS.PowerCores[ONS.FinalCore[1]].Health <= 0)
        deadCore = 1;

        //round has ended
    if(deadCore >= 0)
    {
        if(Level != None)
            C = Level.ControllerList;

        while(C != None)
        {
            PC = PlayerController(C);
            if (PC != None)
            {
                PC.ClientSetBehindView(true);
                PC.ClientSetViewTarget(ONS.PowerCores[ONS.FinalCore[deadCore]]);
                PC.SetViewTarget(ONS.PowerCores[ONS.FinalCore[deadCore]]);
                PC.ClientRoundEnded();

            }

            if(C != None)
                C.RoundHasEnded();

            C = C.NextController;
        }
    }

    return retval;
}

// Initialise the vehicle spawn list for a certain player
//function InitialiseVehicleSpawnList(ONSPlusPlayerReplicationInfo NewPlayer)
function InitialiseVehicleSpawnList(UTComp_ONSPlayerReplicationInfo NewPlayer)
{
	local int i;

	for (i=0; i<VehicleSpawnMonitors.Length; i++)
		VehicleSpawnMonitors[i].InitialiseVehicleSpawnList(NewPlayer);
}

function PowerNodeDestroyed(ONSPowerNode Node)
{
	local NavigationPoint n;
	local int IsolatedNum;

    ONSOnslaughtGame(Level.Game).UpdateSeveredLinks(); // snarf wtf

	for (n=Level.NavigationPointList; n!=none; n=n.NextNavigationPoint)
		if (ONSPowerNode(n) != none && ONSPowerNode(n).bSevered && (ONSPowerNode(n).DefenderTeamIndex == 0 || ONSPowerNode(n).DefenderTeamIndex == 1))
			IsolatedNum++;


	//PreIsolated = IsolatedNum; // snarf wtf?
	SavedScorers = Node.Scorers;

	bGrabResult = True;

    UpdateLinkStateHook(Node); //snarf again, wtf dude
}

function UpdateLinkStateHook(ONSPowerCore Node)
{
	local NavigationPoint n;
	local int IsolatedNum, i;
	local float ScoreBonus;

	NotifyUpdateLinkStateHook(Node);

	if (bGrabResult)
	{
		if (OPGRI == none && level.game.GameReplicationInfo != none)
			OPGRI = level.game.GameReplicationInfo;

		for (n=Level.NavigationPointList; n!=none; n=n.NextNavigationPoint)
			if (ONSPowerNode(n) != none && ONSPowerNode(n).bSevered && (ONSPowerNode(n).DefenderTeamIndex == 0 || ONSPowerNode(n).DefenderTeamIndex == 1))
				IsolatedNum++;

		// We know how many powernodes have been isolated from destroying this node, update the scores of the contributors
		if (IsolatedNum - PreIsolated > 0) // snarf wtfwtfwtf!
		{
			for (i=0; i<SavedScorers.Length; i++)
			{
				if (SavedScorers[i].C != none)
				{
					ScoreBonus = float(Node.Score) * SavedScorers[i].Pct * (IsolateBonusPctPerNode * (IsolatedNum - PreIsolated) * 0.01);
                    //log("Got node isolate bonus! ScoreBonus="$ScoreBonus);
					SavedScorers[i].C.PlayerReplicationInfo.Score += ScoreBonus;
				}
			}
		}

		bGrabResult = False;
		PreIsolated = 0;
	}
}

//points for damaging vehicles 
// Updated for 1.40 by pOOty to fix damage points inconsistencies.
function int NetDamage(int OriginalDamage, int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	//local float CurDamage;
	local int CurDamage;
	local float DamagePts;
  local bool bDebug;

  bDebug = MutatorOwner.RepInfo.bDebugLogging; // for somereason this always false??
  // bDebug = True;
  Log("UTComp:ONSGameRules-Debug "$bDebug$"Vehicle Damage Points="$MutatorOwner.RepInfo.VehicleDamagePoints);
	//CurDamage = Super.NetDamage(OriginalDamage, Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);
	CurDamage = Damage;

//	if (DamageType != Class'DamTypeLinkShaft' && DamageType != Class'DamTypeLinkPlasma' && injured != None
//		&& Vehicle(injured) != None && !Vehicle(injured).IsVehicleEmpty() && instigatedBy != None
//		&& instigatedBy != injured && CurDamage > 0 && instigatedBy.Controller != none
//		&& instigatedBy.Controller.PlayerReplicationInfo != none
//		&& UTComp_ONSPlayerReplicationInfo(instigatedBy.Controller.PlayerReplicationInfo) != none)
	if (CurDamage > 0) { // check this first, if 0 or less rest is pointless (ok bad pun)
		if (DamageType != Class'DamTypeLinkShaft' ) { // ignore linkshaft damage, but lets keep LinkPlasma, shaft might double points on healing/node linking
			 if (injured != None && Vehicle(injured) != None && !Vehicle(injured).IsVehicleEmpty()) { // vehicle and occupied
			    if (instigatedBy != None && instigatedBy != injured && instigatedBy.Controller != none) { // have a player who damaged and not themself
			 			  if (instigatedBy.Controller.PlayerReplicationInfo != none && UTComp_ONSPlayerReplicationInfo(instigatedBy.Controller.PlayerReplicationInfo) != none)  // have PRI objects
			 			  { // we've passed all the checks award bonus points, refactored the ugly if for debugging
								if (bDebug) Log("UTComp:ONSGameRules-Passed all DamagePoint Checks, Assigning OPGRI for PlayerName:"$instigatedBy.Controller.PlayerReplicationInfo.PlayerName$" dealt "$CurDamage$" points of Damage");
								if (OPGRI == none && PlayerController(instigatedBy.Controller) != none && PlayerController(instigatedBy.Controller).GameReplicationInfo != none)
									OPGRI = PlayerController(instigatedBy.Controller).GameReplicationInfo;
							     
									if (OPGRI != none) 	{
										DamagePts = float(CurDamage) / float(MutatorOwner.RepInfo.VehicleDamagePoints);
										if (Vehicle(injured).Team != instigatedBy.Controller.PlayerReplicationInfo.TeamID)
							        {
											UTComp_ONSPlayerReplicationInfo(instigatedBy.Controller.PlayerReplicationInfo).AddVehicleDamageBonus(DamagePts);
											if (bDebug) Log("UTComp:ONSGameRules-Awarding PlayerName:"$instigatedBy.Controller.PlayerReplicationInfo.PlayerName$" Damage Points ("$DamagePts$") for "$CurDamage$" dealt");
							        }
										else
							        {
											UTComp_ONSPlayerReplicationInfo(instigatedBy.Controller.PlayerReplicationInfo).AddVehicleDamageBonus(-1.0 * DamagePts);
											if (bDebug) Log("UTComp:ONSGameRules-Subtracting  PlayerName:"$instigatedBy.Controller.PlayerReplicationInfo.PlayerName$" Damage Points ("$DamagePts$") for "$CurDamage$" dealt to own team");
							        }
								} // OPGRI !none
								else { if (bDebug) Log("UTComp:ONSGameRules-OPGRI=None ");}	
							} // end point awards
							else { if (bDebug) Log("UTComp:ONSGameRules-No PRI ");}	
						} // player checks
						else { if (bDebug) Log("UTComp:ONSGameRules-No InstigatedBy, or self, or no controller");}	
					} // vehicle checks
					else { if (bDebug) Log("UTComp:ONSGameRules-Not an occupied, injured vehicle ");}	
				} // Damge type checks
				else { if (bDebug) Log("UTComp:ONSGameRules-Not allowed Damage Type ");}	
			} // CurDamage < 0 check
			else { if (bDebug) Log("UTComp:ONSGameRules-CurDamage < 0 (CurDamage="$CurDamage$")");}	
     
  if ( NextGameRules != None )
		return NextGameRules.NetDamage( OriginalDamage,Damage,injured,instigatedBy,HitLocation,Momentum,DamageType );

	return Damage;  // Was CurDamge
}

function NavigationPoint FindPlayerStart(Controller Player, optional byte InTeam, optional string incomingName)
{
	local array<NavigationPoint> PointList;

	if (MutatorOwner == none || Player == none || AIController(Player) != none)
		return Super.FindPlayerStart(Player, InTeam, incomingName);

	// HACK HACK HACK HACK HACK HACK HACK MUAHAHAHAHAH! (I'm overriding the FindPlayerStart function)
	if (ONSOnslaughtGame(level.game) != none && Player.PlayerReplicationInfo != none && UTComp_ONSPlayerReplicationInfo(Player.PlayerReplicationInfo) != none
		&& !UTComp_ONSPlayerReplicationInfo(Player.PlayerReplicationInfo).bLookingForStart)
	{
		PointList = UTComp_ONSPlayerReplicationInfo(Player.PlayerReplicationInfo).ONSPlusFindPlayerStart(True);

		if (PointList.Length > 0 && PointList[0] != none)
			return PointList[0];
	}


	return Super.FindPlayerStart(Player, InTeam, incomingName);
}

function GetServerDetails(out GameInfo.ServerResponseLine ServerState)
{
}


defaultproperties
{
    // DamageScoreQuota=100.0
    IsolateBonusPctPerNode=20.0
}