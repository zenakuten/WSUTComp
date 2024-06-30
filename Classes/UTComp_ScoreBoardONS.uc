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

// updated ONS Player Info pooty 03/2024
simulated function DrawPlayerInformation(Canvas C, PlayerReplicationInfo PRI, float XOffset, float YOffset, float Scale)
{
    local float tmpEff;
    local int i, otherteam;
    local PlayerReplicationInfo OwnerPRI;
    local UTComp_PRI uPRI;
    local string AdminString;
    local float oldClipX;
    local float StartY;
    local ONSPlayerReplicationInfo ONSPRI;
    
    ONSPRI = ONSPlayerReplicationInfo(PRI);
    
    StartY = 0.110;
    
    if(Owner!=None)
       OwnerPRI = PlayerController(Owner).PlayerReplicationInfo;

    uPRI=class'UTComp_Util'.static.GetUTCompPRI(PRI);
    
    if (PRI.bAdmin && RepInfo != None && !RepInfo.bSilentAdmin)
       AdminString ="Admin";
    // Draw Player name

    C.Font = NotReducedFont;
    
    //C.SetPos(C.ClipX*0.188+XOffset, (C.ClipY*0.159)+YOffset);
    //C.SetPos(C.ClipX*0.188+XOffset, (C.ClipY*StartY)+YOffset);
    C.SetPos(C.ClipX*0.205+XOffset, (C.ClipY*StartY)+YOffset);
    oldClipX=C.ClipX;
    C.ClipX=C.ClipX*0.470+XOffset;

    if(default.benablecolorednamesonscoreboard && uPRI!=None && uPRI.ColoredName !="")
    {
        C.DrawTextClipped(uPRI.ColoredName$AdminString);
    }
    else
    {
        C.SetDrawColor(255,255,255,255);
        C.DrawTextClipped(PRI.PlayerName$AdminString);
    }
    C.ClipX=OldClipX;

    for(i=0;i<MAXPLAYERS;i++)
    {
        if( PRI == OwnerPRI )
            C.SetDrawColor(255,255,0,255);
        else
            C.SetDrawColor(255,255,255,255);
    }

    // DrawScore
    if(PRI.Score>99)
      C.Font= SortaReducedFont;
    else
       C.Font = NotReducedFont;


    if ( PRI.bOutOfLives )
    {
        C.SetPos(C.ClipX*0.0190+XOffset, (C.ClipY*StartY)+YOffset);
        C.DrawText("OUT");
    }
    else
    {
        C.DrawTextJustified(int(PRI.Score), 0,C.ClipX*0.022+XOffset,C.ClipY*(StartY-0.05)+YOffset, C.ClipX*0.068+XOffset, C.ClipY*(StartY+0.090)+Yoffset);
//        C.DrawTextJustified(int(PRI.Score), 0,C.ClipX*0.0190+XOffset,C.ClipY*0.159+YOffset, C.ClipX*0.068+XOffset, C.ClipY*0.204+Yoffset);


    }
    if(PRI.Team!=None && PRI.Team.TeamIndex==0)
      OtherTeam=1;
    else
      OtherTeam=0;

/*  ONS Only, so no flags.
    if(PRI.Team !=None && (GRI.FlagState[OtherTeam] != EFlagState.FLAG_Home) && (GRI.FlagState[OtherTeam] != EFlagState.FLAG_Down) && (PRI.HasFlag != None || PRI == GRI.FlagHolder[PRI.Team.TeamIndex]))
    {
        C.SetDrawColor(255,255,255,255);
        C.SetPos(C.ClipX*0.41+XOffset, (C.ClipY*StartY)+YOffset);
        C.DrawTile(material'xInterface.S_FlagIcon',90*scale,64*Scale,0,0,90,64);
    }
*/    
    
    // Player Deaths
    if(PRI.Deaths>99)
        C.Font=SmallerFont;
    else
        C.Font=ReducedFont;
    C.SetDrawColor(255,0,0,255);
    C.SetPos(C.ClipX*0.070+XOffset, (C.ClipY*StartY)+YOffset);
    C.DrawText(int(PRI.Deaths));

    // Player Effeciency
    if(uPRI.RealKills-PRI.Deaths >99)
        C.Font = SmallerFont;
    else
        C.Font=ReducedFont;
    C.SetPos(C.ClipX*0.070+XOffset, (C.ClipY*(StartY+0.020))+YOffset);
    C.SetDrawColor(0,200,255,255);
    tmpEff = (uPRI.RealKills-PRI.Deaths);
    C.DrawText(int(tmpEff));

    C.Font = SmallerFont;
      
    if(PRI==OwnerPRI)
        C.SetDrawColor(255,255,0,255);
    else
        C.SetDrawColor(255,255,255,255);
    if ( Level.NetMode != NM_Standalone )
    { // Net Info
        C.SetPos(C.ClipX*0.108+XOffset, (C.ClipY*(StartY-0.005))+YOffset);
        C.DrawText("Ping:"$Min(999,4*PRI.Ping));

        C.SetPos(C.ClipX*0.108+XOffset, (C.ClipY*(StartY+0.013))+YOffset);
        C.DrawText("P/L :"$PRI.PacketLoss);
    }

// To Do Get some Node stats, but how?  Dont seem to be stored anywhere in PRI.
/*
    if (ONSPRI != None) {
    C.SetPos(C.ClipX*0.148+XOffset, (C.ClipY*(StartY-0.005))+YOffset);
    C.DrawText("NBlt:"@ONSPRI.FlagTouches);

    C.SetPos(C.ClipX*0.148+XOffset, (C.ClipY*(StartY+0.013))+YOffset);
    C.DrawText("NDst:"@ONSPRI.FlagReturns);
    }
*/			
    // put PPH on the bottom line next to Time in Game
    C.SetPos(C.ClipX*0.148+XOffset, (C.ClipY*(StartY+0.030))+YOffset);
    C.DrawText(FPH@Clamp(3600*PRI.Score/FMax(1,FPHTime - PRI.StartTime),-999,9999),true);




    C.SetPos(C.ClipX*0.108+XOffset, (C.ClipY*(StartY+0.030))+YOffset);

    if(uWarmup==None)
       foreach DynamicActors(class'UTComp_Warmup', uWarmup)
           break;
    if(uWarmup!=None && uWarmup.bInWarmup)
    {
       if(!uPRI.bIsReady)
          C.DrawText("Not Ready");
       else
          C.DrawText("Ready");
    }
    else if(PRI.bReadyToPlay && !GRI.bMatchHasBegun)
        C.DrawText("Ready");
    else if(!GRI.bMatchHasBegun)
        C.DrawText("Not Ready");
    else
    C.DrawText(FormatTime(Max(0,FPHTime - PRI.StartTime)) );

    // Location Name
    // Hide if Player is using HUDTeamoverlay
    if (OwnerPRI.bOnlySpectator || (PRI.Team!=None && OwnerPRI.Team!=None && PRI.Team.TeamIndex==OwnerPRI.Team.TeamIndex))
    {
        C.SetDrawColor(255,150,0,255);
        C.SetPos(C.ClipX*0.21+XOffset, (C.ClipY*(StartY+0.030))+YOffset);
        C.DrawText(Left(PRI.GetLocationName(), 30));
    }
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