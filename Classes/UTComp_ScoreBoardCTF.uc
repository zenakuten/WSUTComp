

class UTComp_ScoreBoardCTF extends UTComp_ScoreBoard;

//font names and objects
var Font FontArrayFonts[9];
var localized string FontArrayNames[9];

//Font indices
var int FONT_PLAYER_PING;
var int FONT_PLAYER_PL;
var int FONT_PLAYER_LOCATION;
var int FONT_PLAYER_STAT_NUM;
var int FONT_PLAYER_STAT;
var int FONT_PLAYER_SCORE;
var int FONT_PLAYER_NAME;
var int FONT_TEAM_POWERUP_NUM;
var int FONT_TEAM_PING;
var int FONT_TEAM_PL;
var int FONT_TEAM_POWERUP_PER;
var int FONT_TEAM_SCORE;

//Stats stuff fore scoreboard layout
struct Stats
{
  var string name;
  var float nameW;
  var float nameH;
  var string value;
  var float valueW;
  var float valueH;
};

//Materials for backgrounds
var material TeamBoxMaterial;
var material TeamHeaderMaterial;

/*
 * Draw the map title, ie "Capture the Flag on Grendelkeep"
 */
function DrawMapTitle(Canvas Canvas)
{
  return; //fuck this who cares
  local string titlestring,scoreinfostring,RestartString;
  local float xl, yl, full, height, top, medH, smallH, titleXL, scoreInfoXL;

  Canvas.Font = HUDClass.static.GetMediumFontFor(Canvas);
  Canvas.StrLen("W",xl,medH);
  height = medH;
  Canvas.Font = HUDClass.static.GetConsoleFont(Canvas);
  Canvas.StrLen("W",xl,smallH);
  height += smallH;

  full = height;
  top  = Canvas.ClipY - 8 - full;

  titleString     = GetTitleString();
  scoreInfoString = GetDefaultScoreInfoString();

  Canvas.StrLen(titleString, titleXL, YL);
  Canvas.DrawColor = HUDClass.default.GoldColor;

  if (UnrealPlayer(Owner).bDisplayLoser)
  {
    ScoreInfoString = class'HUDBase'.default.YouveLostTheMatch;
  }
  else if (UnrealPlayer(Owner).bDisplayWinner)
  {
    ScoreInfoString = class'HUDBase'.default.YouveWonTheMatch;
  }
  else if (PlayerController(Owner).IsDead())
  {
    RestartString = GetRestartString();
    ScoreInfoString = RestartString;
  }

  Canvas.StrLen(scoreInfoString,scoreInfoXL,YL);

  Canvas.Font = NotReducedFont;
  Canvas.SetDrawColor(255,150,0,255);
  Canvas.StrLen(TitleString,TitleXL,YL);
  Canvas.SetPos( (Canvas.ClipX/2) - (TitleXL/2), Canvas.ClipY*0.03);
  Canvas.DrawText(TitleString);


  Canvas.Font = HUDClass.static.GetMediumFontFor(Canvas);
  Canvas.StrLen(ScoreInfoString,ScoreInfoXL,YL);
  Canvas.SetPos( (Canvas.ClipX/2) - (ScoreInfoXL/2), Top + (Full/2) - (YL/2));
  Canvas.DrawText(ScoreInfoString);
}

/*
 * Re-draw the scoreboard with updated data
 */
