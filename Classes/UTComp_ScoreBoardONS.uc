class UTComp_ScoreBoardONS extends UTComp_ScoreBoard;
// TO DO pooty 10/2023
// Nice to add core health to scoreboard
// and perhaps node stats per player

function String GetTitleString()
{
    local string titlestring;

    if ( Level.NetMode == NM_Standalone )
    {
        if ( Level.Game.CurrentGameProfile != None )
            titlestring = SkillLevel[Clamp(Level.Game.CurrentGameProfile.BaseDifficulty,0,7)];
        else
            titlestring = SkillLevel[Clamp(Level.Game.GameDifficulty,0,7)];
        titlestring = titlestring$spacer;
    }
   // else if ( (GRI != None) && (GRI.BotDifficulty >= 0) )
   //     titlestring = SkillLevel[Clamp( GRI.BotDifficulty,0,7)];
   // ONly show bot skill on Standalone games.. no one cares about that on servers.
    
    return titlestring$Level.Title;
}
function String GetDefaultScoreInfoString()
{
    local String ScoreInfoString;

    if ( GRI.MaxLives != 0 )
        ScoreInfoString = MaxLives@GRI.MaxLives;
    else if ( GRI.GoalScore != 0 )
    {
        if(!GRI.bTeamGame)
            ScoreInfoString = FragLimit@GRI.GoalScore;
        else
            ScoreInfoString = FragLimitTeam@GRI.GoalScore;
    }
    if ( GRI.RemainingTime > 0 )
        ScoreInfoString = ScoreInfoString@spacer@TimeLimit$FormatTime(GRI.RemainingTime);
    else
        ScoreInfoString = ScoreInfoString@spacer@FooterText@FormatTime(GRI.ElapsedTime);

    return ScoreInfoString;
}


function DrawTitle2(Canvas Canvas)
{
    local string titlestring,scoreinfostring,RestartString;
    local float xl,yl,Full, Height, Top, MedH, SmallH;
    local float TitleXL,ScoreInfoXL;

    Canvas.Font = HUDClass.static.GetMediumFontFor(Canvas);
    Canvas.StrLen("W",xl,MedH);
    Height = MedH;
    Canvas.Font = HUDClass.static.GetConsoleFont(Canvas);
    Canvas.StrLen("W",xl,SmallH);
    Height += SmallH;

    Full = Height;
    //Top  = Canvas.ClipY-8-Full;
		Top  = Canvas.ClipY-4-Full;

    TitleString     = GetTitleString();
    ScoreInfoString = GetDefaultScoreInfoString();
    

    Canvas.StrLen(TitleString, TitleXL, YL);
    Canvas.DrawColor = HUDClass.default.GoldColor;

    if ( UnrealPlayer(Owner).bDisplayLoser )
        ScoreInfoString = class'HUDBase'.default.YouveLostTheMatch;
    else if ( UnrealPlayer(Owner).bDisplayWinner )
        ScoreInfoString = class'HUDBase'.default.YouveWonTheMatch;
    else if ( PlayerController(Owner).IsDead() )
    {
        RestartString = GetRestartString();
        ScoreInfoString = RestartString;
    }
    
    //Canvas.StrLen(ScoreInfoString,ScoreInfoXL,YL);

    Canvas.Font = NotReducedFont;
    Canvas.SetDrawColor(255,150,0,255);
    Canvas.StrLen(TitleString,TitleXL,YL);
    Canvas.SetPos( (Canvas.ClipX/2) - (TitleXL/2), Canvas.ClipY*0.005);
    Canvas.DrawText(TitleString);


    //Canvas.Font = HUDClass.static.GetMediumFontFor(Canvas);
    Canvas.StrLen(ScoreInfoString,ScoreInfoXL,YL);
    Canvas.SetPos( (Canvas.ClipX/2) - (ScoreInfoXL/2), Canvas.ClipY*0.035); 
    Canvas.DrawText(ScoreInfoString);
   
   
   /* OLD Code with Title at top, score limit at bottom
    Canvas.StrLen(TitleString,TitleXL,YL);
    Canvas.SetPos( (Canvas.ClipX/2) - (TitleXL/2), Canvas.ClipY*0.03);
    Canvas.DrawText(TitleString);


    Canvas.Font = HUDClass.static.GetMediumFontFor(Canvas);
    Canvas.StrLen(ScoreInfoString,ScoreInfoXL,YL);
    Canvas.SetPos( (Canvas.ClipX/2) - (ScoreInfoXL/2), Top + (Full/2) - (YL/2));
    Canvas.DrawText(ScoreInfoString);
    */
}

defaultproperties
{
     fraglimitteam="Score to Win:"
     TimeLimit="Time to OT "
     FooterText="Elapsed Game Time "
     TmpFontSize=1
     //tmp1=0.156000
     //tmp2=0.172000
     //tmp3=0.189000
     // put the offsets in each one based off StartY.
     
     bEnableColoredNamesOnScoreboard=True
     bDrawStats=False
     bDrawPickups=False
     bOverrideDisplayStats=false
     ScoreboardDefaultColor=(R=0,G=0,B=0,A=0)
}