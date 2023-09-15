class UTComp_Menu_ColorWeapons extends UTComp_Menu_MainMenu;
var automated moCheckBox ch_TeamColorRockets;
var automated moCheckBox ch_TeamColorBio;
var automated moCheckBox ch_TeamColorFlak;
var automated moCheckBox ch_TeamColorShock;
var automated GUIImage weaponCheckBox, redBox, blueBox;
var automated GUILabel RRL, RBL, RGL, BRL, BGL, BBL, redBoxLabel, blueBoxLabel;
var automated GUISlider RRSlide, RBSlide, RGSlide, BRSlide, BGSlide, BBSlide;
var automated moCheckBox ch_TeamColorEnemyAlly;
var TeamColorSpinnyRocket redRox,blueRox;
var vector      RedRoxOffset;
var vector      BlueRoxOffset;

function bool AllowOpen(string MenuClass)
{
	if(PlayerOwner()==None || PlayerOwner().PlayerReplicationInfo==None)
		return false;
	return true;
}

simulated function bool CanUseColors()
{
    local UTComp_ServerReplicationInfo RepInfo;

    RepInfo = BS_xPlayer(PlayerOwner()).RepInfo;
    if(RepInfo != None)
        return RepInfo.bAllowColorWeapons;

    return false;
}

event Opened(GUIComponent Sender)
{
    super.Opened(Sender);

    if(redRox == None)
    {
        redRox = PlayerOwner().Spawn(class'TeamColorSpinnyRocket');
        redRox.SetTeam(0);
        UpdateRedRoxColors();
    }

    if(blueRox == None)
    {
        blueRox = PlayerOwner().Spawn(class'TeamColorSpinnyRocket');
        blueRox.SetTeam(1);
        UpdateBlueRoxColors();
    }

    HideSpinnyRox(false);
}

event Closed(GUIComponent Sender, bool bCancelled)
{
    HideSpinnyRox(true);
    if(redRox!=None)
    {
        redRox.bHidden=true;
    }
    if(blueRox!=None)
    {
        blueRox.bHidden=true;
    }
    super.Closed(Sender, bCancelled);
}

function Free()
{
    super.Free();
    if(redRox!=None)
    {
        redRox.Destroy();
        redRox=None;
    }
    if(blueRox!=None)
    {
        blueRox.Destroy();
        blueRox=None;
    }

}

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    local BS_xPlayer P;

	Super.InitComponent(myController,MyOwner);	 
	 
    P = BS_xPlayer(PlayerOwner());
    if(P == None)
        return;
		
    ch_TeamColorRockets.Checked(Settings.bTeamColorRockets);
    ch_TeamColorBio.Checked(Settings.bTeamColorBio);
    ch_TeamColorFlak.Checked(Settings.bTeamColorFlak);
    ch_TeamColorShock.Checked(Settings.bTeamColorShock);
    ch_TeamColorEnemyAlly.Checked(!Settings.bTeamColorUseTeam);

    if(!CanUseColors())
    {
        ch_TeamColorRockets.DisableMe();
        ch_TeamColorBio.DisableMe();
        ch_TeamColorFlak.DisableMe();
        ch_TeamColorShock.DisableMe();
        ch_TeamColorEnemyAlly.DisableMe();
        RRSlide.DisableMe();
        RBSlide.DisableMe();
        RGSlide.DisableMe();
        BRSlide.DisableMe();
        BGSlide.DisableMe();
        BBSlide.DisableMe();

        ch_TeamColorRockets.SetHint("Server disabled");
        ch_TeamColorBio.SetHint("Server disabled");
        ch_TeamColorFlak.SetHint("Server disabled");
        ch_TeamColorShock.SetHint("Server disabled");
        ch_TeamColorEnemyAlly.SetHint("Server disabled");
        RRSlide.SetHint("Server disabled");
        RBSlide.SetHint("Server disabled");
        RGSlide.SetHint("Server disabled");
        BRSlide.SetHint("Server disabled");
        BGSlide.SetHint("Server disabled");
        BBSlide.SetHint("Server disabled");
    }

    UpdateColorTextTeam();    
    MatchSlidersToColors();
}

