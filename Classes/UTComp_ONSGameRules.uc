
Class UTComp_ONSGameRules extends GameRules;

//var ONSPlusGameReplicationInfo OPGRI;
//var ONSPlusMutator MutatorOwner;

//var config bool bEnableEndRoundCheckScore;  // flag to use end round fix or not Removed pooty 03/2023
var config bool bDebugRules;  // general debug

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
		Log("ERROR: UTComp_ONSGameRules.MutatorOwner IS NONE IN OPInitialise", 'WSUTComp_Error');
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
	if (bDebugRules) log("Finished OPInitialise",'WSUTComp_ONSGameRules_OPInitialise');
}

// snarf attempt to fix the after round shenanigans
// Removed as custom score getting refactored and this should never be needed. 03/2023 Pooty
/*
function bool CheckScore(PlayerReplicationInfo Scorer)
{
    local PlayerController PC;
    local Controller C;
    local ONSOnslaughtGame ONS;
    local int deadCore;
    //local bool retval;

    if (bEnableEndRoundCheckScore) {

			Global.timer(); //clears all timers
			
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

	// lots of checking on C since there's been a few crashes when someone leaves
	// maybe this catches it.
	        while(C != None)
	        {
	            if(C != None) PC = PlayerController(C);
	            if (PC != None) PC.ClientSetBehindView(true);
	            if (PC != None) PC.ClientSetViewTarget(ONS.PowerCores[ONS.FinalCore[deadCore]]);
	            if (PC != None) PC.SetViewTarget(ONS.PowerCores[ONS.FinalCore[deadCore]]);
	            if (PC != None) PC.ClientRoundEnded();
	            

	            if(C != None) C.RoundHasEnded();  // We know round has ended just set client views commented out. 03/2023 pooty

	            if(C != None) C = C.NextController;
	        } // while
	        if (bDebugRules) log("Finished Resetting ClientViews",'WSUTComp_ONSGameRules_CheckScore');
	    } // dead core
	  }  // end bEnableEndRoundCheckScore

// Moved here to match other gamerules. other examples always show this at the end 03/2023 pooty
 if ( NextGameRules != None )
        return NextGameRules.CheckScore(Scorer);

    return false;
}

*/

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

function int NetDamage(int OriginalDamage, int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local int CurDamage, ptsDamage;

	CurDamage = Damage;
    if ( NextGameRules != None )
		CurDamage = NextGameRules.NetDamage( OriginalDamage,Damage,injured,instigatedBy,HitLocation,Momentum,DamageType );

	if (DamageType != Class'DamTypeLinkShaft' && injured != None
		&& Vehicle(injured) != None && !Vehicle(injured).IsVehicleEmpty() && instigatedBy != None
		&& instigatedBy != injured && CurDamage > 0 && instigatedBy.Controller != none
		&& instigatedBy.Controller.PlayerReplicationInfo != none
		&& UTComp_ONSPlayerReplicationInfo(instigatedBy.Controller.PlayerReplicationInfo) != none)
	{
		if (OPGRI == none && PlayerController(instigatedBy.Controller) != none && PlayerController(instigatedBy.Controller).GameReplicationInfo != none)
			OPGRI = PlayerController(instigatedBy.Controller).GameReplicationInfo;

		if (OPGRI != none)
		{
            ptsDamage = Min(curDamage, Vehicle(Injured).Health);
			if (Vehicle(injured).Team != instigatedBy.Controller.PlayerReplicationInfo.TeamID)
            {
				UTComp_ONSPlayerReplicationInfo(instigatedBy.Controller.PlayerReplicationInfo).AddVehicleDamageBonus(float(ptsDamage) / float(MutatorOwner.RepInfo.VehicleDamagePoints));
            }
			else
            {
				UTComp_ONSPlayerReplicationInfo(instigatedBy.Controller.PlayerReplicationInfo).AddVehicleDamageBonus(-1.0 * float(ptsDamage) / float(MutatorOwner.RepInfo.VehicleDamagePoints));
            }
		}
	}
    
	return CurDamage;
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

/*
function GetServerDetails(out GameInfo.ServerResponseLine ServerState)
{
}
*/

defaultproperties
{
    // DamageScoreQuota=100.0
    IsolateBonusPctPerNode=20.0
    
    bDebugRules=False
}