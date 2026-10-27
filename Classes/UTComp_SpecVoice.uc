//-----------------------------------------------------------
// Spectator voice chat HUD and menu (MutUTComp.bSpectatorVoiceChat)
//-----------------------------------------------------------
// Client only, added by BS_xPlayer.InitializeClient(). Does nothing unless the local player is a
// spectator; the server side is in BS_xPlayer (SpecVoiceJoin and friends).
//  - HUD: HudCDeathmatch draws the talk meter (DrawHudPassA) and talker portrait (DrawHudPassC)
//    only from DrawHud(), which HUD.PostRender() skips for the spectating HUD. Its Tick() still
//    tracks who is talking, and interactions render after the HUD, so this draws the same two.
//  - Menu: the stock speech menu is unusable for spectators. ExtendedConsole.SpeechMenuToggle()
//    returns for bOnlySpectator, and UnrealChatRoom.CanJoinChannel() hides every channel. The
//    console runs the SpeechMenuToggle command before any local interaction sees it, but key
//    presses reach interactions before the binding fires, so the bound key is intercepted.
//    Public is the only room a spectator can use (Local needs a pawn), plus their coached team's.
class UTComp_SpecVoice extends Interaction;

var BS_xPlayer PC;
var VoiceChatRoom PublicRoom, TeamRoom; // cached, re-resolved while None

var bool bMenuOpen;
var int NumRows;       // 2, or 4 for a coach; set when the menu opens
var string KeyText[4]; // "1-" etc. in the console's key style; set when the menu opens

var localized string TalkText, StopTalkText, JoinText, LeaveText;

event Initialized()
{
    PC = BS_xPlayer(ViewportOwner.Actor);
}

event NotifyLevelChange()
{
    if (PC != None && PC.SpecVoice == self)
        PC.SpecVoice = None;
    PC = None;
    PublicRoom = None;
    TeamRoom = None;
    Master.RemoveInteraction(self);
}

function bool IsSpectator()
{
    return PC != None && PC.PlayerReplicationInfo != None && PC.PlayerReplicationInfo.bOnlySpectator;
}

function VoiceChatRoom GetPublicRoom()
{
    if (PublicRoom == None)
        PublicRoom = PC.GetSpecVoiceRoom(false);
    return PublicRoom;
}

// None unless coaching
function VoiceChatRoom GetTeamRoom()
{
    if (TeamRoom == None)
        TeamRoom = PC.GetSpecVoiceRoom(true);
    return TeamRoom;
}

// By the member bit alone: Room.IsMember() and GetMembers() are false/empty once the mask goes
// negative (see UTComp_SpecVoiceMaskFix)
function bool InRoom(VoiceChatRoom Room, PlayerReplicationInfo PRI)
{
    // 255 = not replicated yet. 3374 servers hand out IDs past 31 that share bit VoiceID & 31.
    return PRI != None && PRI.VoiceID != 255 && bool(Room.GetMask() & (1 << (PRI.VoiceID & 31)));
}

// =====================================================================================================================
//  Input
// =====================================================================================================================

function bool IsSpeechMenuKey(EInputKey Key)
{
    // KEYBINDING takes the EInputKey name minus "IK_"
    return InStr(Caps(PC.ConsoleCommand("KEYBINDING" @ Mid(GetEnum(enum'EInputKey', Key), 3))), "SPEECHMENUTOGGLE") != -1;
}

// Same key scheme as the stock menu (bSpeechMenuUseLetters)
function int KeyToNumber(EInputKey Key)
{
    local ExtendedConsole EC;
    local int i;

    EC = ExtendedConsole(ViewportOwner.Console);
    if (EC != None && EC.bSpeechMenuUseLetters)
    {
        for (i = 0; i < 10; i++)
            if (Key == EC.LetterKeys[i])
                return i;
        return -1;
    }

    // NumberKeys isn't config: always IK_0..IK_9
    if (Key >= IK_0 && Key <= IK_9)
        return int(Key) - 0x30; // IK_0; the compiler can't cast a bare enum tag
    return -1;
}

