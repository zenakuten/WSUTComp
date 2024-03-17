class wsGUIVertScrollBar extends GUIVertScrollBar;

defaultproperties
{
    StyleName="WSButton"
     Begin Object Class=GUIVertScrollZone Name=ScrollZone
         StyleName="WSButton"
         OnScrollZoneClick=GUIVertScrollBar.ZoneClick
         OnClick=ScrollZone.InternalOnClick
     End Object
     MyScrollZone=GUIVertScrollZone'WSUTComp.wsGUIVertScrollBar.ScrollZone'

     Begin Object Class=wsGUIVertScrollButton Name=DownBut
         bIncreaseButton=True
         OnClick=GUIVertScrollBar.IncreaseClick
         OnKeyEvent=DownBut.InternalOnKeyEvent
         StyleName="WSVertDownButton"
     End Object
     MyIncreaseButton=wsGUIVertScrollButton'WSUTComp.wsGUIVertScrollBar.DownBut'

     Begin Object Class=wsGUIVertScrollButton Name=UpBut
         OnClick=GUIVertScrollBar.DecreaseClick
         OnKeyEvent=UpBut.InternalOnKeyEvent
         StyleName="WSVertUpButton"
     End Object
     MyDecreaseButton=wsGUIVertScrollButton'WSUTComp.wsGUIVertScrollBar.UpBut'

     Begin Object Class=GUIVertGripButton Name=Grip
         OnMousePressed=GUIVertScrollBar.GripPressed
         OnKeyEvent=Grip.InternalOnKeyEvent
         StyleName="WSSliderKnob"
     End Object
     MyGripButton=GUIVertGripButton'WSUTComp.wsGUIVertScrollBar.Grip'    
}