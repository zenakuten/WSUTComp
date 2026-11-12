

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

// FontArrayFonts entries this board draws with, resolved once (see PrepareFrame).
// They don't depend on the resolution.
var transient Font CTFFonts[9];
var transient bool bCTFFontsCached;

// Per-player stat labels. They are constant, so their sizes are measured once per
// frame in UpdateScoreBoard instead of once per row.
var string StatNames[6];
var transient float StatNameW[6], StatNameH[6];
var transient float LongestOStatName, LongestDStatName;

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

  // Fonts, warmup and emoticon lookups, once per frame. The FONT_* indices are
  // constants in defaultproperties.
  PrepareFrame(C);
  maxTiles=8; //max players per team?

  // Stat label sizes are the same for every row (constant text, constant font).
  C.Font = CTFFonts[FONT_PLAYER_STAT];
  LongestOStatName = 0;
  LongestDStatName = 0;
  for (i = 0; i < 6; i++)
  {
    C.StrLen(StatNames[i], StatNameW[i], StatNameH[i]);

    //Find the longest name for both left and right.
    if (i < 3 && StatNameW[i] > LongestOStatName)
      LongestOStatName = StatNameW[i];
    else if (i > 3 && StatNameW[i] > LongestDStatName)
      LongestDStatName = StatNameW[i];
  }


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

  DrawStats(C);
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


// Resolves the fonts this board uses once; GetFontWithSize was called ~25 times
// per row. A font that fails to load stays None instead of retrying (and logging)
// on every call.
simulated function PrepareFrame(Canvas C)
{
  if (!bCTFFontsCached)
  {
    bCTFFontsCached = true;
    CTFFonts[FONT_PLAYER_PING]      = GetFontWithSize(FONT_PLAYER_PING);
    CTFFonts[FONT_PLAYER_STAT]      = GetFontWithSize(FONT_PLAYER_STAT);
    CTFFonts[FONT_PLAYER_STAT_NUM]  = GetFontWithSize(FONT_PLAYER_STAT_NUM);
    CTFFonts[FONT_PLAYER_SCORE]     = GetFontWithSize(FONT_PLAYER_SCORE);
    CTFFonts[FONT_PLAYER_NAME]      = GetFontWithSize(FONT_PLAYER_NAME);
    CTFFonts[FONT_PLAYER_NAME - 1]  = GetFontWithSize(FONT_PLAYER_NAME - 1);
    CTFFonts[FONT_TEAM_SCORE]       = GetFontWithSize(FONT_TEAM_SCORE);
    CTFFonts[FONT_TEAM_PING]        = GetFontWithSize(FONT_TEAM_PING);
    CTFFonts[FONT_TEAM_POWERUP_PER] = GetFontWithSize(FONT_TEAM_POWERUP_PER);
    CTFFonts[FONT_TEAM_POWERUP_NUM] = GetFontWithSize(FONT_TEAM_POWERUP_NUM);
  }
  Super.PrepareFrame(C);
}

/*
 * Draw the UTComp logo
 */