function bool KeyEvent(out EInputKey Key, out EInputAction Action, float Delta)
{
    local int n;


    if (Action != IST_Press || !IsSpectator())
        return false;

    if (!bMenuOpen)
    {
        // Players keep the stock menu
        if (GetPublicRoom() == None || !IsSpeechMenuKey(Key))
            return false;

        OpenMenu();
        return true;
    }

    if (Key == IK_Escape || IsSpeechMenuKey(Key))
    {
        CloseMenu(false);
        return true;
    }

    n = KeyToNumber(Key);
    if (n >= 1 && n <= NumRows)
    {
        Select(n);
        CloseMenu(true);
        return true;
    }

    return false;
}

function OpenMenu()
{
    local ExtendedConsole EC;
    local EInputKey Key;
    local int i;

    NumRows = 2;
    if (GetTeamRoom() != None)
        NumRows = 4;

    // As ExtendedConsole.SpeechMenuVisible.NumberToString()
    EC = ExtendedConsole(ViewportOwner.Console);
    for (i = 0; i < NumRows; i++)
    {
        if (EC == None)
            Key = class'ExtendedConsole'.default.NumberKeys[i + 1];
        else if (EC.bSpeechMenuUseLetters)
            Key = EC.LetterKeys[i + 1];
        else
            Key = EC.NumberKeys[i + 1];
        KeyText[i] = PC.ConsoleCommand("LOCALIZEDKEYNAME" @ int(Key)) $ "-";
    }

    bMenuOpen = true;
    if (EC != None)
        PC.ClientPlaySound(EC.SMOpenSound);
}

function CloseMenu(bool bAccepted)
{
    local ExtendedConsole EC;

    bMenuOpen = false;
    EC = ExtendedConsole(ViewportOwner.Console);
    if (EC == None)
        return;

    if (bAccepted)
        PC.ClientPlaySound(EC.SMAcceptSound);
    else
        PC.ClientPlaySound(EC.SMDenySound);
}

// Rows: 1 talk on Public, 2 join/leave Public, 3 talk on Team, 4 join/leave Team
function Select(int n)
{
    local VoiceChatRoom Room;
    local bool bTeam;

    bTeam = n > 2;
    if (bTeam)
        Room = GetTeamRoom();
    else
        Room = GetPublicRoom();
    if (Room == None)
        return;

    if ((n & 1) == 1)
    {
        // ServerSpeak() toggles, so it is only trusted to turn talking off
        if (PC.ActiveRoom == Room)
            PC.ServerSpeak(Room.ChannelIndex);
        else
            PC.ServerSpecVoiceJoin(bTeam, true);
    }
    else if (InRoom(Room, PC.PlayerReplicationInfo))
    {
        if (PC.ActiveRoom == Room)
            PC.ActiveRoom = None;
        PC.ServerSpecVoiceLeave(bTeam);
    }
    else
        PC.ServerSpecVoiceJoin(bTeam, false);
}

// =====================================================================================================================
//  Drawing
// =====================================================================================================================

function PostRender(Canvas C)
{
    local HudCDeathmatch H;
    local plane OldModulate;
    local byte OldStyle;

    if (!IsSpectator())
    {
        bMenuOpen = false;
        return;
    }

    OldStyle = C.Style;
    C.Style = 5; // STY_Alpha; ERenderStyle belongs to Actor

    // Inverse of HUD.PostRender()'s DrawSpectatingHud() test: the regular HUD draws these itself
    H = HudCDeathmatch(PC.myHUD);
    if (H != None && !H.bHideHUD && !H.bShowScoreBoard && !H.bShowLocalStats && !H.bShowDebugInfo
        && (H.PawnOwner == None || H.PawnOwnerPRI == None || (PC.IsSpectating() && PC.bBehindView)))
    {
        // HUD.PostRender() applies HudOpacity this way and restores it before we run
        OldModulate = C.ColorModulate;
        C.ColorModulate.X = 1;
        C.ColorModulate.Y = 1;
        C.ColorModulate.Z = 1;
        C.ColorModulate.W = H.HudOpacity / 255;

        if (PC.Level.TimeSeconds - H.LastVoiceGainTime < 0.333)
            H.DisplayVoiceGain(C);

        if (H.Portrait != None && (H.bShowPortrait || (H.bShowPortraitVC && PC.Level.TimeSeconds - H.LastPlayerIDTalkingTime < 2.0)))
            DrawPortrait(C, H);

        C.ColorModulate = OldModulate;
    }

    if (bMenuOpen)
        DrawMenu(C);

    C.Style = OldStyle;
}

