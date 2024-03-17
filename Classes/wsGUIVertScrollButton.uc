class wsGUIVertScrollButton extends GUIVertScrollButton;

#exec TEXTURE IMPORT NAME=WSDownArrow GROUP=GUI FILE=Textures\DownMark.dds MIPS=off ALPHA=1 DXT=5
#exec TEXTURE IMPORT NAME=WSUpArrow GROUP=GUI FILE=Textures\UpMark.dds MIPS=off ALPHA=1 DXT=5

var() Material UpArrow, DownArrow;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    if(bIncreaseButton)
    {
        Graphic=DownArrow;
    }

	Super(GUIScrollButtonBase).Initcomponent(MyController, MyOwner);
}

defaultproperties
{
    ImageIndex=-1
    DownArrow=Material'WSDownArrow'
    UpArrow=Material'WSUpArrow'
    Graphic=Material'WSUpArrow'
}