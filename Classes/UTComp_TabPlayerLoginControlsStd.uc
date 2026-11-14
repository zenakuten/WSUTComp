// Join/spectate panel for the standard login menu.  BS_xPlayer lifts the
// matching server side rules (GameInfo.BecomeSpectator / AllowBecomeActivePlayer
// both refuse before the match has begun and after it has ended), so the click
// is actually honoured.
// Also adds the admin "UTComp ban" context item, like UTComp_TabPlayerLoginControls.
Class UTComp_TabPlayerLoginControlsStd extends UT2K4Tab_PlayerLoginControls;

var UTComp_ServerReplicationInfo RepInfo;

// Stock fills items 0-5, adds 6-8 (separator, Kick, Ban) for admins and trims
// everything past 5 for everyone else.  The UTComp ban goes in at 9.
function bool ContextMenuOpened(GUIContextMenu Menu)
{
    if (!Super.ContextMenuOpened(Menu))
        return false;

    if (!PlayerOwner().PlayerReplicationInfo.bAdmin)
        return true;

    if (RepInfo == None)
        foreach PlayerOwner().DynamicActors(Class'UTComp_ServerReplicationInfo', RepInfo)
            break;

    if (RepInfo != None && RepInfo.bUseDefaultScoreboardColor)
        Menu.ContextItems[9] = "UTComp ban ["$GUIList(Controller.ActiveControl).Get()$"]";
    else if (Menu.ContextItems.Length > 9)
        Menu.ContextItems.Remove(9, Menu.ContextItems.Length - 9);

    return true;
}

function ContextClick(GUIContextMenu Menu, int ClickIndex)
{
    local GUIList List;
    local PlayerController PC;
    local GameReplicationInfo GRI;

    // Stock has no case for 9 and would just return.
    if (ClickIndex != 9)
    {
        Super.ContextClick(Menu, ClickIndex);
        return;
    }

    GRI = GetGRI();
    List = GUIList(Controller.ActiveControl);
    if (GRI == None || List == None || GRI.FindPlayerByID(int(List.GetExtra())) == None)
        return;

    PC = PlayerOwner();
    if (BS_xPlayer(PC) != None)
        BS_xPlayer(PC).ServerSetMenuColor(List.GetExtra());
}

// The stock tab keeps the Join Game / Spectate button disabled until the match
// has begun and again once it has ended.  Every other guard it applies is kept;
// only those two are dropped.  Between rounds the button is held enabled too.
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

    // Mid-round stock already enables it, so leave it alone.  Between rounds
    // (RoundEnded, e.g. Assault) BS_xPlayer's RoundEnded state takes the click.
    if (GRI.bMatchHasBegun && !PC.IsInState('RoundEnded'))
        return false;

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