simulated event UpdateScoreBoard(Canvas C)
{
  local PlayerReplicationInfo PRI, OwnerPRI;
  local PlayerReplicationInfo RedPRI[MAXPLAYERS], BluePRI[MAXPLAYERS], SPecPRI[MAXPLAYERS];
  local int i, BluePlayerCount, RedPlayerCount, RedOwnerOffset, BlueOwnerOffset, maxTiles, numspecs;
  local float screenScale;
  local bool bOwnerDrawn;

  // Fonts
  mainFont         = HUDClass.static.GetMediumFontFor(C);
  notReducedFont   = GetSmallerFontFor(C,1);
  sortaReducedFont = GetSmallerFontFor(C,2);
  reducedFont      = GetSmallerFontFor(C,3);
  smallerFont      = GetSmallerFontFor(C,4);
  soTiny           = GetSmallerFontFor(C,5);
  maxTiles=8; //max players per team?


  FONT_PLAYER_PING      = 1;
  FONT_PLAYER_PL        = 1;
  FONT_PLAYER_LOCATION  = 4;
  FONT_PLAYER_STAT_NUM  = 1;
  FONT_PLAYER_STAT      = 1;
  FONT_PLAYER_SCORE     = 6;
  FONT_PLAYER_NAME      = 6;
  FONT_TEAM_POWERUP_NUM = 3;
  FONT_TEAM_PING        = 3;
  FONT_TEAM_PL          = 3;
  FONT_TEAM_POWERUP_PER = 5;
  FONT_TEAM_SCORE       = 7;



  if(Owner!=None)
  {
    OwnerPRI = PlayerController(Owner).PlayerReplicationInfo;
  }

  //Fill team PRI arrays

  //Red/Blue offsets are useless?
  RedOwnerOffset  = -1;
  BlueOwnerOffset = -1;

  for (i=0; i<GRI.PRIArray.Length; i++)
  {
    PRI = GRI.PRIArray[i];

    if(PRI.bOnlySpectator)
    {
      specPRI[numSpecs]=PRI;
      numSpecs++;
    }

    if ((!PRI.bOnlySpectator || PRI.bWaitingPlayer))
    {
      if (PRI.Team == None || PRI.Team.TeamIndex == 0)
      {
        if (RedPlayerCount < MAXPLAYERS)
        {
          RedPRI[RedPlayerCount] = PRI;

          if (PRI == OwnerPRI)
          {
            RedOwnerOffset = RedPlayerCount;
          }

          RedPlayerCount++;
        }
      }
      else
      {
        if (BluePlayerCount < MAXPLAYERS)
        {
          BluePRI[BluePlayerCount] = PRI;

          if (PRI == OwnerPRI)
          {
            BlueOwnerOffset = BluePlayerCount;
          }

          BluePlayerCount++;
        }
      }
    }
  }

  screenScale = C.ClipX/1920; //1920 as a base..go down from there. 1024x768 --> 1024/1920 = 0.533 etc

  //what the fuck?
  // C.FontScaleX = C.ClipX / 1920;
  // C.FontScaleY = C.ClipX / 1080;
  //DrawLogo(C, screenScale);
  //DrawMapTitle(C);

  DrawTeamHeader(C,0);
  DrawCTFTeamInfoBoxes(C, 0, RedPlayerCount);
  DrawTeamHeader(C,1);
  DrawCTFTeamInfoBoxes(C, 1, BluePlayerCount);

  C.SetDrawColor(255,255,255,255);

  if (((FPHTime == 0) || (!UnrealPlayer(Owner).bDisplayLoser && !UnrealPlayer(Owner).bDisplayWinner)) && (GRI.ElapsedTime > 0))
  {
    FPHTime = GRI.ElapsedTime;
  }

  for ( i=0; i<RedPlayerCount && i<maxTiles; i++ )
  {
    if(!redPRI[i].bOnlySpectator)
    {
      if(i==(maxTiles-1) && !bOwnerDrawn && OwnerPRI.Team != none && OwnerPRI.Team.TeamIndex==0 && !OwnerPRI.bOnlySpectator)
      {
        DrawPlayerInformation(C, OwnerPRI, 95, 185 + 85*i, screenScale);
      }
      else
      {
        DrawPlayerInformation(C, RedPRI[i], 95, 185 + 85*i, screenScale);
      }

      if (RedPRI[i]==OwnerPRI)
      {
        bOwnerDrawn=True;
      }
    }
  }

  for ( i=0; i<BluePlayerCount && i<maxTiles; i++ )
  {
    if(!BluePRI[i].bOnlySpectator)
    {
      if(i==(maxTiles-1) && !bOwnerDrawn && OwnerPRI.Team != none && OwnerPRI.Team.TeamIndex==1 && !OwnerPRI.bOnlySpectator)
      {
        DrawPlayerInformation(C, OwnerPRI, 985, 185 + 85*i, screenScale);
      }
      else
      {
        DrawPlayerInformation(C, BluePRI[i], 985, 185 + 85*i, screenScale);
      }

      if (BluePRI[i]==OwnerPRI)
      {
        bOwnerDrawn=True;
      }
    }
  }

  if (!class'UTComp_ScoreBoard'.default.bDrawLGIStats)
  {
      DrawStats(C);
  }
  DrawPowerups(C);

  if(numSpecs>0)
  {
    //ArrangeSpecs(specPRI);
    for (i=0; i<numspecs && specPRI[i]!=None; i++)
    {
      DrawSpecs(C, SpecPRI[i], i);
    }

    DrawSpecs(C,None,i);
  }
}


/*
 * Draw the UTComp logo
 */