function MatchSlidersToColors()
{
    local Color red;
    local Color blue;
    local int myTeam;

    myTeam = PlayerOwner().GetTeamNum();
    red = class'TeamColorManager'.static.GetColor(0,PlayerOwner());
    blue = class'TeamColorManager'.static.GetColor(1,PlayerOwner());
    if(IsEnemyAlly())
    {
        red = class'TeamColorManager'.static.GetColor(1-myTeam,PlayerOwner());
        blue = class'TeamColorManager'.static.GetColor(myTeam,PlayerOwner());
    }

    RRSlide.Value = red.R;
    RGSlide.Value = red.G;
    RBSlide.Value = red.B;

    BRSlide.Value = blue.R;
    BGSlide.Value = blue.G;
    BBSlide.Value = blue.B;
}

function InternalOnChange( GUIComponent C )
{
    Switch(C)
    {	
        case ch_TeamColorEnemyAlly:
            Settings.bTeamColorUseTeam = !ch_TeamColorEnemyAlly.IsChecked();
            UpdateColors();
            MatchSlidersToColors();
        break;

        case ch_TeamColorRockets:
            Settings.bTeamColorRockets = ch_TeamColorRockets.IsChecked();
        break;
        
        case ch_TeamColorBio:
            Settings.bTeamColorBio = ch_TeamColorBio.IsChecked();
        break;

        case ch_TeamColorFlak:
            Settings.bTeamColorFlak = ch_TeamColorFlak.IsChecked();
        break;

        case ch_TeamColorShock:
            Settings.bTeamColorShock = ch_TeamColorShock.IsChecked();
        break;

        case RRSlide:
            Settings.TeamColorRed.R = RRSlide.Value;
            UpdateColors();
        break;

        case RGSlide:
            Settings.TeamColorRed.G = RGSlide.Value;
            UpdateColors();
        break;

        case RBSlide:
            Settings.TeamColorRed.B = RBSlide.Value;
            UpdateColors();
        break;
        
        case BRSlide:
            Settings.TeamColorBlue.R = BRSlide.Value;
            UpdateColors();
        break;

        case BGSlide:
            Settings.TeamColorBlue.G = BGSlide.Value;
            UpdateColors();
        break;

        case BBSlide:
            Settings.TeamColorBlue.B = BBSlide.Value;
            UpdateColors();
        break;

    }
	
    SaveSettings();
}

function bool IsEnemyAlly()
{
    return !Settings.bTeamColorUseTeam;
}

function UpdateRedRoxColors()
{
    local int myTeam;
    myTeam = PlayerOwner().GetTeamNum();
    if(redRox != None && redRox.RocketTrail != None)
    {
        if(IsEnemyAlly())
        {
            redRox.SetTeam(1-myTeam);
        }
        else
        {
            redRox.SetTeam(0);
        }

        redRox.RocketTrail.bColorSet=false;
    }
}

function UpdateBlueRoxColors()
{
    local int myTeam;
    myTeam = PlayerOwner().GetTeamNum();
    if(blueRox != None && blueRox.RocketTrail != None)
    {
        if(IsEnemyAlly())
        {
            blueRox.SetTeam(myTeam);
        }
        else
        {
            blueRox.SetTeam(1);
        }
        blueRox.RocketTrail.bColorSet=false;
    }
}

function InternalDraw(Canvas C)
{
	local vector CamPos, X, Y, Z;
	local rotator CamRot;

	C.GetCameraLocation(CamPos, CamRot);
	GetAxes(CamRot, X, Y, Z);

    if(redRox != None)
    {
	    redRox.SetLocation(CamPos + (RedRoxOffset.X * X) + (RedRoxOffset.Y * Y) + (RedRoxOffset.Z * Z));
	    C.DrawActor(redRox.RocketTrail, false, true, 90.0);
	    C.DrawActor(redRox.Corona, false, true, 90.0);
	    C.DrawActor(redRox, false, true, 90.0);
    }

    if(blueRox != None)
    {
	    blueRox.SetLocation(CamPos + (BlueRoxOffset.X * X) + (BlueRoxOffset.Y * Y) + (BlueRoxOffset.Z * Z));
	    C.DrawActor(blueRox.RocketTrail, false, true, 90.0);
	    C.DrawActor(blueRox.Corona, false, true, 90.0);
	    C.DrawActor(blueRox, false, true, 90.0);
    }

	//return false;
}