// Portrait block of HudCDeathmatch.DrawHudPassC()
function DrawPortrait(Canvas C, HudCDeathmatch H)
{
    local VoiceChatRoom VCR;
    local PlayerReplicationInfo PRI;
    local float PortraitWidth, PortraitHeight, X, Y, XL, YL, Abbrev;
    local string PortraitString;

    PRI = H.PortraitPRI;
    PortraitWidth = 0.125 * C.ClipY;
    PortraitHeight = 1.5 * PortraitWidth;
    C.DrawColor = H.WhiteColor;

    C.SetPos(-PortraitWidth*H.PortraitX + 0.025*PortraitWidth, 0.5*(C.ClipY-PortraitHeight) + 0.025*PortraitHeight);
    C.DrawTile(H.Portrait, PortraitWidth, PortraitHeight, 0, 0, 256, 384);

    C.Font = H.GetFontSizeIndex(C, -2);
    if (PRI != None)
    {
        PortraitString = PRI.PlayerName;
        C.StrLen(PortraitString, XL, YL);
        if (XL > PortraitWidth)
        {
            C.Font = H.GetFontSizeIndex(C, -4);
            C.StrLen(PortraitString, XL, YL);
            if (XL > PortraitWidth)
            {
                Abbrev = float(Len(PortraitString)) * PortraitWidth/XL;
                PortraitString = Left(PortraitString, Abbrev);
                C.StrLen(PortraitString, XL, YL);
            }
        }
    }

    C.DrawColor = C.static.MakeColor(160,160,160);
    C.SetPos(-PortraitWidth*H.PortraitX + 0.025*PortraitWidth, 0.5*(C.ClipY-PortraitHeight) + 0.025*PortraitHeight);
    C.DrawTile(Material'XGameShaders.ModuNoise', PortraitWidth, PortraitHeight, 0.0, 0.0, 512, 512);

    C.DrawColor = H.WhiteColor;
    C.SetPos(-PortraitWidth*H.PortraitX, 0.5*(C.ClipY-PortraitHeight));
    C.DrawTileStretched(texture'InterfaceContent.Menu.BorderBoxA1', 1.05*PortraitWidth, 1.05*PortraitHeight);

    if (PRI == None)
        return;

    X = C.ClipY/256 - PortraitWidth*H.PortraitX;
    Y = 0.5*(C.ClipY+PortraitHeight) + 0.06*PortraitHeight;
    C.SetPos(X + 0.5*(PortraitWidth - XL), Y);

    if (PRI.Team != None)
    {
        if (PRI.Team.TeamIndex == 0)
            C.DrawColor = H.RedColor;
        else
            C.DrawColor = H.TurqColor;
    }
    C.DrawText(PortraitString, true);

    if (PC.Level.TimeSeconds - H.LastPlayerIDTalkingTime < 2.0 && PRI.ActiveChannel != -1 && PC.VoiceReplicationInfo != None)
    {
        VCR = PC.VoiceReplicationInfo.GetChannelAt(PRI.ActiveChannel);
        if (VCR != None)
        {
            PortraitString = "(" @ VCR.GetTitle() @ ")";
            C.StrLen(PortraitString, XL, YL);
            if (H.PortraitX == 0)
                C.SetPos(Max(0, X + 0.5*(PortraitWidth - XL)), Y + YL);
            else
                C.SetPos(X + 0.5*(PortraitWidth - XL), Y + YL);
            C.DrawText(PortraitString);
        }
    }
}

