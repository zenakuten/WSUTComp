//class UTComp_Menu_Emoticons extends UT2k3TabPanel;
class UTComp_Menu_Emoticons extends UTComp_Menu_MainMenu;

var automated AltSectionBackground BackG;
var automated GUIVertScrollBar ScrollBar;
var EmoticonsReplicationInfo ERI;
var int Offset;
var automated moCheckBox ch_EnableEmoticons;

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
	Offset = NewPos;
}

delegate OnRender(Canvas C)
{	
	local int i;
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
	
	for(i=0; i<ERI.Smileys.Length; ++i)
	{		
		if(Offset>i)
			continue;
			
		C.SetPos(0,iconY);
        if(ERI.Smileys[i].Icon != None)
            C.DrawTile(ERI.Smileys[i].Icon, 64,64, 0,0,64,64);
        else if(ERI.Smileys[i].MatIcon != None)
            C.DrawTile(ERI.Smileys[i].MatIcon, 64,64, 0,0,64,64);
		C.SetPos(128,iconY+24);
		C.DrawText(ERI.Smileys[i].Event);
		
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

defaultproperties
{
     Begin Object Class=GUIVertScrollBar Name=ScrollBarObj
         ItemsPerPage=5
         PositionChanged=UTComp_Menu_Emoticons.PositionChanged
         WinTop=0.300000
         WinLeft=0.885000
         WinWidth=0.035000
         WinHeight=0.520000
         OnPreDraw=ScrollBarObj.GripPreDraw
         OnRendered=UTComp_Menu_Emoticons.OnRender
     End Object
     ScrollBar=GUIVertScrollBar'UTCompOmni.UTComp_Menu_Emoticons.ScrollBarObj'

    Begin Object class=moCheckBox name=EnableEmoticonsCheck
		WinWidth=0.150000
		WinHeight=0.030000
		WinLeft=0.70000
		WinTop=0.300000
        Caption="Enable Emoticons"
        OnChange=InternalOnChange
        OnCreateComponent=SpeedCheck.InternalOnCreateComponent
    End Object
    ch_EnableEmoticons=moCheckBox'UTComp_Menu_Emoticons.EnableEmoticonsCheck'
}