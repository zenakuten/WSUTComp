class TeamColorShockComboCore extends ShockComboCore;

var int TeamNum;
var bool bColorSet;

var Material TeamColorMaterial;
var ColorModifier Alpha;
var bool bAlphaSet;
var UTComp_Settings Settings;

simulated function bool CanUseColors()
{
   local UTComp_ServerReplicationInfo RepInfo;

    RepInfo = class'UTComp_Util'.static.GetServerReplicationInfo(Instigator);
    if(RepInfo != None)
        return RepInfo.bAllowColorWeapons;

    return false;
}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();

    if(Level.NetMode == NM_DedicatedServer)
        return;

    Settings = BS_xPlayer(Level.GetLocalPlayerController()).Settings;

    if(Settings.bTeamColorShock && CanUseColors())
    {
        Alpha = ColorModifier(Level.ObjectPool.AllocateObject(class'ColorModifier'));
        Alpha.Material = TeamColorMaterial;
        Alpha.AlphaBlend = true;
        Alpha.RenderTwoSided = true;
        Alpha.Color.A = 255;
        Skins[0] = Alpha;
        bAlphaSet=true;
    }
}


function SetColors()
{
    local Color color;
    if(TeamNum == 255)
        return;

    if(bColorSet)
        return;

    if(Level.NetMode != NM_DedicatedServer)
    {
        if(Settings.bTeamColorShock && !bColorSet)
        {
            if(CanUseColors())
            {
                if(TeamNum == 0 || TeamNum == 1)
                {
                    LightBrightness=210;
                    color = class'TeamColorManager'.static.GetColor(TeamNum, Level.GetLocalPlayerController());
                    LightHue = class'TeamColorManager'.static.GetHue(color);

                    Alpha.Color.R = color.R;
                    Alpha.Color.G = color.G;
                    Alpha.Color.B = color.B;
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

simulated function Destroyed()
{
	if ( bAlphaSet )
	{
		Level.ObjectPool.FreeObject(Skins[0]);
		Skins[0] = None;
	}

	super.Destroyed();
}


defaultproperties
{
    TeamColorMaterial=Texture'Shock_core_white'
    TeamNum=255
    bColorSet=false
}