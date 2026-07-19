

class UTComp_Menu_Miscellaneous extends UTComp_Menu_MainMenu;

var automated GUILabel l_ScoreboardTitle;
var automated GUILabel l_GenericTitle;
var automated GUILabel l_CrossScale;
var automated GUILabel l_NewNet;

var automated wsCheckBox ch_UseScoreBoard;
var automated wsCheckBox ch_ShowKills;
var automated wsCheckBox ch_WepStats;
var automated wsCheckBox ch_PickupStats;
var automated wsCheckBox ch_FootSteps;
var automated wsCheckBox ch_MatchHudColor;
var automated wsCheckBox ch_UseEyeHeightAlgo;
var automated wsCheckBox ch_UseNewNet;
var automated wsCheckBox ch_ViewSmoothing;

var automated wsEditBox eb_DPI;
var automated GUILabel l_Cm360;

var automated GUILabel l_Adren;
var automated wsCheckBox ch_Booster;
var automated wsCheckBox ch_Invis;
var automated wsCheckBox ch_Speed;
var automated wsCheckBox ch_Berserk;

var automated moComboBox co_CrosshairScale;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    local UTComp_ServerReplicationInfo RepInfo;
    super.InitComponent(MyController,MyOwner);

    foreach PlayerOwner().DynamicActors(Class'UTComp_ServerReplicationInfo', RepInfo)
        break;

    ch_UseScoreboard.Checked(!Settings.bUseDefaultScoreboard);
    ch_ShowKills.Checked(Settings.bShowKillsOnScoreboard);
    ch_WepStats.Checked(class'UTComp_Scoreboard'.default.bDrawStats);
    ch_PickupStats.Checked(class'UTComp_Scoreboard'.default.bDrawPickups);
    ch_FootSteps.Checked(class'UTComp_xPawn'.default.bPlayOwnFootSteps);
    ch_MatchHudColor.Checked(HUDSettings.bMatchHudColor);
    ch_UseEyeHeightAlgo.Checked(Settings.bUseNewEyeHeightAlgorithm);
    ch_UseNewNet.Checked(Settings.bEnableEnhancedNetCode);
    ch_ViewSmoothing.Checked(Settings.bViewSmoothing);

    eb_DPI.IntOnly(true);
    eb_DPI.SetComponentValue(string(Settings.MouseDPI), true);
    UpdateCm360();

    ch_Booster.Checked(!Settings.bDisableBooster);
    ch_Speed.Checked(!Settings.bDisableSpeed);
    ch_Berserk.Checked(!Settings.bDisableBerserk);
    ch_Invis.Checked(!Settings.bDisableInvis);

    if(RepInfo != None && !RepInfo.bEnableEnhancedNetCode)
    {
        ch_UseNewNet.bVisible=false;
        l_NewNet.Caption="Net Code (server disabled)";
    }
}

