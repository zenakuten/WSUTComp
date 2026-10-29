

class UTComp_ServerReplicationInfo extends ReplicationInfo;

var bool bEnableVoting;
var byte EnableBrightSkinsMode;
var bool bEnableClanSkins;
var bool bEnableTeamOverlay;
var bool bEnablePowerupsOverlay;
var bool bEnableExtraHudClock;
var byte EnableHitSoundsMode;
var bool bEnableWarmup;
var bool bEnableWeaponStats;
var bool bEnablePowerupStats;
var bool benableDoubleDamage;
var bool bEnableTimedOvertimeVoting;


var bool bEnableBrightskinsVoting;
var bool bEnableHitsoundsVoting;
var bool bEnableWarmupVoting;
var bool bEnableTeamOverlayVoting;
var bool bEnablePowerupsOverlayVoting;
var bool bEnableMapVoting;
var bool bEnableGametypeVoting;
var bool bEnableDoubleDamageVoting;
var byte ServerMaxPlayers;
var byte MaxPlayersClone;
var bool bEnableAdvancedVotingOptions;

var string VotingNames[15];
var string VotingOptions[15];
var bool bEnableTimedOvertime;

//var PlayerReplicationInfo LinePRI[10];
// not used pooty 10/2023

var bool bEnableEnhancedNetCode;
var bool bEnableEnhancedNetCodeVoting;

var bool bShieldFix;
var bool bAllowRestartVoteEvenIfMapVotingIsTurnedOff;

var int MaxMultiDodges;
var int MinNetSpeed;
var int MaxNetSpeed;

var int NewNetUpdateFrequency;
var float PingTweenTime;

var int NodeIsolateBonusPct;
var int VehicleHealScore;
var int VehicleDamagePoints;
var int PowerNodeScore;
var int PowerCoreScore;
var int NodeHealBonusPct;
var bool bNodeHealBonusForLockedNodes;
var bool bNodeHealBonusForConstructor;
var bool bSilentAdmin;
var bool bEnableWhitelist;
var bool bUseWhitelist;
var string WhitelistBanMessage;
var bool bUseDefaultScoreboardColor;
var bool bDebugLogging;

var bool bAllowColorWeapons;
var bool bDamageIndicator;

var bool bEnableEmoticons;
var bool bKeepMomentumOnLanding;

var int MaxSavedMoves;
var float NetMoveDelta;
var float MaxResponseTime;
var bool bMoveErrorAccumFix;
var float MoveErrorAccumFixValue;
var float SlopeClearance; // see UTComp_xPawn.ApplySlopeClearance, 0 = off
var bool bVehicleFullPrecisionAim; // server only, not replicated
var byte VehicleUpdateMode; // vehicle seat move rate: 0 stock, 1 NetMoveDelta rate but stock while firing, 2 NetMoveDelta rate
var byte SpectatorUpdateRate; // sends per second for a still spectator camera, 0 = stock

var bool bLimitTaunts;
var int TauntCount;

var bool bAllowTeamRadar;
var bool bAllowTeamRadarMap;
var float TeamRadarCullDistance;

var bool bDisableCameraShake;
var bool bAllowTerrainDodge;

var bool bSpectatorVoiceChat;

