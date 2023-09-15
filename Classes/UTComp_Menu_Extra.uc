
class UTComp_Menu_Extra extends UTComp_Menu_MainMenu;

var automated moCheckBox ch_EnableWidescreenFix;
var automated moComboBox co_DamageSelect;

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

}

function InternalOnChange( GUIComponent C )
{
    switch(C)
    {
        case ch_EnableWidescreenFix: HUDSettings.bEnableWidescreenFix=ch_EnableWidescreenFix.IsChecked(); 
            break;

		case co_DamageSelect: HUDSettings.DamageIndicatorType = co_DamageSelect.GetIndex() + 1;
			break;
    }

    SaveHUDSettings();
}

defaultproperties
{
    Begin Object Class=moCheckBox Name=EnableWidescreenCheck
        Caption="Enable widescreen fixes"
        OnCreateComponent=EnableWidescreenCheck.InternalOnCreateComponent
        WinWidth=0.500000
        WinHeight=0.030000
        WinLeft=0.250000
        WinTop=0.330000
        OnChange=UTComp_Menu_Extra.InternalOnChange
    End Object
    ch_EnableWidescreenFix=moCheckBox'UTComp_Menu_Extra.EnableWidescreenCheck'

    Begin Object Class=moComboBox Name=ComboDamageIndicatorType
         Caption="Damage Indicators:"
         OnCreateComponent=ComboDamageIndicatorType.InternalOnCreateComponent
         WinTop=0.380000
         WinLeft=0.250000
         WinWidth=0.500000
         OnChange=UTComp_Menu_Extra.InternalOnChange
     End Object
     co_DamageSelect=moComboBox'UTComp_Menu_Extra.ComboDamageIndicatorType'
}