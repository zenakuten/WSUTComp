class wsGUISlider extends GUISlider;

#exec TEXTURE IMPORT NAME=WSSliderFill GROUP=GUI FILE=Textures\SliderFillBlurry.dds MIPS=off ALPHA=1 DXT=5


defaultproperties
{
    FillImage=Texture'WSUTComp.GUI.WSSliderFill'
    CaptionStyleName="WSSliderCaption"
    BarStyleName="WSSliderBar"
    StyleName="WSSliderKnob"
}