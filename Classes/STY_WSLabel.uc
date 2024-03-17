class STY_WSLabel extends STY2TextLabel;

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
	KeyName="WSLabel"
	FontColors(0)=(R=255,G=255,B=255)
	FontColors(1)=(R=0,G=255,B=255)
	FontColors(2)=(R=0,G=255,B=255)
	FontColors(3)=(R=0,G=255,B=255)
	FontColors(4)=(R=60,G=60,B=60)
}