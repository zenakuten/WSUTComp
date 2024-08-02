class UTComp_GameStats extends MasterServerGameStats;

function ScoreEvent(PlayerReplicationInfo Who, float Points, string Desc)
{
    local UTComp_ONSPlayerReplicationInfo ONSPRI;
    if(ONSOnslaughtGame(Level.Game) != None)
    {
        ONSPRI = UTComp_ONSPlayerReplicationInfo(Who);
        if(ONSPRI != None)
        {
            switch(Desc)
            {
                case "red_powercore_destroyed":
                case "blue_powercore_destroyed":
                    ONSPRI.CoresDestroyed += 1;
                    break;
                case "red_powernode_destroyed":
                case "blue_powernode_destroyed":
                    ONSPRI.NodesDestroyed += 1;
                    break;
                case "red_constructing_powernode_destroyed":
                case "blue_constructing_powernode_destroyed":
                    ONSPRI.NodesDestroyedConstructing += 1;
                    break;
                case "red_powernode_constructed":
                case "blue_powernode_constructed":
                    ONSPRI.NodesConstructed += 1;
                    break;
            }
        }
        /*
        log("ScoreEvent:"$Who.PlayerName$" event: "$Desc);
        if(Who != None && PlayerController(Who.Owner) != None)
            PlayerController(Who.Owner).ClientMessage(desc);
        */
    }
    super.ScoreEvent(Who,Points,Desc);
}

defaultproperties
{
}