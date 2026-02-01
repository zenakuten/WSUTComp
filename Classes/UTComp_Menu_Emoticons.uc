//class UTComp_Menu_Emoticons extends UT2k3TabPanel;
class UTComp_Menu_Emoticons extends UTComp_Menu_MainMenu;

var automated AltSectionBackground BackG;
var automated GUIVertScrollBar ScrollBar;
var EmoticonsReplicationInfo ERI;
var int ScrollIndex;
var automated wsCheckBox ch_EnableEmoticons;
var automated GUIEditBox eb_Message;
var automated GUILabel lbl_Say;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);

    if(BS_xPlayer(PlayerOwner()) != None)
    {
        ERI = BS_xPlayer(PlayerOwner()).EmoteInfo;
        ScrollBar.ItemCount=ERI.Smileys.length;
    }

    if(HUDSettings != None)
    {
        ch_EnableEmoticons.Checked(HUDSettings.bEnableEmoticons);
    }
}

delegate PositionChanged(int NewPos)
{
	ScrollIndex = NewPos;
}

delegate OnRender(Canvas C)
{	
	local int i,j;
	local float x, y, w, h;
	local float iconY;
	
	x = PageOwner.ActualWidth() * 0.1;
	y = PageOwner.ActualTop() * 1.75;
	w = PageOwner.ActualWidth() * 1.00;
	h = PageOwner.ActualHeight() * 1.00;
	
	C.DrawColor.R = 255;
	C.DrawColor.G = 255;
	C.DrawColor.B = 255;
	C.DrawColor.A = 255;
	
	C.SetOrigin(x+64, y+128);
	C.SetClip(w,h);

    if(ERI == None)
        return;
	
	iconY = 0;
	
	for(i=0; i<ERI.Smileys.Length; i+=4)	
	{		
		if(ScrollIndex>i)
			continue;
			
        for(j=0;j<4 && i+j<ERI.Smileys.Length;j++)
        {
            C.SetPos(j*384,iconY);
            if(ERI.Smileys[i+j].Icon != None)
                C.DrawTile(ERI.Smileys[i+j].Icon, 64,64, 0,0,64,64);
            else if(ERI.Smileys[i+j].MatIcon != None)
                C.DrawTile(ERI.Smileys[i+j].MatIcon, 64,64, 0,0,64,64);
            C.SetPos(64+j*384,iconY+24);
            C.DrawText(ERI.Smileys[i+j].Event);
        }
		
		iconY += 64;
		
		if(C.OrgY+iconY+32 >= C.ClipY)
			break;
	}
}

function InternalOnChange( GUIComponent C )
{
    Switch(C)
    {
        case ch_EnableEmoticons: HUDSettings.bEnableEmoticons=ch_EnableEmoticons.IsChecked();  break;
    }

    SaveHUDSettings();
}

function bool InternalOnEmoteClick(GUIComponent C)
{
    local int Index;
    local string smileyCmd;

    Index=CalcIndex();
    if(Index >= 0)
    {
        smileyCmd=ERI.Smileys[Index].Event;
        eb_Message.TextStr = eb_Message.TextStr$smileyCmd;
        eb_Message.CaretPos = len(eb_Message.TextStr);
    }

    return true;
}

function int CalcIndex()
{
	local float left,top;
    local int coord, x, y, item;
	
	top = PageOwner.ActualTop() * 1.75;
	left = PageOwner.ActualWidth() * 0.1;

    x = clamp((Controller.MouseX - left) / 320,0,3);
    y = ((Controller.MouseY - top) / 64)-2;
    coord = y * 4 + x;
    item = coord + ((scrollindex+2)/4)*4;

    if(item < 0)
        item = -1;
    if(item>ERI.Smileys.Length-1)
        item = -1;

    return item;
}

function bool InternalOnEmoteKeyEvent(out byte Key, out byte State, float delta)
{
    local string text;
    if(Key==13)
    {
        text = eb_Message.GetText();
        if(text != "")
            PlayerOwner().Player.Console.DelayedConsoleCommand("Say "@text);

        eb_Message.SetText("");
        return false;
    }

    if(Key==0xEC)
    {
        ScrollBar.WheelUp();
    }
    else if(Key==0xED)
    {
        ScrollBar.WheelDown();
    }

    return eb_Message.InternalOnKeyEvent(Key, State, delta);
}

function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
    if(Key==0xEC)
    {
        ScrollBar.WheelUp();
    }
    else if(Key==0xED)
    {
        ScrollBar.WheelDown();
    }

    return false;
}


defaultproperties
{
     Begin Object Class=wsGUIVertScrollBar Name=ScrollBarObj
         ItemsPerPage=5
         PositionChanged=UTComp_Menu_Emoticons.PositionChanged
         WinTop=0.300000
         WinLeft=0.885000
         WinWidth=0.035000
         WinHeight=0.520000
         OnPreDraw=ScrollBarObj.GripPreDraw
         OnRendered=UTComp_Menu_Emoticons.OnRender
     End Object
     ScrollBar=wsGUIVertScrollBar'WSUTComp.UTComp_Menu_Emoticons.ScrollBarObj'

    Begin Object class=wsCheckBox name=EnableEmoticonsCheck
		WinWidth=0.150000
		WinHeight=0.030000
		WinLeft=0.70000
		WinTop=0.300000
        Caption="Enable Emoticons"
        OnChange=InternalOnChange
        OnCreateComponent=EnableEmoticonsCheck.InternalOnCreateComponent
    End Object
    ch_EnableEmoticons=wsCheckBox'UTComp_Menu_Emoticons.EnableEmoticonsCheck'

    Begin Object Class=GUILabel Name=SayLabel
        Caption="Say:"
        TextColor=(R=255,G=255,B=255,A=255)
        WinTop=0.764162
        WinLeft=0.325062
    End Object
    lbl_Say=GUILabel'UTComp_Menu_Emoticons.SayLabel'

    Begin Object Class=GUIEditBox Name=MessageEditBox
        StyleName="WSEditBox"
		WinWidth=0.50500
		WinHeight=0.035000
		WinLeft=0.359062
		WinTop=0.779162
         OnActivate=MessageEditBox.InternalActivate
         OnDeActivate=MessageEditBox.InternalDeactivate
         OnKeyType=MessageEditBox.InternalOnKeyType
         OnKeyEvent=UTComp_Menu_Emoticons.InternalOnEmoteKeyEvent
    End Object
    eb_Message=GUIEditBox'UTComp_Menu_Emoticons.MessageEditBox'

    OnClick=InternalOnEmoteClick
    OnKeyEvent=InternalOnKeyEvent
}