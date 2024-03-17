class wsGUIListBox extends GUIListBox;

defaultproperties
{
    StyleName="WSButton"
    SectionStyleName="ListSection"
    
    Begin Object Class=wsGUIVertScrollBar Name=TheScrollbar
         bVisible=False
         OnPreDraw=TheScrollbar.GripPreDraw
    End Object
    MyScrollBar=wsGUIVertScrollBar'WSUTComp.wsGUIListBox.TheScrollbar'    
    
}