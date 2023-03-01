


class UTComp_Menu_Admin extends UTComp_Menu_MainMenu;

var automated moCheckBox ch_UseWhitelist;
var UTComp_ServerReplicationInfo RepInfo;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    super.InitComponent(MyController,MyOwner);

    foreach PlayerOwner().DynamicActors(Class'UTComp_ServerReplicationInfo', RepInfo)
        break;

    ch_UseWhitelist.bVisible=false;
    ch_UseWhitelist.Checked(false);

    if(RepInfo != None)
    {
        ch_UseWhitelist.bVisible=RepInfo.bEnableWhitelist;
        ch_UseWhitelist.Checked(RepInfo.bUseWhitelist);
    }
}

event Opened(GUIComponent Sender)
{
	if ( bCaptureInput )
		FadeIn();

    foreach PlayerOwner().DynamicActors(Class'UTComp_ServerReplicationInfo', RepInfo)
        break;

    ch_UseWhitelist.bVisible=false;
    ch_UseWhitelist.Checked(false);

    if(RepInfo != None)
    {
        ch_UseWhitelist.bVisible=RepInfo.bEnableWhitelist;
        ch_UseWhitelist.Checked(RepInfo.bUseWhitelist);
    }

	Super.Opened(Sender);
}

function InternalOnChange( GUIComponent C )
{
    switch(C)
    {
        case ch_UseWhitelist:
            if(IsAdmin() && BS_xPlayer(PlayerOwner()) != None)
            {
                log("admin menu setting usewhitelist="$ch_UseWhitelist.IsChecked());
                BS_xPlayer(PlayerOwner()).ServerUseWhitelist(ch_UseWhitelist.IsChecked());
            }
            break;
    }
}

function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
    if (Key == 0x1B)
        return false;
    return true;
}

defaultproperties
{


    Begin Object Class=moCheckBox Name=WhitelistCheck
        Caption="Use UTComp player whitelist."
        OnCreateComponent=WhitelistCheck.InternalOnCreateComponent
        WinWidth=0.500000
        WinHeight=0.030000
        WinLeft=0.250000
        WinTop=0.330000
        OnChange=UTComp_Menu_Admin.InternalOnChange
    End Object
    ch_UseWhitelist=moCheckBox'UTComp_Menu_Admin.WhitelistCheck'
}
