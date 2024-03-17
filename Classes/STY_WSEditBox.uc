class STY_WSEditBox extends STY2SquareButton;

#exec TEXTURE IMPORT NAME=WSEditBlur GROUP=GUI FILE=Textures\EditBoxBlurry.dds MIPS=off ALPHA=1 DXT=5
#exec TEXTURE IMPORT NAME=WSEditFocus GROUP=GUI FILE=Textures\EditBoxFocused.dds MIPS=off ALPHA=1 DXT=5
#exec TEXTURE IMPORT NAME=WSEditWatch GROUP=GUI FILE=Textures\EditBoxWatched.dds MIPS=off ALPHA=1 DXT=5
#exec TEXTURE IMPORT NAME=WSEditDisable GROUP=GUI FILE=Textures\EditBoxDisabled.dds MIPS=off ALPHA=1 DXT=5

//description:
//	Img(0) Blurry	(component has no focus at all)
//	Img(1) Watched	(when Mouse is hovering over it)
//	Img(2) Focused	(component is selected)
//	Img(3) Pressed	(component is being pressed)
//	Img(4) Disabled	(component is disabled)

defaultproperties
{
	KeyName="WSEditBox"
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
	Images(0)=Texture'WSUTComp.GUI.WSEditBlur'
	Images(1)=Texture'WSUTComp.GUI.WSEditWatch'
	Images(2)=Texture'WSUTComp.GUI.WSEditFocus'
	Images(3)=Texture'WSUTComp.GUI.WSEditFocus'
	Images(4)=Texture'WSUTComp.GUI.WSEditDisable'
}