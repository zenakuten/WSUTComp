
class STY_WSButtonActive extends STY_WSButton;

// Same as WSButton, but the Blurry (unfocused/unhovered) state renders like the Watched
// state -- cyan caption + thick WSWatch image -- so the tab button for the currently
// open menu stays highlighted even when it isn't hovered or focused.

defaultproperties
{
	KeyName="WSButtonActive"
	FontColors(0)=(R=0,G=255,B=255)
	ImgColors(0)=(B=200,G=200,R=200,A=170)
	Images(0)=Texture'WSUTComp.GUI.WSWatch'
}
