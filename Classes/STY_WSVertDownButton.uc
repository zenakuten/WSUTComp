class STY_WSVertDownButton extends STY2VertDownButton;

#exec TEXTURE IMPORT NAME=WSButton GROUP=GUI FILE=Textures\buttonThin_d.tga MIPS=off ALPHA=1
#exec TEXTURE IMPORT NAME=WSWatch GROUP=GUI FILE=Textures\buttonThick_d.tga MIPS=off ALPHA=1
#exec TEXTURE IMPORT NAME=WSNone GROUP=GUI FILE=Textures\button_none.tga MIPS=off ALPHA=1

//description:
//	Img(0) Blurry	(component has no focus at all)
//	Img(1) Watched	(when Mouse is hovering over it)
//	Img(2) Focused	(component is selected)
//	Img(3) Pressed	(component is being pressed)
//	Img(4) Disabled	(component is disabled)

defaultproperties
{
	KeyName="WSVertDownButton"
	FontColors(0)=(R=255,G=255,B=255)
	FontColors(1)=(R=0,G=255,B=255)
	FontColors(2)=(R=0,G=255,B=255)
	FontColors(3)=(R=0,G=255,B=255)
	FontColors(4)=(R=60,G=60,B=60)
	ImgColors(0)=(B=200,G=200,R=200,A=200)
	ImgColors(1)=(B=200,G=200,R=200,A=170)
	ImgColors(2)=(B=200,G=200,R=200,A=170)
	ImgColors(3)=(B=200,G=200,R=200,A=190)
	ImgColors(4)=(B=200,G=200,R=200,A=80)
	Images(0)=Texture'WSUTComp.GUI.WSButton'
	Images(1)=Texture'WSUTComp.GUI.WSWatch'
	Images(2)=Texture'WSUTComp.GUI.WSWatch'
	Images(3)=Texture'WSUTComp.GUI.WSButton'
	Images(4)=Texture'WSUTComp.GUI.WSNone'
}