simulated function DrawLogo(Canvas C , float Scale)
{
  // Border
	C.SetPos(0,0);
  C.Style=5;
  C.SetDrawColor(255,255,255,180);
  C.DrawTileStretched(TeamHeaderMaterial,C.ClipX,C.ClipY*0.066);

  // TCM Logo
  C.SetPos(0,0);

  C.DrawTile(material'UTCompLogo',(512*0.75)*Scale,(128*0.75)*Scale,0,0,256,64);
}

/*
 * Draw team header
 */

simulated function DrawTeamHeader(Canvas C, byte team)
{
  local float scoreWidth, scoreHeight;
  local float pingWidth, pingHeight;
  local float plWidth, plHeight;
  local float powerupPercentWidth, powerupPercentHeight;
  local float powerupNumWidth, powerupNumHeight;
  local float pingMaxWidth, pingMaxHeight;
  local float scoreX, scoreY;
  local float x_ping, x_pl;
  local int baseHeight, baseWidth, baseY, baseX;
  local int x;
  local int teamKills, teamDeaths, teamMidAirs;
  local PlayerReplicationInfo PRI;
  local UTComp_PRI uPRI;

  switch (team)
  {
    case 0:
      baseX = 95;
      break;
    case 1:
      baseX = 985;
      break;
    default:
  }

  baseHeight = 75;
  baseWidth  = 840;
  baseY      = 110;
  // redBaseX   = 95;  //95+840 width = 935, 960-935 = 25 (Gap to mid)
  // blueBaseX  = 985; //960 + 25 gap from mid

  //Turn on alpha for transparent fuckery
  C.Style = ERenderStyle.STY_Alpha;

  C.SetDrawColor(0,0,0,90);

  //Main header
  SetPosScaled(C, baseX, baseY);
  DrawTileStretchedScaled(C, TeamHeaderMaterial, baseWidth, baseHeight);

  //Score
  C.SetDrawColor(255, 255, 255, 255);
  C.Style = ERenderStyle.STY_Normal;
  C.Font = GetFontWithSize(FONT_TEAM_SCORE);

  C.StrLen(int(GRI.Teams[team].Score), scoreWidth, scoreHeight);

  switch (team)
  {
    case 0:
      scoreX = baseX + baseWidth - scoreWidth - 15;
      break;
    case 1:
      scoreX = baseX + 15;
      break;
    default:
  }

  scoreY = baseY - scoreHeight + (baseHeight + scoreHeight)/2;
  SetPosScaled(C, scoreX, scoreY);
  C.DrawText(int(GRI.Teams[team].Score));

  //Average ping/PL REMOVED

  //Powerups/flag timing OR LGI Stats
  if (class'UTComp_ScoreBoard'.default.bDrawLGIStats)
  {
      for(x = 0; x < GRI.PRIArray.Length; x++)
      {
          PRI = GRI.PRIArray[x];
          if(!PRI.bOnlySpectator && PRI.Team != None && PRI.Team.TeamIndex == team)
          {
              uPRI = class'UTComp_Util'.static.GetUTCompPRI(PRI);
              if (uPRI != None)
              {
                  teamKills += uPRI.RealKills;
                  teamDeaths += uPRI.RealDeaths;
                  teamMidAirs += uPRI.MidAirs;
              }
          }
      }

      C.Font = GetFontWithSize(FONT_TEAM_POWERUP_PER);
      C.StrLen("Team Kills", powerupPercentWidth, powerupPercentHeight);
      C.Font = GetFontWithSize(FONT_TEAM_POWERUP_NUM);
      C.StrLen("99", powerupNumWidth, powerupNumHeight);

      for (x = 0; x < 3; x++) {
          C.Font = GetFontWithSize(FONT_TEAM_POWERUP_PER);
          if (x == 0) C.StrLen("Team Kills", powerupPercentWidth, powerupPercentHeight);
          else if (x == 1) C.StrLen("Team Deaths", powerupPercentWidth, powerupPercentHeight);
          else if (x == 2) C.StrLen("Team Mid-Airs", powerupPercentWidth, powerupPercentHeight);
          
                    
          C.Font = GetFontWithSize(FONT_TEAM_POWERUP_NUM);
          if (x == 0) C.StrLen(string(teamKills), powerupNumWidth, powerupNumHeight);
          else if (x == 1) C.StrLen(string(teamDeaths), powerupNumWidth, powerupNumHeight);
          else if (x == 2) C.StrLen(string(teamMidAirs), powerupNumWidth, powerupNumHeight);
          
                    
          SetPosScaled(C, baseX + 210 + 210*x - (powerupPercentWidth / (C.ClipX / 1920.0))/2, baseY + (baseHeight - powerupNumHeight - powerupPercentHeight)/2);
          
          if (x == 0) C.DrawText("Team Kills");
          else if (x == 1) C.DrawText("Team Deaths");
          else if (x == 2) C.DrawText("Team Mid-Airs");

          SetPosScaled(C, baseX + 210 + 210*x - (powerupNumWidth / (C.ClipX / 1920.0))/2 - 8.0, baseY + powerupPercentHeight + 5.0 + (baseHeight - powerupNumHeight - powerupPercentHeight)/2);
          
          C.Font = GetFontWithSize(FONT_TEAM_POWERUP_NUM);
          if (x == 0) C.DrawText(string(teamKills));
          else if (x == 1) C.DrawText(string(teamDeaths));
          else if (x == 2) C.DrawText(string(teamMidAirs));
      }
  }
  else
  {
      C.Font = GetFontWithSize(FONT_TEAM_POWERUP_PER);
      C.StrLen("100%", powerupPercentWidth, powerupPercentHeight);
      C.Font = GetFontWithSize(FONT_TEAM_POWERUP_NUM);
      C.StrLen("99", powerupNumWidth, powerupNumHeight);

      for (x = 0; x < 3; x++) {

        //TODO: screenScale icons by resolution
        //TODO: fix flag/clock so it doesnt look dumb + flag has some extra shit at top right
        switch (x)
        {
          case 0:
            SetPosScaled(C, baseX + 180 + 200*x, baseY + (baseHeight - 64)/2);
            C.DrawTile(material'HudContent.Generic.Hud', 64, 64, 0, 164, 73, 82); //amp
            break;
          case 1:
            SetPosScaled(C, baseX + 180 + 200*x, baseY + (baseHeight - 64)/2);
            C.DrawTile(material'HudContent.Generic.Hud', 64, 64, 1, 248, 64, 64); //100a
            break;
          case 2:
            SetPosScaled(C, baseX + 180 + 200*x, baseY + 35); //clock is short, so move it down
            C.DrawTile(material'HudContent.Generic.Hud', 40, 40, 148, 354, 40, 40); //clock
            SetPosScaled(C, baseX + 180 + 200*x, baseY + (baseHeight - 64)/2);
            C.DrawTile(material'HudContent.Generic.Hud', 64, 64, 338, 128, 56, 81); //flag
            break;
          default:

        }

        SetPosScaled(C, baseX + 50 + 200*x, baseY + (baseHeight - powerupNumHeight - powerupPercentHeight)/2);
        C.Font = GetFontWithSize(FONT_TEAM_POWERUP_PER);
        C.DrawText("0%");

        SetPosScaled(C, baseX + 50 + 200*x, baseY + powerupPercentHeight + (baseHeight - powerupNumHeight - powerupPercentHeight)/2);
        C.Font = GetFontWithSize(FONT_TEAM_POWERUP_NUM);
        C.DrawText("0");
      }
  }
}

