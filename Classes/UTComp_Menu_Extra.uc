
class UTComp_Menu_Extra extends UTComp_Menu_MainMenu;

var automated wsCheckBox ch_EnableWidescreenFix;
var automated wsComboBox co_DamageSelect;
var automated GUILabel lb_DamageSelect;
var automated wsCheckBox ch_EnableAwards;
var automated wsCheckBox ch_FastGhost;
var automated wsCheckBox ch_ColorGhost;
var automated GUILabel ghost, ghostFX, ghostR, ghostG, ghostB, ghostA, ghostFXR, ghostFXG, ghostFXB, ghostFXA;
var automated GUISlider ghostRSlide, ghostGSlide, ghostBSlide, ghostASlide, ghostFXRSlide, ghostFXGSlide, ghostFXBSlide, ghostFXASlide;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    local UTComp_ServerReplicationInfo RepInfo;

    super.InitComponent(MyController,MyOwner);

    ch_EnableWidescreenFix.Checked(HUDSettings.bEnableWidescreenFix);

    co_DamageSelect.AddItem("Disabled");
	co_DamageSelect.AddItem("Centered");
	co_DamageSelect.AddItem("Floating");
	co_DamageSelect.ReadOnly(True);
	co_DamageSelect.SetIndex(HUDSettings.DamageIndicatorType - 1);

    RepInfo = BS_xPlayer(PlayerOwner()).RepInfo;
    if(RepInfo != None && !RepInfo.bDamageIndicator)
    {
        co_DamageSelect.DisableMe();
        co_DamageSelect.SetHint("Server disabled");
    }

    ch_EnableAwards.Checked(Settings.bEnableAwards);
    ch_FastGhost.Checked(Settings.bFastGhost);
    ch_ColorGhost.Checked(Settings.bColorGhost);
    MatchSlidersToColors();
    MatchTextToSliders();
}

function InternalOnChange( GUIComponent C )
{
    switch(C)
    {
        case ch_EnableWidescreenFix: HUDSettings.bEnableWidescreenFix=ch_EnableWidescreenFix.IsChecked(); 
            break;

		case co_DamageSelect: HUDSettings.DamageIndicatorType = co_DamageSelect.GetIndex() + 1;
			break;

        case ch_EnableAwards: Settings.bEnableAwards=ch_EnableAwards.IsChecked(); 
            break;

        case ch_FastGhost: Settings.bFastGhost=ch_FastGhost.IsChecked(); 
            break;

        case ch_ColorGhost: Settings.bColorGhost=ch_ColorGhost.IsChecked(); 
            break;

        case GhostRSlide: Settings.DeResColor.R = GhostRSlide.Value;
            MatchTextToSliders();
            break;

        case GhostGSlide: Settings.DeResColor.G = GhostGSlide.Value;
            MatchTextToSliders();
            break;

        case GhostBSlide: Settings.DeResColor.B = GhostBSlide.Value;
            MatchTextToSliders();
            break;

        case GhostASlide: Settings.DeResColor.A = GhostASlide.Value;
            MatchTextToSliders();
            break;

        case GhostFXRSlide: Settings.DeResFXColor.R = GhostFXRSlide.Value;
            MatchTextToSliders();
            break;

        case GhostFXGSlide: Settings.DeResFXColor.G = GhostFXGSlide.Value;
            MatchTextToSliders();
            break;

        case GhostFXBSlide: Settings.DeResFXColor.B = GhostFXBSlide.Value;
            MatchTextToSliders();
            break;

        case GhostFXASlide: Settings.DeResFXColor.A = GhostFXASlide.Value;
            MatchTextToSliders();
            break;
    }

    SaveSettings();
    SaveHUDSettings();
}

