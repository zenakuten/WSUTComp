
class STY_WSButtonTab extends STY_WSButton;

// Tab-button style: like WSButton but the Focused state renders like the normal
// (Blurry) state. When a menu opens the framework auto-focuses a tab button, and the
// stock WSButton draws Focused in cyan -- which made an unrelated tab look highlighted.
// Hover (Watched) stays cyan so buttons still highlight under the mouse.

defaultproperties
{
	KeyName="WSButtonTab"
	FontColors(2)=(R=255,G=255,B=255)
	ImgColors(2)=(B=200,G=200,R=200,A=200)
	Images(2)=Texture'WSUTComp.GUI.WSButton'
}