/*
 * Draw the background boxes for each player.
 */
simulated function DrawCTFTeamInfoBoxes(Canvas C, byte team, int playerCount)
{
  local int baseHeight, baseWidth, baseX, baseY;
  local int rVal, bVal;
  local int x;
  local int alpha;

  switch (team)
  {
    case 0:
      rVal = 255;
      bVal = 0;
      baseX = 95;
      break;
    case 1:
      rVal = 0;
      bVal = 255;
      baseX = 985;
    default:
  }

  baseHeight = 85;
  baseWidth  = 840;
  baseY      = 110+75; //offset+height of header

  C.Style = ERenderStyle.STY_Alpha;

  for (x = 0; x < playerCount; x++) {
    if (x % 2 == 0) {
      alpha = 64;
    } else {
      alpha = 84;
    }

    C.SetDrawColor(rVal, 0, bVal, alpha);

    SetPosScaled(C, baseX, baseY + x*baseHeight);
    DrawTileStretchedScaled(C, TeamBoxMaterial, baseWidth, baseHeight);
  }
}


/*
 * Score, Ping, PL, Name, and stats for a given player (PRI)
 */
simulated function DrawPlayerInformation(Canvas C, PlayerReplicationInfo PRI, float baseX, float baseY, float screenScale)
{
  local UTComp_PRI uPRI;
  local TeamPlayerReplicationInfo tPRI;
  local float scoreWidth, scoreHeight, maxScoreWidth;
  local float pingplWidth, pingplHeight;
  local float playerNameWidth, playerNameHeight;
  local int boxWidth, boxHeight;
  local string pingplString;
  local int count, col, row;
  local array<Stats> statsArray;
  local float statX;
  local Stats stat1, stat2, stat3, stat4, stat5, stat6, stat7, stat8, stat9, stat10, stat11, stat12, tempStat;
  local int totalStats;
  local float kd, Accuracy;
  local int Shots, Hits;



  local float availableNameSpace, nameScale, playerNameX;
  local float maxNameWidth, maxNameHeight, maxValueWidth, maxValueHeight;
  local float colWidth[3], totalStatsWidth, statScale, availableStatSpace;
  local float curStatX;

  if (uWarmup == none)
    foreach dynamicActors(class'UTComp_Warmup', uWarmup)
      break;

  boxWidth  = 840;
  boxHeight = 85;

  uPRI = class'UTComp_Util'.static.GetUTCompPRI(PRI);
  tPRI = TeamPlayerReplicationInfo(PRI);

  if (uWarmup != None && uWarmup.bInWarmup) {
    if (!uPRI.bIsReady) C.SetDrawColor(255, 0, 0, 255);
    else C.SetDrawColor(0, 255, 0, 255);

    SetPosScaled(C, baseX + 20, baseY + (boxHeight - 64)/2);
    C.DrawTile(material'HudContent.Generic.Hud', 64, 64, 338, 128, 56, 81);
    C.SetDrawColor(255, 255, 255, 255);
  }

  pingplString = string(PRI.Ping*4)$"ms\ "@string(PRI.PacketLoss)$"%";

  C.Font = GetFontWithSize(FONT_PLAYER_SCORE);
  C.StrLen(PRI.Score, scoreWidth, scoreHeight);
  C.StrLen("999", maxScoreWidth, scoreHeight);

  C.Font = GetFontWithSize(FONT_PLAYER_PING);
  C.StrLen(pingplString, pingplWidth, pingplHeight);

  if (uWarmup == None || !uWarmup.bInWarmup) {
  C.Font = GetFontWithSize(FONT_PLAYER_SCORE);
  SetPosScaled(C, baseX + 15, baseY + (boxHeight - scoreHeight - pingplHeight)/2);
  C.DrawText(int(PRI.Score));
  }

  C.Font = GetFontWithSize(FONT_PLAYER_PING);
  SetPosScaled(C, baseX + 15 + 3, baseY + scoreHeight + (boxHeight - scoreHeight - pingplHeight)/2);
  C.DrawText(pingplString);

  C.Font = GetFontForPlayerName(PRI.PlayerName);
  C.StrLen(PRI.PlayerName, playerNameWidth, playerNameHeight);
  playerNameX = baseX + 40 + maxScoreWidth;

  if (class'UTComp_ScoreBoard'.default.bDrawLGIStats)
  {
    totalStats = 12;
    if (uPRI.RealDeaths > 0) kd = float(uPRI.RealKills) / uPRI.RealDeaths;
    else kd = float(uPRI.RealKills);

    statsArray[statsArray.Length] = stat1;
    statsArray[0].name = "Caps";
    statsArray[0].value = string(uPRI.FlagCaps);

    statsArray[statsArray.Length] = stat2;
    statsArray[1].name = "Assists";
    statsArray[1].value = string(uPRI.Assists);

    statsArray[statsArray.Length] = stat3;
    statsArray[2].name = "Grabs";
    statsArray[2].value = string(uPRI.FlagGrabs);

    statsArray[statsArray.Length] = stat4;
    statsArray[3].name = "Returns";
    statsArray[3].value = string(tPRI.FlagReturns);

    statsArray[statsArray.Length] = stat5;
    statsArray[4].name = "Flag Kills";
    statsArray[4].value = string(uPRI.FlagKills);

    statsArray[statsArray.Length] = stat6;
    statsArray[5].name = "Covers";
    statsArray[5].value = string(uPRI.Covers);

    statsArray[statsArray.Length] = stat7;
    statsArray[6].name = "Seals";
    statsArray[6].value = string(uPRI.Seals);

    statsArray[statsArray.Length] = stat8;
    statsArray[7].name = "Accuracy";
    statsArray[7].value = string(uPRI.SSR_Accuracy) $ "%";
    
    statsArray[statsArray.Length] = stat9;
    statsArray[8].name = "K/D";
    statsArray[8].value = string(uPRI.RealKills) @ "/" @ string(uPRI.RealDeaths) @ "(" $ Left(string(kd), 4) $ ")";

    statsArray[statsArray.Length] = stat10;
    statsArray[9].name = "Mid-Airs";
    statsArray[9].value = string(uPRI.MidAirs);

    statsArray[statsArray.Length] = stat11;
    statsArray[10].name = "Best Spree";
    if (uPRI.MaxSpree >= 30) statsArray[10].value = "Godlike";
    else if (uPRI.MaxSpree >= 25) statsArray[10].value = "Unstoppable";
    else if (uPRI.MaxSpree >= 20) statsArray[10].value = "Holy Shit";
    else if (uPRI.MaxSpree >= 15) statsArray[10].value = "Dominating";
    else if (uPRI.MaxSpree >= 10) statsArray[10].value = "Rampage";
    else if (uPRI.MaxSpree >= 5) statsArray[10].value = "Killing Spree";
    else statsArray[10].value = string(uPRI.MaxSpree);

    statsArray[statsArray.Length] = stat12;
    statsArray[11].name = "Best Multi";
    if (uPRI.MaxMultiKill >= 7) statsArray[11].value = "Holy Shit";
    else if (uPRI.MaxMultiKill == 6) statsArray[11].value = "Monster Kill";
    else if (uPRI.MaxMultiKill == 5) statsArray[11].value = "Unstoppable";
    else if (uPRI.MaxMultiKill == 4) statsArray[11].value = "Mega Kill";
    else if (uPRI.MaxMultiKill == 3) statsArray[11].value = "Ultra Kill";
    else if (uPRI.MaxMultiKill == 2) statsArray[11].value = "Multi Kill";
    else if (uPRI.MaxMultiKill == 1) statsArray[11].value = "Double Kill";
    else statsArray[11].value = string(uPRI.MaxMultiKill);
  }
  else
  {
    totalStats = 6;
    statsArray[statsArray.Length] = stat1;
    statsArray[0].name = "Grabs";
    statsArray[0].value = uPRI.FlagGrabs@"("$uPRI.FlagPickups$")";
    statsArray[statsArray.Length] = stat2;
    statsArray[1].name = "Caps";
    statsArray[1].value = uPRI.FlagCaps@"("$uPRI.Assists$")";
    statsArray[statsArray.Length] = stat3;
    statsArray[2].name = "Covers";
    statsArray[2].value = string(uPRI.Covers);
    statsArray[statsArray.Length] = stat4;
    statsArray[3].name = "Flag Kills";
    statsArray[3].value = string(uPRI.FlagKills);
    statsArray[statsArray.Length] = stat5;
    statsArray[4].name = "Returns";
    statsArray[4].value = string(tPRI.FlagReturns);
    statsArray[statsArray.Length] = stat6;
    statsArray[5].name = "Seals";
    statsArray[5].value = string(uPRI.Seals);
  }

  for (count = 0; count < totalStats; count++) {
    C.Font = GetFontWithSize(FONT_PLAYER_STAT);
    C.StrLen(statsArray[count].name, statsArray[count].nameW, statsArray[count].nameH);
    C.Font = GetFontWithSize(FONT_PLAYER_STAT_NUM);
    C.StrLen(statsArray[count].value, statsArray[count].valueW, statsArray[count].valueH);
  }

  C.Font = GetFontWithSize(FONT_PLAYER_STAT);
  C.StrLen("Returns", maxNameWidth, maxNameHeight);
  C.Font = GetFontWithSize(FONT_PLAYER_STAT_NUM);
  C.StrLen("999", maxValueWidth, maxValueHeight);
  colWidth[0] = (maxNameWidth / screenScale) + (maxValueWidth / screenScale) + 20.0;

  C.Font = GetFontWithSize(FONT_PLAYER_STAT);
  C.StrLen("Accuracy", maxNameWidth, maxNameHeight);
  C.Font = GetFontWithSize(FONT_PLAYER_STAT_NUM);
  C.StrLen("100.0%", maxValueWidth, maxValueHeight);
  colWidth[1] = (maxNameWidth / screenScale) + (maxValueWidth / screenScale) + 20.0;
  
  C.Font = GetFontWithSize(FONT_PLAYER_STAT);
  C.StrLen("Max MultiKill", maxNameWidth, maxNameHeight);
  C.Font = GetFontWithSize(FONT_PLAYER_STAT_NUM);
  C.StrLen("00/00 (0.00)", maxValueWidth, maxValueHeight);
  colWidth[2] = (maxNameWidth / screenScale) + (maxValueWidth / screenScale) + 10.0;

  totalStatsWidth = 0;
  for (col = 0; col < (totalStats / 4 + 1); col++) {
     if (totalStats == 6 && col >= 2) break;
     if (totalStats == 12 && col >= 3) break;
     totalStatsWidth += colWidth[col];
  }

  statScale = 1.0;
  availableStatSpace = (baseX + boxWidth - 10) - (playerNameX + (playerNameWidth / screenScale) + 20.0);
  if (totalStatsWidth > availableStatSpace && availableStatSpace > 0)
  {
      statScale = availableStatSpace / totalStatsWidth;
  }
  
  // Total drawn width is screenScaled
  totalStatsWidth *= statScale;
  
  statX = baseX + boxWidth - totalStatsWidth - 10;
  availableNameSpace = statX - playerNameX - 10;
  nameScale = 1.0;
  if (playerNameWidth > availableNameSpace && availableNameSpace > 0)
  {
      nameScale = availableNameSpace / playerNameWidth;
  }

  C.Font = GetFontForPlayerName(PRI.PlayerName);
  SetPosScaled(C, playerNameX, baseY + (boxHeight - playerNameHeight*nameScale)/2);
  C.FontScaleX = nameScale;
  C.FontScaleY = nameScale;
  if (uPRI.ColoredName == "") C.DrawText(PRI.PlayerName);
  else C.DrawText(uPRI.ColoredName);
  C.FontScaleX = 1.0;
  C.FontScaleY = 1.0;

  curStatX = statX;
  
  C.FontScaleX = statScale;
  C.FontScaleY = statScale;
  
  for (count = 0; count < totalStats; count++) {
    if (totalStats == 12) { col = count / 4; row = count % 4; }
    else { col = count / 3; row = count % 3; }
    
    if (row == 0 && col > 0) {
        curStatX += (colWidth[col-1] * statScale);
    }
    
    // We must manually measure the specific column's NameWidth to know where to place the Value for this col!
    C.Font = GetFontWithSize(FONT_PLAYER_STAT);
    if (col == 0) C.StrLen("Returns", maxNameWidth, maxNameHeight);
    else if (col == 1) C.StrLen("Accuracy", maxNameWidth, maxNameHeight);
    else C.StrLen("Max MultiKill", maxNameWidth, maxNameHeight);

    C.Font = GetFontWithSize(FONT_PLAYER_STAT);
    if (totalStats == 12) SetPosScaled(C, curStatX, baseY + (boxHeight - (statsArray[count].nameH * statScale) * 4)/2 + (statsArray[count].nameH * statScale)*row);
    else SetPosScaled(C, curStatX, baseY + (boxHeight - (statsArray[count].nameH * statScale) * 3)/2 + (statsArray[count].nameH * statScale)*row);
    
    C.SetDrawColor(255, 255, 255, 255);
    C.DrawText(statsArray[count].name);

    C.Font = GetFontWithSize(FONT_PLAYER_STAT_NUM);
    if (totalStats == 12) SetPosScaled(C, curStatX + ((maxNameWidth / screenScale) + 15.0) * statScale, baseY + (boxHeight - (statsArray[count].nameH * statScale) * 4)/2 + (statsArray[count].nameH * statScale)*row);
    else SetPosScaled(C, curStatX + ((maxNameWidth / screenScale) + 15.0) * statScale, baseY + (boxHeight - (statsArray[count].nameH * statScale) * 3)/2 + (statsArray[count].nameH * statScale)*row);
    C.DrawText(statsArray[count].value);
  }
  
  C.FontScaleX = 1.0;
  C.FontScaleY = 1.0;
}


