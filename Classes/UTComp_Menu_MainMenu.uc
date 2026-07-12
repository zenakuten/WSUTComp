
class UTComp_Menu_MainMenu extends PopupPageBase;

#exec TEXTURE IMPORT NAME=Display95 GROUP=GUI FILE=Textures\Display95.dds MIPS=off ALPHA=1 DXT=5
#exec TEXTURE IMPORT NAME=Display99 GROUP=GUI FILE=Textures\Display99.dds MIPS=off ALPHA=1 DXT=5

var automated array<GUIButton> UTCompMenuButtons;
var automated GUITabControl c_Main;
var automated FloatingImage i_FrameBG2;
var UTComp_Settings Settings;
var UTComp_HUDSettings HUDSettings;

// Index into UTCompMenuButtons of the tab button for this menu, so it can stay
// highlighted while its menu is shown. Each menu sets this in defaultproperties; -1
// means none (base menu).
var int ActiveMenuButton;

// Config writes are deferred until the menu closes instead of being written on every
// change. Each StaticSaveConfig/SaveConfig rewrites an ini synchronously and stalls the
// game thread (~0.5s per write under Wine), which was hitching every slider release.
// We record what changed and flush it once in OnClose (which also fires on tab switch).
var bool bDirtySettings;
var bool bDirtyHUDSettings;
var array< class<Object> > DirtyConfigClasses;

simulated function SaveSettings()
{
    bDirtySettings = true;
}

simulated function SaveHUDSettings()
{
    bDirtyHUDSettings = true;
}

// Queue a config class to be persisted once, on close.
simulated function MarkConfigDirty(class<Object> ConfigClass)
{
    local int i;

    for(i=0; i<DirtyConfigClasses.Length; i++)
        if(DirtyConfigClasses[i] == ConfigClass)
            return;
    DirtyConfigClasses[DirtyConfigClasses.Length] = ConfigClass;
}

// Persist everything that changed while the menu was open.
simulated function FlushSettings()
{
    local int i;
    local class<Object> ConfigClass;

    if(bDirtySettings && Settings != None)
    {
        Settings.Save();
        bDirtySettings = false;
    }
    if(bDirtyHUDSettings && HUDSettings != None)
    {
        HUDSettings.SaveConfig();
        bDirtyHUDSettings = false;
    }
    for(i=0; i<DirtyConfigClasses.Length; i++)
    {
        ConfigClass = DirtyConfigClasses[i];
        ConfigClass.static.StaticSaveConfig();
    }
    DirtyConfigClasses.Length = 0;
}

// Position a preview actor so DrawActor projects it into the given pane, and set FovDeg to
// the FOV that reproduces the on-screen size the old clipped sub-viewport gave it (the
// clipped FOV scaled by screen-width / pane-width). The preview menus use DrawActor instead
// of DrawActorClipped because the clipped variant calls RI SetViewport and restores it to
// full screen, corrupting the menu window viewport for the GUI on-top re-render of the
// focused control and the tab buttons - the source of the vertical drift.
function vector SpinnyPaneLoc(Canvas C, GUIImage Bounds, vector CamPos, vector Fwd, vector Rgt, vector Up, float Dist, float ClippedFOV, out float FovDeg)
{
    local float ndcX, ndcY, tanHalf, aspect, r, u, paneCX, paneCY;

    paneCX = Bounds.ActualLeft() + Bounds.ActualWidth() * 0.5;
    paneCY = Bounds.ActualTop() + Bounds.ActualHeight() * 0.5;

    FovDeg  = ClippedFOV * float(C.SizeX) / Bounds.ActualWidth();
    tanHalf = Tan(FovDeg * 0.5 * Pi / 180.0);
    aspect  = float(C.SizeX) / float(C.SizeY);

    ndcX = 2.0 * paneCX / float(C.SizeX) - 1.0;
    ndcY = 1.0 - 2.0 * paneCY / float(C.SizeY);

    r = ndcX * tanHalf * Dist;
    u = ndcY * (tanHalf / aspect) * Dist;

    return CamPos + Dist * Fwd + r * Rgt + u * Up;
}

