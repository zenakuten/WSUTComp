

// Team DeathMatch scoreboard.
//
// This uses the same custom style as the DeathMatch scoreboard (UTComp_ScoreBoard),
// which already supports team games (two team info boxes, per-team score and average
// ping, per-player rows). See UTComp_ScoreBoardONS for an example of a team game that
// extends this same base and adds game-specific data (nodes, cores). Team DeathMatch
// has no extra per-player data, so it only needs to inherit the shared layout.
class utcomp_ScoreBoardTDM extends UTComp_ScoreBoard;

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
