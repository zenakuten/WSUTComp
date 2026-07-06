
class STY_WSSliderKnobWhite extends STY_WSSliderKnob;

#exec TEXTURE IMPORT NAME=WSSliderKnobWhite GROUP=GUI FILE=Textures\SliderKnobWhite.dds MIPS=off ALPHA=1 DXT=5

// Same as WSSliderKnob but with a white grab bar instead of cyan. Used by the R/G/B
// color sliders so their knob doesn't clash with the colored fill.

defaultproperties
{
	KeyName="WSSliderKnobWhite"
	Images(0)=Texture'WSUTComp.GUI.WSSliderKnobWhite'
	Images(1)=Texture'WSUTComp.GUI.WSSliderKnobWhite'
	Images(2)=Texture'WSUTComp.GUI.WSSliderKnobWhite'
	Images(3)=Texture'WSUTComp.GUI.WSSliderKnobWhite'
	Images(4)=Texture'WSUTComp.GUI.WSSliderKnobWhite'
}
