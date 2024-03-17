//-----------------------------------------------------------
//
//-----------------------------------------------------------
class UTComp_menu_AdrenMenu extends UTComp_Menu_MainMenu;

var automated wsCheckBox ch_booster;
var automated wsCheckBox ch_invis;
var automated wsCheckBox ch_speed;
var automated wsCheckBox ch_berserk;

var automated GUILAbel l_adren;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    super.InitComponent(MyController,MyOwner);

    ch_booster.Checked(!Settings.bDisableBooster);
    ch_speed.Checked(!Settings.bDisableSpeed);
    ch_berserk.Checked(!Settings.bDisableBerserk);
    ch_invis.Checked(!Settings.bDisableInvis);
}

function InternalOnChange( GUIComponent C )
{
    switch(C)
    {
        case ch_booster: Settings.bDisableBooster=!ch_booster.IsChecked(); break;
        case ch_invis:  Settings.bDisableInvis=!ch_Invis.IsChecked();
        case ch_speed:  Settings.bDisableSpeed=!ch_Speed.IsChecked(); break;
        case ch_berserk: Settings.bDisableberserk=!ch_Berserk.IsChecked(); break;
    }
    SaveSettings();
}


DefaultProperties
{
    Begin Object Class=GUILabel Name=AdrenLabel
        Caption="----Adrenaline Combo Settings----"
        TextColor=(B=255,G=255,R=0)
		WinWidth=1.000000
		WinHeight=0.060000
		WinLeft=0.250000
		WinTop=0.36
     End Object
     l_Adren=GUILabel'UTComp_Menu_AdrenMenu.AdrenLabel'


     Begin Object Class=wsCheckBox Name=BoosterCheck
        Caption="Enable Booster Combo"
        OnCreateComponent=BoosterCheck.InternalOnCreateComponent
		WinWidth=0.500000
		WinHeight=0.030000
		WinLeft=0.250000
		WinTop=0.430000
         OnChange=UTComp_Menu_AdrenMenu.InternalOnChange
     End Object
     ch_Booster=wsCheckBox'UTComp_Menu_AdrenMenu.BoosterCheck'

      Begin Object Class=wsCheckBox Name=InvisCheck
        Caption="Enable Invisibility Combo"
        OnCreateComponent=InvisCheck.InternalOnCreateComponent
		WinWidth=0.500000
		WinHeight=0.030000
		WinLeft=0.250000
		WinTop=0.480000
         OnChange=UTComp_Menu_AdrenMenu.InternalOnChange
     End Object
     ch_Invis=wsCheckBox'UTComp_Menu_AdrenMenu.InvisCheck'

          Begin Object Class=wsCheckBox Name=SpeedCheck
        Caption="Enable Speed Combo"
        OnCreateComponent=SpeedCheck.InternalOnCreateComponent
		WinWidth=0.500000
		WinHeight=0.030000
		WinLeft=0.250000
		WinTop=0.530000
         OnChange=UTComp_Menu_AdrenMenu.InternalOnChange
     End Object
     ch_Speed=wsCheckBox'UTComp_Menu_AdrenMenu.SpeedCheck'

     Begin Object Class=wsCheckBox Name=BerserkCheck
        Caption="Enable Berserk Combo"
        OnCreateComponent=BerserkCheck.InternalOnCreateComponent
		WinWidth=0.500000
		WinHeight=0.030000
		WinLeft=0.250000
		WinTop=0.580000
         OnChange=UTComp_Menu_AdrenMenu.InternalOnChange
     End Object
     ch_Berserk=wsCheckBox'UTComp_Menu_AdrenMenu.BerserkCheck'
}