/*
 * Arrange specs - WebAdmin, DemoRecSpectator go first.
 */
simulated function ArrangeSpecs(out PlayerReplicationInfo PRI[MAXPLAYERS])
{

}

/*
 *-----------------
 * Scaling functions
 * Regular Canvas functions but screenScaled versions to reduce stuff like ClipX*0.01248 existing in all the draw functions
 * These are here because I am too lazy to subclass Canvas (lol)
 *-----------------
 */

function float ScaleX(Canvas C, float value)
{
  return C.ClipX * (value/1920);
}

function float ScaleY(Canvas C, float value)
{
  return C.ClipY * (value/1080);
}

function SetPosScaled(Canvas C, float x, float y)
{
  C.SetPos(ScaleX(C, x), ScaleY(C, y));
}

function DrawTileStretchedScaled(Canvas C, material mat, float XL, float YL)
{
  C.DrawTileStretched(mat, ScaleX(C, XL), ScaleY(C, YL));
}

function DrawBoxScaled(Canvas C, float w, float h)
{

}

function DrawTextJustifiedScaled(Canvas C, coerce string text, byte justification, float x1, float y1, float x2, float y2)
{
  C.DrawTextJustified(text, justification, ScaleX(C, x1), ScaleY(C, y1), ScaleX(C, x2), ScaleY(C, y2));
}