function InternalOnChange( GUIComponent C )
{
    switch(C)
    {
        case ch_UseScoreboard: Settings.bUseDefaultScoreboard=!ch_UseScoreBoard.IsChecked(); 
            if(Settings.bUseDefaultScoreboard)
            {
                class'UTComp_Scoreboard'.default.bDrawStats=false;
                ch_WepStats.Checked(class'UTComp_Scoreboard'.default.bDrawStats);
                BS_xPlayer(PlayerOwner()).SetBStats(class'UTComp_Scoreboard'.default.bDrawStats);
                class'UTComp_Scoreboard'.default.bDrawPickups=false;
                ch_PickupStats.Checked(class'UTComp_Scoreboard'.default.bDrawPickups);
            }
            BS_xPlayer(PlayerOwner()).InitializeScoreboard();
            break;
        case ch_ShowKills: Settings.bShowKillsOnScoreboard=ch_ShowKills.IsChecked(); break;
        case ch_WepStats:  class'UTComp_Scoreboard'.default.bDrawStats=ch_WepStats.IsChecked();
                           BS_xPlayer(PlayerOwner()).SetBStats(class'UTComp_Scoreboard'.default.bDrawStats);break;
        case ch_PickupStats:  class'UTComp_Scoreboard'.default.bDrawPickups=ch_PickupStats.IsChecked(); break;
        case ch_FootSteps: class'UTComp_xPawn'.default.bPlayOwnFootSteps=ch_FootSteps.IsChecked(); break;
        case ch_MatchHudColor:  HUDSettings.bMatchHudColor=ch_MatchHudColor.IsChecked(); break;
        case ch_UseEyeHeightAlgo:
            Settings.bUseNewEyeHeightAlgorithm=ch_UseEyeHeightAlgo.IsChecked();
            BS_xPlayer(PlayerOwner()).SetEyeHeightAlgorithm(ch_UseEyeHeightAlgo.IsChecked());
            break;
        case ch_UseNewNet:  Settings.bEnableEnhancedNetCode=ch_UseNewNet.IsChecked();
                            BS_xPlayer(PlayerOwner()).TurnOffNetCode(); break;
        case ch_ViewSmoothing:  Settings.bViewSmoothing=ch_ViewSmoothing.IsChecked();
            break;
        case eb_DPI:  Settings.MouseDPI=int(eb_DPI.GetText());
            UpdateCm360();
            break;
        case ch_Booster: Settings.bDisableBooster=!ch_Booster.IsChecked(); break;
        case ch_Invis:  Settings.bDisableInvis=!ch_Invis.IsChecked(); break;
        case ch_Speed:  Settings.bDisableSpeed=!ch_Speed.IsChecked(); break;
        case ch_Berserk: Settings.bDisableBerserk=!ch_Berserk.IsChecked(); break;
    }
    MarkConfigDirty(class'UTComp_Overlay');
    MarkConfigDirty(class'BS_xPlayer');
    SaveSettings();
    MarkConfigDirty(class'UTComp_Scoreboard');
    MarkConfigDirty(class'UTComp_xPawn');
    MarkConfigDirty(class'UTComp_HudCDeathMatch');
    SaveHUDSettings();
    BS_xPlayer(PlayerOwner()).MatchHudColor();

}

// Computes cm/360 (physical mouse distance to turn 360 degrees) from the player's
// current settings and the entered DPI, and updates the display label.
//
// Engine mouse->yaw chain (see Engine.PlayerInput / Engine.PlayerController and the
// native input scaling in UnIn.cpp), for a raw mouse movement of N device counts:
//   native:  aMouseX += 0.01 * N * Speed        (Speed = the MouseX "Axis" binding speed)
//   native:  aMouseX *= 20 / DeltaTime
//   script:  aMouseX *= MouseSensitivity * (FOV/90)    (smoothing off)
//   script:  aTurn   += aMouseX
//   script:  ViewRotation.Yaw += 32.0 * DeltaTime * aTurn    (DeltaTime cancels out)
//
//   Net: Yaw_per_count = 6.4 * Speed * Sensitivity * (FOV/90) URU   (65536 URU = 360 degrees)
//
// counts per 360 = 65536 / Yaw_per_count, and cm/360 = counts * 2.54 / DPI, so:
//   cm/360 = (65536 * 90 * 2.54) / (6.4 * DPI * Speed * Sensitivity * FOV)
//          = 2340864 / (DPI * Speed * Sensitivity * FOV)
//
// mouse-sensitivity.com assumes Speed = 2.0 (the default MouseX/MouseY binding speed);
// here we read the player's actual binding value instead.
function UpdateCm360()
{
    local string BindStr;
    local float Speed, Sens, FOV, DPI, Cm360;
    local int idx, whole, frac;
    local string FracStr;

    // Read the "Speed=" value from the player's MouseX axis binding.
    Speed = 2.0;
    BindStr = PlayerOwner().ConsoleCommand("KEYBINDING MouseX");
    idx = InStr(BindStr, "Speed=");
    if(idx != -1)
    {
        BindStr = Mid(BindStr, idx + 6);
        idx = InStr(BindStr, " ");
        if(idx != -1)
            BindStr = Left(BindStr, idx);
        idx = InStr(BindStr, "|");
        if(idx != -1)
            BindStr = Left(BindStr, idx);
        Speed = float(BindStr);
    }
    Speed = Abs(Speed);

    Sens = class'PlayerInput'.default.MouseSensitivity;
    // The engine scales mouse input by DesiredFOV (PlayerInput.PlayerInput:
    // FOVScale = DesiredFOV * 0.01111), which is the FOV the player is actually
    // using - not DefaultFOV, which can be a stale config value.
    FOV = PlayerOwner().DesiredFOV;
    DPI = Settings.MouseDPI;

    if(DPI > 0 && Speed > 0 && Sens > 0 && FOV > 0)
        Cm360 = 2340864.0 / (DPI * Speed * Sens * FOV);
    else
        Cm360 = 0.0;

    // Format Cm360 with two decimals (no printf in UnrealScript).
    whole = int(Cm360);
    frac = int((Cm360 - whole) * 100.0 + 0.5);
    if(frac >= 100)
    {
        whole += 1;
        frac -= 100;
    }
    FracStr = string(frac);
    if(frac < 10)
        FracStr = "0" $ FracStr;

    l_Cm360.Caption = "cm/360:" @ (whole $ "." $ FracStr);
}

