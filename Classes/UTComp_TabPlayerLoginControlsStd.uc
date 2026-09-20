// Join/spectate panel for the standard login menu.  BS_xPlayer lifts the
// matching server side rule (GameInfo.BecomeSpectator / AllowBecomeActivePlayer
// both refuse before the match has begun), so the click is actually honoured.
Class UTComp_TabPlayerLoginControlsStd extends UT2K4Tab_PlayerLoginControls;

// The stock tab keeps the Join Game / Spectate button disabled until the match
// has begun.  Every other guard it applies is kept; only that one is dropped.
function bool UTCompShouldEnableSpecButton()
{
    local GameReplicationInfo GRI;
    local PlayerController PC;

    PC = PlayerOwner();
    if (PC == None || PC.PlayerReplicationInfo == None)
        return false;

    GRI = GetGRI();
    if (GRI == None || GRI.bMatchHasBegun)
        return false;          // stock already enables it, leave it alone

    if (PC.myHUD != None && PC.myHUD.IsInCinematic())
        return false;

    if (PC.IsInState('GameEnded'))
        return false;

    if (GRI.MaxLives > 0 && PC.PlayerReplicationInfo.bOnlySpectator)
        return false;

    return true;
}

function bool InternalOnPreDraw(Canvas C)
{
    local bool bResult;

    bResult = Super.InternalOnPreDraw(C);
    if (UTCompShouldEnableSpecButton())
        EnableComponent(b_Spec);

    return bResult;
}

defaultproperties
{
}
