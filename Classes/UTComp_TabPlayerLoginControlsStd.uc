// Join/spectate panel for the standard login menu.  BS_xPlayer lifts the
// matching server side rules (GameInfo.BecomeSpectator / AllowBecomeActivePlayer
// both refuse before the match has begun and after it has ended), so the click
// is actually honoured.
Class UTComp_TabPlayerLoginControlsStd extends UT2K4Tab_PlayerLoginControls;

// The stock tab keeps the Join Game / Spectate button disabled until the match
// has begun and again once it has ended.  Every other guard it applies is kept;
// only those two are dropped.
function bool UTCompShouldEnableSpecButton()
{
    local GameReplicationInfo GRI;
    local PlayerController PC;

    PC = PlayerOwner();
    if (PC == None || PC.PlayerReplicationInfo == None)
        return false;

    GRI = GetGRI();
    if (GRI == None)
        return false;

    if (PC.myHUD != None && PC.myHUD.IsInCinematic())
        return false;

    // After the match stock disables it too.  BS_xPlayer's GameEnded state takes
    // the click and applies it to the next map, so lives don't matter here.
    if (PC.IsInState('GameEnded'))
        return true;

    if (GRI.bMatchHasBegun)
        return false;          // stock already enables it, leave it alone

    if (GRI.MaxLives > 0 && PC.PlayerReplicationInfo.bOnlySpectator)
        return false;

    return true;
}

function bool InternalOnPreDraw(Canvas C)
{
    local bool bResult, bOverride;
    local GUIButton SpecButton;

    // Keep the stock pass from disabling the button when we want it enabled.
    // Disabling and re-enabling it every frame resets its hover/pressed state,
    // which can swallow the click.  The first pass needs b_Spec for InitGRI.
    bOverride = UTCompShouldEnableSpecButton();
    if (bOverride && !bInit)
    {
        SpecButton = b_Spec;
        b_Spec = None;
    }

    bResult = Super.InternalOnPreDraw(C);

    if (SpecButton != None)
        b_Spec = SpecButton;
    if (bOverride)
        EnableComponent(b_Spec);

    return bResult;
}

defaultproperties
{
}
