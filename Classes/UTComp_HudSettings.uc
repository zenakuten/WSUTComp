class UTComp_HUDSettings extends Object
    Config(WSUTComp)
    PerObjectConfig;

struct SpecialCrosshair
{
    var texture CrossTex;
    var float CrossScale;
    var color CrossColor;
    var float OffsetX;
    var float OffsetY;
};

var config array<SpecialCrosshair> UTCompCrosshairs;
var config bool bEnableUTCompCrosshairs;
var config bool bEnableCrosshairSizing;
var config bool bEnableWidescreenFix;
var config int DamageIndicatorType; // 1 = Disabled, 2 = Centered, 3 = Floating

var config bool bMatchHudColor;

var SpecialCrosshair TempxHair;

var config bool bEnableEmoticons;
var config bool bEnableMapTeamRadar;
var config bool bEnableTeamRadar;
var config Color TeamRadarPlayer;
var config Color TeamRadarVehicle;

defaultproperties
{
    bEnableCrosshairSizing=True
    bEnableWidescreenFix=False
    DamageIndicatorType=2
    bEnableEmoticons=True
    bEnableMapTeamRadar=True
    bEnableTeamRadar=False
    TeamRadarPlayer=(R=0,G=255,B=0,A=255)
    TeamRadarVehicle=(R=255,G=0,B=255,A=255)
}