/*
 *-----------------
 * String functions
 *-----------------
 */
function String GetRestartString()
{
  local string RestartString;

  RestartString = Restart;
  if (PlayerController(Owner).PlayerReplicationInfo.bOutOfLives)
  {
    RestartString = OutFireText;
  }
  else if ( Level.TimeSeconds - UnrealPlayer(Owner).LastKickWarningTime < 2 )
  {
    RestartString = class'GameMessage'.Default.KickWarning;
  }

  return RestartString;
}


function String GetTitleString()
{
  local string titlestring;

  if ( Level.NetMode == NM_Standalone )
  {
    if ( Level.Game.CurrentGameProfile != None )
    {
      titlestring = SkillLevel[Clamp(Level.Game.CurrentGameProfile.BaseDifficulty,0,7)];
    }
    else
    {
      titlestring = SkillLevel[Clamp(Level.Game.GameDifficulty,0,7)];
    }
  }
  else if ( (GRI != None) && (GRI.BotDifficulty >= 0) )
  {
    titlestring = SkillLevel[Clamp( GRI.BotDifficulty,0,7)];
  }

  return titlestring@GRI.GameName$MapName$Level.Title;
}

function String GetDefaultScoreInfoString()
{
  local String ScoreInfoString;

  if (GRI.MaxLives != 0)
  {
    ScoreInfoString = MaxLives@GRI.MaxLives;
  }
  else if ( GRI.GoalScore != 0 )
  {

    ScoreInfoString = FragLimitTeam@GRI.GoalScore;

    if (GRI.TimeLimit != 0)
    {
      ScoreInfoString = ScoreInfoString@spacer@TimeLimit$FormatTime(GRI.RemainingTime);
    }
  }
  else
  {
    ScoreInfoString = ScoreInfoString@spacer@FooterText@FormatTime(GRI.ElapsedTime);
  }

  return ScoreInfoString;
}

