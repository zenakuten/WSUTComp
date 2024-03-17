
class STY_WSSliderBar extends STY2SliderBar;

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
	KeyName="WSSliderBar"
	FontColors(0)=(R=255,G=255,B=255)
	FontColors(1)=(R=0,G=255,B=255)
	FontColors(2)=(R=0,G=255,B=255)
	FontColors(3)=(R=0,G=255,B=255)
	FontColors(4)=(R=60,G=60,B=60)
	ImgColors(0)=(B=255,G=255,R=255,A=255)
	ImgColors(1)=(B=255,G=255,R=255,A=255)
	ImgColors(2)=(B=255,G=255,R=255,A=255)
	ImgColors(3)=(B=255,G=255,R=255,A=255)
	ImgColors(4)=(B=255,G=255,R=255,A=255)
	Images(0)=Texture'WSUTComp.GUI.WSButton'
	Images(1)=Texture'WSUTComp.GUI.WSWatch'
	Images(2)=Texture'WSUTComp.GUI.WSWatch'
	Images(3)=Texture'WSUTComp.GUI.WSButton'
	Images(4)=Texture'WSUTComp.GUI.WSNone'
}