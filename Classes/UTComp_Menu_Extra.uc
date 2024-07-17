
class UTComp_Menu_Extra extends UTComp_Menu_MainMenu;

var automated wsCheckBox ch_EnableWidescreenFix;
var automated wsComboBox co_DamageSelect;
var automated GUILabel lb_DamageSelect;
var automated wsCheckBox ch_UseSpectatorsWeaponHand;
var automated wsComboBox co_SpectatorsWeaponHand;

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

    co_SpectatorsWeaponHand.AddItem("Left");
	co_SpectatorsWeaponHand.AddItem("Centered");
	co_SpectatorsWeaponHand.AddItem("Right");
	co_SpectatorsWeaponHand.AddItem("Hidden");
	co_SpectatorsWeaponHand.ReadOnly(True);
	co_SpectatorsWeaponHand.SetIndex(HUDSettings.SpectatorsWeaponHand + 1);
}

function InternalOnChange( GUIComponent C )
{
    switch(C)
    {
        case ch_EnableWidescreenFix: HUDSettings.bEnableWidescreenFix=ch_EnableWidescreenFix.IsChecked(); 
            break;

		case co_DamageSelect: HUDSettings.DamageIndicatorType = co_DamageSelect.GetIndex() + 1;
			break;

        case co_SpectatorsWeaponHand: HUDSettings.SpectatorsWeaponHand=co_SpectatorsWeaponHand.GetIndex() - 1; 
            break;
    }

    SaveHUDSettings();
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

    Begin Object Class=wsComboBox Name=SpectatorWeaponHand
        Caption="Spectating weapon hand:"
        OnCreateComponent=SpectatorWeaponHand.InternalOnCreateComponent
        WinWidth=0.500000
        WinLeft=0.250000
        WinTop=0.430000
        OnChange=UTComp_Menu_Extra.InternalOnChange
    End Object
    co_SpectatorsWeaponHand=wsComboBox'UTComp_Menu_Extra.SpectatorWeaponHand'
}