class UTComp_Menu_HUD extends UTComp_Menu_MainMenu;

var automated wsCheckBox ch_EnableMapTeamRadar;
var automated wsCheckBox ch_EnableTeamRadar;
var automated GUILabel radar, radarVehicle, radarR, radarG, radarB, radarA, radarVehicleR, radarVehicleG, radarVehicleB, radarVehicleA;
var automated GUISlider radarRSlide, radarGSlide, radarBSlide, radarASlide, radarVehicleRSlide, radarVehicleGSlide, radarVehicleBSlide, radarVehicleASlide;
var automated GUILabel radarMapScaleLabel, radarMapAlphaLabel, radarMapXLabel, radarMapYLabel;
var automated GUISlider radarMapScaleSlide, radarMapAlphaSlide, radarMapXSlide, radarMapYSlide;

function InitComponent(GUIController MyController, GUIComponent MyComponent)
{
    super.InitComponent(MyController, MyComponent);

    ch_EnableMapTeamRadar.Checked(HUDSettings.bEnableMapTeamRadar);
    ch_EnableTeamRadar.Checked(HUDSettings.bEnableTeamRadar);
    MatchSlidersToColors();
    MatchTextToSliders();

    if(!CanUseTeamRadar())
    {
        ch_EnableTeamRadar.DisableMe();
        ch_EnableTeamRadar.SetHint("Server disabled");
        radar.Hide(); 
        radarVehicle.Hide(); 
        radarR.Hide();
        radarG.Hide();
        radarB.Hide();
        radarA.Hide();
        radarVehicleR.Hide();
        radarVehicleG.Hide();
        radarVehicleB.Hide();
        radarVehicleA.Hide();
        radarRSlide.Hide();
        radarGSlide.Hide();
        radarBSlide.Hide();
        radarASlide.Hide();
        radarVehicleRSlide.Hide();
        radarVehicleGSlide.Hide();
        radarVehicleBSlide.Hide();
        radarVehicleASlide.Hide();
    }

    if(!CanUseTeamRadarMap())
    {
        ch_EnableMapTeamRadar.DisableMe();
        ch_EnableMapTeamRadar.SetHint("Server disabled");
        radarMapScaleLabel.Hide();
        radarMapScaleSlide.Hide();
        radarMapAlphaLabel.Hide();
        radarMapAlphaSlide.Hide();
        radarMapXLabel.Hide();
        radarMapXSlide.Hide();
        radarMapYLabel.Hide();
        radarMapYSlide.Hide();
    }
}

simulated function bool CanUseTeamRadar()
{
    local UTComp_ServerReplicationInfo RepInfo;

    RepInfo = BS_xPlayer(PlayerOwner()).RepInfo;
    if(RepInfo != None)
        return RepInfo.bAllowTeamRadar;

    return false;
}

simulated function bool CanUseTeamRadarMap()
{
    local UTComp_ServerReplicationInfo RepInfo;

    RepInfo = BS_xPlayer(PlayerOwner()).RepInfo;
    if(RepInfo != None)
        return RepInfo.bAllowTeamRadarMap;

    return false;
}

function InternalOnChange( GUIComponent C )
{
    switch(C)
    {
        case ch_EnableMapTeamRadar: HUDSettings.bEnableMapTeamRadar=ch_EnableMapTeamRadar.IsChecked(); 
            break;

        case ch_EnableTeamRadar: HUDSettings.bEnableTeamRadar=ch_EnableTeamRadar.IsChecked(); 
            break;

        case radarRSlide: HUDSettings.TeamRadarPlayer.R = radarRSlide.Value;
            MatchTextToSliders();
            break;

        case radarGSlide: HUDSettings.TeamRadarPlayer.G = radarGSlide.Value;
            MatchTextToSliders();
            break;

        case radarBSlide: HUDSettings.TeamRadarPlayer.B = radarBSlide.Value;
            MatchTextToSliders();
            break;

        case radarASlide: HUDSettings.TeamRadarPlayer.A = radarASlide.Value;
            MatchTextToSliders();
            break;

        case radarVehicleRSlide: HUDSettings.TeamRadarVehicle.R = radarVehicleRSlide.Value;
            MatchTextToSliders();
            break;

        case radarVehicleGSlide: HUDSettings.TeamRadarVehicle.G = radarVehicleGSlide.Value;
            MatchTextToSliders();
            break;

        case radarVehicleBSlide: HUDSettings.TeamRadarVehicle.B = radarVehicleBSlide.Value;
            MatchTextToSliders();
            break;

        case radarVehicleASlide: HUDSettings.TeamRadarVehicle.A = radarVehicleASlide.Value;
            MatchTextToSliders();
            break;

        case radarMapScaleSlide: HUDSettings.MapTeamRadarScale = radarMapScaleSlide.Value;
            break;

        case radarMapAlphaSlide: HUDSettings.MapTeamRadarAlpha = radarMapAlphaSlide.Value;
            break;

        case radarMapXSlide: HUDSettings.MapTeamRadarX = radarMapXSlide.Value;
            break;

        case radarMapYSlide: HUDSettings.MapTeamRadarY = radarMapYSlide.Value;
            break;
    }

    SaveSettings();
    SaveHUDSettings();
}

