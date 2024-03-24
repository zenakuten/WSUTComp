class wsGUIScrollTextBox extends GUIScrollTextBox;

defaultproperties
{
    StyleName="WSLabelWhite"
    SectionStyleName="ListSection"
    
    Begin Object Class=wsGUIVertScrollBar Name=TheScrollbar
         bVisible=False
         OnPreDraw=TheScrollbar.GripPreDraw
    End Object
    MyScrollBar=wsGUIVertScrollBar'WSUTComp.wsGUIScrollTextBox.TheScrollbar'  
}