// Layout follows the stock menu in ExtendedConsole.SpeechMenuVisible.PostRender()
function DrawMenu(Canvas C)
{
    local ExtendedConsole EC;
    local VoiceChatRoom Rooms[2], Room;
    local GameReplicationInfo GRI;
    local string Title, MenuTitle, Row[4];
    local color RowColor[4], TeamColor;
    local float OriginX, OriginY, Margin, LineSpace, Tab, XL, YL, X, Y, W, H, TextX, RowY;
    local int i;

    Rooms[0] = GetPublicRoom();
    if (Rooms[0] == None)
    {
        bMenuOpen = false;
        return;
    }
    if (NumRows > 2)
    {
        Rooms[1] = GetTeamRoom();
        if (Rooms[1] == None)
            NumRows = 2;
        else if (Rooms[1].GetTeam() == 0)
            TeamColor = class'HUD'.default.RedColor;
        else
            TeamColor = class'HUD'.default.TurqColor;
    }

    // Two rows per room: talk, then join/leave. The talk row is green while talking on it.
    for (i = 0; i < NumRows; i += 2)
    {
        Room = Rooms[i >> 1];
        Title = Room.GetTitle();
        if (i == 0)
            RowColor[0] = class'HUD'.default.WhiteColor;
        else
            RowColor[i] = TeamColor;
        RowColor[i + 1] = RowColor[i];

        if (PC.ActiveRoom == Room)
        {
            Row[i] = Repl(StopTalkText, "%title%", Title);
            RowColor[i] = class'HUD'.default.GreenColor;
        }
        else
            Row[i] = Repl(TalkText, "%title%", Title);

        if (InRoom(Room, PC.PlayerReplicationInfo))
            Row[i + 1] = Repl(LeaveText, "%title%", Title);
        else
            Row[i + 1] = Repl(JoinText, "%title%", Title);
    }

    EC = ExtendedConsole(ViewportOwner.Console);
    if (EC != None)
    {
        OriginX = EC.SMOriginX;
        OriginY = EC.SMOriginY;
        Margin = EC.SMMargin;
        MenuTitle = EC.SMStateName[1];
    }
    else
    {
        OriginX = class'ExtendedConsole'.default.SMOriginX;
        OriginY = class'ExtendedConsole'.default.SMOriginY;
        Margin = class'ExtendedConsole'.default.SMMargin;
        MenuTitle = class'ExtendedConsole'.default.SMStateName[1];
    }

    C.Font = class'UT2MidGameFont'.static.GetMidGameFont(C.ClipX);

    // Sizing
    for (i = 0; i < NumRows; i++)
    {
        C.TextSize(KeyText[i] $ " ", XL, YL);
        Tab = FMax(Tab, XL);
    }
    LineSpace = YL * 1.1;
    for (i = 0; i < NumRows; i++)
    {
        C.TextSize(Row[i], XL, YL);
        W = FMax(W, XL);
    }
    W += Tab;
    C.TextSize(MenuTitle, XL, YL);
    W = FMax(W, XL) + 2 * Margin * C.ClipX;
    H = 2 * Margin * C.ClipY + (NumRows - 1) * LineSpace + YL;

    X = C.ClipX * OriginX;
    Y = C.ClipY * OriginY;
    TextX = X + Margin * C.ClipX;
    RowY = Y + Margin * C.ClipY;

    // Box and title bar
    C.SetDrawColor(255,255,255,255);
    C.SetPos(X, Y);
    C.DrawTileStretched(texture'InterfaceContent.Menu.BorderBoxD', W, H);
    C.SetPos(X, Y - 1.5 * LineSpace);
    C.DrawTileStretched(texture'InterfaceContent.Menu.BorderBoxD', W, 1.5 * LineSpace);
    C.SetDrawColor(255,255,128,255);
    C.SetPos(TextX, Y - 1.2 * LineSpace);
    C.DrawText(MenuTitle, false);

    for (i = 0; i < NumRows; i++)
    {
        C.SetDrawColor(128,255,128,255);
        C.SetPos(TextX, RowY + i * LineSpace);
        C.DrawText(KeyText[i], false);

        C.DrawColor = RowColor[i];
        C.SetPos(TextX + Tab, RowY + i * LineSpace);
        C.DrawText(Row[i], false);
    }

    // Who is in the channel being talked on (else Public), as the stock menu lists beside a channel
    Room = Rooms[0];
    if (PC.ActiveRoom != None && PC.ActiveRoom == Rooms[1])
        Room = Rooms[1];
    GRI = PC.GameReplicationInfo;
    if (GRI == None)
        return;
    C.SetDrawColor(255,255,175,220);
    X += W + Margin * C.ClipX;
    RowY += 0.1 * LineSpace;
    for (i = 0; i < GRI.PRIArray.Length; i++)
    {
        if (!InRoom(Room, GRI.PRIArray[i]))
            continue;
        C.SetPos(X, RowY);
        C.DrawText(GRI.PRIArray[i].PlayerName, false);
        RowY += LineSpace;
    }
}

defaultproperties
{
    bVisible=True
    TalkText="Talk on %title%"
    StopTalkText="Stop talking on %title%"
    JoinText="Join %title%"
    LeaveText="Leave %title%"
}
