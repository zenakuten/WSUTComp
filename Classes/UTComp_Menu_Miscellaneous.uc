

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
var automated wsCheckBox ch_ShockCrashFix;

var automated GUIButton bu_adren;

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
    ch_ShockCrashFix.Checked(Settings.bShockCrashFix);

    if(RepInfo != None && !RepInfo.bEnableEnhancedNetCode)
    {
        ch_UseNewNet.bVisible=false;
        l_NewNet.Caption="-----------Net Code (server disabled)----------";
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
        case ch_ShockCrashFix:  Settings.bShockCrashFix=ch_ShockCrashFix.IsChecked(); 
            break;
    }
    class'UTComp_Overlay'.static.StaticSaveConfig();
    class'BS_xPlayer'.static.StaticSaveConfig();
    SaveSettings();
    class'UTComp_Scoreboard'.static.StaticSaveConfig();
    class'UTComp_xPawn'.static.StaticSaveConfig();
    class'UTComp_HudCDeathMatch'.Static.StaticSaveConfig();
    SaveHUDSettings();
    BS_xPlayer(PlayerOwner()).MatchHudColor();

}

function bool InternalOnClick(GUIComponent C)
{
    switch(C)
    {
        case bu_Adren:  PlayerOwner().ClientReplaceMenu(string(class'UTComp_Menu_AdrenMenu')); break;
    }
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

    Begin Object Class=GUILabel Name=ScoreboardLabel
        Caption="----------Scoreboard----------"
        TextColor=(B=255,G=255,R=0)
        WinWidth=1.000000
        WinHeight=0.060000
        WinLeft=0.250000
        WinTop=0.290000
    End Object
    l_ScoreboardTitle=GUILabel'ScoreboardLabel'

    Begin Object Class=wsCheckBox Name=ScoreboardCheck
        Caption="Use UTComp enhanced scoreboard."
        OnCreateComponent=ScoreboardCheck.InternalOnCreateComponent
        WinWidth=0.500000
        WinHeight=0.030000
        WinLeft=0.250000
        WinTop=0.330000
        OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
    End Object
    ch_UseScoreBoard=wsCheckBox'UTComp_Menu_Miscellaneous.ScoreboardCheck'

    Begin Object Class=wsCheckBox Name=StatsCheck
        Caption="Show weapon stats on scoreboard."
        OnCreateComponent=StatsCheck.InternalOnCreateComponent
        WinLeft=0.250000
        WinTop=0.370000
        OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
    End Object
    ch_WepStats=wsCheckBox'UTComp_Menu_Miscellaneous.StatsCheck'

    Begin Object Class=wsCheckBox Name=PickupCheck
        Caption="Show pickup stats on scoreboard."
        OnCreateComponent=PickupCheck.InternalOnCreateComponent
        WinLeft=0.250000
        WinTop=0.410000
        OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
    End Object
    ch_PickupStats=wsCheckBox'UTComp_Menu_Miscellaneous.PickupCheck'

    Begin Object Class=wsCheckBox Name=KillsCheck
        Caption="Show kills on scoreboard."
        OnCreateComponent=KillsCheck.InternalOnCreateComponent
        WinWidth=0.500000
        WinHeight=0.030000
        WinLeft=0.250000
        WinTop=0.450000
        OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
    End Object
    ch_ShowKills=wsCheckBox'UTComp_Menu_Miscellaneous.KillsCheck'

    Begin Object Class=GUIButton Name=AdrenButton
        Caption="Disable Adrenaline Combos"
        StyleName="WSButton"
        WinWidth=0.400000
        WinHeight=0.050000
        WinLeft=0.2500000
        WinTop=0.49000
        OnClick=UTComp_Menu_Miscellaneous.InternalOnClick
        OnKeyEvent=AdrenButton.InternalOnKeyEvent
    End Object
    bu_adren=GUIButton'UTComp_Menu_Miscellaneous.AdrenButton'

    Begin Object Class=GUILabel Name=GenericLabel
        Caption="----Generic UT2004 Settings----"
        TextColor=(B=255,G=255,R=0)
        WinWidth=1.000000
        WinHeight=0.060000
        WinLeft=0.250000
        WinTop=0.530000
    End Object
    l_GenericTitle=GUILabel'UTComp_Menu_Miscellaneous.GenericLabel'

    Begin Object Class=wsCheckBox Name=FootCheck
        Caption="Play own footstep sounds."
        Hint="Weapon bob must be off!  Requires respawn for change to take effect"
        OnCreateComponent=FootCheck.InternalOnCreateComponent
        WinWidth=0.500000
        WinHeight=0.030000
        WinLeft=0.250000
        WinTop=0.570000
        OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
    End Object
    ch_FootSteps=wsCheckBox'UTComp_Menu_Miscellaneous.FootCheck'

    Begin Object Class=wsCheckBox Name=HudColorCheck
        Caption="Match Hud Color To Skins"
        OnCreateComponent=HudColorCheck.InternalOnCreateComponent
        WinWidth=0.500000
        WinHeight=0.030000
        WinLeft=0.250000
        WinTop=0.610000
        OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
    End Object
    ch_MatchHudColor=wsCheckBox'UTComp_Menu_Miscellaneous.HudColorCheck'

    Begin Object Class=wsCheckBox Name=UseEyeHeightAlgoCheck
        Caption="Use New EyeHeight Algorithm"
        Hint="You want this"
        OnCreateComponent=HudColorCheck.InternalOnCreateComponent
        WinWidth=0.500000
        WinHeight=0.030000
        WinLeft=0.250000
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
        WinLeft=0.250000
        WinTop=0.690000
        OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
    End Object
    ch_ViewSmoothing=wsCheckBox'UTComp_Menu_Miscellaneous.UseViewSmoothing'

    Begin Object Class=wsCheckBox Name=ShockCrashFix
        Caption="Shock crash fix"
        Hint="Fix crash for shock overlay error"
        OnCreateComponent=HudColorCheck.InternalOnCreateComponent
        WinWidth=0.150000
        WinHeight=0.030000
        WinLeft=0.600000
        WinTop=0.690000
        OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
    End Object
    ch_ShockCrashFix=wsCheckBox'UTComp_Menu_Miscellaneous.ShockCrashFix'

    Begin Object Class=GUILabel Name=NewNetLabel
        Caption="-----------Net Code-----------"
        TextColor=(B=255,G=255,R=0)
        WinWidth=1.000000
        WinHeight=0.060000
        WinLeft=0.250000
        WinTop=0.730000
    End Object
    l_NewNet=GUILabel'NewNetLabel'

    Begin Object Class=wsCheckBox Name=NewNetCheck
        Caption="Enable Enhanced Netcode"
        OnCreateComponent=NewNetCheck.InternalOnCreateComponent
        WinWidth=0.500000
        WinHeight=0.030000
        WinLeft=0.250000
        WinTop=0.770000
        OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
    End Object
    ch_UseNewNet=wsCheckBox'UTComp_Menu_Miscellaneous.NewNetCheck'
}
