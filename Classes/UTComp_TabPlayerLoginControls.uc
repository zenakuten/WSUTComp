// ONSPlus: Coded by Shambler (Shambler__@Hotmail.com or Shambler@OldUnreal.com , ICQ:108730864)
Class UTComp_TabPlayerLoginControls extends UT2k4Tab_PlayerLoginControlsOnslaught;

var UTComp_ServerReplicationInfo RepInfo;

function bool ButtonClicked(GUIComponent Sender)
{
	local PlayerController PC;

	PC = PlayerOwner();

	if (GUITabControl(MenuOwner) != None && GUITabControl(MenuOwner).TabStack.Length > 0 && GUITabControl(MenuOwner).TabStack[0] != None
		&& GUITabControl(MenuOwner).TabStack[0].MyPanel != None)
	{
        return Super.ButtonClicked(Sender);
	}
	else
	{
		return False;
	}

	return True;
}


// Added "Spectate player" option to right-click context menu
function bool ContextMenuOpened(GUIContextMenu Menu)
{
	local GUIList List;
	local PlayerReplicationInfo PRI;
	local byte Restriction;
	local GameReplicationInfo GRI;
	local int PlayerID;


	GRI = GetGRI();

	if (GRI == None)
		return false;

	List = GUIList(Controller.ActiveControl);

	if (List == None)
	{
		return False;
	}

	if (!List.IsValid())
		return False;

    if (RepInfo==None)
        foreach PlayerOwner().DynamicActors(Class'UTComp_ServerReplicationInfo', RepInfo)
            break;

	PlayerID = int(List.GetExtra());
	PRI = GRI.FindPlayerByID(PlayerID);

	if (PRI == None || PRI.bBot || PlayerIDIsMine(PlayerID))
    {
		return False;
    }

	Restriction = PlayerOwner().ChatManager.GetPlayerRestriction(PlayerID);

	if (bool(Restriction & 1))
		Menu.ContextItems[0] = ContextItems[0];
	else
		Menu.ContextItems[0] = DefaultItems[0];

	if (bool(Restriction & 2))
		Menu.ContextItems[1] = ContextItems[1];
	else
		Menu.ContextItems[1] = DefaultItems[1];

	if (bool(Restriction & 4))
		Menu.ContextItems[2] = ContextItems[2];
	else
		Menu.ContextItems[2] = DefaultItems[2];

	if (bool(Restriction & 8))
		Menu.ContextItems[3] = ContextItems[3];
	else
		Menu.ContextItems[3] = DefaultItems[3];

	PlayerID = int(List.GetExtra());
	Menu.ContextItems[4] = "-";
	Menu.ContextItems[5] = "Spectate Player";
	Menu.ContextItems[6] = BuddyText;

    Menu.ContextItems[7] = "WhoIs";

	if (PlayerOwner().PlayerReplicationInfo.bAdmin)
	{
		Menu.ContextItems[8] = "-";
		Menu.ContextItems[9] = KickPlayer$"["$List.Get()$"]";
		Menu.ContextItems[10] = BanPlayer$"["$List.Get()$"]";
        if(RepInfo != None && RepInfo.bUseDefaultScoreboardColor)
        {
            Menu.ContextItems[11] = "UTComp ban "$"["$List.Get()$"]";
        }
	}
	else if (Menu.ContextItems.Length > 8)
	{
		Menu.ContextItems.Remove(8, Menu.ContextItems.Length - 8);
	}

	return True;
}

function ContextClick(GUIContextMenu Menu, int ClickIndex)
{
	local bool bUndo;
	local byte Type;
	local GUIList List;
	local PlayerController PC;
	local PlayerReplicationInfo PRI;
	local GameReplicationInfo GRI;
	local int PlayerID;

	GRI = GetGRI();

	if (GRI == None)
		return;

	PC = PlayerOwner();
    if(ClickIndex < 4)
        bUndo = Menu.ContextItems[ClickIndex] == ContextItems[ClickIndex];
	List = GUIList(Controller.ActiveControl);

	if (List == None)
		return;

	PlayerID = int(List.GetExtra());
	PRI = GRI.FindPlayerById(PlayerID);

	if (PRI == None)
		return;

	if (ClickIndex > 7)	// Admin stuff
	{
		switch (ClickIndex)
		{
			case 8:
			case 9:
				PC.AdminCommand("admin kick"@List.GetExtra());
				break;

			case 10:
				PC.AdminCommand("admin kickban"@List.GetExtra());
				break;
            case 11:
                if(BS_xPlayer(PC) != None)
                    BS_xPlayer(PC).ServerSetMenuColor(List.GetExtra());
				PC.AdminCommand("admin kickban"@List.GetExtra());
                break;

		}

		return;
	}

	if (ClickIndex > 3)
	{
		switch (ClickIndex)
		{
			case 5:
				if (!PC.PlayerReplicationInfo.bOnlySpectator)
					PC.BecomeSpectator();

				if (BS_xPlayer(PC) != none)
					BS_xPlayer(PC).ServerViewPlayer(PlayerID);

				break;
			case 6:
				Controller.AddBuddy(List.Get());                
				break;
			case 7:
                PC.ClientMessage("²*** Running Whois on"@PRI.PlayerName@"***");
                // try both. AntiTCC and ClanManager version
                // PC.ConsoleCommand("WhoIs"@StripColorCodes(PRI.PlayerName));
                PC.ConsoleCommand("CM WhoIs"@StripColorCodes(PRI.PlayerName));                
				break;
			case 4:
		}

		return;
	}

	Type = 1 << ClickIndex;

	if (bUndo)
	{
		if (PC.ChatManager.ClearRestrictionID(PRI.PlayerID, Type))
		{
			PC.ServerChatRestriction(PRI.PlayerID, PC.ChatManager.GetPlayerRestriction(PRI.PlayerID));
			ModifiedChatRestriction(Self, PRI.PlayerID);
		}
	}
	else
	{
		if (PC.ChatManager.AddRestrictionID(PRI.PlayerID, Type))
		{
			PC.ServerChatRestriction(PRI.PlayerID, PC.ChatManager.GetPlayerRestriction(PRI.PlayerID));
			ModifiedChatRestriction(Self, PRI.PlayerID);
		}
	}
}

defaultproperties
{
    Begin Object Class=GUIContextMenu name=PlayerListContextMenu
		OnSelect=ContextClick
		OnOpen=ContextMenuOpened
	End Object
	ContextMenu=PlayerListContextMenu
}