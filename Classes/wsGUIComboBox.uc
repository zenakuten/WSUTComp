class wsGUIComboBox extends GUIComboBox;

#exec TEXTURE IMPORT NAME=WSDownArrow GROUP=GUI FILE=Textures\DownMark.dds MIPS=off ALPHA=1 DXT=5
#exec TEXTURE IMPORT NAME=WSLeftArrow GROUP=GUI FILE=Textures\LeftMark.dds MIPS=off ALPHA=1 DXT=5

var() Material DownArrow, LeftArrow;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    MyShowListBtn.Graphic = DownArrow;
    Super.Initcomponent(MyController, MyOwner);
}

function bool ShowListBox(GUIComponent Sender)
{
	if ( bDebugging )
		log(Name@"ShowListBox MyListBox.bVisible:"$MyListBox.bVisible);

	OnShowList();

    MyListBox.SetVisibility(!MyListBox.bVisible);
	if (MyListBox.bVisible)
		MyShowListBtn.Graphic = LeftArrow;
    else
	    MyShowListBtn.Graphic = DownArrow;

    if (MyListBox.bVisible)
    {
        List.SetFocus(none);
        List.SetTopItem(List.Index);
    }

    return true;
}

function HideListBox()
{
	if ( bDebugging )
		log(Name@"HideListBox");

	OnHideList();

	if ( Controller != None )
		MyShowListBtn.Graphic = DownArrow;

    MyListBox.Hide();
    List.SilentSetIndex( List.FindIndex(TextStr) );
}

defaultproperties
{
     DownArrow=Material'WSDownArrow'
     LeftArrow=Material'WSLeftArrow'

     MaxVisibleItems=8
     Index=-1
     Begin Object Class=GUIEditBox Name=EditBox1
         bNeverScale=True
         OnActivate=EditBox1.InternalActivate
         OnDeActivate=EditBox1.InternalDeactivate
         OnKeyType=EditBox1.InternalOnKeyType
         OnKeyEvent=EditBox1.InternalOnKeyEvent
         StyleName="WSButton"
         //StyleName="WSComboButton"
     End Object
     Edit=GUIEditBox'WSUTComp.wsGUIComboBox.EditBox1'

     Begin Object Class=GUIComboButton Name=ShowList
         StyleName="WSButton"
         ImageIndex=-1
         Graphic=Material'WSDownArrow'
         RenderWeight=0.600000
         bNeverScale=True
         OnKeyEvent=ShowList.InternalOnKeyEvent
     End Object
     MyShowListBtn=GUIComboButton'WSUTComp.wsGUIComboBox.ShowList'

     Begin Object Class=wsGUIListBox Name=ListBox1
         OnCreateComponent=ListBox1.InternalOnCreateComponent
         StyleName="WSButton"
         SelectedStyleName="WSListBox"
         SectionStyleName="WSButton"
         OutlineStyleName="WSListBox"
         RenderWeight=0.700000
         bTabStop=False
         bVisible=False
         bNeverScale=True
     End Object
     MyListBox=wsGUIListBox'WSUTComp.wsGUIComboBox.ListBox1'

     PropagateVisibility=True
     WinHeight=0.060000
     bAcceptsInput=True
     Begin Object Class=GUIToolTip Name=GUIComboBoxToolTip
     End Object
     ToolTip=GUIToolTip'WSUTComp.wsGUIComboBox.GUIComboBoxToolTip'

     OnKeyEvent=wsGUIComboBox.InternalOnKeyEvent
}