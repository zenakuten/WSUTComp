class MutUTComp extends Mutator
    config(WSUTComp_Server)
    PerObjectConfig;

// #exec OBJ LOAD FILE="Textures\minimegatex.utx" PACKAGE=WSUTComp
#exec OBJ LOAD FILE="Textures\minimegatex.utx"
#exec OBJ LOAD FILE="Textures\TeamColorTex.utx" PACKAGE=WSUTComp

var config bool bEnableVoting;
var config bool bEnableBrightskinsVoting;
var config bool bEnableHitsoundsVoting;
var config bool bEnableWarmupVoting;
var config bool bEnableTeamOverlayVoting;
var config bool bEnablePowerupsOverlayVoting;
var config bool bEnableMapVoting;
var config bool bEnableGametypeVoting;
var config bool bEnableTimedOvertimeVoting;
var config float VotingPercentRequired;
var config float VotingTimeLimit;

var config bool bEnableDoubleDamage;
var config byte EnableBrightSkinsMode;
var config bool bEnableClanSkins;
var config bool bEnableTeamOverlay;
var config bool bEnablePowerupsOverlay;
var config byte EnableHitSoundsMode;
var config bool bEnableWarmup;
var config float WarmupReadyPercentRequired;
var config bool bShowSpawnsDuringWarmup;
var config bool bEnableWeaponStats;
var config bool bEnablePowerupStats;
var config bool bShowTeamScoresInServerBrowser;

var config byte ServerMaxPlayers;
var config bool bEnableAdvancedVotingOptions;
var config array<string> AlwaysUseThisMutator;

var config bool bEnableAutoDemoRec;
var config string AutoDemoRecMask;
var config byte EnableWarmupWeaponsMode;
var config int WarmupTime;
var config int WarmupHealth;

var config bool bForceMapVoteMatchPrefix;
var config bool bEnableTimedOvertime;
var config int TimedOverTimeLength;
var config int NumGrenadesOnSpawn;

var config bool bShieldFix;
var config bool  bAllowRestartVoteEvenIfMapVotingIsTurnedOff;

var config int MaxMultiDodges;

var config int MinNetSpeed;
var config int MaxNetSpeed;

// CTF-related
var config int CapBonus, FlagKillBonus, CoverBonus, SealBonus, GrabBonus, MinimalCapBonus;
var config float BaseReturnBonus, MidReturnBonus, EnemyBaseReturnBonus, CloseSaveReturnBonus;

var config byte CoverMsgType;
var config byte CoverSpreeMsgType;
var config byte SealMsgType;
var config byte SavedMsgType;

var config bool bShowSealRewardConsoleMsg;
var config bool bShowAssistConsoleMsg;

var config int SuicideInterval;

var config int NodeIsolateBonusPct;
var config int VehicleHealScore;
var config int VehicleDamagePoints;
var config bool bDebugLogging;  // config flag to turn on debug logging and/or client messages
var config int PowerCoreScore;
var config int PowerNodeScore;
var config int NodeHealBonusPct;
var config bool bNodeHealBonusForLockedNodes;
var config bool bNodeHealBonusForConstructor;

var config int NewNetUpdateFrequency;
var config float PingTweenTime;
var config bool bSilentAdmin;
var config bool bEnableWhitelist;
var config bool bUseWhitelist;
var config string WhitelistBanMessage;
var config bool bAllowColorWeapons;
var config bool bDamageIndicator;
var config bool bEnableEmoticons;
var config bool bFastWeaponSwitch;
var config bool bKeepMomentumOnLanding;

// warping fix stuff
var config int MaxSavedMoves;
var config float NetMoveDelta;
var config float MaxResponseTime;
var config bool bMoveErrorAccumFix;
var config float MoveErrorAccumFixValue;

var config bool bLimitTaunts;
var config int TauntCount;

struct MapVotePair
{
    var string GametypeOptions;
    var string GametypeName;
};

var config array<MapVotePair> VotingGametype;

var config bool bEnableEnhancedNetCode;
var config bool bEnableEnhancedNetCodeVoting;
var config bool bUseDefaultScoreboardColor;
var config float PawnCollisionHistoryLength;
var config array<string> IgnoredHitSounds;

var config bool bNoTeamBoosting;
var config bool bNoTeamBoostingVehicles;

var config bool bChargedWeaponsNoSpawnProtection;
var config bool bUseUTCompStats;

var bool bEnableScoreboard;  
var bool bDemoStarted;
var bool bEnableDoubleDamageVoting;
var bool bWarmupDisabled;

var Emoticons EmoteActor;

var UTComp_ServerReplicationInfo RepInfo;
var UTComp_OverlayUpdate OverlayClass;
var UTComp_VotingHandler VotingClass;
var UTComp_Warmup WarmupInfo;
var class<UTComp_Warmup> WarmupClass;
var bool bHasInteraction;

var string origcontroller;
var class<PlayerController> origcclass;

var float StampArray[256];
var float counter;
var controller countercontroller;

var string FriendlyVersionPrefix;
var string FriendlyVersionName;
var string FriendlyVersionNumber;

struct PowerupInfoStruct
{
    var xPickupBase PickupBase;
    var int Team;
    var float NextRespawnTime;
    var PlayerReplicationInfo LastTaker;
};

var PowerupInfoStruct PowerupInfo[8];

//==========================
//  Begin Enhanced Netcode stuff
//==========================
var PawnCollisionCopy PCC;

var TimeStamp StampInfo;

var float AverDT;
var float ClientTimeStamp;

var array<float> DeltaHistory;
var bool bEnhancedNetCodeEnabledAtStartOfMap;

var FakeProjectileManager FPM;

const AVERDT_SEND_PERIOD = 4.00;
var float LastReplicatedAverDT;

// newnet 
var class<weapon> WeaponClasses[13];
var string WeaponClassNames[13];

//utcomp
var class<weapon> WeaponClassesUTComp[13];
var string WeaponClassNamesUTComp[13];

var class<Weapon> ReplacedWeaponClasses[13];

var class<WeaponPickup> ReplacedWeaponPickupClasses[13];

//newnet
var class<WeaponPickup> WeaponPickupClasses[13];
var string WeaponPickupClassNames[13];

//utcomp
var class<WeaponPickup> WeaponPickupClassesUTComp[13];
var string WeaponPickupClassNamesUTComp[13];

var bool bDefaultWeaponsChanged;
//==========================
//  End Enhanced Netcode stuff
//==========================

var UTComp_ONSGameRules ONSGameRules;
var UTComp_Whitelist Whitelist;

var string OriginalStatsClass;

function PreBeginPlay()
{
    bEnhancedNetCodeEnabledAtStartOfMap = bEnableEnhancedNetCode;
    log("MutUTComp Debug="$bDebugLogging);
    if (bDebugLogging) log("Starting PreBeginPlay...",'MutUTComp');
    
    ReplacePawnAndPC();
    SetupVoting();
    SetupColoredDeathMessages();
    StaticSaveConfig();
    SetupFlags();
    SetupPowerupInfo();
    SetupWhitelist();
    SetupEmoticons();
    SetupInstagib();
    InitStatsOverride();

    super.PreBeginPlay();
    if (bDebugLogging) log("Finished PreBeginPlay...",'MutUTComp');
}

function SetupInstagib()
{
    local MutInstagib instagib;

    foreach DynamicActors(class'MutInstagib', instagib)
        break;

    if(instagib == None)
        return;

    if(bEnableEnhancedNetCode)
    {
        instagib.default.WeaponName='NewNet_SuperShockRifle';
        instagib.default.WeaponString="WSUTComp.NewNet_SuperShockRifle";
        instagib.default.DefaultWeaponName="WSUTComp.NewNet_SuperShockRifle";
        instagib.WeaponName='NewNet_SuperShockRifle';
        instagib.WeaponString="WSUTComp.NewNet_SuperShockRifle";
        instagib.DefaultWeaponName="WSUTComp.NewNet_SuperShockRifle";
    }
    else
    {
        instagib.default.WeaponName='UTComp_SuperShockRifle';
        instagib.default.WeaponString="WSUTComp.UTComp_SuperShockRifle";
        instagib.default.DefaultWeaponName="WSUTComp.UTComp_SuperShockRifle";
        instagib.WeaponName='UTComp_SuperShockRifle';
        instagib.WeaponString="WSUTComp.UTComp_SuperShockRifle";
        instagib.DefaultWeaponName="WSUTComp.UTComp_SuperShockRifle";
    }
}

function SetupEmoticons()
{
    if(bEnableEmoticons)
    {
        log("spawning emote actor");
        EmoteActor = spawn(class'Emoticons', self);
    }
}

function SetupPowerupInfo()
{
    local xPickupBase pickupBase;
    local int i;
    local byte shieldPickupCount;
    local byte uDamagePickupCount;
    local byte kegPickupCount;
    local bool forceTeam; // Force finding a team if there's 2 powerups of the same type.

    foreach AllActors(class'xPickupBase', pickupBase)
    {

        if (pickupBase.PowerUp == class'XPickups.SuperShieldPack' || pickupBase.PowerUp == class'XPickups.SuperHealthPack' || pickupBase.PowerUp == class'XPickups.UDamagePack')
        {
            PowerupInfo[i].PickupBase = pickupBase;

            if (pickupBase.myPickUp != None)
                PowerupInfo[i].NextRespawnTime = pickupBase.myPickUp.GetRespawnTime() + pickupBase.myPickup.RespawnEffectTime + Level.GRI.ElapsedTime;

            if (pickupBase.PowerUp == class'XPickups.SuperShieldPack')
                shieldPickupCount++;
            else if (pickupBase.PowerUp == class'XPickups.SuperHealthPack')
                kegPickupCount++;
            else if (pickupBase.PowerUp == class'XPickups.UDamagePack')
                uDamagePickupCount++;

            i++;

            if (i == 8)
            break;
        }
    }

    for (i = 0; i < 8; i++)
    {
        if (PowerupInfo[i].PickupBase == None)
            break;

        forceTeam = false;

        if (PowerupInfo[i].PickupBase.PowerUp == class'XPickups.SuperShieldPack' && shieldPickupCount == 2)
            forceTeam = true;
        else if (PowerupInfo[i].PickupBase.PowerUp == class'XPickups.SuperHealthPack' && kegPickupCount == 2)
            forceTeam = true;
        else if (PowerupInfo[i].PickUpBase.PowerUp == class'XPickups.UDamagePack' && uDamagePickupCount == 2)
            forceTeam = true;

        PowerupInfo[i].Team = GetTeamNum(PowerupInfo[i].PickupBase, forceTeam);
    }

}

function LogPickup(Pawn other, Pickup item)
{
    local int i;

    for (i = 0; i < 8; i++)
    {
        if (PowerupInfo[i].PickupBase == None)
            break;

        if (PowerupInfo[i].PickupBase.myPickup == item)
        {
            PowerupInfo[i].NextRespawnTime = item.GetRespawnTime() - item.RespawnEffectTime + Level.GRI.ElapsedTime;
            PowerupInfo[i].LastTaker = other.PlayerReplicationInfo;
        }
    }

    if (i > 0)
    {
        SortPowerupInfo(0, i - 1);
    }
}