replication
{
    reliable if(Role==Role_Authority)
        bEnableVoting, EnableBrightSkinsMode, EnableHitSoundsMode,
        bEnableClanSkins, bEnableTeamOverlay, bEnablePowerupsOverlay,
        bEnableWarmup, bEnableBrightskinsVoting,
        bEnableHitsoundsVoting, bEnableTeamOverlayVoting, bEnablePowerupsOverlayVoting,
        bEnableMapVoting, bEnableGametypeVoting, VotingNames,
        benableDoubleDamage, ServerMaxPlayers, bEnableTimedOvertime,
        MaxPlayersClone, bEnableAdvancedVotingOptions, VotingOptions,  bEnableTimedOvertimeVoting, // LinePRI,
        bEnableEnhancedNetCodeVoting,bEnableEnhancedNetCode, bEnableWarmupVoting,NewNetUpdateFrequency,PingTweenTime,
        bAllowRestartVoteEvenIfMapVotingIsTurnedOff, MaxMultiDodges, MinNetSpeed, MaxNetSpeed,
        NodeIsolateBonusPct, VehicleHealScore, VehicleDamagePoints, PowerNodeScore, PowerCoreScore, NodeHealBonusPct, 
        bNodeHealBonusForLockedNodes, bNodeHealBonusForConstructor, bSilentAdmin, bUseDefaultScoreboardColor, 
        bEnableWhitelist, bUseWhitelist, WhitelistBanMessage, bDebugLogging,
        bAllowColorWeapons, bDamageIndicator, MaxSavedMoves, bEnableEmoticons, bKeepMomentumOnLanding, NetMoveDelta, VehicleUpdateMode, SpectatorUpdateRate,
        MaxResponseTime, bMoveErrorAccumFix, MoveErrorAccumFixValue, SlopeClearance, bLimitTaunts, TauntCount,
        bAllowTeamRadar, bAllowTeamRadarMap, TeamRadarCullDistance,
		bDisableCameraShake, bAllowTerrainDodge, bSpectatorVoiceChat;
}

// These properties don't fit in one bunch, so the engine sends the rest in later updates and the
// client's BS_xPlayer.InitializeClient() can run before they arrive. Re-apply whenever they do.
simulated event PostNetReceive()
{
    local BS_xPlayer PC;

    PC = BS_xPlayer(Level.GetLocalPlayerController());
    if (PC != None && PC.bClientInitialized)
        PC.ApplyServerSettings();
}

defaultproperties
{
     bNetNotify=True
     bEnableVoting=False
     EnableBrightSkinsMode=3
     bEnableClanSkins=True
     bEnableTeamOverlay=True
     bEnablePowerupsOverlay=True
     EnableHitSoundsMode=1
     bEnableWarmup=True
     bEnableWeaponStats=True
     bEnablePowerupStats=True
     bEnableBrightskinsVoting=True
     bEnableHitsoundsVoting=False
     bEnableWarmupVoting=True
     bEnableTeamOverlayVoting=True
     bEnablePowerupsOverlayVoting=True
     bEnableMapVoting=True
     bEnableGametypeVoting=True
     bEnableDoubleDamageVoting=True
     ServerMaxPlayers=10
     bEnableTimedOvertimeVoting=True
     bEnableTimedOvertime=False
     NewNetUpdateFrequency=1
     PingTweenTime=3.0

     NodeIsolateBonusPct=20
     VehicleHealScore=500
     VehicleDamagePoints=200
     PowerNodeScore=10
     PowerCoreScore=5
     NodeHealBonusPct=60
     bNodeHealBonusForConstructor=false
     bSilentAdmin=true
     bEnableWhitelist=false
     bUseWhitelist=false
     WhitelistBanMessage="Not allowed.  Contact the server adminstrator to gain access."
     bUseDefaultScoreboardColor=false
     bDebugLogging = false

     bAllowColorWeapons=true
     bDamageIndicator=true

     bEnableEmoticons=true
     bKeepMomentumOnLanding=true
     MaxSavedMoves=750
     NetMoveDelta=0.011
     MaxResponseTime=0.125000
     bMoveErrorAccumFix=false
     MoveErrorAccumFixValue=0.009
     SlopeClearance=0.1
     bVehicleFullPrecisionAim=true
     VehicleUpdateMode=0
     SpectatorUpdateRate=0

     bLimitTaunts=false
     TauntCount=10
     bAllowTeamRadar=false
     bAllowTeamRadarMap=false
     TeamRadarCullDistance=10000.0
	 
	 bDisableCameraShake=false
	 bAllowTerrainDodge=false
}
