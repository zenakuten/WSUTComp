class TeamColorFlakTrail extends FlakTrail;

var int TeamNum;
var bool bColorSet;

simulated function bool CanUseColors()
{
   local UTComp_ServerReplicationInfo RepInfo;

    RepInfo = class'UTComp_Util'.static.GetServerReplicationInfo(Level.GetLocalPlayerController());
    if(RepInfo != None)
        return RepInfo.bAllowColorWeapons;

    return false;
}

function SetColors()
{
    local Color color;
    local UTComp_Settings Settings;

    if(bColorSet)
        return;

    if(Level.NetMode != NM_DedicatedServer)
    {
        Settings = BS_xPlayer(Level.GetLocalPlayerController()).Settings;
        if(Settings.bTeamColorFlak)
        {
            if(CanUseColors())
            {
                if(TeamNum == 0 || TeamNum == 1)
                {
                    color = class'TeamColorManager'.static.GetColor(TeamNum, Level.GetLocalPlayerController());
                    LightHue = class'TeamColorManager'.static.GetHue(color);

                    mColorRange[0].R=color.R;
                    mColorRange[0].G=color.G;
                    mColorRange[0].B=color.B;

                    mColorRange[1].R=color.R;
                    mColorRange[1].G=color.G;
                    mColorRange[1].B=color.B;
                    bColorSet=true;
                }
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
}