function SortPowerupInfo(int low, int high)
{
  //  low is the lower index, high is the upper index
  //  of the region of array a that is to be sorted
  local Int i, j;
  local float x;
  Local PowerupInfoStruct Temp;

  i = Low;
  j = High;
  x = PowerupInfo[(Low + High) / 2].NextRespawnTime;

  //  partition
  do
  {
   while (PowerupInfo[i].NextRespawnTime < x)
      i += 1;
    while ((PowerupInfo[j].NextRespawnTime > x) && (x > 0))
     j -= 1;

    if (i <= j)
    {
     // swap array elements, inlined
     Temp = PowerupInfo[i];
      PowerupInfo[i] = PowerupInfo[j];
      PowerupInfo[j] = Temp;
      i += 1;
      j -= 1;
    }
  } until (i > j);

  //  recursion
  if (low < j)
    SortPowerupInfo(low, j);
  if (i < high)
    SortPowerupInfo(i, high);
}

function int GetTeamNum(Actor a, bool forceTeam)
{
    local string locationName;
    local Volume V;
    local Volume Best;
    local CTFBase FlagBase;
    local CTFBase RedFlagBase;
    local CTFBase BlueFlagBase;

    locationName = a.Region.Zone.LocationName;

    if (Instr(Caps(locationName), "RED" ) != -1)
        return 0;

    if (Instr(Caps(locationName), "BLUE" ) != -1)
        return 1;

    // For example the 100 in Citadel, we need to find in what volume it is.
    foreach AllActors( class'Volume', V )
    {
        if( V.LocationName == "" || V.LocationName == class'Volume'.default.LocationName)
            continue;

        if( (Best != None) && (V.LocationPriority <= Best.LocationPriority) )
            continue;

        if( V.Encompasses(a) )
            Best = V;
    }

    if (Best != None)
    {
        Log("BestName"@a@Best.LocationName);
        if (Instr(Caps(Best.LocationName), "RED" ) != -1)
            return 0;
        if (Instr(Caps(Best.LocationName), "BLUE" ) != -1)
            return 1;
    }

    if (forceTeam && Level.Game.IsA('xCTFGame'))
    {
        // Well we will look at the distance from the flag base...


        ForEach DynamicActors(class 'CTFBase', FlagBase)
        {
            if (FlagBase.DefenderTeamIndex == 0)
                RedFlagBase = flagBase;
            else
                BlueFlagBase = flagBase;
        }

        if (RedFlagBase != None && BlueFlagBase != None)
        {
            if (VSize(a.Location - RedFlagBase.Location) < VSize(a.Location - BlueFlagBase.Location))
                return 0;
            else
                return 1;
        }
    }

    return 255;
}

/* Change the flags the the UTComp one so we can track caps and assists. */
function SetupFlags()
{
    local CTFBase FlagBase;

    if (!Level.Game.IsA('xCTFGame'))
        return;

    ForEach DynamicActors(class 'CTFBase', FlagBase)
    {
        if (FlagBase.DefenderTeamIndex == 0)
            FlagBase.FlagType = class'UTComp_xRedFlag';
        else
            FlagBase.FlagType = class'UTComp_xBlueFlag';
    }
}

function SetupColoredDeathMessages()
{
    if(Level.Game.DeathMessageClass==class'xGame.xDeathMessage')
        Level.Game.DeathMessageClass=class'UTComp_xDeathMessage';
    else if(Level.Game.DeathMessageClass==Class'SkaarjPack.InvasionDeathMessage')
        Level.Game.DeathMessageClass=class'UTComp_InvasionDeathMessage';
}


function SetupWhitelist()
{
    if(Role == Role_Authority)
    {
        if (Whitelist == none) {
            Whitelist = new(none, "Whitelist") class'UTComp_Whitelist';
            Whitelist.StaticSaveConfig();
        }
    }
}

function ModifyPlayer(Pawn Other)
{
    local inventory inv;
    local int i;

    //Give all weps if its warmup
    if(WarmupInfo!=None && !Level.Game.IsA('UTComp_ClanArena')&& (WarmupInfo.bInWarmup==True || WarmupInfo.bGivePlayerWeaponHack ))
    {
        switch(EnableWarmupWeaponsMode)
        {
        case 0: break;

        case 3:
            Other.CreateInventory("Onslaught.ONSGrenadeLauncher");
            Other.CreateInventory("Onslaught.ONSAVRiL");
            Other.CreateInventory("Onslaught.ONSMineLayer");
        case 2:
            Other.CreateInventory("XWeapons.SniperRifle");
            Other.CreateInventory("XWeapons.RocketLauncher");
            Other.CreateInventory("XWeapons.FlakCannon");
            Other.CreateInventory("XWeapons.MiniGun");
            Other.CreateInventory("XWeapons.LinkGun");
            Other.CreateInventory("XWeapons.ShockRifle");
            Other.CreateInventory("XWeapons.BioRifle");
            Other.CreateInventory("XWeapons.AssaultRifle");
            Other.CreateInventory("XWeapons.ShieldGun");
            break;

        case 1:
            if(!WarmupInfo.bWeaponsChecked)
                WarmupInfo.FindWhatWeaponsToGive();
            for(i=0; i<WarmupInfo.sWeaponsToGive.Length; i++)
                Other.CreateInventory(WarmupInfo.sWeaponsToGive[i]);
        }

        for(Inv=Other.Inventory; Inv!=None; Inv=Inv.Inventory)
	        if(Weapon(Inv)!=None)
	        {
                Weapon(Inv).SuperMaxOutAmmo();
	            Weapon(Inv).Loaded();
	        }
	    if (WarmupHealth!=0)
            Other.Health=WarmupHealth;
        else
            Other.Health=199;
    }

    if(bEnhancedNetCodeEnabledAtStartOfMap)
    {
        SpawnCollisionCopy(Other);
        RemoveOldPawns();
    }

    if (UTComp_xPawn(Other) != none) {
        UTComp_xPawn(Other).MultiDodgesRemaining = RepInfo.MaxMultiDodges;
    }

    Super.ModifyPlayer(Other);

    if (ONSOnslaughtGame(Level.Game) != none && Other != none && Other.PlayerReplicationInfo != none && UTComp_ONSPlayerReplicationInfo(Other.PlayerReplicationInfo) != none)
	{
		if (UTComp_ONSPlayerReplicationInfo(Other.PlayerReplicationInfo).MutatorOwner == none)
			UTComp_ONSPlayerReplicationInfo(Other.PlayerReplicationInfo).MutatorOwner = self;

		if (!UTComp_ONSPlayerReplicationInfo(Other.PlayerReplicationInfo).bInitializedVSpawnList
			|| UTComp_ONSPlayerReplicationInfo(Other.PlayerReplicationInfo).LastInitialiseTeam != Other.GetTeamNum())
		{
            if(ONSGameRules != None)
            {
                ONSGameRules.InitialiseVehicleSpawnList(UTComp_ONSPlayerReplicationInfo(Other.PlayerReplicationInfo));
            }
			UTComp_ONSPlayerReplicationInfo(Other.PlayerReplicationInfo).bInitializedVSpawnList = True;
			UTComp_ONSPlayerReplicationInfo(Other.PlayerReplicationInfo).LastInitialiseTeam = Other.GetTeamNum();
		}
    }
}


/*
function DriverEnteredVehicle(Vehicle V, Pawn P)
{
	SpawnCollisionCopy(V);

    if( NextMutator != none )
		NextMutator.DriverEnteredVehicle(V, P);
}
*/

function DriverEnteredVehicle(Vehicle V, Pawn P)
{
    local PawnCollisionCopy C;
    if(RepInfo != none && RepInfo.bEnableEnhancedNetCode)
    {
        C = PCC;
        while(C != None)
        {
            if(C.CopiedPawn == P)
            {
                C.SetPawn(V);
                break;
            }
            C = C.Next;
        }
    }

    if( NextMutator != none )
		NextMutator.DriverEnteredVehicle(V, P);
}

function DriverLeftVehicle(Vehicle V, Pawn P)
{
    local PawnCollisionCopy C;

    if(RepInfo != None && RepInfo.bEnableEnhancedNetCode)
    {
        C = PCC;
        while(C != None)
        {
            if(C.CopiedPawn == V)
            {
                C.SetPawn(P);
                break;
            }
            C = C.Next;
        }
    }

    if( NextMutator != none )
		NextMutator.DriverLeftVehicle(V, P);
}

function SpawnCollisionCopy(Pawn Other)
{

    if(PCC==None)
    {
        PCC = Spawn(class'PawnCollisionCopy');
        PCC.SetPawn(Other);
    }
    else
        PCC.AddPawnToList(Other);

}

function RemoveOldPawns()
{
    PCC = PCC.RemoveOldPawns();
}

function ListPawns()
{
    local PawnCollisionCopy PCC2;
    for(PCC2=PCC; PCC2!=None; PCC2=PCC2.Next)
       PCC2.Identify();
}

static function bool IsPredicted(actor A)
{
   if(A == none || A.IsA('xPawn'))
       return true;
   //Fix up vehicle a bit, we still wanna predict if its in the list w/o a driver
   if((A.IsA('Vehicle') && Vehicle(A).Driver!=None))
       return true;
   return false;
}


function SetupTeamOverlay()
{
    if((!bEnableTeamOverlay && !bEnablePowerupsOverlay) || !Level.Game.bTeamGame)
        return;
    if (OverlayClass==None)
    {
        OverlayClass=Spawn(class'UTComp_OverlayUpdate', self);
        OverlayClass.UTCompMutator=self;
        OverlayClass.InitializeOverlay();
    }
}

function SetupWarmup()
{
    if(Level.Game.IsA('UTComp_ClanArena'))
    {
       if(!bEnableWarmup)
       {
           bEnableWarmup=true;
           WarmupTime = 30.0;
       }
    }
    else if(!bEnableWarmup || Level.Game.IsA('ASGameInfo') || Level.Game.IsA('Invasion') || Level.Title~="Bollwerk Ruins 2004 - Pro Edition")
    {
        bWarmupDisabled = true;
        return;
    }

    if(WarmupInfo==None)
        WarmupInfo=Spawn(WarmupClass, self);

    WarmupInfo.iWarmupTime=WarmupTime;

    WarmupInfo.fReadyPercent=WarmupReadyPercentRequired;
    WarmupInfo.InitializeWarmup();
}

function SetupVoting()
{
    if(!bEnableVoting)
        return;
    if(VotingClass==None)
    {
        VotingClass=Spawn(class'UTComp_VotingHandler', self);
        VotingClass.fVotingTime=VotingTimeLimit;
        VotingClass.fVotingPercent=VotingPercentRequired;
        VotingClass.InitializeVoting();
        VotingClass.UTCompMutator=Self;
    }
}