simulated function string GetAverageTeamPing(byte team)
{
  local int i;
  local float avg;
  local int NumSamples;

  for(i = 0; i < GRI.PRIArray.Length; i++)
  {
    if(!GRI.PRIArray[i].bOnlySpectator && GRI.PRIArray[i].Team != None && GRI.PRIArray[i].Team.TeamIndex == team)
    {
      Avg += GRI.PRIArray[i].Ping;
      NumSamples++;
    }
  }

  return string(int(4.0*Avg/float(NumSamples))); //Why 4?
}

simulated function string GetAverageTeamPL(byte team)
{
  local int i;
  local float avg;
  local int numSamples;

  for (i = 0; i < GRI.PRIArray.length; i++)
  {
    if (!GRI.PRIArray[i].bOnlySpectator && GRI.PRIArray[i].Team != None && GRI.PRIArray[i].Team.TeamIndex == team)
    {
      avg += GRI.PRIArray[i].PacketLoss;
      numSamples++;
    }
  }

  return string(int(avg/float(numSamples)));
}

/*
 * -----------
 * Font loader
 * -----------
 */

static function Font GetFontWithSize(int i)
{
  if( default.FontArrayFonts[i] == None )
  {
    default.FontArrayFonts[i] = Font(DynamicLoadObject(default.FontArrayNames[i], class'Font'));
    if(default.FontArrayFonts[i] == None)
    {
      Log("Warning: "$default.Class$" Couldn't dynamically load font "$default.FontArrayNames[i]);
    }
  }

  return default.FontArrayFonts[i];
}

