class TeamColorShockProjectile extends ShockProjectile;


var int TeamNum;
var bool bColorSet;
var UTComp_Settings Settings;

replication
{
    unreliable if(Role == Role_Authority)
       TeamNum;
}

simulated function bool CanUseColors()
{
   local UTComp_ServerReplicationInfo RepInfo;

    RepInfo = class'UTComp_Util'.static.GetServerReplicationInfo(Instigator);
    if(RepInfo != None)
        return RepInfo.bAllowColorWeapons;

    return false;
}

function SetupTeam()
{
    if(Instigator != None && Instigator.Controller != None)
    {
        TeamNum=class'TeamColorManager'.static.GetTeamNum(Instigator.Controller, Level);
    }
}

simulated function PostBeginPlay()
{
    super(Projectile).PostBeginPlay();

    if ( Level.NetMode != NM_DedicatedServer)
	{
        ShockBallEffect = Spawn(class'TeamColorShockBall', self);
        ShockBallEffect.SetBase(self);
	}

	Velocity = Speed * Vector(Rotation); // starts off slower so combo can be done closer

    SetTimer(0.4, false);
    tempStartLoc = Location;

    SetupTeam();
}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();

    if(Level.NetMode == NM_DedicatedServer)
        return;

    Settings = BS_xPlayer(Level.GetLocalPlayerController()).Settings;

    SetupTeam();
    SetColors();
}

// get replicated team number from owner projectile and set texture
simulated function SetColors()
{
    local Color color;
    
    if(Level.NetMode == NM_DedicatedServer)
        return;

    if(Settings.bTeamColorShock && !bColorSet)
    {
        if(CanUseColors())
        {
            if(TeamNum == 0 || TeamNum == 1)
            {
                color = class'TeamColorManager'.static.GetColor(TeamNum, Level.GetLocalPlayerController());
                LightHue = class'TeamColorManager'.static.GetHue(color);

                //when using team colors, we simulate this texture using the TeamColorShockBall emitter
                //so we can color it
                Texture=None;
                Skins[0]=None;

                bColorSet=true;
            }
        }
    }
}

simulated function Tick(float DT)
{
    super.Tick(DT);
    SetColors();
}

defaultproperties
{
    TeamNum=255
    bColorSet=false
}