function SetupStats()
{
    Class'XWeapons.TransRecall'.Default.Transmaterials[0]=None;
    Class'XWeapons.TransRecall'.Default.Transmaterials[1]=None;

    if(!bEnableWeaponStats)
        return;
    if(bEnableEnhancedNetcode)
        class'XWeapons.ShieldFire'.default.AutoFireTestFreq=0.05;

    class'XWeapons.AssaultRifle'.default.FireModeClass[0] = Class'UTComp_AssaultFire';
    class'XWeapons.AssaultRifle'.default.FireModeClass[1] = Class'UTComp_AssaultGrenade';

    class'XWeapons.BioRifle'.default.FireModeClass[0] = Class'UTComp_BioFire';
    class'XWeapons.BioRifle'.default.FireModeClass[1] = Class'UTComp_BioChargedFire';

    class'XWeapons.ShockRifle'.default.FireModeClass[0] = Class'UTComp_ShockBeamFire';
    class'XWeapons.ShockRifle'.default.FireModeClass[1] = Class'UTComp_ShockProjFire';

    class'XWeapons.LinkGun'.default.FireModeClass[0] = Class'UTComp_LinkAltFire';
    class'XWeapons.LinkGun'.default.FireModeClass[1] = Class'UTComp_LinkFire';

    class'XWeapons.MiniGun'.default.FireModeClass[0] = Class'UTComp_MinigunFire';
    class'XWeapons.MiniGun'.default.FireModeClass[1] = Class'UTComp_MinigunAltFire';

    class'XWeapons.FlakCannon'.default.FireModeClass[0] = Class'UTComp_FlakFire';
    class'XWeapons.FlakCannon'.default.FireModeClass[1] = Class'UTComp_FlakAltFire';

    class'XWeapons.RocketLauncher'.default.FireModeClass[0] = Class'UTComp_RocketFire';
    class'XWeapons.RocketLauncher'.default.FireModeClass[1] = Class'UTComp_RocketMultiFire';

    class'XWeapons.SniperRifle'.default.FireModeClass[0]= Class'UTComp_SniperFire';
    class'UTClassic.ClassicSniperRifle'.default.FireModeClass[0]= Class'UTComp_ClassicSniperFire';

    class'Onslaught.ONSMineLayer'.default.FireModeClass[0] = Class'UTComp_ONSMineThrowFire';

    class'Onslaught.ONSGrenadeLauncher'.default.FireModeClass[0] =Class'UTComp_ONSGrenadeFire';

    class'OnsLaught.ONSAvril'.default.FireModeClass[0] =Class'UTComp_ONSAvrilFire';

    class'XWeapons.SuperShockRifle'.default.FireModeClass[0]=class'UTComp_SuperShockBeamFire';
    class'XWeapons.SuperShockRifle'.default.FireModeClass[1]=class'UTComp_SuperShockBeamFire';

 }


simulated function Tick(float DeltaTime)
{
    local PlayerController PC;
    local Mutator M;
    local int x;

    //if(Level.NetMode==NM_DedicatedServer)
    if(Level.NetMode==NM_DedicatedServer || Level.NetMode == NM_ListenServer)
    {
        if(bEnhancedNetCodeEnabledAtStartOfMap)
        {
            if (bDefaultWeaponsChanged == false) {
                bDefaultWeaponsChanged = true;
                // replace DefaultWeaponName (fix for simple Arena mutators)
                for(M = Level.Game.BaseMutator; M != None; M = M.NextMutator)
                    if (M.DefaultWeaponName != "")
                        for (x = 0; x < ArrayCount(ReplacedWeaponClasses); x++)
                            if (M.DefaultWeaponName ~= WeaponClassNames[x])
                                M.DefaultWeaponName = string(WeaponClasses[x]);
            }

            ClientTimeStamp+=DeltaTime;
            counter+=1;
            StampArray[counter%256] = ClientTimeStamp;
            AverDT = (9.0*AverDT + DeltaTime) * 0.1;
            SetPawnStamp();
            if(ClientTimeStamp > LastReplicatedAverDT + AVERDT_SEND_PERIOD)
            {
                StampInfo.ReplicatedAverDT(AverDT);
                LastReplicatedAverDT = ClientTimeStamp;
            }
        }
        else
        {
            if (bDefaultWeaponsChanged == false) {
                bDefaultWeaponsChanged = true;
                // replace DefaultWeaponName (fix for simple Arena mutators)
                for(M = Level.Game.BaseMutator; M != None; M = M.NextMutator)
                    if (M.DefaultWeaponName != "")
                        for (x = 0; x < ArrayCount(ReplacedWeaponClasses); x++)
                            if (M.DefaultWeaponName ~= WeaponClassNames[x])
                                M.DefaultWeaponName = string(WeaponClassesUTComp[x]);
            }
        }

        if (!bEnableAutoDemoRec || bDemoStarted || (default.bEnableWarmup && !bWarmupDisabled) || Level.Game.bWaitingToStartMatch)
            return;
        else
           AutoDemoRecord();
        return;
    }

    if( FPM==None && Level.NetMode == NM_Client)
        FPM = Spawn(Class'FakeProjectileManager');

    if(bHasInteraction)
        return;
    PC=Level.GetLocalPlayerController();

    if(PC!=None && BS_xPlayer(PC) != None)
    {
        BS_xPlayer(PC).Overlay = UTComp_Overlay(PC.Player.InteractionMaster.AddInteraction(string(class'UTComp_Overlay'), PC.Player));
        bHasInteraction=True;
        class'DamTypeLinkShaft'.default.bSkeletize=false;
    }
}

function SetPawnStamp()
{
    local rotator R;
    local int i;
    local Pawn P;

    if(countercontroller==none)
        countercontroller = spawn(class'TimeStamp_Controller');

    if(countercontroller != none && countercontroller.Pawn == none)
    {
        P = spawn(countercontroller.PawnClass);
        countercontroller.Possess(P);
    }

    R.Yaw = (counter%256)*256;
    i=counter/256;
    R.Pitch = i*256;

    if(countercontroller.Pawn != None)
        countercontroller.Pawn.SetRotation(R);
}

simulated function float GetStamp(int stamp)
{
   return StampArray[stamp%256];
}

function ReplacePawnAndPC()
{
    if(Level.Game.DefaultPlayerClassName~="xGame.xPawn")
        Level.Game.DefaultPlayerClassName=string(class'UTComp_xPawn');
    if(class'xPawn'.default.ControllerClass==class'XGame.XBot') //bots don't skin otherwise
        class'xPawn'.default.ControllerClass=class'UTComp_xBot';

    Level.Game.PlayerControllerClassName=string(class'BS_xPlayer');
}

function SpawnReplicationClass()
{
    local int i;
    if(RepInfo==None)
        RepInfo=Spawn(class'UTComp_ServerReplicationInfo', self);

    RepInfo.bEnableVoting=bEnableVoting;
    RepInfo.EnableBrightSkinsMode=Clamp(EnableBrightSkinsMode,1,3);
    RepInfo.bEnableClanSkins=bEnableClanSkins;
    RepInfo.bEnableTeamOverlay=bEnableTeamOverlay;
    RepInfo.bEnablePowerupsOverlay=bEnablePowerupsOverlay;
    RepInfo.EnableHitSoundsMode=EnableHitSoundsMode;
    RepInfo.bEnableScoreboard=bEnableScoreboard;
    RepInfo.bEnableWarmup=bEnableWarmup;
    RepInfo.bEnableWeaponStats=bEnableWeaponStats;
    RepInfo.bEnablePowerupStats=bEnablePowerupStats;
    RepInfo.bEnableBrightskinsVoting=bEnableBrightskinsVoting;
    RepInfo.bEnableHitsoundsVoting=bEnableHitsoundsVoting;
    RepInfo.bEnableWarmupVoting=bEnableWarmupVoting;
    RepInfo.bEnableTeamOverlayVoting=bEnableTeamOverlayVoting;
    RepInfo.bEnablePowerupsOverlayVoting=bEnablePowerupsOverlayVoting;
    RepInfo.bEnableMapVoting=bEnableMapVoting;
    RepInfo.bEnableGametypeVoting=bEnableGametypeVoting;
    RepInfo.ServerMaxPlayers=ServerMaxPlayers;
    RepInfo.bEnableDoubleDamage=bEnableDoubleDamage;
    RepInfo.bEnableDoubleDamageVoting=bEnableDoubleDamageVoting;
    RepInfo.MaxPlayersClone=Level.Game.MaxPlayers;
    RepInfo.bEnableAdvancedVotingOptions=bEnableAdvancedVotingOptions;
    RepInfo.bEnableTimedOvertimeVoting=bEnableTimedOvertimeVoting;
    RepInfo.bEnableTimedOvertime=bEnableTimedOvertime;
    RepInfo.bEnableEnhancedNetcode=bEnableEnhancedNetcode;
    RepInfo.bEnableEnhancedNetcodeVoting=bEnableEnhancedNetcodeVoting;
    RepInfo.MaxMultiDodges = MaxMultiDodges;
    RepInfo.MinNetSpeed = MinNetSpeed;
    RepInfo.MaxNetSpeed = MaxNetSpeed;
    RepInfo.bShieldFix=bShieldFix;
    RepInfo.bAllowRestartVoteEvenIfMapVotingIsTurnedOff = bAllowRestartVoteEvenIfMapVotingIsTurnedOff;

    RepInfo.NewNetUpdateFrequency = NewNetUpdateFrequency;
    RepInfo.PingTweenTime = PingTweenTime;
    RepInfo.NodeIsolateBonusPct=NodeIsolateBonusPct;
    RepInfo.VehicleHealScore=VehicleHealScore;
    RepInfo.VehicleDamagePoints=VehicleDamagePoints;
    RepInfo.PowerCoreScore=PowerCoreScore;
    RepInfo.PowerNodeScore=PowerNodeScore;
    RepInfo.NodeHealBonusPct=NodeHealBonusPct;
    RepInfo.bNodeHealBonusForLockedNodes = bNodeHealBonusForLockedNodes;
    RepInfo.bNodeHealBonusForConstructor = bNodeHealBonusForConstructor;
    RepInfo.bSilentAdmin=bSilentAdmin;
    RepInfo.bEnableWhitelist=bEnableWhitelist;
    RepInfo.bUseWhitelist=bUseWhitelist;
    RepInfo.WhitelistBanMessage=WhitelistBanMessage;
    RepInfo.bUseDefaultScoreboardColor = bUseDefaultScoreboardColor;
    RepInfo.bDebugLogging = bDebugLogging;
    RepInfo.bAllowColorWeapons = bAllowColorWeapons;
    RepInfo.bDamageIndicator = bDamageIndicator;
    RepInfo.bEnableEmoticons = bEnableEmoticons;
    RepInfo.bKeepMomentumOnLanding = bKeepMomentumOnLanding;

    RepInfo.MaxSavedMoves = MaxSavedMoves;
    RepInfo.NetMoveDelta = NetMoveDelta;
    RepInfo.MaxResponseTime = MaxResponseTime;
    RepInfo.bMoveErrorAccumFix = bMoveErrorAccumFix;
    RepInfo.MoveErrorAccumFixValue = MoveErrorAccumFixValue;

    RepInfo.bLimitTaunts = bLimitTaunts;
    RepInfo.TauntCount = TauntCount;

    for(i=0; i<VotingGametype.Length && i<ArrayCount(RepInfo.VotingNames); i++)
        RepInfo.VotingNames[i]=VotingGametype[i].GameTypeName;

    for(i=0; i<VotingGametype.Length && i<ArrayCount(RepInfo.VotingOptions); i++)
        RepInfo.VotingOptions[i]=VotingGametype[i].GameTypeOptions;

    if(Level.Game.IsA('CTFGame') || Level.Game.IsA('ONSOnslaughtGame') || Level.Game.IsA('ASGameInfo') || Level.Game.IsA('xBombingRun')
    || Level.Game.IsA('xMutantGame') || Level.Game.IsA('xLastManStandingGame') || Level.Game.IsA('xDoubleDom') || Level.Game.IsA('Invasion'))
    {
       bEnableTimedOvertime=False;
    }

    RepInfo.NetUpdateTime=Level.TimeSeconds-1;
}

