
class UTComp_Menu_Extra extends UTComp_Menu_MainMenu;

var automated moCheckBox ch_EnableWidescreenFix;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    super.InitComponent(MyController,MyOwner);
    ch_EnableWidescreenFix.Checked(HUDSettings.bEnableWidescreenFix);
}

function InternalOnChange( GUIComponent C )
{
    switch(C)
    {
        case ch_EnableWidescreenFix: HUDSettings.bEnableWidescreenFix=ch_EnableWidescreenFix.IsChecked(); 
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
}