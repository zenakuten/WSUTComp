

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

var bool bLimitTaunts;
var int TauntCount;

var bool bAllowTeamRadar;
var bool bAllowTeamRadarMap;

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
        bAllowColorWeapons, bDamageIndicator, MaxSavedMoves, bEnableEmoticons, bKeepMomentumOnLanding, NetMoveDelta, 
        MaxResponseTime, bMoveErrorAccumFix, MoveErrorAccumFixValue, bLimitTaunts, TauntCount,
        bAllowTeamRadar, bAllowTeamRadarMap;
}

defaultproperties
{
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
     NewNetUpdateFrequency=200
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
     MaxSavedMoves=250
     NetMoveDelta=0.011
     MaxResponseTime=0.125000
     bMoveErrorAccumFix=false
     MoveErrorAccumFixValue=0.009

     bLimitTaunts=false
     TauntCount=10
     bAllowTeamRadar=false
     bAllowTeamRadarMap=true
}

