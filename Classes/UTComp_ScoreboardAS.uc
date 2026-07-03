

// Assault scoreboard.
//
// Uses the same custom style as the DeathMatch scoreboard (UTComp_ScoreBoard), which
// already supports team games (two team info boxes, per-team score and average ping,
// per-player rows). Assault is a team game with game-specific data, so - like
// UTComp_ScoreBoardONS does for nodes/cores - it inherits the shared layout and only
// overrides DrawPlayerInformation to append the Assault trophy icons (vehicles
// destroyed, objectives disabled, final objective disabled) read from
// ASPlayerReplicationInfo.
class UTComp_ScoreboardAS extends UTComp_ScoreBoard;

// Draw one Assault trophy icon (and a count when greater than 1). Returns the X the
// next icon should start at.
simulated function float DrawTrophy(Canvas C, Texture Tex, byte Count, float IconX, float IconY, float IconW, float IconH, float U, float V, float UL, float VL)
{
    local string Num;
    local float NumW, NumH;

    if(Count <= 0)
        return IconX;

    C.SetDrawColor(255,255,255,255);
    C.SetPos(IconX, IconY);
    C.DrawTile(Tex, IconW, IconH, U, V, UL, VL);

    IconX += IconW + IconH*0.15;

    if(Count > 1)
    {
        Num = string(Count);
        C.StrLen(Num, NumW, NumH);
        C.SetPos(IconX, IconY + (IconH - NumH)*0.5);
        C.DrawText(Num);
        IconX += NumW;
    }

    return IconX + IconH*0.35;
}

simulated function DrawPlayerInformation(Canvas C, PlayerReplicationInfo PRI, float XOffset, float YOffset, float Scale)
{
    local ASPlayerReplicationInfo ASPRI;
    local float StartY, IconX, IconY, IconH;

    // Draw the standard row (name, score, deaths, efficiency, ping, location, ...)
    Super.DrawPlayerInformation(C, PRI, XOffset, YOffset, Scale);

    ASPRI = ASPlayerReplicationInfo(PRI);
    if(ASPRI == None)
        return;

    StartY = 0.110;
    IconH  = C.ClipY*0.032;                       // fit inside the compact player row
    IconY  = C.ClipY*(StartY-0.005) + YOffset;
    IconX  = C.ClipX*0.40 + XOffset;

    C.Style = ERenderStyle.STY_Normal;
    C.Font  = SmallerFont;

    // Vehicles destroyed - HUD sheet icon (53x42, keep aspect ratio)
    IconX = DrawTrophy(C, Texture'HudContent.Generic.HUD', ASPRI.DestroyedVehicles,
                       IconX, IconY, IconH*(53.0/42.0), IconH, 227, 406, 53, 42);

    // Objectives disabled
    IconX = DrawTrophy(C, Texture'AS_FX_TX.Icons.ScoreBoard_Objective_Final', ASPRI.DisabledObjectivesCount,
                       IconX, IconY, IconH, IconH, 0, 0, 128, 128);

    // Final objective disabled (round won)
    IconX = DrawTrophy(C, Texture'AS_FX_TX.Icons.ScoreBoard_Objective_Single', ASPRI.DisabledFinalObjective,
                       IconX, IconY, IconH, IconH, 0, 0, 128, 128);
}

defaultproperties
{
    fraglimitteam="SCORE LIMIT:"
    TmpFontSize=1
    bEnableColoredNamesOnScoreboard=True
    bDrawStats=False
    bDrawPickups=False
    bOverrideDisplayStats=false
    ScoreboardDefaultColor=(R=0,G=0,B=0,A=0)
}