function PostBeginPlay()
{
	local UTComp_GameRules G;
	local mutator M;
	local string URL;

  if (bDebugLogging) log("Starting PostBeginPlay...",'MutUTComp');
	Super.PostBeginPlay();

	URL = Level.GetLocalURL();
	URL = Mid(URL, InStr(URL, "?"));
	ParseURL(URl);
    SetupTeamOverlay();
    SetupWarmup();
    SpawnReplicationClass();

    G = spawn(class'UTComp_GameRules');
    G.UTCompMutator=self;
	G.OVERTIMETIME=TimedOverTimeLength;

    Level.Game.AddGameModifier(G);

    if(ONSOnslaughtGame(Level.Game) != none)
    {
        ONSGameRules = Spawn(Class'UTComp_ONSGameRules', self);
        ONSGameRules.OPInitialise();
        Level.Game.AddGameModifier(ONSGameRules);

		ONSOnslaughtGame(Level.Game).GameUMenuType = string(Class'UTComp_ONSLoginMenu');

    }

    if(StampInfo == none && bEnhancedNetCodeEnabledAtStartOfMap)
       StampInfo = Spawn(class'TimeStamp');

    for(M=Level.Game.BaseMutator; M!=None; M=M.NextMutator)
    {
        if(string(M.Class)~="SpawnGrenades.MutSN")
            return;
    }
    class'GrenadeAmmo'.default.InitialAmount = NumGrenadesOnSpawn;
    if (bDebugLogging) log("Finished PostBeginPlay...",'MutUTComp');
}

simulated function bool InStrNonCaseSensitive(String S, string S2)
{
    local int i;
    for(i=0; i<=(Len(S)-Len(S2)); i++)
    {
        if(Mid(S, i, Len(s2))~=S2)
            return true;
    }
    return false;
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
    local LinkedReplicationInfo lPRI;
    local int x, i;
	local WeaponLocker L;
    local EmoticonsReplicationInfo EmoteInfo;

    bSuperRelevant = 0;
   if(Other.IsA('pickup') && Level.Game!=None && Level.Game.IsA('utcomp_clanarena'))
        return false;
    if (Controller(Other) != None && MessagingSpectator(Other) == None && ONSOnslaughtGame(Level.Game) != none )
		Controller(Other).PlayerReplicationInfoClass = class'UTComp_ONSPlayerReplicationInfo';
    
    if ( GameReplicationInfo(Other) != None && bFastWeaponSwitch)
    {
        GameReplicationInfo(Other).bFastWeaponSwitching = true;
    }

    if(bEnhancedNetCodeEnabledAtStartOfMap)
    {
        // use NewNet weapons
        if (xWeaponBase(Other) != None)
    	{
	    	for (x = 0; x < ArrayCount(ReplacedWeaponClasses); x++)
	    		if (xWeaponBase(Other).WeaponType == ReplacedWeaponClasses[x])
	    		{
                	xWeaponBase(Other).WeaponType = WeaponClasses[x];
                 }
	    	         	return true;

        }
	    else if (WeaponPickup(Other) != None)
    	{
             for (x = 0; x < ArrayCount(ReplacedWeaponPickupClasses); x++)
		    	if ( Other.Class == ReplacedWeaponPickupClasses[x])
		    	{
                    ReplaceWith(Other, WeaponPickupClassNames[x]);
                    return false;
	     		}
	        //sigh, need this in case we can't change the wep-base
    	}
    	else if (WeaponLocker(Other) != None)
    	{
    		if(Level.Game.IsA('UTComp_ClanArena'))
                L.GotoState('Disabled');
            L = WeaponLocker(Other);
    		for (x = 0; x < ArrayCount(ReplacedWeaponClasses); x++)
    			for (i = 0; i < L.Weapons.Length; i++)
    				if (L.Weapons[i].WeaponClass == ReplacedWeaponClasses[x])
    					L.Weapons[i].WeaponClass = WeaponClasses[x];
    		return true;
    	}
	}
    else
    {
        // use UTComp weapons
        if (xWeaponBase(Other) != None)
    	{
	    	for (x = 0; x < ArrayCount(ReplacedWeaponClasses); x++)
	    		if (xWeaponBase(Other).WeaponType == ReplacedWeaponClasses[x])
	    		{
                	xWeaponBase(Other).WeaponType = WeaponClassesUTComp[x];
                 }
	    	         	return true;

        }
	    else if (WeaponPickup(Other) != None)
    	{
             for (x = 0; x < ArrayCount(ReplacedWeaponPickupClasses); x++)
		    	if ( Other.Class == ReplacedWeaponPickupClasses[x])
		    	{
                    ReplaceWith(Other, WeaponPickupClassNamesUTComp[x]);
                    return false;
	     		}
	        //sigh, need this in case we can't change the wep-base
    	}
    	else if (WeaponLocker(Other) != None)
    	{
            L = WeaponLocker(Other);
    		for (x = 0; x < ArrayCount(ReplacedWeaponClasses); x++)
    			for (i = 0; i < L.Weapons.Length; i++)
    				if (L.Weapons[i].WeaponClass == ReplacedWeaponClasses[x])
    					L.Weapons[i].WeaponClass = WeaponClassesUTComp[x];
    		return true;
    	}
    }

    if (PlayerReplicationInfo(Other)!=None)
    {
        if(PlayerReplicationInfo(Other).CustomReplicationInfo!=None)
        {
            lPRI=PlayerReplicationInfo(Other).CustomReplicationInfo;
            while(lPRI.NextReplicationInfo!=None)
            {
                 lPRI=lPRI.NextReplicationInfo;
            }
            lPRI.NextReplicationInfo=Spawn(class'UTComp_PRI', Other.Owner);
            if(bEnhancedNetCodeEnabledAtStartOfMap)
                lPRI.NextReplicationInfo.NextReplicationInfo = Spawn(class'NewNet_PRI', Other.Owner);
        }
        else
        {
            PlayerReplicationInfo(Other).CustomReplicationInfo=Spawn(class'UTComp_PRI', Other.Owner);
            if(bEnhancedNetCodeEnabledAtStartOfMap)
                PlayerReplicationInfo(Other).CustomReplicationInfo.NextReplicationInfo = Spawn(class'NewNet_PRI', Other.Owner);
        }
    }

    if(BS_xPlayer(Other) != None && BS_xPlayer(Other).EmoteInfo == None && bEnableEmoticons)
    {
        EmoteInfo = spawn(class'EmoticonsReplicationInfo', Other);
        EmoteInfo.EmoteActor = EmoteActor;
        BS_xPlayer(Other).EmoteInfo = EmoteInfo;
    }

    if (Other.IsA('UDamagePack') && !GetDoubleDamage())
    {
       return false;
    }
    return true;
}

function bool SniperCheckReplacement( Actor Other, out byte bSuperRelevant )
{
	local int i;
	local WeaponLocker L;

	bSuperRelevant = 0;
    if ( xWeaponBase(Other) != None )
    {
		if ( xWeaponBase(Other).WeaponType == class'UTClassic.ClassicSniperRifle' )
			xWeaponBase(Other).WeaponType = class'XWeapons.SniperRifle';
	}
	else if ( ClassicSniperRiflePickup(Other) != None )
		ReplaceWith( Other, "XWeapons.SniperRiflePickup");
	else if ( ClassicSniperAmmoPickup(Other) != None )
		ReplaceWith( Other, "XWeapons.SniperAmmoPickup");
	else if ( WeaponLocker(Other) != None )
	{
		L = WeaponLocker(Other);
		for (i = 0; i < L.Weapons.Length; i++)
			if (L.Weapons[i].WeaponClass == class'ClassicSniperRifle')
				L.Weapons[i].WeaponClass = class'SniperRifle';
		return true;
	}
	else
		return true;
	return false;
}

function bool getDoubleDamage()
{
   return bEnableDoubleDamage;
}


function ModifyLogin(out string Portal, out string Options)
{
    local bool bSeeAll;
	local bool bSpectator;


    if (Level.game == none) {
		Log ("utv2004s: Level.game is none?");
		return;
	}

	if (origcontroller != "") {
		Level.Game.PlayerControllerClassName = origcontroller;
		Level.Game.PlayerControllerClass = origcclass;
		origcontroller = "";
	}

    bSpectator = ( Level.Game.ParseOption( Options, "SpectatorOnly" ) ~= "1" );
    bSeeAll = ( Level.Game.ParseOption( Options, "UTVSeeAll" ) ~= "true" );

	if (bSeeAll && bSpectator) {
		Log ("utv2004s: Creating utv controller");
		origcontroller = Level.Game.PlayerControllerClassName;
		origcclass = Level.Game.PlayerControllerClass;
		Level.Game.PlayerControllerClassName = string(class'UTV_BS_xPlayer');
		Level.Game.PlayerControllerClass = none;
	}

  if (bDebugLogging)  log("Initial ScoreboardType="$Level.Game.ScoreBoardType$" MAXPLAYERS="$Level.Game.MaxPlayers,'MutUTComp');
// Restructing IF pooty 10/2023

/* old code
    if(Level.Game.ScoreBoardType~="xInterface.ScoreBoardDeathMatch")
    {  
        if(bEnableScoreBoard)
            Level.Game.ScoreBoardType=string(class'UTComp_Scoreboard');
        else
            Level.Game.ScoreBoardType=string(class'UTComp_ScoreBoardDM');
    }
    else if(Level.Game.ScoreBoardType~="xInterface.ScoreBoardTeamDeathMatch")
    {
        if(bEnableScoreBoard)
        {
            //TODO: SCOREBOARD
            //if (Level.Game.IsA('xCTFGame'))
            //    Level.Game.ScoreBoardType=string(class'UTComp_ScoreBoardCTF');
            //else
                Level.Game.ScoreBoardType=string(class'UTComp_Scoreboard');
        }
        else if(ONSOnslaughtGame(Level.Game) == none) // no custom scoreboard at all for Onslaught 
        {
            //if scoreboard is disabled and NOT and ONS game, then use this scoreboard
            //for ONS game don't touch ScoreBoardType with scoreboard disabled
            Level.Game.ScoreBoardType=string(class'UTComp_ScoreBoardTDM');
        }
    }
    else if(Level.Game.ScoreBoardType~="UT2k4Assault.ScoreBoard_Assault")
    {
        Level.Game.ScoreBoardType=string(class'UTComp_ScoreBoard_AS');
    }
    else if(Level.game.scoreboardtype~="BonusPack.MutantScoreboard")
    {
        Level.Game.ScoreBoardType=string(class'UTComp_ScoreBoard_Mutant');
    }
*/
  
	  
	 	  	//  the UTComp_ScoreBoard  It  has special graphics/display
	  	// it CAN handle both DM And TDM games.
	  	// Can be overridden by UserSettings
	  	// If you don't use UTComp_Scoreboard then the other scoreboards
	  	// UTComp_ScoreboardDM, UTComp_ScoreboardTDM - Same as the default scoreboard but with Colored Names
	  	// No "real" option to just use default scoreboards -- that's ok colored names are cool.
	  	
	    if(Level.Game.ScoreBoardType~="xInterface.ScoreBoardDeathMatch")
	    {  // Regular DM Game
	        if(bEnableScoreboard) 
	           Level.Game.ScoreBoardType=string(class'UTComp_Scoreboard'); // special UTComp Scoreboard has different graphics.
	        else Level.Game.ScoreBoardType=string(class'UTComp_ScoreBoardDM');  // "Normal" scoreboard with some minor tweaks
	    } // end DM if
	    else if(Level.Game.ScoreBoardType~="xInterface.ScoreBoardTeamDeathMatch")
	    {  // WE have a TeamDM Game. (eg. ONS, CTF, AS etc.)
	    	// Careful here as all these GameTypes are subclasses of TDM
	        if(bEnableScoreboard)
	        {
	        	if (Level.Game.IsA('ONSOnslaughtGame')) Level.Game.ScoreBoardType=string(class'UTComp_ScoreBoardONS');
	        //	else if (Level.Game.IsA('xCTFGame')) Level.Game.ScoreBoardType=string(class'UTComp_ScoreBoardCTF');  // this one is quite different...based on Enhanced.
	        // Commented out in previous version so keeping it commented out pooty 10/23
	        	else Level.Game.ScoreBoardType=string(class'UTComp_ScoreBoard');  // Enhanced for any TDM game that isn't specific above
	        }
	        else Level.Game.ScoreBoardType=string(class'UTComp_ScoreBoardTDM');  //default GT for any TDM game that isn't specific above
	       
	     }  //else TDM if end
	     else if (bEnableScoreboard && Level.Game.IsA('xMutantGame')) Level.Game.ScoreBoardType=string(class'UTComp_ScoreBoardMutant');
	     else if (bEnableScoreboard && Level.Game.IsA('ASGameInfo')) Level.Game.ScoreBoardType=string(class'UTComp_ScoreBoardAS');
	     // should never get here either DM game or TDM game..but just to be safe
	    // so we will just leave it alone, as it could be some other custom scoreboard.
	  
	  
	if (bDebugLogging) log("ModifyLogin ScoreboardType="$Level.Game.ScoreBoardType,'MutUTComp');
	
    Super.ModifyLogin(Portal, Options);

    if(level.game.hudtype~="xInterface.HudCTeamDeathmatch")
        Level.Game.HudType=string(class'UTComp_HudCTeamDeathmatch');
    else if(level.game.hudtype~="xInterface.HudCDeathmatch")
        Level.Game.HudType=string(class'UTComp_HudCDeathmatch');
    else if(level.game.hudtype~="xInterface.HudCBombingRun")
        Level.Game.HudType=string(class'UTComp_HudCBombingRun');
    else if(level.game.hudtype~="xInterface.HudCCaptureTheFlag")
        Level.Game.HudType=string(class'UTComp_HudCCaptureTheFlag');
    else if(level.game.hudtype~="xInterface.HudCDoubleDomination")
        Level.Game.HudType=string(class'UTComp_HudCDoubleDomination');
    else if(level.game.hudtype~="Onslaught.ONSHUDOnslaught")
        Level.Game.HudType=string(class'UTComp_ONSHUDOnslaught');
    else if(level.game.hudtype~="SkaarjPack.HUDInvasion")
        Level.Game.HudType=string(class'UTComp_HudInvasion');
    else if(level.game.hudtype~="BonusPack.HudLMS")
        Level.Game.HudType=string(class'UTComp_HudLMS');
    else if(level.game.hudtype~="BonusPack.HudMutant")
        Level.Game.HudType=string(class'UTComp_HudMutant');
    else if(level.game.hudtype~="ut2k4assault.Hud_Assault")
        Level.Game.HudType=string(class'UTComp_Hud_Assault');
}