function bool InternalOnClick(GUIComponent C)
{
    return super.InternalOnClick(C);
}

function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
    if (Key == 0x1B)
        return false;
    return true;
}

defaultproperties
{
    ActiveMenuButton=8

    Begin Object Class=GUILabel Name=ScoreboardLabel
        Caption="Scoreboard"
        TextColor=(B=255,G=255,R=0)
        WinWidth=1.000000
        WinHeight=0.060000
        WinLeft=0.200000
        WinTop=0.290000
    End Object
    l_ScoreboardTitle=GUILabel'ScoreboardLabel'

    Begin Object Class=wsCheckBox Name=ScoreboardCheck
        Caption="Use UTComp enhanced scoreboard."
        OnCreateComponent=ScoreboardCheck.InternalOnCreateComponent
        WinWidth=0.250000
        WinHeight=0.030000
        WinLeft=0.200000
        WinTop=0.330000
        OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
    End Object
    ch_UseScoreBoard=wsCheckBox'UTComp_Menu_Miscellaneous.ScoreboardCheck'

    Begin Object Class=wsCheckBox Name=StatsCheck
        Caption="Show weapon stats on scoreboard."
        OnCreateComponent=StatsCheck.InternalOnCreateComponent
        WinWidth=0.250000
        WinHeight=0.030000
        WinLeft=0.200000
        WinTop=0.370000
        OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
    End Object
    ch_WepStats=wsCheckBox'UTComp_Menu_Miscellaneous.StatsCheck'

    Begin Object Class=wsCheckBox Name=PickupCheck
        Caption="Show pickup stats on scoreboard."
        OnCreateComponent=PickupCheck.InternalOnCreateComponent
        WinWidth=0.250000
        WinHeight=0.030000
        WinLeft=0.200000
        WinTop=0.410000
        OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
    End Object
    ch_PickupStats=wsCheckBox'UTComp_Menu_Miscellaneous.PickupCheck'

    Begin Object Class=wsCheckBox Name=KillsCheck
        Caption="Show kills on scoreboard."
        OnCreateComponent=KillsCheck.InternalOnCreateComponent
        WinWidth=0.250000
        WinHeight=0.030000
        WinLeft=0.200000
        WinTop=0.450000
        OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
    End Object
    ch_ShowKills=wsCheckBox'UTComp_Menu_Miscellaneous.KillsCheck'

    Begin Object Class=GUILabel Name=AdrenLabel
        Caption="Adrenaline Combos"
        TextColor=(B=255,G=255,R=0)
        WinWidth=0.500000
        WinHeight=0.060000
        WinLeft=0.500000
        WinTop=0.290000
    End Object
    l_Adren=GUILabel'UTComp_Menu_Miscellaneous.AdrenLabel'

    Begin Object Class=wsCheckBox Name=BoosterCheck
        Caption="Enable Booster Combo"
        OnCreateComponent=BoosterCheck.InternalOnCreateComponent
        WinWidth=0.250000
        WinHeight=0.030000
        WinLeft=0.500000
        WinTop=0.330000
        OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
    End Object
    ch_Booster=wsCheckBox'UTComp_Menu_Miscellaneous.BoosterCheck'

    Begin Object Class=wsCheckBox Name=InvisCheck
        Caption="Enable Invisibility Combo"
        OnCreateComponent=InvisCheck.InternalOnCreateComponent
        WinWidth=0.250000
        WinHeight=0.030000
        WinLeft=0.500000
        WinTop=0.370000
        OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
    End Object
    ch_Invis=wsCheckBox'UTComp_Menu_Miscellaneous.InvisCheck'

    Begin Object Class=wsCheckBox Name=SpeedCheck
        Caption="Enable Speed Combo"
        OnCreateComponent=SpeedCheck.InternalOnCreateComponent
        WinWidth=0.250000
        WinHeight=0.030000
        WinLeft=0.500000
        WinTop=0.410000
        OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
    End Object
    ch_Speed=wsCheckBox'UTComp_Menu_Miscellaneous.SpeedCheck'

    Begin Object Class=wsCheckBox Name=BerserkCheck
        Caption="Enable Berserk Combo"
        OnCreateComponent=BerserkCheck.InternalOnCreateComponent
        WinWidth=0.250000
        WinHeight=0.030000
        WinLeft=0.500000
        WinTop=0.450000
        OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
    End Object
    ch_Berserk=wsCheckBox'UTComp_Menu_Miscellaneous.BerserkCheck'

    Begin Object Class=GUILabel Name=GenericLabel
        Caption="Generic UT2004 Settings"
        TextColor=(B=255,G=255,R=0)
        WinWidth=1.000000
        WinHeight=0.060000
        WinLeft=0.200000
        WinTop=0.530000
    End Object
    l_GenericTitle=GUILabel'UTComp_Menu_Miscellaneous.GenericLabel'

    Begin Object Class=wsCheckBox Name=FootCheck
        Caption="Play own footstep sounds."
        Hint="Weapon bob must be off!  Requires respawn for change to take effect"
        OnCreateComponent=FootCheck.InternalOnCreateComponent
        WinWidth=0.250000
        WinHeight=0.030000
        WinLeft=0.200000
        WinTop=0.570000
        OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
    End Object
    ch_FootSteps=wsCheckBox'UTComp_Menu_Miscellaneous.FootCheck'

    Begin Object Class=wsCheckBox Name=HudColorCheck
        Caption="Match Hud Color To Skins"
        OnCreateComponent=HudColorCheck.InternalOnCreateComponent
        WinWidth=0.250000
        WinHeight=0.030000
        WinLeft=0.200000
        WinTop=0.610000
        OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
    End Object
    ch_MatchHudColor=wsCheckBox'UTComp_Menu_Miscellaneous.HudColorCheck'

    Begin Object Class=wsCheckBox Name=UseEyeHeightAlgoCheck
        Caption="Use New EyeHeight Algorithm"
        Hint="You want this"
        OnCreateComponent=HudColorCheck.InternalOnCreateComponent
        WinWidth=0.250000
        WinHeight=0.030000
        WinLeft=0.200000
        WinTop=0.650000
        OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
    End Object
    ch_UseEyeHeightAlgo=wsCheckBox'UTComp_Menu_Miscellaneous.UseEyeHeightAlgoCheck'

    Begin Object Class=wsCheckBox Name=UseViewSmoothing
        Caption="Use view smoothing"
        Hint="Smooth the view when using new Eyeheight algorithm"
        OnCreateComponent=HudColorCheck.InternalOnCreateComponent
        WinWidth=0.250000
        WinHeight=0.030000
        WinLeft=0.200000
        WinTop=0.690000
        OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
    End Object
    ch_ViewSmoothing=wsCheckBox'UTComp_Menu_Miscellaneous.UseViewSmoothing'


    Begin Object Class=GUILabel Name=NewNetLabel
        Caption="Net Code"
        TextColor=(B=255,G=255,R=0)
        WinWidth=0.500000
        WinHeight=0.060000
        WinLeft=0.500000
        WinTop=0.530000
    End Object
    l_NewNet=GUILabel'NewNetLabel'

    Begin Object Class=wsCheckBox Name=NewNetCheck
        Caption="Enable Enhanced Netcode"
        OnCreateComponent=NewNetCheck.InternalOnCreateComponent
        WinWidth=0.250000
        WinHeight=0.030000
        WinLeft=0.500000
        WinTop=0.570000
        OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
    End Object
    ch_UseNewNet=wsCheckBox'UTComp_Menu_Miscellaneous.NewNetCheck'

    Begin Object Class=wsEditBox Name=DPIEditBox
        Caption="DPI for cm/360"
        Hint="Your mouse DPI - used only to display cm/360 below"
        CaptionWidth=0.550000
        bAutoSizeCaption=true
        WinWidth=0.250000
        WinHeight=0.030000
        WinLeft=0.500000
        WinTop=0.610000
        OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
    End Object
    eb_DPI=wsEditBox'UTComp_Menu_Miscellaneous.DPIEditBox'

    Begin Object Class=GUILabel Name=Cm360Label
        Caption="cm/360:"
        TextColor=(B=255,G=255,R=0)
        WinWidth=0.480000
        WinHeight=0.030000
        WinLeft=0.500000
        WinTop=0.650000
    End Object
    l_Cm360=GUILabel'UTComp_Menu_Miscellaneous.Cm360Label'
}
