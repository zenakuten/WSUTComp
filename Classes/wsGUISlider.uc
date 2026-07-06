class wsGUISlider extends GUISlider;

#exec TEXTURE IMPORT NAME=WSSliderFill GROUP=GUI FILE=Textures\SliderFillBlurry.dds MIPS=off ALPHA=1 DXT=5
#exec TEXTURE IMPORT NAME=WSSliderFillRed GROUP=GUI FILE=Textures\SliderFillRed.dds MIPS=off ALPHA=1 DXT=5
#exec TEXTURE IMPORT NAME=WSSliderFillGreen GROUP=GUI FILE=Textures\SliderFillGreen.dds MIPS=off ALPHA=1 DXT=5
#exec TEXTURE IMPORT NAME=WSSliderFillBlue GROUP=GUI FILE=Textures\SliderFillBlue.dds MIPS=off ALPHA=1 DXT=5

// Fired on every mouse-drag step (not just on release), so owners can do live updates.
delegate OnSliding(GUIComponent Sender);

function bool InternalCapturedMouseMove(float deltaX, float deltaY)
{
    local bool bResult;

    bResult = Super.InternalCapturedMouseMove(deltaX, deltaY);
    OnSliding(self);
    return bResult;
}


defaultproperties
{
    FillImage=Texture'WSUTComp.GUI.WSSliderFill'
    CaptionStyleName="WSSliderCaption"
    BarStyleName="WSSliderBar"
    StyleName="WSSliderKnob"
}