function GetServerPlayers( out GameInfo.ServerResponseLine ServerState )
{
    local int i;

    if(!Level.Game.bTeamGame)
        return;

    if(bShowTeamScoresInServerBrowser && TeamGame(Level.Game).Teams[0]!=None)
    {
        i = ServerState.PlayerInfo.Length;
        ServerState.PlayerInfo.Length = i+1;
        ServerState.PlayerInfo[i].PlayerName = Chr(0x1B)$chr(10)$chr(245)$chr(10)$"Red Team Score";
        ServerState.PlayerInfo[i].Score = TeamGame(Level.Game).Teams[0].Score;
    }

    if(bShowTeamScoresInServerBrowser && TeamGame(Level.Game).Teams[1]!=None)
    {
        i = ServerState.PlayerInfo.Length;
        ServerState.PlayerInfo.Length = i+1;
        ServerState.PlayerInfo[i].PlayerName =  Chr(0x1B)$chr(10)$chr(245)$chr(10)$"Blue Team Score";
        ServerState.PlayerInfo[i].Score = TeamGame(Level.Game).Teams[1].Score;
    }
}

function ServerTraveling(string URL, bool bItems)
{
   class'xPawn'.default.ControllerClass=class'XGame.XBot';

   class'XWeapons.ShockRifle'.default.FireModeClass[1]=Class'XWeapons.ShockProjFire';
   class'GrenadeAmmo'.default.InitialAmount = 4;

   class'XWeapons.AssaultRifle'.default.FireModeClass[0] = Class'XWeapons.AssaultFire';
   class'XWeapons.AssaultRifle'.default.FireModeClass[1] = Class'XWeapons.AssaultGrenade';

    class'XWeapons.BioRifle'.default.FireModeClass[0] = Class'XWeapons.BioFire';
    class'XWeapons.BioRifle'.default.FireModeClass[1] = Class'XWeapons.BioChargedFire';

    class'XWeapons.ShockRifle'.default.FireModeClass[0] = Class'XWeapons.ShockBeamFire';
    class'XWeapons.ShockRifle'.default.FireModeClass[1] = Class'XWeapons.ShockProjFire';

    class'XWeapons.LinkGun'.default.FireModeClass[0] = Class'XWeapons.LinkAltFire';
    class'XWeapons.LinkGun'.default.FireModeClass[1] = Class'XWeapons.LinkFire';

    class'XWeapons.MiniGun'.default.FireModeClass[0] = Class'XWeapons.MinigunFire';
    class'XWeapons.MiniGun'.default.FireModeClass[1] = Class'XWeapons.MinigunAltFire';

    class'XWeapons.FlakCannon'.default.FireModeClass[0] = Class'XWeapons.FlakFire';
    class'XWeapons.FlakCannon'.default.FireModeClass[1] = Class'XWeapons.FlakAltFire';

    class'XWeapons.RocketLauncher'.default.FireModeClass[0] = Class'XWeapons.RocketFire';
    class'XWeapons.RocketLauncher'.default.FireModeClass[1] = Class'XWeapons.RocketMultiFire';

    class'XWeapons.SniperRifle'.default.FireModeClass[0]= Class'XWeapons.SniperFire';
    class'UTClassic.ClassicSniperRifle'.default.FireModeClass[0]= Class'UTClassic.ClassicSniperFire';

    class'Onslaught.ONSMineLayer'.default.FireModeClass[0] = Class'Onslaught.ONSMineThrowFire';

    class'Onslaught.ONSGrenadeLauncher'.default.FireModeClass[0] =Class'UTComp_ONSGrenadeFire';

    class'Onslaught.ONSAVRiL'.default.FireModeClass[0] =Class'Onslaught.ONSAVRiLFire';

    class'XWeapons.SuperShockRifle'.default.FireModeClass[0]=class'XWeapons.SuperShockBeamFire';
    class'XWeapons.SuperShockRifle'.default.FireModeClass[1]=class'XWeapons.SuperShockBeamFire';

   ParseUrl(Url);

   Super.ServerTraveling(url, bitems);
}

function ParseURL(string Url)
{
   local string Skinz0r, Sounds, overlay, powerupsOverlay, warmup, dd, TimedOver
   , TimedOverLength, grenadesonspawn, enableenhancednetcode, suicideIntervalString;
   local array<string> Parts;
   local int i;


    Split(Url, "?", Parts);

   for(i=0; i<Parts.Length; i++)
   {
       if(Parts[i]!="")
       {
           if(Left(Parts[i],Len("BrightSkinsMode"))~= "BrightSkinsMode")
               Skinz0r=Right(Parts[i], Len(Parts[i])-Len("BrightSkinsMode")-1);
           if(Left(Parts[i],Len("HitSoundsMode"))~= "HitSoundsMode")
               Sounds=Right(Parts[i], Len(Parts[i])-Len("HitSoundsMode")-1);
           if(Left(Parts[i],Len("EnableTeamOverlay"))~= "EnableTeamOverlay")
               Overlay=Right(Parts[i], Len(Parts[i])-Len("EnableTeamOverlay")-1);
           if (Left(Parts[i],Len("EnablePowerupsOverlay"))~= "EnablePowerupsOverlay")
               PowerupsOverlay=Right(Parts[i], Len(Parts[i])-Len("EnablePowerupsOverlay")-1);
           if(Left(Parts[i],Len("EnableWarmup"))~= "EnableWarmup")
               Warmup=Right(Parts[i], Len(Parts[i])-Len("EnableWarmup")-1);
           if(Left(Parts[i],Len("DoubleDamage"))~= "DoubleDamage")
               DD=Right(Parts[i], Len(Parts[i])-Len("DoubleDamage")-1);
           if(Left(Parts[i],Len("EnableTimedOverTime"))~= "EnableTimedOverTime")
               TimedOver=Right(Parts[i], Len(Parts[i])-Len("EnableTimedOverTime")-1);
           if(Left(Parts[i],Len("TimedOverTimeLength"))~= "TimedOverTimeLength")
               TimedOverLength=Right(Parts[i], Len(Parts[i])-Len("TimedOverTimeLength")-1);
           if(Left(Parts[i],Len("GrenadesOnSpawn"))~= "GrenadesOnSpawn")
               GrenadesOnSpawn=Right(Parts[i], Len(Parts[i])-Len("GrenadesOnSpawn")-1);
           if(Left(Parts[i],Len("EnableEnhancedNetcode"))~= "EnableEnhancedNetcode")
               EnableEnhancedNetcode=Right(Parts[i], Len(Parts[i])-Len("EnableEnhancedNetcode")-1);
           if (Left(Parts[i], Len("SuicideInterval")) ~= "SuicideInterval")
               suicideIntervalString = Right(Parts[i], Len(Parts[i])-Len("SuicideInterval")-1);
       }
   }
   if(Skinz0r !="" && int(Skinz0r)<4 && int(Skinz0r)>0)
   {
       default.EnableBrightskinsMode=Int(Skinz0r);
       EnableBrightskinsMode = default.EnableBrightskinsMode;
   }
   if(Sounds !="" && int(Sounds)<3 && int(Sounds)>=0)
   {
       default.EnableHitsoundsMode=Int(Sounds);
       EnableHitsoundsMode = default.EnableHitsoundsMode;
   }
   if(Overlay !="" && (Overlay~="False" || Overlay~="True"))
   {
       default.bEnableTeamOverlay=Overlay~="True";
       bEnableTeamOverlay = default.bEnableTeamOverlay;
   }
   if(PowerupsOverlay !="" && (PowerupsOverlay~="False" || PowerupsOverlay~="True"))
   {
       default.bEnablePowerupsOverlay=PowerupsOverlay~="True";
       bEnablePowerupsOverlay = default.bEnablePowerupsOverlay;
   }
   if(Warmup !="" && (Warmup~="False" || Warmup~="True"))
   {
       default.bEnableWarmup=(Warmup~="True");
       bEnableWarmup=default.bEnableWarmup;
   }
   if(DD !="" && (DD~="False" || DD~="True"))
   {
       default.bEnableDoubleDamage=(DD~="True");
       bEnableDoubleDamage = default.bEnableDoubleDamage;
   }
 
   if(TimedOverLength !="" && int(TimedOverLength)>=0)
   {
       if(int(TimedOverLength) == 0)
          default.bEnableTimedOverTime=false;
       else
       {
          default.TimedOvertimeLength=60*Int(TimedOverLength);
          default.bEnableTimedOverTime=True;
       }
       bEnableTimedOverTime = default.bEnableTimedOverTime;
       TimedOvertimeLength = default.TimedOvertimeLength;
   }
   if(GrenadesOnSpawn !="" && int(GrenadesOnSpawn)<9 && int(GrenadesOnSpawn)>=0)
   {
       default.NumGrenadesOnSpawn=Int(GrenadesOnSpawn);
       NumGrenadesOnSpawn = default.NumGrenadesOnSpawn;
   }
   if(EnableEnhancedNetcode !="" && (EnableEnhancedNetcode~="false" || EnableEnhancedNetcode~="True"))
   {
       default.bEnableEnhancedNetcode=(EnableEnhancedNetcode~="True");
       bEnhancedNetCodeEnabledAtStartOfMap=default.bEnableEnhancedNetcode;
       bEnableEnhancedNetcode = default.bEnableEnhancedNetCode;
   }
   if (suicideIntervalString != "")
   {
      default.SuicideInterval = Int(suicideIntervalString);
      SuicideInterval = default.SuicideInterval;
   }
   StaticSaveConfig();
}