simulated function DrawLogo(Canvas C , float scale)
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
  C.Font = CTFFonts[FONT_TEAM_SCORE];

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

  //Average ping/PL
  C.Font = CTFFonts[FONT_TEAM_PING];
  //STRLEN IS FUCKING STUPID
  C.StrLen("Ping", pingWidth, pingHeight);
  C.StrLen("PL", plWidth, plHeight);
  C.StrLen("Ping 999ms", pingMaxWidth, pingMaxHeight);

  switch (team)
  {
    case 0:
      x_ping = baseX + 20;
      x_pl = x_ping + pingWidth - plWidth;
      break;
    case 1:
      x_ping = baseX + baseWidth - pingMaxWidth;
      x_pl = x_ping + plWidth;
      break;
    default:
  }

  SetPosScaled(C, x_ping, baseY + (baseHeight - pingHeight - plHeight)/2);
  C.DrawText("Ping"@GetAverageTeamPing(team)$"ms");
  SetPosScaled(C, x_pl, baseY + pingHeight + (baseHeight - pingHeight - plHeight)/2);
  C.DrawText("PL"@GetAverageTeamPL(team)$"%");

  //Powerups/flag timing
  C.Font = CTFFonts[FONT_TEAM_POWERUP_PER];
  C.StrLen("100%", powerupPercentWidth, powerupPercentHeight);
  C.Font = CTFFonts[FONT_TEAM_POWERUP_NUM];
  C.StrLen("99", powerupNumWidth, powerupNumHeight);

  for (x = 0; x < 3; x++) {

    //TODO: scale icons by resolution
    //TODO: fix flag/clock so it doesnt look dumb + flag has some extra shit at top right
    switch (x)
    {
      case 0:
        SetPosScaled(C, baseX + pingMaxWidth - 64 + 100 + 200*x, baseY + (baseHeight - 64)/2);
        C.DrawTile(material'HudContent.Generic.Hud', 64, 64, 0, 164, 73, 82); //amp
        break;
      case 1:
        SetPosScaled(C, baseX + pingMaxWidth - 64 + 100 + 200*x, baseY + (baseHeight - 64)/2);
        C.DrawTile(material'HudContent.Generic.Hud', 64, 64, 1, 248, 64, 64); //100a
        break;
      case 2:
        SetPosScaled(C, baseX + pingMaxWidth - 64 + 100 + 200*x, baseY + 35); //clock is short, so move it down
        C.DrawTile(material'HudContent.Generic.Hud', 40, 40, 148, 354, 40, 40); //clock
        SetPosScaled(C, baseX + pingMaxWidth - 64 + 100 + 200*x, baseY + (baseHeight - 64)/2);
        C.DrawTile(material'HudContent.Generic.Hud', 64, 64, 338, 128, 56, 81); //flag
        break;
      default:

    }

    SetPosScaled(C, baseX + pingMaxWidth + 100 + 200*x, baseY + (baseHeight - powerupNumHeight - powerupPercentHeight)/2);
    C.Font = CTFFonts[FONT_TEAM_POWERUP_PER];
    C.DrawText("0%");

    SetPosScaled(C, baseX + pingMaxWidth + 100 + 200*x, baseY + powerupPercentHeight + (baseHeight - powerupNumHeight - powerupPercentHeight)/2);
    C.Font = CTFFonts[FONT_TEAM_POWERUP_NUM];
    C.DrawText("0");
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
simulated function DrawPlayerInformation(Canvas C, PlayerReplicationInfo PRI, float baseX, float baseY, float scale)
{
  local UTComp_PRI uPRI;
  local TeamPlayerReplicationInfo tPRI;
  local float scoreWidth, scoreHeight, maxScoreWidth;
  local float pingplWidth, pingplHeight;
  local float playerNameWidth, playerNameHeight;
  local int boxWidth, boxHeight;
  local string pingplString;
  local int count;
  local string statValue[6];
  local float statX, statY;
  local bool bWarmup;

  //TODO: Global this or something
  boxWidth  = 840;
  boxHeight = 85;

  uPRI = class'UTComp_Util'.static.GetUTCompPRI(PRI);
  tPRI = TeamPlayerReplicationInfo(PRI);

  // uWarmup is cached by PrepareFrame and is None when warmup is disabled. It
  // used to be read unchecked here, logging Accessed None twice per row per frame
  // (and evaluating to false, which bWarmup keeps).
  bWarmup = uWarmup != None && uWarmup.bInWarmup;

  //Ready/Not Ready
  if (bWarmup) {
    if (!uPRI.bIsReady) {
      C.SetDrawColor(255, 0, 0, 255);
    } else {
      C.SetDrawColor(0, 255, 0, 255);
    }


    SetPosScaled(C, baseX + 20, baseY + (boxHeight - 64)/2);
    C.DrawTile(material'HudContent.Generic.Hud', 64, 64, 338, 128, 56, 81); //flag, tinted red (?)
    C.SetDrawColor(255, 255, 255, 255);
  }

  //Score and Ping/PL
  pingplString = string(PRI.Ping*4)$"ms\ "@string(PRI.PacketLoss)$"%";

  C.Font = CTFFonts[FONT_PLAYER_SCORE];
  C.StrLen(PRI.Score, scoreWidth, scoreHeight);
  C.StrLen("999", maxScoreWidth, scoreHeight);

  C.Font = CTFFonts[FONT_PLAYER_PING];
  C.StrLen(pingplString, pingplWidth, pingplHeight);

  if (!bWarmup) {
  C.Font = CTFFonts[FONT_PLAYER_SCORE];
  SetPosScaled(C, baseX + 15, baseY + (boxHeight - scoreHeight - pingplHeight)/2);
  C.DrawText(int(PRI.Score));
  }

  C.Font = CTFFonts[FONT_PLAYER_PING];
  SetPosScaled(C, baseX + 15 + 3, baseY + scoreHeight + (boxHeight - scoreHeight - pingplHeight)/2);
  C.DrawText(pingplString);

  //Player Name
  C.Font = GetFontForPlayerName(PRI.PlayerName);
  C.StrLen(PRI.PlayerName, playerNameWidth, playerNameHeight);
  SetPosScaled(C, baseX + 40 + maxScoreWidth, baseY + (boxHeight - playerNameHeight)/2);
  if (uPRI.ColoredName == "") {
    if (!TryDrawEmoteName(C, PRI.PlayerName))
      C.DrawText(PRI.PlayerName);
  } else {
    if (!TryDrawEmoteName(C, uPRI.ColoredName))
      C.DrawText(uPRI.ColoredName);
  }

  //Stats
  // Labels (StatNames) and their sizes (StatNameW/H, Longest*StatName) are
  // measured once per frame in UpdateScoreBoard; only the values are per row.
  // (The value widths used to be measured too, but nothing read them.)
  statValue[0] = uPRI.FlagGrabs@"("$uPRI.FlagPickups$")";
  statValue[1] = uPRI.FlagCaps@"("$uPRI.Assists$")";
  statValue[2] = string(uPRI.Covers);
  statValue[3] = string(uPRI.FlagKills);
  statValue[4] = string(tPRI.FlagReturns);
  statValue[5] = string(uPRI.Seals);

  statX = baseX + boxWidth - 300;

  //Left column
  for (count = 0; count < 3; count++) {
    statY = baseY + (boxHeight - StatNameH[count]*3)/2 + StatNameH[count]*count;

    C.Font = CTFFonts[FONT_PLAYER_STAT];
    SetPosScaled(C, statX + LongestOStatName - StatNameW[count], statY);
    C.DrawText(StatNames[count]);

    C.Font = CTFFonts[FONT_PLAYER_STAT_NUM];
    SetPosScaled(C, statX + LongestOStatName + 5, statY);
    C.DrawText(statValue[count]);
  }

  //Right column
  for (count = 3; count < 6; count++) {
    statY = baseY + (boxHeight - StatNameH[count]*3)/2 + StatNameH[count]*(count - 3);

    C.Font = CTFFonts[FONT_PLAYER_STAT];
    SetPosScaled(C, statX + 100 + LongestOStatName + LongestDStatName - StatNameW[count], statY);
    C.DrawText(StatNames[count]);

    C.Font = CTFFonts[FONT_PLAYER_STAT_NUM];
    SetPosScaled(C, statX + 100 + LongestOStatName + LongestDStatName + 5, statY);
    C.DrawText(statValue[count]);
  }
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
 * Regular Canvas functions but scaled versions to reduce stuff like ClipX*0.01248 existing in all the draw functions
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

// ScaleX/ScaleY inlined: these run ~20 times per row.
function SetPosScaled(Canvas C, float x, float y)
{
  C.SetPos(C.ClipX * (x/1920), C.ClipY * (y/1080));
}

function DrawTileStretchedScaled(Canvas C, material mat, float XL, float YL)
{
  C.DrawTileStretched(mat, C.ClipX * (XL/1920), C.ClipY * (YL/1080));
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
    return CTFFonts[FONT_PLAYER_NAME - 1];
  } else {
    return CTFFonts[FONT_PLAYER_NAME];
  }
}

defaultproperties
{
  fraglimitteam="SCORE LIMIT:"
  bEnableColoredNamesOnScoreboard=True
  bDrawStats=True
  bDrawPickups=True
  bOverrideDisplayStats=false

  // FontArrayNames indices (used to be assigned every frame).
  FONT_PLAYER_PING      = 1
  FONT_PLAYER_PL        = 1
  FONT_PLAYER_LOCATION  = 4
  FONT_PLAYER_STAT_NUM  = 1
  FONT_PLAYER_STAT      = 1
  FONT_PLAYER_SCORE     = 6
  FONT_PLAYER_NAME      = 6
  FONT_TEAM_POWERUP_NUM = 3
  FONT_TEAM_PING        = 3
  FONT_TEAM_PL          = 3
  FONT_TEAM_POWERUP_PER = 5
  FONT_TEAM_SCORE       = 7

  StatNames(0) = "Grabs"
  StatNames(1) = "Caps"
  StatNames(2) = "Covers"
  StatNames(3) = "Flag Kills"
  StatNames(4) = "Returns"
  StatNames(5) = "Seals"

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