function InitComponent(GUIController MyController, GUIComponent MyComponent)
{
    local int i;

    MyController.RegisterStyle(class'STY_WSButton', true);
    MyController.RegisterStyle(class'STY_WSButtonTab', true);
    MyController.RegisterStyle(class'STY_WSButtonActive', true);
    MyController.RegisterStyle(class'STY_WSComboButton', true);
    MyController.RegisterStyle(class'STY_WSLabel', true);
    MyController.RegisterStyle(class'STY_WSLabelWhite', true);
    MyController.RegisterStyle(class'STY_WSListBox', true);
    MyController.RegisterStyle(class'STY_WSSliderBar', true);
    MyController.RegisterStyle(class'STY_WSSliderCaption', true);
    MyController.RegisterStyle(class'STY_WSSliderKnob', true);
    MyController.RegisterStyle(class'STY_WSSliderKnobWhite', true);
    MyController.RegisterStyle(class'STY_WSEditBox', true);
    MyController.RegisterStyle(class'STY_WSSpinner', true);
    MyController.RegisterStyle(class'STY_WSVertDownButton', true);
    MyController.RegisterStyle(class'STY_WSVertUpButton', true);

	super.InitComponent(MyController, MyComponent);

    Settings = BS_xPlayer(PlayerOwner()).Settings;
    HUDSettings = BS_xPlayer(PlayerOwner()).HUDSettings;

    // Reset every tab button to the tab style (which doesn't highlight on focus, only
    // on hover), then give only this menu's button the always-highlighted active style.
    // The framework auto-focuses a button when a menu opens; without this the focused
    // button and the active button would both show cyan.
    for(i=0; i<UTCompMenuButtons.Length; i++)
        UTCompMenuButtons[i].Style =
            MyController.GetStyle("WSButtonTab", UTCompMenuButtons[i].FontScale);

    if(ActiveMenuButton >= 0 && ActiveMenuButton < UTCompMenuButtons.Length)
        UTCompMenuButtons[ActiveMenuButton].Style =
            MyController.GetStyle("WSButtonActive", UTCompMenuButtons[ActiveMenuButton].FontScale);
}

function bool InternalOnClick(GUIComponent C)
{
    if(C==UTCompMenuButtons[0])
        PlayerOwner().ClientReplaceMenu(string(class'UTComp_Menu_BrightSkins'));

    else if(C==UTCompMenuButtons[1])
        PlayerOwner().ClientReplaceMenu(string(class'UTComp_Menu_ColorNames'));

    else if(C==UTCompMenuButtons[2])
        PlayerOwner().ClientReplaceMenu(string(class'UTComp_Menu_TeamOverlay'));

    else if(C==UTCompMenuButtons[3])
        PlayerOwner().ClientReplaceMenu(string(class'UTComp_Menu_Crosshairs'));

    else if(C==UTCompMenuButtons[4])
        PlayerOwner().ClientReplaceMenu(string(class'UTComp_Menu_Hitsounds'));

    else if(C==UTCompMenuButtons[5])
        PlayerOwner().ClientReplaceMenu(string(class'UTComp_Menu_HUD'));

    else if(C==UTCompMenuButtons[6])
        PlayerOwner().ClientReplaceMenu(string(class'UTComp_Menu_Voting'));

    else if(C==UTCompMenuButtons[7])
        PlayerOwner().ClientReplaceMenu(string(class'UTComp_Menu_AutoDemoSS'));

    else if(C==UTCompMenuButtons[8])
        PlayerOwner().ClientReplaceMenu(string(class'UTComp_Menu_Miscellaneous'));

    else if(C==UTCompMenuButtons[9])
        PlayerOwner().ClientReplaceMenu(string(class'UTComp_Menu_ColorWeapons'));

    else if(C==UTCompMenuButtons[10])
        PlayerOwner().ClientReplaceMenu(string(class'UTComp_Menu_Extra'));

    else if(C==UTCompMenuButtons[11])
        PlayerOwner().ClientReplaceMenu(string(class'UTComp_Menu_Emoticons'));

    return false;
}