function AutoDemoRecord()
{
    if(class'MutUTComp'.default.bEnableAutoDemorec)
    {
        ConsoleCommand("Demorec"@CreateAutoDemoRecName());
    }
    bDemoStarted=true;
}

function string CreateAutoDemoRecName()
{
    local string S;
    S=class'MutUTComp'.default.AutoDemoRecMask;
    S=Repl(S, "%p", CreatePlayerString());
    S=Repl(S, "%t", CreateTimeString());
    S=StripIllegalWindowsCharacters(S);
    return S;
}

function string CreatePlayerString()
{
    local controller C;
    local array<string> RedPlayerNames;
    local array<string> BluePlayerNames;
    local string ReturnString;
    local int i;

    for(C=Level.ControllerList; C!=None; C=C.NextController)
    {
        if(PlayerController(C)!=None && C.PlayerReplicationInfo!=None && !C.PlayerReplicationInfo.bOnlySpectator && C.PlayerReplicationInfo.PlayerName!="")
        {
            if(C.GetTeamNum()==1)
                BluePlayerNames[BluePlayerNames.Length]=C.PlayerReplicationInfo.PlayerName;
            else
                RedPlayerNames[RedPlayerNames.Length]=C.PlayerReplicationInfo.PlayerName;
        }
    }

    if(BluePlayerNames.Length>0 && RedPlayerNames.Length>0)
    {
         ReturnString=BluePlayerNames[0];
         for(i=1; i<BluePlayerNames.Length && i<4; i++)
         {
             ReturnString$="-"$BluePlayerNames[i];
         }
         ReturnString$="-vs-"$RedPlayerNames[0];
         for(i=1; i<RedPlayerNames.Length && i<4; i++)
         {
             ReturnString$="-"$RedPlayerNames[i];
         }
    }
    else if(RedPlayerNames.Length>0)
    {
        ReturnString=RedPlayerNames[0];
        for(i=1; i<RedPlayerNames.Length && i<8; i++)
        {
            ReturnString$="-vs-"$RedPlayerNames[i];
        }
    }
    else if(BluePlayerNames.Length>0)
    {
         ReturnString=BluePlayerNames[0];
         for(i=1; i<BluePlayerNames.Length && i<4; i++)
         {
             ReturnString$="-"$BluePlayerNames[i];
         }
         returnString$="-vs-EmptyTeam";
    }
    returnstring=Left(returnstring, 100);
    return ReturnString;
}

function GetServerDetails( out GameInfo.ServerResponseLine ServerState )
{
    local int i;
    super.GetServerDetails(ServerState);

	i = ServerState.ServerInfo.Length;
	ServerState.ServerInfo.Length = i+2;
	ServerState.ServerInfo[i].Key = FriendlyVersionPrefix;
	ServerState.ServerInfo[i].Value = FriendlyVersionName$" "$FriendlyVersionNumber;
	ServerState.ServerInfo[i+1].Key = "Enhanced Netcode";
	ServerState.ServerInfo[i+1].Value = string(bEnhancedNetCodeEnabledAtStartOfMap);
}

function string CreateTimeString()
{
    local string hourdigits, minutedigits;

    if(Len(level.hour)==1)
        hourDigits="0"$Level.Hour;
    else
        hourDigits=Left(level.Hour, 2);
    if(len(level.minute)==1)
        minutedigits="0"$Level.Minute;
    else
        minutedigits=Left(Level.Minute, 2);

   return hourdigits$"-"$minutedigits;
}

simulated function string StripIllegalWindowsCharacters(string S)
{
   S=repl(S, ".", "-");
   S=repl(S, "*", "-");
   S=repl(S, ":", "-");
   S=repl(S, "|", "-");
   S=repl(S, "/", "-");
   S=repl(S, ";", "-");
   S=repl(S, "\\","-");
   S=repl(S, ">", "-");
   S=repl(S, "<", "-");
   S=repl(S, "+", "-");
   S=repl(S, " ", "-");
   S=repl(S, "?", "-");
   return S;
}