function MatchSlidersToColors()
{
    radarRSlide.Value = HUDSettings.TeamRadarPlayer.R;
    radarGSlide.Value = HUDSettings.TeamRadarPlayer.G;
    radarBSlide.Value = HUDSettings.TeamRadarPlayer.B;
    radarASlide.Value = HUDSettings.TeamRadarPlayer.B;

    radarVehicleRSlide.Value = HUDSettings.TeamRadarVehicle.R;
    radarVehicleGSlide.Value = HUDSettings.TeamRadarVehicle.G;
    radarVehicleBSlide.Value = HUDSettings.TeamRadarVehicle.B;
    radarVehicleASlide.Value = HUDSettings.TeamRadarVehicle.B;

    radarMapScaleSlide.Value = HUDSettings.MapTeamRadarScale;
    radarMapAlphaSlide.Value = HUDSettings.MapTeamRadarAlpha;
    radarMapXSlide.Value = HUDSettings.MapTeamRadarX;
    radarMapYSlide.Value = HUDSettings.MapTeamRadarY;
}

function MatchTextToSliders()
{
    radar.TextColor = HUDSettings.TeamRadarPlayer;
    radarVehicle.TextColor = HUDSettings.TeamRadarVehicle;
}

defaultproperties
{
    Begin Object Class=wsCheckBox Name=EnableMapTeamRadarCheck
        Caption="Show teammates on the HUD or minimap"
        Hint="Show teammates as a dot on the HUD or minimap"
        OnCreateComponent=EnableMapTeamRadarCheck.InternalOnCreateComponent
        WinWidth=0.500000
        WinHeight=0.030000
        WinLeft=0.250000
        WinTop=0.300000
        OnChange=UTComp_Menu_HUD.InternalOnChange
    End Object
    ch_EnableMapTeamRadar=wsCheckBox'UTComp_Menu_HUD.EnableMapTeamRadarCheck'

    Begin Object Class=wsCheckBox Name=EnableTeamRadarCheck
        Caption="Show teammates through walls"
        Hint="Allows seeing teammates through walls"
        OnCreateComponent=EnableTeamRadarCheck.InternalOnCreateComponent
        WinWidth=0.500000
        WinHeight=0.030000
        WinLeft=0.250000
        WinTop=0.35
        OnChange=UTComp_Menu_HUD.InternalOnChange
    End Object
    ch_EnableTeamRadar=wsCheckBox'UTComp_Menu_HUD.EnableTeamRadarCheck'

    Begin Object Class=GUILabel Name=radarMapScaleSliderLabel
        Caption="Radar Scale"
        TextColor=(R=255,G=255,B=255)
        WinTop=0.40
        WinLeft=0.25
        WinHeight=20.000000
    End Object
    radarMapScaleLabel=GUILabel'UTComp_Menu_HUD.radarMapScaleSliderLabel'

    Begin Object Class=wsGUISlider Name=RadarMapScaleSlider
        bIntSlider=False
        WinTop=0.39500
        WinLeft=0.40000
        WinWidth=0.35000
        OnClick=RadarMapScaleSlider.InternalOnClick
        OnMousePressed=RadarMapScaleSlider.InternalOnMousePressed
        OnMouseRelease=RadarMapScaleSlider.InternalOnMouseRelease
        OnChange=UTComp_Menu_HUD.InternalOnChange
        OnKeyEvent=RadarMapScaleSlider.InternalOnKeyEvent
        OnCapturedMouseMove=RadarMapScaleSlider.InternalCapturedMouseMove
        MaxValue=2.0
    End Object
    radarMapScaleSlide=wsGUISlider'UTComp_Menu_HUD.RadarMapScaleSlider'

    Begin Object Class=GUILabel Name=radarMapAlphaSliderLabel
        Caption="Radar Alpha"
        TextColor=(R=255,G=255,B=255)
        WinTop=0.45
        WinLeft=0.25
        WinHeight=20.000000
    End Object
    radarMapAlphaLabel=GUILabel'UTComp_Menu_HUD.radarMapAlphaSliderLabel'

    Begin Object Class=wsGUISlider Name=RadarMapAlphaSlider
        bIntSlider=True
        WinTop=0.44500
        WinLeft=0.40000
        WinWidth=0.35000
        OnClick=RadarMapAlphaSlider.InternalOnClick
        OnMousePressed=RadarMapAlphaSlider.InternalOnMousePressed
        OnMouseRelease=RadarMapAlphaSlider.InternalOnMouseRelease
        OnChange=UTComp_Menu_HUD.InternalOnChange
        OnKeyEvent=RadarMapAlphaSlider.InternalOnKeyEvent
        OnCapturedMouseMove=RadarMapAlphaSlider.InternalCapturedMouseMove
        MaxValue=255
    End Object
    radarMapAlphaSlide=wsGUISlider'UTComp_Menu_HUD.RadarMapAlphaSlider'

    Begin Object Class=GUILabel Name=radarMapXSliderLabel
        Caption="Radar X"
        TextColor=(R=255,G=255,B=255)
        WinTop=0.50
        WinLeft=0.25
        WinHeight=20.000000
    End Object
    radarMapXLabel=GUILabel'UTComp_Menu_HUD.radarMapXSliderLabel'

    Begin Object Class=wsGUISlider Name=RadarMapXSlider
        bIntSlider=false
        WinTop=0.49500
        WinLeft=0.40000
        WinWidth=0.35000
        OnClick=RadarMapXSlider.InternalOnClick
        OnMousePressed=RadarMapXSlider.InternalOnMousePressed
        OnMouseRelease=RadarMapXSlider.InternalOnMouseRelease
        OnChange=UTComp_Menu_HUD.InternalOnChange
        OnKeyEvent=RadarMapXSlider.InternalOnKeyEvent
        OnCapturedMouseMove=RadarMapXSlider.InternalCapturedMouseMove
        MaxValue=1.0
    End Object
    radarMapXSlide=wsGUISlider'UTComp_Menu_HUD.RadarMapXSlider'

    Begin Object Class=GUILabel Name=radarMapYSliderLabel
        Caption="Radar Y"
        TextColor=(R=255,G=255,B=255)
        WinTop=0.55
        WinLeft=0.25
        WinHeight=20.000000
    End Object
    radarMapYLabel=GUILabel'UTComp_Menu_HUD.radarMapYSliderLabel'

    Begin Object Class=wsGUISlider Name=RadarMapYSlider
        bIntSlider=false
        WinTop=0.54500
        WinLeft=0.40000
        WinWidth=0.35000
        OnClick=RadarMapYSlider.InternalOnClick
        OnMousePressed=RadarMapYSlider.InternalOnMousePressed
        OnMouseRelease=RadarMapYSlider.InternalOnMouseRelease
        OnChange=UTComp_Menu_HUD.InternalOnChange
        OnKeyEvent=RadarMapYSlider.InternalOnKeyEvent
        OnCapturedMouseMove=RadarMapYSlider.InternalCapturedMouseMove
        MaxValue=1.0
    End Object
    radarMapYSlide=wsGUISlider'UTComp_Menu_HUD.RadarMapYSlider'

    /////////////////////

     Begin Object Class=wsGUISlider Name=RedRSlider
         bIntSlider=True
         WinTop=0.6250000
         WinLeft=0.120000
         WinWidth=0.260000
         OnClick=RedRSlider.InternalOnClick
         OnMousePressed=RedRSlider.InternalOnMousePressed
         OnMouseRelease=RedRSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_HUD.InternalOnChange
         OnKeyEvent=RedRSlider.InternalOnKeyEvent
         OnCapturedMouseMove=RedRSlider.InternalCapturedMouseMove
         MaxValue=255
     End Object
     radarRSlide=wsGUISlider'UTComp_Menu_HUD.RedRSlider'

     Begin Object Class=wsGUISlider Name=RedGSlider
         bIntSlider=True
         WinTop=0.6750000
         WinLeft=0.120000
         WinWidth=0.260000
         OnClick=RedGSlider.InternalOnClick
         OnMousePressed=RedGSlider.InternalOnMousePressed
         OnMouseRelease=RedGSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_HUD.InternalOnChange
         OnKeyEvent=RedGSlider.InternalOnKeyEvent
         OnCapturedMouseMove=RedGSlider.InternalCapturedMouseMove
         MaxValue=255
     End Object
     radarGSlide=wsGUISlider'UTComp_Menu_HUD.RedGSlider'

     Begin Object Class=wsGUISlider Name=RedBSlider
         bIntSlider=True
         WinTop=0.7250000
         WinLeft=0.120000
         WinWidth=0.260000
         OnClick=RedBSlider.InternalOnClick
         OnMousePressed=RedBSlider.InternalOnMousePressed
         OnMouseRelease=RedBSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_HUD.InternalOnChange
         OnKeyEvent=RedBSlider.InternalOnKeyEvent
         OnCapturedMouseMove=RedBSlider.InternalCapturedMouseMove
         MaxValue=255
     End Object
     radarBSlide=wsGUISlider'UTComp_Menu_HUD.RedBSlider'

     Begin Object Class=wsGUISlider Name=RedASlider
         bIntSlider=True
         WinTop=0.7750000
         WinLeft=0.120000
         WinWidth=0.260000
         OnClick=RedASlider.InternalOnClick
         OnMousePressed=RedASlider.InternalOnMousePressed
         OnMouseRelease=RedASlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_HUD.InternalOnChange
         OnKeyEvent=RedBSlider.InternalOnKeyEvent
         OnCapturedMouseMove=RedASlider.InternalCapturedMouseMove
         MaxValue=255
     End Object
     radarASlide=wsGUISlider'UTComp_Menu_HUD.RedASlider'

     Begin Object Class=wsGUISlider Name=BlueRSlider
         bIntSlider=True
         WinTop=0.6250000
         WinLeft=0.5500000
         WinWidth=0.260000
         OnClick=BlueRSlider.InternalOnClick
         OnMousePressed=BlueRSlider.InternalOnMousePressed
         OnMouseRelease=BlueRSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_HUD.InternalOnChange
         OnKeyEvent=BlueRSlider.InternalOnKeyEvent
         OnCapturedMouseMove=BlueRSlider.InternalCapturedMouseMove
         MaxValue=255
     End Object
     radarVehicleRSlide=wsGUISlider'UTComp_Menu_HUD.BlueRSlider'

     Begin Object Class=wsGUISlider Name=BlueGSlider
         bIntSlider=True
         WinTop=0.6750000
         WinLeft=0.5500000
         WinWidth=0.260000
         OnClick=BlueGSlider.InternalOnClick
         OnMousePressed=BlueGSlider.InternalOnMousePressed
         OnMouseRelease=BlueGSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_HUD.InternalOnChange
         OnKeyEvent=BlueGSlider.InternalOnKeyEvent
         OnCapturedMouseMove=BlueGSlider.InternalCapturedMouseMove
         MaxValue=255
     End Object
     radarVehicleGSlide=wsGUISlider'UTComp_Menu_HUD.BlueGSlider'

     Begin Object Class=wsGUISlider Name=BlueBSlider
         bIntSlider=True
         WinTop=0.7250000
         WinLeft=0.550000
         WinWidth=0.260000
         OnClick=BlueBSlider.InternalOnClick
         OnMousePressed=BlueBSlider.InternalOnMousePressed
         OnMouseRelease=BlueBSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_HUD.InternalOnChange
         OnKeyEvent=BlueBSlider.InternalOnKeyEvent
         OnCapturedMouseMove=BlueBSlider.InternalCapturedMouseMove
         MaxValue=255
     End Object
     radarVehicleBSlide=wsGUISlider'UTComp_Menu_HUD.BlueBSlider'

     Begin Object Class=wsGUISlider Name=BlueASlider
         bIntSlider=True
         WinTop=0.7750000
         WinLeft=0.550000
         WinWidth=0.260000
         OnClick=BlueASlider.InternalOnClick
         OnMousePressed=BlueASlider.InternalOnMousePressed
         OnMouseRelease=BlueASlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_HUD.InternalOnChange
         OnKeyEvent=BlueASlider.InternalOnKeyEvent
         OnCapturedMouseMove=BlueASlider.InternalCapturedMouseMove
         MaxValue=255
     End Object
     radarVehicleASlide=wsGUISlider'UTComp_Menu_HUD.BlueASlider'

     Begin Object Class=GUILabel Name=radarLabel
         Caption="Through Wall Player Color"
         TextColor=(R=255,G=255,B=255)
         WinTop=0.6000000
         WinLeft=0.235000
         WinHeight=20.000000
     End Object
     radar=GUILabel'UTComp_Menu_HUD.radarLabel'

     Begin Object Class=GUILabel Name=radarVehicleLabel
         Caption="Through Wall Vehicle Color"
         TextColor=(R=255,G=255,B=255)
         WinTop=0.6000000
         WinLeft=0.650000
         WinHeight=20.000000
     End Object
     radarVehicle=GUILabel'UTComp_Menu_HUD.radarVehicleLabel'

     Begin Object Class=GUILabel Name=RedRLabel
         Caption="R"
         TextColor=(R=255)
         WinTop=0.6300000
         WinLeft=0.100000
         WinHeight=20.000000
     End Object
     radarR=GUILabel'UTComp_Menu_HUD.RedRLabel'

     Begin Object Class=GUILabel Name=RedGLabel
         Caption="G"
         TextColor=(G=255)
         WinTop=0.6800000
         WinLeft=0.100000
         WinHeight=20.000000
     End Object
     radarG=GUILabel'UTComp_Menu_HUD.RedGLabel'

     Begin Object Class=GUILabel Name=RedBLabel
         Caption="B"
         TextColor=(B=255)
         WinTop=0.730000
         WinLeft=0.100000
         WinHeight=20.000000
     End Object
     radarB=GUILabel'UTComp_Menu_HUD.RedBLabel'

     Begin Object Class=GUILabel Name=RedALabel
         Caption="A"
         TextColor=(R=255,G=255,B=255)
         WinTop=0.780000
         WinLeft=0.100000
         WinHeight=20.000000
     End Object
     radarA=GUILabel'UTComp_Menu_HUD.RedALabel'

     Begin Object Class=GUILabel Name=BlueRLabel
         Caption="R"
         TextColor=(R=255)
         WinTop=0.6300000
         WinLeft=0.53000
         WinHeight=20.000000
     End Object
     radarVehicleR=GUILabel'UTComp_Menu_HUD.BlueRLabel'

     Begin Object Class=GUILabel Name=BlueGLabel
         Caption="G"
         TextColor=(G=255)
         WinTop=0.6800000
         WinLeft=0.53000
         WinHeight=20.000000
     End Object
     radarVehicleG=GUILabel'UTComp_Menu_HUD.BlueGLabel'

     Begin Object Class=GUILabel Name=BlueBLabel
         Caption="B"
         TextColor=(B=255)
         WinTop=0.730000
         WinLeft=0.53000
         WinHeight=20.000000
     End Object
     radarVehicleB=GUILabel'UTComp_Menu_HUD.BlueBLabel'

     Begin Object Class=GUILabel Name=BlueALabel
         Caption="A"
         TextColor=(R=255,G=255,B=255)
         WinTop=0.780000
         WinLeft=0.53000
         WinHeight=20.000000
     End Object
     radarVehicleA=GUILabel'UTComp_Menu_HUD.BlueALabel'

}