function HideSpinnyRox(bool bHide)
{
    log("HideSpinnyRox hide="$bHide);
    if(RedRox != None)
    {
        RedRox.bHidden=bHide;
        RedRox.Corona.bHidden=bHide;
        RedRox.RocketTrail.bHidden=bHide;
    }
    if(BlueRox != None)
    {
        BlueRox.bHidden=bHide;
        BlueRox.Corona.bHidden=bHide;
        BlueRox.RocketTrail.bHidden=bHide;
    }
}

function UpdateColorTextTeam()
{
    local int myTeam;
    myTeam=PlayerOwner().GetTeamNum();
    if(IsEnemyAlly())
    {
        redBoxLabel.TextColor = class'TeamColorManager'.static.GetColor(1-myTeam,PlayerOwner());
        blueBoxLabel.TextColor = class'TeamColorManager'.static.GetColor(myTeam,PlayerOwner());
    }
    else
    {
        redBoxLabel.TextColor = class'TeamColorManager'.static.GetColor(0,PlayerOwner());
        blueBoxLabel.TextColor = class'TeamColorManager'.static.GetColor(1,PlayerOwner());
    }
}

function UpdateColors()
{
    UpdateColorTextTeam();
    UpdateRedRoxColors();
    UpdateBlueRoxColors();
}

