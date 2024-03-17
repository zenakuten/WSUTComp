class wsGUINumericEdit extends GUINumericEdit;

defaultproperties
{
    Begin Object Class=GUIEditBox Name=cMyEditBox
         bIntOnly=True
         bNeverScale=True
         StyleName="WSEditBox"
         OnActivate=cMyEditBox.InternalActivate
         OnDeActivate=cMyEditBox.InternalDeactivate
         OnKeyType=cMyEditBox.InternalOnKeyType
         OnKeyEvent=cMyEditBox.InternalOnKeyEvent
     End Object
     MyEditBox=GUIEditBox'WSUTComp.wsGUINumericEdit.cMyEditBox'

     Begin Object Class=GUISpinnerButton Name=cMySpinner
         StyleName="WSSpinner"     
         bTabStop=False
         bNeverScale=True
         OnClick=cMySpinner.InternalOnClick
         OnKeyEvent=cMySpinner.InternalOnKeyEvent
     End Object
     MySpinner=GUISpinnerButton'WSUTComp.wsGUINumericEdit.cMySpinner'

     StyleName="WSButton"
     Value="0"
     MinValue=-9999
     MaxValue=9999
     Step=1
     PropagateVisibility=True
     WinHeight=0.060000
     bAcceptsInput=True
     Begin Object Class=GUIToolTip Name=GUINumericEditToolTip
     End Object
     ToolTip=GUIToolTip'WSUTComp.wsGUINumericEdit.GUINumericEditToolTip
}