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

// The base slider only refreshes its value tooltip while dragging, so after a
// programmatic value change (a reset button, config load, etc.) a hover shows the
// stale value. Refresh the tip from the current value each time it is about to show.
// (Mirrors the default GUIComponent.OnBeginTooltip body, plus the refresh.)
function GUIToolTip RefreshValueTooltip()
{
    if ( bShowValueTooltip && ToolTip != None )
        ToolTip.SetTip( GetValueString() );

    if ( ToolTip != None )
        return ToolTip.EnterArea();
    if ( MenuOwner != None )
        return MenuOwner.OnBeginTooltip();
    return None;
}


defaultproperties
{
    FillImage=Texture'WSUTComp.GUI.WSSliderFill'
    CaptionStyleName="WSSliderCaption"
    BarStyleName="WSSliderBar"
    StyleName="WSSliderKnob"
    OnBeginTooltip=wsGUISlider.RefreshValueTooltip
}