defaultproperties
{
    Begin Object Class=GUIImage Name=TabWeaponBackground
         Image=Texture'InterfaceContent.Menu.ScoreBoxA'
         ImageColor=(A=100)
         ImageStyle=ISTY_Stretched
         WinTop=0.300000
         WinLeft=0.075000
         WinWidth=0.850000
         WinHeight=0.220000
         RenderWeight=1.000000
         bNeverFocus=True
    End Object
    weaponCheckBox=GUIImage'UTCompOmni.UTComp_Menu_ColorWeapons.TabWeaponBackground'

    Begin Object Class=moCheckBox Name=CheckTeamColorRockets
         Caption="Team colored rockets"
         OnCreateComponent=SpeedCheck.InternalOnCreateComponent
         Hint="Add team coloring to rockets"
         WinTop=0.310000
         WinLeft=0.100000
         WinWidth=0.800000
         OnChange=UTComp_Menu_ColorWeapons.InternalOnChange
     End Object
     ch_TeamColorRockets=moCheckBox'UTCompOmni.UTComp_Menu_ColorWeapons.CheckTeamColorRockets'

    Begin Object Class=moCheckBox Name=CheckTeamColorBio
         Caption="Team colored bio"
         OnCreateComponent=SpeedCheck.InternalOnCreateComponent
         Hint="Add team coloring to bio globs"
         WinTop=0.360000
         WinLeft=0.100000
         WinWidth=0.800000
         OnChange=UTComp_Menu_ColorWeapons.InternalOnChange
     End Object
     ch_TeamColorBio=moCheckBox'UTCompOmni.UTComp_Menu_ColorWeapons.CheckTeamColorBio'

    Begin Object Class=moCheckBox Name=CheckTeamColorFlak
         Caption="Team colored flak"
         OnCreateComponent=SpeedCheck.InternalOnCreateComponent
         Hint="Add team coloring to flak"
         WinTop=0.410000
         WinLeft=0.100000
         WinWidth=0.800000
         OnChange=UTComp_Menu_ColorWeapons.InternalOnChange
     End Object
     ch_TeamColorFlak=moCheckBox'UTCompOmni.UTComp_Menu_ColorWeapons.CheckTeamColorFlak'

    Begin Object Class=moCheckBox Name=CheckTeamColorShock
         Caption="Team colored shock"
         OnCreateComponent=SpeedCheck.InternalOnCreateComponent
         Hint="Add team coloring to shock"
         WinTop=0.460000
         WinLeft=0.100000
         WinWidth=0.800000
         OnChange=UTComp_Menu_ColorWeapons.InternalOnChange
     End Object
     ch_TeamColorShock=moCheckBox'UTCompOmni.UTComp_Menu_ColorWeapons.CheckTeamColorShock'

    Begin Object Class=moCheckBox Name=CheckTeamColorEnemyAlly
         Caption="Use enemy/ally colors"
         OnCreateComponent=SpeedCheck.InternalOnCreateComponent
         Hint="Use enemy/ally logic instead of red/blue"
         WinTop=0.76
         WinLeft=0.100000
         WinWidth=0.350000
         OnChange=UTComp_Menu_ColorWeapons.InternalOnChange
    End Object
    ch_TeamColorEnemyAlly=moCheckBox'UTCompOmni.UTComp_Menu_ColorWeapons.CheckTeamColorEnemyAlly'

    Begin Object Class=GUIImage Name=TabRedColorBackground
         Image=Texture'InterfaceContent.Menu.ScoreBoxA'
         ImageColor=(A=100)
         ImageStyle=ISTY_Stretched
         WinTop=0.550000
         WinLeft=0.075000
         WinWidth=0.42500
         WinHeight=0.270000
         RenderWeight=1.000000
         bNeverFocus=True
    End Object
    redBox=GUIImage'UTCompOmni.UTComp_Menu_ColorWeapons.TabRedColorBackground'

    Begin Object Class=GUIImage Name=TabBlueColorBackground
         Image=Texture'InterfaceContent.Menu.ScoreBoxA'
         ImageColor=(A=100)
         ImageStyle=ISTY_Stretched
         WinTop=0.550000
         WinLeft=0.50000
         WinWidth=0.42500
         WinHeight=0.270000
         RenderWeight=1.000000
         bNeverFocus=True
    End Object
    blueBox=GUIImage'UTCompOmni.UTComp_Menu_ColorWeapons.TabBlueColorBackground'

    Begin Object Class=GUILabel Name=RedBoxLbl
         Caption="Red or Enemy"
         TextColor=(B=255,G=255,R=255)
         WinTop=0.580000
         WinLeft=0.230000
         WinHeight=20.000000
     End Object
     redboxLabel=GUILabel'UTCompOmni.UTComp_Menu_ColorWeapons.RedBoxLbl'

    Begin Object Class=GUILabel Name=BlueBoxLbl
         Caption="Blue or Ally"
         TextColor=(B=255,G=255,R=255)
         WinTop=0.580000
         WinLeft=0.680000
         WinHeight=20.000000
     End Object
     blueboxLabel=GUILabel'UTCompOmni.UTComp_Menu_ColorWeapons.BlueBoxLbl'


    // ------------------

     Begin Object Class=GUISlider Name=RedRSlider
         bIntSlider=True
         WinTop=0.6250000
         WinLeft=0.120000
         WinWidth=0.260000
         OnClick=RedRSlider.InternalOnClick
         OnMousePressed=RedRSlider.InternalOnMousePressed
         OnMouseRelease=RedRSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_ColorWeapons.InternalOnChange
         OnKeyEvent=RedRSlider.InternalOnKeyEvent
         OnCapturedMouseMove=RedRSlider.InternalCapturedMouseMove
         MaxValue=255
     End Object
     RRSlide=GUISlider'UTCompOmni.UTComp_Menu_ColorWeapons.RedRSlider'

     Begin Object Class=GUISlider Name=RedGSlider
         bIntSlider=True
         WinTop=0.6750000
         WinLeft=0.120000
         WinWidth=0.260000
         OnClick=RedGSlider.InternalOnClick
         OnMousePressed=RedGSlider.InternalOnMousePressed
         OnMouseRelease=RedGSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_ColorWeapons.InternalOnChange
         OnKeyEvent=RedGSlider.InternalOnKeyEvent
         OnCapturedMouseMove=RedGSlider.InternalCapturedMouseMove
         MaxValue=255
     End Object
     RGSlide=GUISlider'UTCompOmni.UTComp_Menu_ColorWeapons.RedGSlider'

     Begin Object Class=GUISlider Name=RedBSlider
         bIntSlider=True
         WinTop=0.7250000
         WinLeft=0.120000
         WinWidth=0.260000
         OnClick=RedBSlider.InternalOnClick
         OnMousePressed=RedBSlider.InternalOnMousePressed
         OnMouseRelease=RedBSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_ColorWeapons.InternalOnChange
         OnKeyEvent=RedBSlider.InternalOnKeyEvent
         OnCapturedMouseMove=RedBSlider.InternalCapturedMouseMove
         MaxValue=255
     End Object
     RBSlide=GUISlider'UTCompOmni.UTComp_Menu_ColorWeapons.RedBSlider'

     Begin Object Class=GUISlider Name=BlueRSlider
         bIntSlider=True
         WinTop=0.6250000
         WinLeft=0.5500000
         WinWidth=0.260000
         OnClick=BlueRSlider.InternalOnClick
         OnMousePressed=BlueRSlider.InternalOnMousePressed
         OnMouseRelease=BlueRSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_ColorWeapons.InternalOnChange
         OnKeyEvent=BlueRSlider.InternalOnKeyEvent
         OnCapturedMouseMove=BlueRSlider.InternalCapturedMouseMove
         MaxValue=255
     End Object
     BRSlide=GUISlider'UTCompOmni.UTComp_Menu_ColorWeapons.BlueRSlider'

     Begin Object Class=GUISlider Name=BlueGSlider
         bIntSlider=True
         WinTop=0.6750000
         WinLeft=0.5500000
         WinWidth=0.260000
         OnClick=BlueGSlider.InternalOnClick
         OnMousePressed=BlueGSlider.InternalOnMousePressed
         OnMouseRelease=BlueGSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_ColorWeapons.InternalOnChange
         OnKeyEvent=BlueGSlider.InternalOnKeyEvent
         OnCapturedMouseMove=BlueGSlider.InternalCapturedMouseMove
         MaxValue=255
     End Object
     BGSlide=GUISlider'UTCompOmni.UTComp_Menu_ColorWeapons.BlueGSlider'

     Begin Object Class=GUISlider Name=BlueBSlider
         bIntSlider=True
         WinTop=0.7250000
         WinLeft=0.550000
         WinWidth=0.260000
         OnClick=BlueBSlider.InternalOnClick
         OnMousePressed=BlueBSlider.InternalOnMousePressed
         OnMouseRelease=BlueBSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_ColorWeapons.InternalOnChange
         OnKeyEvent=BlueBSlider.InternalOnKeyEvent
         OnCapturedMouseMove=BlueBSlider.InternalCapturedMouseMove
         MaxValue=255
     End Object
     BBSlide=GUISlider'UTCompOmni.UTComp_Menu_ColorWeapons.BlueBSlider'

     Begin Object Class=GUILabel Name=RedRLabel
         Caption="R:"
         TextColor=(B=255,G=255,R=255)
         WinTop=0.6250000
         WinLeft=0.100000
         WinHeight=20.000000
     End Object
     RRL=GUILabel'UTCompOmni.UTComp_Menu_ColorWeapons.RedRLabel'

     Begin Object Class=GUILabel Name=RedGLabel
         Caption="G:"
         TextColor=(B=255,G=255,R=255)
         WinTop=0.6750000
         WinLeft=0.100000
         WinHeight=20.000000
     End Object
     RGL=GUILabel'UTCompOmni.UTComp_Menu_ColorWeapons.RedGLabel'

     Begin Object Class=GUILabel Name=RedBLabel
         Caption="B:"
         TextColor=(B=255,G=255,R=255)
         WinTop=0.725000
         WinLeft=0.100000
         WinHeight=20.000000
     End Object
     RBL=GUILabel'UTCompOmni.UTComp_Menu_ColorWeapons.RedBLabel'

     Begin Object Class=GUILabel Name=BlueRLabel
         Caption="R:"
         TextColor=(B=255,G=255,R=255)
         WinTop=0.6250000
         WinLeft=0.53000
         WinHeight=20.000000
     End Object
     BRL=GUILabel'UTCompOmni.UTComp_Menu_ColorWeapons.BlueRLabel'

     Begin Object Class=GUILabel Name=BlueGLabel
         Caption="G:"
         TextColor=(B=255,G=255,R=255)
         WinTop=0.6750000
         WinLeft=0.53000
         WinHeight=20.000000
     End Object
     BGL=GUILabel'UTCompOmni.UTComp_Menu_ColorWeapons.BlueGLabel'

     Begin Object Class=GUILabel Name=BlueBLabel
         Caption="B:"
         TextColor=(B=255,G=255,R=255)
         WinTop=0.725000
         WinLeft=0.53000
         WinHeight=20.000000
     End Object
     BBL=GUILabel'UTCompOmni.UTComp_Menu_ColorWeapons.BlueBLabel'

     //RedRoxOffset=(X=300.000000,Y=-25.000000,Z=-50.000000)
     //BlueRoxOffset=(X=300.000000,Y=175.000000,Z=-50.000000)
     RedRoxOffset=(X=300.000000,Y=-30.000000,Z=-60.000000)
     BlueRoxOffset=(X=300.000000,Y=220.000000,Z=-60.000000)

    OnRendered=InternalDraw
}
