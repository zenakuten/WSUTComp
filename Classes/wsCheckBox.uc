// ====================================================================
//  Class:  XInterface.wsCheckBox
//  Combines a label and check box button.
// ====================================================================

class wsCheckBox extends moCheckBox;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    local GUIStyles S;
    Super(GUIMenuOption).Initcomponent(MyController, MyOwner);

    MyCheckBox = wsGUICheckBoxButton(MyComponent);
    MyCheckBox.OnChange = ButtonChecked;
    MyCheckBox.OnClick = InternalClick;

    S = Controller.GetStyle(CheckStyleName,MyCheckBox.FontScale);
    if ( S != none )
        MyCheckBox.Graphic = S.Images[0];
}

defaultproperties
{
     bSquare=True
     CaptionWidth=0.800000
     ComponentClassName="WSUTComp.wsGUICheckBoxButton"
     LabelStyleName="WSLabel"
}
