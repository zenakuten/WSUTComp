class UTComp_HUDSettings extends Object
    Config(UTCompOmni)
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

defaultproperties
{
    bEnableCrosshairSizing=True
    bEnableWidescreenFix=False
    DamageIndicatorType=1
}
