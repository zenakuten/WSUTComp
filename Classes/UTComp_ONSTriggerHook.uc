Class UTComp_ONSTriggerHook extends Actor;

// This class is used to hook two types of events, nodes getting isolated and vehiclefactories spawning vehicles (it works quite well too)
//var ONSPlusScoreRules Master;
var UTComp_ONSGameRules Master;
//var ONSPlusGameReplicationInfo GRIMaster;
var GameReplicationInfo GRIMaster;

var array<ONSVehicleFactory> HookedFactoryList;

function Trigger(Actor Other, Pawn EventInstigator)
{
	local int i, FactoryListNum;

	if (Master != none)
	{
		// Moved this part of if statement here to prevent possible bugs
		if (ONSPowerNode(Other) != none)
			Master.PowerNodeDestroyed(ONSPowerNode(Other));
	}
	else if (ONSVehicleFactory(Other) != none && ONSVehicle(EventInstigator) != none)
	{
		// When this actor is initially spawned the GameInfo will not have spawned the GameReplicationInfo yet, so see if GRIMaster can be set yet
		//if (GRIMaster == none && Level.GRI != none && ONSPlusGameReplicationInfo(Level.GRI) != none)
		if (GRIMaster == none && Level.GRI != none)
			GRIMaster = Level.GRI;

		// We have received a spawn notification from a vehicle factory, pass the radar information for this vehicle on to players on the relevant team
		if (GRIMaster != none)
			for (i=0; i<GRIMaster.PRIArray.Length; i++)
				if (UTComp_ONSPlayerReplicationInfo(GRIMaster.PRIArray[i]) != none && UTComp_ONSPlayerReplicationInfo(GRIMaster.PRIArray[i]).Team != none
					&& UTComp_ONSPlayerReplicationInfo(GRIMaster.PRIArray[i]).Team.TeamIndex == ONSVehicleFactory(Other).TeamNum)
					UTComp_ONSPlayerReplicationInfo(GRIMaster.PRIArray[i]).UpdateFactoryList(ONSVehicleFactory(Other));

		// Update our own list (we keep a list here for new players, the PRI will maintain the ENTIRE list for that player)
		FactoryListNum = HookedFactoryList.Length;

		// Check if the current factory is already in list
		for (i=0; i<HookedFactoryList.Length; i++)
		{
			if (HookedFactoryList[i] == Other)
			{
				FactoryListNum = i;
				break;
			}
		}

		// The actual update
		HookedFactoryList[FactoryListNum] = ONSVehicleFactory(Other);
	}
}

// Initialise this objects vehicle spawn list for a certain player
//function InitialiseVehicleSpawnList(ONSPlusPlayerReplicationInfo NewPlayer)
function InitialiseVehicleSpawnList(UTComp_ONSPlayerReplicationInfo NewPlayer)
{
	local int i;

	for (i=0; i<HookedFactoryList.Length; i++)
    {
		if (NewPlayer.Team != none && HookedFactoryList[i].TeamNum == NewPlayer.Team.TeamIndex)
			NewPlayer.UpdateFactoryList(HookedFactoryList[i]);
    }
}

defaultproperties
{
	bHidden=True
}