//TODO: FIX THIS
simulated function Font GetFontForPlayerName(String playerName)
{
  local int length;

  length = Len(playerName);

  if (length >= 14) {
    return GetFontWithSize(FONT_PLAYER_NAME - 1);
  } else {
    return GetFontWithSize(FONT_PLAYER_NAME);
  }
}

defaultproperties
{
  fraglimitteam="SCORE LIMIT:"
  bEnableColoredNamesOnScoreboard=True
  bDrawStats=True
  bDrawPickups=True
  bOverrideDisplayStats=false
  FontArrayNames(0)  = "Engine.DefaultFont"
  FontArrayNames(1)  = "2K4Fonts.Verdana12"
  FontArrayNames(2)  = "2K4Fonts.Verdana14"
  FontArrayNames(3)  = "UT2003Fonts.FontEurostile14"
  FontArrayNames(4)  = "2K4Fonts.Verdana16"
  FontArrayNames(5)  = "UT2003Fonts.FontEurostile17"
  FontArrayNames(6)  = "UT2003Fonts.FontEurostile29"
  FontArrayNames(7)  = "UT2003Fonts.FontEurostile37"
  FontArrayNames(8)  = "Engine.DefaultFont"

  TeamBoxMaterial = Material'Engine.WhiteTexture'
  TeamHeaderMaterial = Material'Engine.BlackTexture'
}