function MatchSlidersToColors()
{
    GhostRSlide.Value = Settings.DeResColor.R;
    GhostGSlide.Value = Settings.DeResColor.G;
    GhostBSlide.Value = Settings.DeResColor.B;
    GhostASlide.Value = Settings.DeResColor.B;

    GhostFXRSlide.Value = Settings.DeResFXColor.R;
    GhostFXGSlide.Value = Settings.DeResFXColor.G;
    GhostFXBSlide.Value = Settings.DeResFXColor.B;
    GhostFXASlide.Value = Settings.DeResFXColor.B;
}

function MatchTextToSliders()
{
    ghost.TextColor = Settings.DeResColor;
    ghostFX.TextColor = Settings.DeResFXColor;
}

defaultproperties
{
    Begin Object Class=wsCheckBox Name=EnableWidescreenCheck
        Caption="Enable widescreen fixes"
        Hint="Use built-in Fox WSFix"
        OnCreateComponent=EnableWidescreenCheck.InternalOnCreateComponent
        WinWidth=0.500000
        WinHeight=0.030000
        WinLeft=0.250000
        WinTop=0.330000
        OnChange=UTComp_Menu_Extra.InternalOnChange
    End Object
    ch_EnableWidescreenFix=wsCheckBox'UTComp_Menu_Extra.EnableWidescreenCheck'

    Begin Object Class=wsComboBox Name=ComboDamageIndicatorType
         Caption="Damage Indicators:"
         OnCreateComponent=ComboDamageIndicatorType.InternalOnCreateComponent
         WinTop=0.380000
         WinLeft=0.250000
         WinWidth=0.500000
         OnChange=UTComp_Menu_Extra.InternalOnChange
     End Object
     co_DamageSelect=wsComboBox'UTComp_Menu_Extra.ComboDamageIndicatorType'

    Begin Object Class=wsCheckBox Name=EnableAwardsCheck
        Caption="Enable awards"
        Hint="Play sound for air rocket, impressive shock combo"
        OnCreateComponent=EnableAwardsCheck.InternalOnCreateComponent
        WinWidth=0.500000
        WinHeight=0.030000
        WinLeft=0.250000
        WinTop=0.43
        OnChange=UTComp_Menu_Extra.InternalOnChange
    End Object
    ch_EnableAwards=wsCheckBox'UTComp_Menu_Extra.EnableAwardsCheck'

    Begin Object Class=wsCheckBox Name=FastGhostCheck
        Caption="Fast ghost"
        Hint="Make dead players turn to ghost immediately"
        OnCreateComponent=FastGhostCheck.InternalOnCreateComponent
        WinWidth=0.500000
        WinHeight=0.030000
        WinLeft=0.250000
        WinTop=0.48
        OnChange=UTComp_Menu_Extra.InternalOnChange
    End Object
    ch_FastGhost=wsCheckBox'UTComp_Menu_Extra.FastGhostCheck'

    Begin Object Class=wsCheckBox Name=ColorGhostCheck
        Caption="Color ghost"
        Hint="Use configured ghost color"
        OnCreateComponent=ColorGhostCheck.InternalOnCreateComponent
        WinWidth=0.500000
        WinHeight=0.030000
        WinLeft=0.250000
        WinTop=0.53
        OnChange=UTComp_Menu_Extra.InternalOnChange
    End Object
    ch_ColorGhost=wsCheckBox'UTComp_Menu_Extra.ColorGhostCheck'

    /////////////////////

     Begin Object Class=wsGUISlider Name=RedRSlider
         bIntSlider=True
         WinTop=0.6250000
         WinLeft=0.120000
         WinWidth=0.260000
         OnClick=RedRSlider.InternalOnClick
         OnMousePressed=RedRSlider.InternalOnMousePressed
         OnMouseRelease=RedRSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_Extra.InternalOnChange
         OnKeyEvent=RedRSlider.InternalOnKeyEvent
         OnCapturedMouseMove=RedRSlider.InternalCapturedMouseMove
         MaxValue=255
     End Object
     ghostRSlide=wsGUISlider'UTComp_Menu_Extra.RedRSlider'

     Begin Object Class=wsGUISlider Name=RedGSlider
         bIntSlider=True
         WinTop=0.6750000
         WinLeft=0.120000
         WinWidth=0.260000
         OnClick=RedGSlider.InternalOnClick
         OnMousePressed=RedGSlider.InternalOnMousePressed
         OnMouseRelease=RedGSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_Extra.InternalOnChange
         OnKeyEvent=RedGSlider.InternalOnKeyEvent
         OnCapturedMouseMove=RedGSlider.InternalCapturedMouseMove
         MaxValue=255
     End Object
     ghostGSlide=wsGUISlider'UTComp_Menu_Extra.RedGSlider'

     Begin Object Class=wsGUISlider Name=RedBSlider
         bIntSlider=True
         WinTop=0.7250000
         WinLeft=0.120000
         WinWidth=0.260000
         OnClick=RedBSlider.InternalOnClick
         OnMousePressed=RedBSlider.InternalOnMousePressed
         OnMouseRelease=RedBSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_Extra.InternalOnChange
         OnKeyEvent=RedBSlider.InternalOnKeyEvent
         OnCapturedMouseMove=RedBSlider.InternalCapturedMouseMove
         MaxValue=255
     End Object
     ghostBSlide=wsGUISlider'UTComp_Menu_Extra.RedBSlider'

     Begin Object Class=wsGUISlider Name=RedASlider
         bIntSlider=True
         WinTop=0.7750000
         WinLeft=0.120000
         WinWidth=0.260000
         OnClick=RedASlider.InternalOnClick
         OnMousePressed=RedASlider.InternalOnMousePressed
         OnMouseRelease=RedASlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_Extra.InternalOnChange
         OnKeyEvent=RedBSlider.InternalOnKeyEvent
         OnCapturedMouseMove=RedASlider.InternalCapturedMouseMove
         MaxValue=255
     End Object
     ghostASlide=wsGUISlider'UTComp_Menu_Extra.RedASlider'

     Begin Object Class=wsGUISlider Name=BlueRSlider
         bIntSlider=True
         WinTop=0.6250000
         WinLeft=0.5500000
         WinWidth=0.260000
         OnClick=BlueRSlider.InternalOnClick
         OnMousePressed=BlueRSlider.InternalOnMousePressed
         OnMouseRelease=BlueRSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_Extra.InternalOnChange
         OnKeyEvent=BlueRSlider.InternalOnKeyEvent
         OnCapturedMouseMove=BlueRSlider.InternalCapturedMouseMove
         MaxValue=255
     End Object
     ghostFXRSlide=wsGUISlider'UTComp_Menu_Extra.BlueRSlider'

     Begin Object Class=wsGUISlider Name=BlueGSlider
         bIntSlider=True
         WinTop=0.6750000
         WinLeft=0.5500000
         WinWidth=0.260000
         OnClick=BlueGSlider.InternalOnClick
         OnMousePressed=BlueGSlider.InternalOnMousePressed
         OnMouseRelease=BlueGSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_Extra.InternalOnChange
         OnKeyEvent=BlueGSlider.InternalOnKeyEvent
         OnCapturedMouseMove=BlueGSlider.InternalCapturedMouseMove
         MaxValue=255
     End Object
     ghostFXGSlide=wsGUISlider'UTComp_Menu_Extra.BlueGSlider'

     Begin Object Class=wsGUISlider Name=BlueBSlider
         bIntSlider=True
         WinTop=0.7250000
         WinLeft=0.550000
         WinWidth=0.260000
         OnClick=BlueBSlider.InternalOnClick
         OnMousePressed=BlueBSlider.InternalOnMousePressed
         OnMouseRelease=BlueBSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_Extra.InternalOnChange
         OnKeyEvent=BlueBSlider.InternalOnKeyEvent
         OnCapturedMouseMove=BlueBSlider.InternalCapturedMouseMove
         MaxValue=255
     End Object
     ghostFXBSlide=wsGUISlider'UTComp_Menu_Extra.BlueBSlider'

     Begin Object Class=wsGUISlider Name=BlueASlider
         bIntSlider=True
         WinTop=0.7750000
         WinLeft=0.550000
         WinWidth=0.260000
         OnClick=BlueASlider.InternalOnClick
         OnMousePressed=BlueASlider.InternalOnMousePressed
         OnMouseRelease=BlueASlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_Extra.InternalOnChange
         OnKeyEvent=BlueASlider.InternalOnKeyEvent
         OnCapturedMouseMove=BlueASlider.InternalCapturedMouseMove
         MaxValue=255
     End Object
     ghostFXASlide=wsGUISlider'UTComp_Menu_Extra.BlueASlider'

     Begin Object Class=GUILabel Name=GhostLabel
         Caption="Ghost"
         TextColor=(R=255,G=255,B=255)
         WinTop=0.6000000
         WinLeft=0.235000
         WinHeight=20.000000
     End Object
     ghost=GUILabel'UTComp_Menu_Extra.GhostLabel'

     Begin Object Class=GUILabel Name=GhostFXLabel
         Caption="Ghost FX"
         TextColor=(R=255,G=255,B=255)
         WinTop=0.6000000
         WinLeft=0.650000
         WinHeight=20.000000
     End Object
     ghostFX=GUILabel'UTComp_Menu_Extra.GhostFXLabel'

     Begin Object Class=GUILabel Name=RedRLabel
         Caption="R"
         TextColor=(R=255)
         WinTop=0.6300000
         WinLeft=0.100000
         WinHeight=20.000000
     End Object
     ghostR=GUILabel'UTComp_Menu_Extra.RedRLabel'

     Begin Object Class=GUILabel Name=RedGLabel
         Caption="G"
         TextColor=(G=255)
         WinTop=0.6800000
         WinLeft=0.100000
         WinHeight=20.000000
     End Object
     ghostG=GUILabel'UTComp_Menu_Extra.RedGLabel'

     Begin Object Class=GUILabel Name=RedBLabel
         Caption="B"
         TextColor=(B=255)
         WinTop=0.730000
         WinLeft=0.100000
         WinHeight=20.000000
     End Object
     ghostB=GUILabel'UTComp_Menu_Extra.RedBLabel'

     Begin Object Class=GUILabel Name=RedALabel
         Caption="A"
         TextColor=(R=255,G=255,B=255)
         WinTop=0.780000
         WinLeft=0.100000
         WinHeight=20.000000
     End Object
     ghostA=GUILabel'UTComp_Menu_Extra.RedALabel'

     Begin Object Class=GUILabel Name=BlueRLabel
         Caption="R"
         TextColor=(R=255)
         WinTop=0.6300000
         WinLeft=0.53000
         WinHeight=20.000000
     End Object
     ghostFXR=GUILabel'UTComp_Menu_Extra.BlueRLabel'

     Begin Object Class=GUILabel Name=BlueGLabel
         Caption="G"
         TextColor=(G=255)
         WinTop=0.6800000
         WinLeft=0.53000
         WinHeight=20.000000
     End Object
     ghostFXG=GUILabel'UTComp_Menu_Extra.BlueGLabel'

     Begin Object Class=GUILabel Name=BlueBLabel
         Caption="B"
         TextColor=(B=255)
         WinTop=0.730000
         WinLeft=0.53000
         WinHeight=20.000000
     End Object
     ghostFXB=GUILabel'UTComp_Menu_Extra.BlueBLabel'

     Begin Object Class=GUILabel Name=BlueALabel
         Caption="A"
         TextColor=(R=255,G=255,B=255)
         WinTop=0.780000
         WinLeft=0.53000
         WinHeight=20.000000
     End Object
     ghostFXA=GUILabel'UTComp_Menu_Extra.BlueALabel'


}