static function FillPlayInfo (PlayInfo PlayInfo)
{
	PlayInfo.AddClass(Default.Class);
    PlayInfo.AddSetting("UTComp Settings", "EnableBrightSkinsMode", "Brightskins Mode", 1, 1, "Select", "0;Disabled;1;Epic Style;2;BrighterEpic Style;3;UTComp Style ");
    PlayInfo.AddSetting("UTComp Settings", "EnableHitSoundsMode", "Hitsounds Mode", 1, 1, "Select", "0;Disabled;1;Line Of Sight;2;Everywhere");
    PlayInfo.AddSetting("UTComp Settings", "bEnableWarmup", "Enable Warmup", 1, 1, "Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableDoubleDamage", "Enable Double Damage", 1, 1, "Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableAutoDemoRec", "Enable Serverside Demo-Recording", 1, 1, "Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableTeamOverlay", "Enable Team Overlay", 1, 1, "Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnablePowerupsOverlay", "Enable Powerups Overlay for spectators", 1, 1, "Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableEnhancedNetcode", "Enable Enhanced Netcode", 1, 1, "Check");
    PlayInfo.AddSetting("UTComp Settings", "ServerMaxPlayers", "Voting Max Players",255, 1, "Text","2;0:32",,False,False);
    PlayInfo.AddSetting("UTComp Settings", "NumGrenadesOnSpawn", "Number of grenades on spawn",255, 1, "Text","2;0:32",,False,False);
    PlayInfo.AddSetting("UTComp Settings", "MaxMultiDodges", "Number of additional dodges",255, 1, "Text","2;0:99",);
    PlayInfo.AddSetting("UTComp Settings", "MinNetSpeed", "Minimum NetSpeed for Clients",255, 1, "Text","0;0:1000000",);
    PlayInfo.AddSetting("UTComp Settings", "MaxNetSpeed", "Maximum NetSpeed for Clients",255, 1, "Text","0;0:1000000",);

    PlayInfo.AddSetting("UTComp Settings", "bEnableVoting", "Enable Voting", 1, 1, "Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableBrightskinsVoting", "Allow players to vote on Brightskins settings", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableWarmupVoting", "Allow players to vote on Warmup setting", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableHitsoundsVoting", "Allow players to vote on Hitsounds settings", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableTeamOverlayVoting", "Allow players to vote on team overlay setting", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnablePowerupsOverlayVoting", "Allow players to vote on powerups overlay setting", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableEnhancedNetcodeVoting", "Allow players to vote on enhanced netcode setting", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableMapVoting", "Allow players to vote for map changes", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "WarmupTime", "Warmup Time",1, 1, "Text","0;0:1800",,False,False);
    PlayInfo.AddSetting("UTComp Settings", "EnableWarmupWeaponsMode", "0) none 1) utcomp 2) tam 3) ons+tam",1, 1, "Text","0;0:3",,False,False);

    PlayInfo.AddSetting("UTComp Settings", "SuicideInterval", "Minimum time between two suicides", 1, 1, "Text", "0;0:1800",, False, False);
    PlayInfo.AddSetting("UTComp Settings", "bShowSpawnsDuringWarmup", "Show Spawns during Warmup", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableEmoticons", "Enable Emoticons", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "bFastWeaponSwitch", "Fast weapon switch", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "bAllowColorWeapons", "Enable color weapons", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "bNoTeamBoosting", "Teammates can't knock you around with weapons", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "bNoTeamBoostingVehicles", "Teammates can't knock you around in a vehicle", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "bChargedWeaponsNoSpawnProtection", "Disable spawn protection during weapon charging", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "bLimitTaunts", "Limit the number of voice taunts allowed", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "TauntCount", "Number of voice taunts allowed",1, 1, "Text","0;0:999",,False,False);
    PlayInfo.AddSetting("UTComp Movement Settings", "bKeepMomentumOnLanding", "UTComp style gliding movement", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Movement Settings", "NetMoveDelta", "How often clients send move updates (default 0.011)",1, 1, "Text","0.011;0.001:0.022",,False,False);
    PlayInfo.AddSetting("UTComp Movement Settings", "MaxSavedMoves", "Max saved moves for warp fix (default 300)",1, 1, "Text","300;100:750",,False,False);
    PlayInfo.AddSetting("UTComp Movement Settings", "MaxResponseTime", "delay for client move update (default 0.125)",1, 1, "Text","0.125;0.001:0.250",,False,False);
    PlayInfo.AddSetting("UTComp Movement Settings", "bMoveErrorAccumFix", "use move accum fix (default false)",1, 1, "Check");
    PlayInfo.AddSetting("UTComp Movement Settings", "MoveErrorAccumFixValue", "move accum fix value (default 0.009)",1, 1, "Text", "0.009:0.001:0.018",,false, false);

    PlayInfo.PopClass();
    super.FillPlayInfo(PlayInfo);
}

static event string GetDescriptionText(string PropName)
{
	switch (PropName)
	{
		case "bEnableWarmup": return "Check this to enable Warmup.";
		case "bEnableDoubleDamage": return "Check this to enable the double damage.";
	    case "EnableBrightSkinsMode": return "Sets the server-forced brightskins mode.";
	    case "EnableHitSoundsMode": return "Sets the server-Forced hitsound mode.";
	    case "bEnableAutoDemoRec": return "Check this to enable a recording of every map, beginning as warmup ends.";
        case "ServerMaxPlayers": return "Set this to the maximum number of players you wish for to allow a client to vote for.";
        case "NumGrenadesOnSpawn": return "Set this to the number of Assault Rifle grenades you wish a player to spawn with.";
        case "MaxMultiDodges": return "Additional dodges players can perform without landing.";
        case "bEnableTeamOverlay": return "Check this to enable the team overlay.";
        case "bEnablePowerupsOverlay": return "Check this to enable the powerups overlay for spectators.";
        case "bEnableEnhancedNetcode": return "Check this to enable the enhanced netcode.";
        case "bEnableVoting": return "Check this to enable voting.";
        case "bEnableBrightSkinsVoting": return "Check this to enable voting for brightskins.";
        case "bEnablehitsoundsVoting": return "Check this to enable voting for hitsounds.";
        case "bEnableTeamOverlayVoting": return "Check this to enable voting for Team Overlay.";
        case "bEnablePowerupsOverlayVoting": return "Check this to enable voting for powerups overlay for spectators.";
        case "bEnableEnhancedNetcodeVoting": return "Check this to enable voting for Enhanced Netcode.";
        case "bEnableWarmupVoting": return "Check this to enable voting for Warmup.";
        case "bEnableMapVoting": return "Check this to enable voting for Maps.";
        case "WarmupTime": return "Time for warmup. Set this to 0 for unlimited, otherwise it is the time in seconds.";
        case "EnableWarmupWeaponsMode": return "Warmup weapon mode: 0) none 1) utcomp 2) tam 3) ons+tam";
        case "MinNetSpeed": return "Minimum NetSpeed for clients on this server";
        case "MaxNetSpeed": return "Maximum NetSpeed for clients on this server";
        case "SuicideInterval": return "Minimum time between two suicides";
        case "bShowSpawnsDuringWarmup": return "Show spawn points during warmup by spawning dummies on every one of them";
        case "bEnableEmoticons": return "Enable emoticons";
        case "bFastWeaponSwitch": return "Enable UT2003 style fast weapon switch";
        case "bAllowColorWeapons": return "Enable color weapons";
        case "bNoTeamBoosting": return "Teammates can't knock you around with weapons";
        case "bNoTeamBoostingVehicles": return "Teammates can't knock you around in a vehicle";
        case "bChargedWeaponsNoSpawnProtection": return "Disable spawn protection during weapon charging";
        case "bLimitTaunts": return "Limit the number of voice taunts allowed";
        case "TauntCount": return "Number of voice taunts allowed";

        case "bKeepMomentumOnLanding": return "UTComp style gliding movement";
        case "NetMoveDelta": return "How often clients send move updates, lower is faster (default 0.011)";
        case "MaxSavedMoves": return "Maximum saved moves for warping fix (default 300)";
        case "MaxResponseTime": return "server delay for client move update before setting position (default 0.125)";
        case "bMoveErrorAccumFix": return "use server define movement accumulation (default false)";
        case "MoveErrorAccumFixValue": return "server defined movement accumulation value (default 0.009)";
    }
	return Super.GetDescriptionText(PropName);
}

function bool ReplaceWith(actor Other, string aClassName)
{
	local Actor A;
	local class<Actor> aClass;

	if ( aClassName == "" )
		return true;

	aClass = class<Actor>(DynamicLoadObject(aClassName, class'Class'));
	if ( aClass != None )
		A = Spawn(aClass,Other.Owner,Other.tag,Other.Location, Other.Rotation);
	if ( Other.IsA('Pickup') )
	{
		if ( Pickup(Other).MyMarker != None )
		{
			Pickup(Other).MyMarker.markedItem = Pickup(A);
			if ( Pickup(A) != None )
			{
				Pickup(A).MyMarker = Pickup(Other).MyMarker;
				A.SetLocation(A.Location
					+ (A.CollisionHeight - Other.CollisionHeight) * vect(0,0,1));
			}
			Pickup(Other).MyMarker = None;
		}
		else if ( A.IsA('Pickup') && !A.IsA('WeaponPickup') )
			Pickup(A).Respawntime = 0.0;
	}
	if ( A != None )
	{
		A.event = Other.event;
		A.tag = Other.tag;
		return true;
	}
	return false;
}

function string GetInventoryClassOverride(string InventoryClassName)
{
    local int x;

    if(bEnhancedNetCodeEnabledAtStartOfMap)
    {
        for(x=0; x<ArrayCount(WeaponClassNames); x++)
           if(InventoryClassName ~= WeaponClassNames[x])
               return string(WeaponClasses[x]);
    }
    else
    {
         for(x=0; x<ArrayCount(WeaponClassNames); x++)
           if(InventoryClassName ~= WeaponClassNames[x])
               return string(WeaponClassesUTComp[x]);
    }

    if ( NextMutator != None )
		return NextMutator.GetInventoryClassOverride(InventoryClassName);

	return InventoryClassName;
}

/*
 fix for netcode not working in second round in assault and ons game modes
 reset is called bewteen rounds, clean up timestamp pawn and controller and recreate 
 ONS and AS round end code calls 

    for(C = Level.ControllerList;C != None; C = C.NextController)
    {
        ...
        C.RoundHasEnded();
    }

   RoundHasEnded in Timestamp_Controller breaks the timestamp mechanism.  
   
   For whatever reason (engine bug?) we cannot override RoundHasEnded() function in 
   Timestamp_Controller.  It never gets called, instead the base method gets called 
   which unpossesses the pawn and destroys itself.  Not good.  Since we can't override 
   RoundHasEnded, we fix what gets broken in the Reset() function that gets called for
   all actors (including this mutator) during round changes. 
*/

function Reset()
{
    local Controller C;
    local UTComp_ONSPlayerReplicationInfo ONSInfo;

    // remove all Timestamp_pawn from clients
    for(C = Level.ControllerList;C != None;C = C.NextController)
    {
        if(BS_xPlayer(C) != None)
            BS_xPlayer(C).ClientResetNetcode();
    }

    // delete these server side, the get recreated in SetPawnStamp function
    if(countercontroller != None)
    {
        if(countercontroller.Pawn != None)
        {
            countercontroller.Pawn.Unpossessed();
            countercontroller.Pawn.Destroy();
            countercontroller.Pawn = None;
        }

        countercontroller.Destroy();
        countercontroller = None;
    }

    // fix for vehicle list not updating between rounds on ONS randomizers
    foreach DynamicActors(class'UTComp_ONSPlayerReplicationInfo', ONSInfo)
    {
        if(ONSInfo != None)
            ONSInfo.ServerVSpawnList.Length = 0;
    }
}

// provide hook for derived classes
function WarmupEnded()
{
}

// use special gamestats for ons gametype 
// to record node stuff for scoreboard
function InitStatsOverride()
{
    local string GameStatsClass;

    if(Level.Game.IsA('ONSOnslaughtGame') && bUseUTCompStats)
    {
        GameStatsClass = string(class'UTComp_GameStats');
        log("overriding stats class, using "$GameStatsClass);
        OriginalStatsClass = Level.Game.GameStatsClass;
        Level.Game.GameStatsClass = GameStatsClass;
    }
}

defaultproperties
{
     bAddToServerPackages=True
     bEnableVoting=False
     bEnableBrightskinsVoting=True
     bEnableHitsoundsVoting=True
     bEnableWarmupVoting=True
     bEnableTeamOverlayVoting=True
     bEnablePowerupsOverlayVoting=True
     bEnableMapVoting=True
     bEnableGametypeVoting=True
     VotingPercentRequired=51.000000
     VotingTimeLimit=30.000000
     benableDoubleDamage=True
     EnableBrightSkinsMode=3
     bEnableClanSkins=True
     bEnablePowerupsOverlay=True
     EnableHitSoundsMode=2
     bEnableScoreboard=True  // really isn't configurable now, UTComp always tweaks scoreboards.
     
     bEnableWarmup=True
     WarmupClass=class'UTComp_Warmup'
     WarmupReadyPercentRequired=100.000000
     bEnableWeaponStats=True
     bEnablePowerupStats=True

     bShowTeamScoresInServerBrowser=True
     ServerMaxPlayers=32
     AlwaysUseThisMutator(0)="MutUTComp"
     AutoDemoRecMask="%d-(%t)-%m-%p"
     EnableWarmupWeaponsMode=1
     WarmupHealth=199

     VotingGametype(0)=(GametypeOptions="?game=XGame.xDeathMatch?timelimit=15?minplayers=0?goalscore=0?Mutator=XWeapons.MutNoSuperWeapon,XGame.MutNoAdrenaline?weaponstay=false?DoubleDamage=false?GrenadesOnSpawn=4?TimedOverTimeLength=0",GametypeName="1v1")
     VotingGametype(1)=(GametypeOptions="?game=XGame.xDeathMatch?timelimit=15?minplayers=0?goalscore=50?weaponstay=True?DoubleDamage=True?GrenadesOnSpawn=4?TimedOverTimeLength=0",GametypeName="FFA")
     VotingGametype(2)=(GametypeOptions="?game=XGame.xTeamGame?timelimit=20?goalscore=0?minplayers=0?Mutator=XWeapons.MutNoSuperWeapon?FriendlyfireScale=1.00?weaponstay=False?DoubleDamage=True?GrenadesOnSpawn=1?TimedOverTimeLength=5",GametypeName="Team Deathmatch")
     VotingGametype(3)=(GametypeOptions="?game=XGame.xCTFGame?timelimit=20?goalscore=0?minplayers=0?mutator=XGame.MutNoAdrenaline,XWeapons.MutNoSuperWeapon?friendlyfirescale=0?weaponstay=true?DoubleDamage=True?GrenadesOnSpawn=4?TimedOverTimeLength=0",GametypeName="Capture the Flag")
     VotingGametype(4)=(GametypeOptions="?game=Onslaught.ONSOnslaughtGame?timelimit=20?goalscore=1?mutator=XWeapons.MutNoSuperWeapon?minplayers=0?friendlyfirescale=0?weaponstay=True?DoubleDamage=True?GrenadesOnSpawn=4?TimedOverTimeLength=0",GametypeName="Onslaught")
     VotingGametype(5)=(GametypeOptions="?game=WSUTComp.UTComp_ClanArena?goalscore=7?TimeLimit=2?FriendlyFireScale=0?GrenadesOnSpawn=4?TimedOverTimeLength=0",GametypeName="Clan Arena")     
     VotingGametype(6)=(GametypeOptions="?game=UT2k4Assault.ASGameInfo?timelimit=20?goalscore=1?FriendlyFireScale=0,WeaponStay=True?mutator=XWeapons.MutNoSuperWeapon?DoubleDamage=True?GrenadesOnSpawn=4?TimedOverTimeLength=0",GametypeName="Assault")
     VotingGametype(7)=(GametypeOptions="?game=XGame.xDoubleDom?timelimit=20?goalscore=0?FriendlyFireScale=0,WeaponStay=true?mutator=XWeapons.MutNoSuperWeapon?DoubleDamage=true?GrenadesOnSpawn=4?TimedOverTimeLength=0",GametypeName="Double Domination")
     VotingGametype(8)=(GametypeOptions="?game=XGame.xBombingRun?timelimit=20?goalscore=0?FriendlyFireScale=0,WeaponStay=True?mutator=XWeapons.MutNoSuperWeapon?DoubleDamage=True?GrenadesOnSpawn=4?TimedOverTimeLength=0",GametypeName="Bombing Run")

     MinNetSpeed=10000
     MaxNetSpeed=1000000

     //ONS
     NodeIsolateBonusPct=20
     VehicleHealScore=200
     VehicleDamagePoints=400
     PowerCoreScore=10
     PowerNodeScore=5
     NodeHealBonusPct=60
     bNodeHealBonusForLockedNodes=false
     bNodeHealBonusForConstructor=false
     bDebugLogging = false


     NewNetUpdateFrequency=200
     PingTweenTime=3.0

     FriendlyName="Wicked Sick UTComp"
     FriendlyVersionPrefix="UTComp Version"
     FriendlyVersionName="Wicked Sick"
     FriendlyVersionNumber="V10"
     Description="A mutator for warmup, brightskins, hitsounds, enhanced netcode, adjustable player scoring and various other features."
     bNetTemporary=True
     bAlwaysRelevant=True
     RemoteRole=ROLE_SimulatedProxy
     bEnableAdvancedVotingOptions=True
     bForceMapVoteMatchPrefix=True
     TimedOverTimeLength=300
     bEnableTimedOvertimeVoting=True
     NumGrenadesOnSpawn=4
     bEnableEnhancedNetCode=true
     bEnableEnhancedNetCodeVoting=false
     PawnCollisionHistoryLength=0.35

     //original weapons
     WeaponClassNames(0)="XWeapons.ShockRifle"
     WeaponClassNames(1)="XWeapons.LinkGun"
     WeaponClassNames(2)="XWeapons.MiniGun"
     WeaponClassNames(3)="XWeapons.FlakCannon"
     WeaponClassNames(4)="XWeapons.RocketLauncher"
     WeaponClassNames(5)="XWeapons.SniperRifle"
     WeaponClassNames(6)="XWeapons.BioRifle"
     WeaponClassNames(7)="XWeapons.AssaultRifle"
     WeaponClassNames(8)="UTClassic.ClassicSniperRifle"
     WeaponClassNames(9)="Onslaught.ONSAVRiL"
     WeaponClassNames(10)="Onslaught.ONSMineLayer"
     WeaponClassNames(11)="Onslaught.ONSGrenadeLauncher"
     WeaponClassNames(12)="XWeapons.SuperShockRifle"
     ReplacedWeaponClasses(0)=Class'XWeapons.ShockRifle'
     ReplacedWeaponClasses(1)=Class'XWeapons.LinkGun'
     ReplacedWeaponClasses(2)=Class'XWeapons.Minigun'
     ReplacedWeaponClasses(3)=Class'XWeapons.FlakCannon'
     ReplacedWeaponClasses(4)=Class'XWeapons.RocketLauncher'
     ReplacedWeaponClasses(5)=Class'XWeapons.SniperRifle'
     ReplacedWeaponClasses(6)=Class'XWeapons.BioRifle'
     ReplacedWeaponClasses(7)=Class'XWeapons.AssaultRifle'
     ReplacedWeaponClasses(8)=Class'UTClassic.ClassicSniperRifle'
     ReplacedWeaponClasses(9)=Class'Onslaught.ONSAVRiL'
     ReplacedWeaponClasses(10)=Class'Onslaught.ONSMineLayer'
     ReplacedWeaponClasses(11)=Class'Onslaught.ONSGrenadeLauncher'
     ReplacedWeaponClasses(12)=Class'XWeapons.SuperShockRifle'
     ReplacedWeaponPickupClasses(0)=Class'XWeapons.ShockRiflePickup'
     ReplacedWeaponPickupClasses(1)=Class'XWeapons.LinkGunPickup'
     ReplacedWeaponPickupClasses(2)=Class'XWeapons.MinigunPickup'
     ReplacedWeaponPickupClasses(3)=Class'XWeapons.FlakCannonPickup'
     ReplacedWeaponPickupClasses(4)=Class'XWeapons.RocketLauncherPickup'
     ReplacedWeaponPickupClasses(5)=Class'XWeapons.SniperRiflePickup'
     ReplacedWeaponPickupClasses(6)=Class'XWeapons.BioRiflePickup'
     ReplacedWeaponPickupClasses(7)=Class'XWeapons.AssaultRiflePickup'
     ReplacedWeaponPickupClasses(8)=Class'UTClassic.ClassicSniperRiflePickup'
     ReplacedWeaponPickupClasses(9)=Class'Onslaught.ONSAVRiLPickup'
     ReplacedWeaponPickupClasses(10)=Class'Onslaught.ONSMineLayerPickup'
     ReplacedWeaponPickupClasses(11)=Class'Onslaught.ONSGrenadePickup'
     ReplacedWeaponPickupClasses(12)=Class'XWeapons.SuperShockRiflePickup'

     // replaced NewNet classes
     WeaponClasses(0)=Class'NewNet_ShockRifle'
     WeaponClasses(1)=Class'NewNet_LinkGun'
     WeaponClasses(2)=Class'NewNet_MiniGun'
     WeaponClasses(3)=Class'NewNet_FlakCannon'
     WeaponClasses(4)=Class'NewNet_RocketLauncher'
     WeaponClasses(5)=Class'NewNet_SniperRifle'
     WeaponClasses(6)=Class'NewNet_BioRifle'
     WeaponClasses(7)=Class'NewNet_AssaultRifle'
     WeaponClasses(8)=Class'NewNet_ClassicSniperRifle'
     WeaponClasses(9)=Class'NewNet_ONSAVRiL'
     WeaponClasses(10)=Class'NewNet_ONSMineLayer'
     WeaponClasses(11)=Class'NewNet_ONSGrenadeLauncher'
     WeaponClasses(12)=Class'NewNet_SuperShockRifle'
     WeaponPickupClasses(0)=Class'NewNet_ShockRiflePickup'
     WeaponPickupClasses(1)=Class'NewNet_LinkGunPickup'
     WeaponPickupClasses(2)=Class'NewNet_MiniGunPickup'
     WeaponPickupClasses(3)=Class'NewNet_FlakCannonPickup'
     WeaponPickupClasses(4)=Class'NewNet_RocketLauncherPickup'
     WeaponPickupClasses(5)=Class'NewNet_SniperRiflePickup'
     WeaponPickupClasses(6)=Class'NewNet_BioRiflePickup'
     WeaponPickupClasses(7)=Class'NewNet_AssaultRiflePickup'
     WeaponPickupClasses(8)=Class'NewNet_ClassicSniperRiflePickup'
     WeaponPickupClasses(9)=Class'NewNet_ONSAVRiLPickup'
     WeaponPickupClasses(10)=Class'NewNet_ONSMineLayerPickup'
     WeaponPickupClasses(11)=Class'NewNet_ONSGrenadePickup'
     WeaponPickupClasses(12)=Class'NewNet_SuperShockRiflePickup'
     WeaponPickupClassNames(0)="WSUTComp.NewNet_ShockRiflePickup"
     WeaponPickupClassNames(1)="WSUTComp.NewNet_LinkGunPickup"
     WeaponPickupClassNames(2)="WSUTComp.NewNet_MiniGunPickup"
     WeaponPickupClassNames(3)="WSUTComp.NewNet_FlakCannonPickup"
     WeaponPickupClassNames(4)="WSUTComp.NewNet_RocketLauncherPickup"
     WeaponPickupClassNames(5)="WSUTComp.NewNet_SniperRiflePickup"
     WeaponPickupClassNames(6)="WSUTComp.NewNet_BioRiflePickup"
     WeaponPickupClassNames(7)="WSUTComp.NewNet_AssaultRiflePickup"
     WeaponPickupClassNames(8)="WSUTComp.NewNet_ClassicSniperRiflePickup"
     WeaponPickupClassNames(9)="WSUTComp.NewNet_ONSAVRiLPickup"
     WeaponPickupClassNames(10)="WSUTComp.NewNet_ONSMineLayerPickup"
     WeaponPickupClassNames(11)="WSUTComp.NewNet_ONSGrenadePickup"
     WeaponPickupClassNames(12)="WSUTComp.NewNet_SuperShockRiflePickup"

    // replaced UTComp classes
     WeaponClassesUTComp(0)=Class'UTComp_ShockRifle'
     WeaponClassesUTComp(1)=Class'UTComp_LinkGun'
     WeaponClassesUTComp(2)=Class'UTComp_MiniGun'
     WeaponClassesUTComp(3)=Class'UTComp_FlakCannon'
     WeaponClassesUTComp(4)=Class'UTComp_RocketLauncher'
     WeaponClassesUTComp(5)=Class'UTComp_SniperRifle'
     WeaponClassesUTComp(6)=Class'UTComp_BioRifle'
     WeaponClassesUTComp(7)=Class'UTComp_AssaultRifle'
     WeaponClassesUTComp(8)=Class'UTComp_ClassicSniperRifle'
     WeaponClassesUTComp(9)=Class'UTComp_ONSAVRiL'
     WeaponClassesUTComp(10)=Class'UTComp_ONSMineLayer'
     WeaponClassesUTComp(11)=Class'UTComp_ONSGrenadeLauncher'
     WeaponClassesUTComp(12)=Class'UTComp_SuperShockRifle'
     WeaponPickupClassesUTComp(0)=Class'UTComp_ShockRiflePickup'
     WeaponPickupClassesUTComp(1)=Class'UTComp_LinkGunPickup'
     WeaponPickupClassesUTComp(2)=Class'UTComp_MiniGunPickup'
     WeaponPickupClassesUTComp(3)=Class'UTComp_FlakCannonPickup'
     WeaponPickupClassesUTComp(4)=Class'UTComp_RocketLauncherPickup'
     WeaponPickupClassesUTComp(5)=Class'UTComp_SniperRiflePickup'
     WeaponPickupClassesUTComp(6)=Class'UTComp_BioRiflePickup'
     WeaponPickupClassesUTComp(7)=Class'UTComp_AssaultRiflePickup'
     WeaponPickupClassesUTComp(8)=Class'UTComp_ClassicSniperRiflePickup'
     WeaponPickupClassesUTComp(9)=Class'UTComp_ONSAVRiLPickup'
     WeaponPickupClassesUTComp(10)=Class'UTComp_ONSMineLayerPickup'
     WeaponPickupClassesUTComp(11)=Class'UTComp_ONSGrenadePickup'
     WeaponPickupClassesUTComp(12)=Class'UTComp_SuperShockRiflePickup'
     WeaponPickupClassNamesUTComp(0)="WSUTComp.UTComp_ShockRiflePickup"
     WeaponPickupClassNamesUTComp(1)="WSUTComp.UTComp_LinkGunPickup"
     WeaponPickupClassNamesUTComp(2)="WSUTComp.UTComp_MiniGunPickup"
     WeaponPickupClassNamesUTComp(3)="WSUTComp.UTComp_FlakCannonPickup"
     WeaponPickupClassNamesUTComp(4)="WSUTComp.UTComp_RocketLauncherPickup"
     WeaponPickupClassNamesUTComp(5)="WSUTComp.UTComp_SniperRiflePickup"
     WeaponPickupClassNamesUTComp(6)="WSUTComp.UTComp_BioRiflePickup"
     WeaponPickupClassNamesUTComp(7)="WSUTComp.UTComp_AssaultRiflePickup"
     WeaponPickupClassNamesUTComp(8)="WSUTComp.UTComp_ClassicSniperRiflePickup"
     WeaponPickupClassNamesUTComp(9)="WSUTComp.UTComp_ONSAVRiLPickup"
     WeaponPickupClassNamesUTComp(10)="WSUTComp.UTComp_ONSMineLayerPickup"
     WeaponPickupClassNamesUTComp(11)="WSUTComp.UTComp_ONSGrenadePickup"
     WeaponPickupClassNamesUTComp(12)="WSUTComp.UTComp_SuperShockRiflePickup"

     bShieldFix=true

     bAllowRestartVoteEvenIfMapVotingIsTurnedOff=false

     CapBonus = 5
     FlagKillBonus = 3
     CoverBonus = 4
     SealBonus = 4
     GrabBonus = 0
     MinimalCapBonus = 5
     BaseReturnBonus = 0.500000
     MidReturnBonus = 2.000000
     EnemyBaseReturnBonus = 5.000000
     CloseSaveReturnBonus = 10.000000


     CoverMsgType = 3
     CoverSpreeMsgType = 3
     SealMsgType = 3
     SavedMsgType = 3

     bShowSealRewardConsoleMsg = true
     bShowAssistConsoleMsg = true

     bSilentAdmin=true
     bEnableWhitelist=false
     bUseWhitelist=false
     WhitelistBanMessage="Not allowed.  Contact the server administrator to gain access"
     bUseDefaultScoreboardColor=false

     SuicideInterval = 3

     IgnoredHitSounds(0)="FireKill"

     bAllowColorWeapons=true
     bDamageIndicator=true

     bEnableEmoticons=true
     bFastWeaponSwitch=true
     bChargedWeaponsNoSpawnProtection=false

     bKeepMomentumOnLanding=true
     MaxSavedMoves=300
     NetMoveDelta=0.011
     MaxResponseTime=0.125000
     bMoveErrorAccumFix=false
     MoveErrorAccumFixValue=0.009

     bLimitTaunts=false
     TauntCount=10

     bUseUTCompStats=true
}