function OnClose(optional bool bCancelled)
{
   FlushSettings();
   if(PlayerOwner().IsA('BS_xPlayer'))
   {
      BS_xPlayer(PlayerOwner()).ReSkinAll();
      BS_xPlayer(PlayerOwner()).InitializeScoreboard();
      BS_xPlayer(PlayerOwner()).MatchHudColor();
   }
   super.OnClose(bCancelled);
}

function bool IsAdmin()
{
	return PlayerOwner() != None && PlayerOwner().PlayerReplicationInfo != None && PlayerOwner().PlayerReplicationInfo.bAdmin;
}

defaultproperties
{
     Begin Object class=GUIButton name=SkinModelButton
         Caption="Skins/Models"
         StyleName="WSButton"
         WinTop=0.130000
         WinLeft=0.11250000
         //WinWidth=0.180000
         WinWidth=0.12
         WinHeight=0.060000
         OnClick=InternalOnClick
     End Object
     UTCompMenuButtons(0)=GUIButton'SkinModelButton'

     Begin Object class=GUIButton name=ColoredNameButton
         Caption="Colored Names"
         StyleName="WSButton"
         WinTop=0.130000
         //WinLeft=0.31250000
         //0.16
         WinLeft=0.2458
         //WinWidth=0.180000
         WinWidth=0.12
         WinHeight=0.060000
         OnClick=InternalOnClick
     End Object
     UTCompMenuButtons(1)=GUIButton'ColoredNameButton'

     Begin Object class=GUIButton name=OverlayButton
         Caption="Team Overlay"
         StyleName="WSButton"
         WinTop=0.130000
         //WinLeft=0.51250000
         WinLeft=0.3791
         //WinWidth=0.180000
         WinWidth=0.12
         WinHeight=0.060000
         OnClick=InternalOnClick
     End Object
     UTCompMenuButtons(2)=GUIButton'OverlayButton'

     Begin Object class=GUIButton name=CrosshairButton
         Caption="Crosshairs"
         StyleName="WSButton"
         WinTop=0.130000
         //WinLeft=0.71250000
         WinLeft=0.5124
         //WinWidth=0.180000
         WinWidth=0.12
         WinHeight=0.060000
         OnClick=InternalOnClick
     End Object
     UTCompMenuButtons(3)=GUIButton'CrosshairButton'

     Begin Object class=GUIButton name=HitsoundButton
         Caption="Hitsounds"
         StyleName="WSButton"
         //WinTop=0.220000
         WinTop=0.130000
         //WinLeft=0.11250000
         WinLeft=0.6458
         //WinWidth=0.180000
         WinWidth=0.12
         WinHeight=0.060000
         OnClick=InternalOnClick
     End Object
     UTCompMenuButtons(4)=GUIButton'HitsoundButton'

     Begin Object class=GUIButton name=HUDButton
         Caption="HUD"
         StyleName="WSButton"
         //WinTop=0.220000
         WinTop=0.130000
         //WinLeft=0.11250000
         WinLeft=0.7791
         //WinWidth=0.180000
         WinWidth=0.12
         WinHeight=0.060000
         OnClick=InternalOnClick
     End Object
     UTCompMenuButtons(5)=GUIButton'HUDButton'

    //-------------------------------------------------------

     Begin Object class=GUIButton name=VotingButton
         Caption="Voting"
         StyleName="WSButton"
         WinTop=0.200000
         WinLeft=0.11250000
         //WinWidth=0.180000
         WinWidth=0.12
         WinHeight=0.060000
         OnClick=InternalOnClick
     End Object
     UTCompMenuButtons(6)=GUIButton'VotingButton'

     Begin Object class=GUIButton name=AutoDemoButton
         Caption="Auto Demo/SS"
         StyleName="WSButton"
         WinTop=0.200000
         WinLeft=0.2458
         //WinWidth=0.180000
         WinWidth=0.12
         WinHeight=0.060000
         OnClick=InternalOnClick
     End Object
     UTCompMenuButtons(7)=GUIButton'AutoDemoButton'

     Begin Object class=GUIButton name=MiscButton
         Caption="Misc"
         StyleName="WSButton"
         WinTop=0.200000
         WinLeft=0.3791
         //WinWidth=0.180000
         WinWidth=0.12
         WinHeight=0.060000
         OnClick=InternalOnClick
     End Object
     UTCompMenuButtons(8)=GUIButton'MiscButton'

     Begin Object class=GUIButton name=WeaponConfigButton
         Caption="Weapon Config"
         StyleName="WSButton"
         WinTop=0.200000
         WinLeft=0.5124
         //WinWidth=0.180000
         WinWidth=0.12
         WinHeight=0.060000
         OnClick=InternalOnClick
     End Object
     UTCompMenuButtons(9)=GUIButton'WeaponConfigButton'

     Begin Object class=GUIButton name=ExtraButton
         Caption="Extra"
         StyleName="WSButton"
         WinTop=0.200000
         WinLeft=0.6458
         //WinWidth=0.180000
         WinWidth=0.12
         WinHeight=0.060000
         OnClick=InternalOnClick
     End Object
     UTCompMenuButtons(10)=GUIButton'ExtraButton'

     Begin Object class=GUIButton name=EmoteButton
         Caption="Emotes"
         StyleName="WSButton"
         WinTop=0.200000
         WinLeft=0.7791
         //WinWidth=0.180000
         WinWidth=0.12
         WinHeight=0.060000
         OnClick=InternalOnClick
     End Object
     UTCompMenuButtons(11)=GUIButton'EmoteButton'

     Begin Object class=GUIButton name=AdminButton
         Caption="Admin"
         StyleName="WSButton"
         WinTop=0.720000
         WinLeft=0.71250000
         //WinWidth=0.180000
         WinWidth=0.144
         WinHeight=0.060000
         OnClick=InternalOnClick
         bVisible=false
     End Object
     UTCompMenuButtons(12)=GUIButton'AdminButton'

     Begin Object Class=GUITabControl Name=LoginMenuTC
         bFillSpace=True
         bDockPanels=True
         TabHeight=0.08
         BackgroundStyleName=""
		 WinWidth=0.725325
		 WinHeight=0.208177
		 WinLeft=0.134782
	     WinTop=0.072718
         bScaleToParent=True
         bAcceptsInput=True
         OnActivate=LoginMenuTC.InternalOnActivate
     End Object
     c_Main=GUITabControl'UTComp_Menu_MainMenu.LoginMenuTC'


     Begin Object Class=FloatingImage Name=FloatingFrameBackground
         Image=Texture'WSUTComp.GUI.Display99'
         ImageColor=(R=64,G=64,B=64,A=200)
         ImageStyle=ISTY_Stretched
         ImageRenderStyle=MSTY_Normal
         WinTop=0.100000
         WinLeft=0.0750000
         WinWidth=0.850000
         WinHeight=0.750000
         bBoundToParent=False
         bScaleToParent=False
         RenderWeight = 0.01
         DropShadowX=0
         DropShadowY=0
     End Object
     i_FrameBG=FloatingImage'UTComp_Menu_MainMenu.FloatingFrameBackground'

     Begin Object Class=FloatingImage Name=FloatingFrameBackground2
         Image=Texture'WSUTComp.GUI.Display95'
         ImageColor=(R=64,G=64,B=64,A=200)
         ImageStyle=ISTY_Stretched
         ImageRenderStyle=MSTY_Normal
         WinTop=0.270000
         WinLeft=0.0750000
         WinWidth=0.850000
         WinHeight=0.580000
         bBoundToParent=False
         bScaleToParent=False
         RenderWeight = 0.02
         DropShadowX=0
         DropShadowY=0
     End Object
     i_FrameBG2=FloatingImage'UTComp_Menu_MainMenu.FloatingFrameBackground2'


  /*   bResizeWidthAllowed=False
     bResizeHeightAllowed=False
     bMoveAllowed=False      */
     ActiveMenuButton=-1
     bRequire640x480=True
     bAllowedAsLast=True
     WinWidth=1.000000
	 WinHeight=0.804690
	 WinLeft=0.000000
	 WinTop=0.114990
	 bPersistent=true

}
