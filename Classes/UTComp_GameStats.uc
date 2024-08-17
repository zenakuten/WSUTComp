// Capture existing GameStats class and proxy through to it
// for score event, do some special processing

class UTComp_GameStats extends GameStats;

var MutUTComp MutOwner;
var GameStats OriginalGameStats;

event PreBeginPlay()
{
    local class<GameStats> GameStatsClass;
    super.PreBeginPlay();

    foreach DynamicActors(class'MutUTComp', MutOwner)
        break;

    if(MutOwner == None)
        log("ERROR!  UTComp_GameStats cannot find mut owner");

    GameStatsClass = class<GameStats>(DynamicLoadObject(MutOwner.OriginalStatsClass, class'Class'));
    if(GameStatsClass != None)
    {
        OriginalGameStats = spawn(GameStatsClass);
        if(OriginalGameStats == None)
            log("Error!  UTComp_GameStats cannot spawn original stats");
        else
            log("UTCompStats: successfully spawned proxy class "$MutOwner.OriginalStatsClass);
    }
    else
        log("ERROR!  UTComp_GameStats cannot dynamic load original stats class");
}

function Init()
{
    if(OriginalGameStats != None)
        OriginalGameStats.Init();
}

function Shutdown()
{
    if(OriginalGameStats != None)
        OriginalGameStats.Shutdown();
}

function Logf(string LogString)
{
    if(OriginalGameStats != None)
        OriginalGameStats.Logf(LogString);
}

function NewGame()
{
    if(OriginalGameStats != None)
        OriginalGameStats.NewGame();
}

function ServerInfo()
{
    if(OriginalGameStats != None)
        OriginalGameStats.ServerInfo();
}

function StartGame()
{
    if(OriginalGameStats != None)
        OriginalGameStats.StartGame();
}

function EndGame(string Reason)
{
    if(OriginalGameStats != None)
        OriginalGameStats.EndGame(Reason);
}

function ConnectEvent(PlayerReplicationInfo Who)
{
    if(OriginalGameStats != None)
        OriginalGameStats.ConnectEvent(Who);
}

function DisconnectEvent(PlayerReplicationInfo Who)
{
    if(OriginalGameStats != None)
        OriginalGameStats.DisconnectEvent(Who);
}

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
    }

    if(OriginalGameStats != None)
        OriginalGameStats.ScoreEvent(Who,Points,Desc);
}

function TeamScoreEvent(int Team, float Points, string Desc)
{
    if(OriginalGameStats != None)
        OriginalGameStats.TeamScoreEvent(Team, Points, Desc);
}

function KillEvent(string Killtype, PlayerReplicationInfo Killer, PlayerReplicationInfo Victim, class<DamageType> Damage)
{
    if(OriginalGameStats != None)
        OriginalGameStats.KillEvent(Killtype, Killer, Victim, Damage);
}

function SpecialEvent(PlayerReplicationInfo Who, string Desc)
{
    if(OriginalGameStats != None)
        OriginalGameStats.SpecialEvent(Who, Desc);
}

function GameEvent(string GEvent, string Desc, PlayerReplicationInfo Who)
{
    if(OriginalGameStats != None)
        OriginalGameStats.GameEvent(GEvent, Desc, Who);
}

defaultproperties
{
}