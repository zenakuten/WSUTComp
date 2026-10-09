// Stock team scoreboard, used for team games when the UTComp enhanced scoreboard
// is turned off. Looks the same as XInterface.ScoreBoardTeamDeathMatch, plus:
//  - colored names (follows the "Show colored names on scoreboard" setting)
//  - PPH stays visible with bigger teams. The stock board only draws PPH when
//    three lines of the small font fit in a player row, which stops happening
//    as rows shrink for bigger teams (and at some resolutions, at all).
//  - admins are not shown as "Admin" when the server uses silent admin.
class UTComp_ScoreBoardStockTeam extends ScoreBoardTeamDeathMatch;

var UTComp_ServerReplicationInfo RepInfo;

// How many sizes below the stock net info font we go to keep ping/PPH/time.
const NETINFO_MAX_FONT_STEPS = 2;

simulated function string GetDisplayName(PlayerReplicationInfo PRI)
{
	local UTComp_PRI uPRI;

	if ( class'UTComp_ScoreBoard'.default.bEnableColoredNamesOnScoreboard )
	{
		uPRI = class'UTComp_Util'.static.GetUTCompPRI(PRI);
		if ( uPRI != None && uPRI.ColoredName != "" )
			return uPRI.ColoredName;
	}
	return PRI.PlayerName;
}

// Left() that doesn't leave part of a color code (Chr(27) + 3 bytes) at the end.
simulated function string LeftKeepColors(string S, int Count)
{
	local int i;

	S = Left(S, Count);
	for ( i=Len(S)-1; i>=0 && i>=Len(S)-3; i-- )
		if ( Mid(S, i, 1) == Chr(27) )
			return Left(S, i);
	return S;
}

// Copy of ScoreBoardTeamDeathMatch.DrawTeam with names from GetDisplayName. Also
// fixes the stock longest-name pass, which measured GRI.PRIArray (all players,
// unsorted) instead of this team's PRIArray.
function DrawTeam(int TeamNum, int PlayerCount, int OwnerOffset, Canvas Canvas, int FontReduction, int BoxSpaceY, int PlayerBoxSizeY, int HeaderOffsetY)
{
	local int i, OwnerPos, NetXPos, NameXPos, BoxTextOffsetY, ScoreXPos, ScoreYPos, BoxXPos, BoxWidth, LineCount,NameY;
	local float XL,YL,IconScale,ScoreBackScale,ScoreYL,MaxNamePos,LongestNameLength, oXL, oYL;
	local string PlayerName[MAXPLAYERS], OrdersText, LongestName;
	local font MainFont, ReducedFont;
	local bool bHaveHalfFont, bNameFontReduction;
	local int SymbolUSize, SymbolVSize, OtherTeam, LastLine;

	BoxWidth = 0.47 * Canvas.ClipX;
	BoxXPos = 0.5 * (0.5 * Canvas.ClipX - BoxWidth);
	BoxWidth = 0.5 * Canvas.ClipX - 2*BoxXPos;
	BoxXPos = BoxXPos + TeamNum * 0.5 * Canvas.ClipX;
	NameXPos = BoxXPos + 0.05 * BoxWidth;
	ScoreXPos = BoxXPos + 0.55 * BoxWidth;
	NetXPos = BoxXPos + 0.76 * BoxWidth;
	bHaveHalfFont = HaveHalfFont(Canvas, FontReduction);

	// draw background box
	Canvas.Style = ERenderStyle.STY_Alpha;
	Canvas.DrawColor = HUDClass.default.WhiteColor;
	Canvas.SetPos(BoxXPos, HeaderOffsetY);
	Canvas.DrawTileStretched( TeamBoxMaterial[TeamNum], BoxWidth, PlayerCount * (PlayerBoxSizeY + BoxSpaceY));

	// draw team header
	IconScale = Canvas.ClipX/4096;
	ScoreBackScale = Canvas.ClipX/1024;
	if ( GRI.TeamSymbols[TeamNum] != None )
	{
		SymbolUSize = GRI.TeamSymbols[TeamNum].USize;
		SymbolVSize = GRI.TeamSymbols[TeamNum].VSize;
	}
	else
	{
		SymbolUSize = 256;
		SymbolVSize = 256;
	}
	ScoreYPos = HeaderOffsetY - SymbolVSize * IconScale - BoxSpaceY;

	Canvas.DrawColor = 0.75 * HUDClass.default.WhiteColor;
	Canvas.SetPos(BoxXPos, ScoreYPos - BoxSpaceY);
	Canvas.DrawTileStretched( Material'InterfaceContent.ScoreBoxA', BoxWidth, HeaderOffsetY + BoxSpaceY - ScoreYPos);

	Canvas.Style = ERenderStyle.STY_Normal;
	Canvas.DrawColor = TeamColors[TeamNum];
	Canvas.SetPos((0.25 + 0.5*TeamNum) * Canvas.ClipX - (SymbolUSize + 32) * IconScale, ScoreYPos);
	if ( GRI.TeamSymbols[TeamNum] != None )
		Canvas.DrawIcon(GRI.TeamSymbols[TeamNum],IconScale);
	MainFont = Canvas.Font;
	Canvas.Font = HUDClass.static.LargerFontThan(MainFont);
	Canvas.StrLen("TEST",XL,ScoreYL);
	if ( ScoreYPos == 0 )
		ScoreYPos = HeaderOffsetY - ScoreYL;
	else
		ScoreYPos = ScoreYPos + 0.5 * SymbolVSize * IconScale - 0.5 * ScoreYL;
	Canvas.SetPos((0.25 + 0.5*TeamNum) * Canvas.ClipX + 32*IconScale,ScoreYPos);
	Canvas.DrawText(int(GRI.Teams[TeamNum].Score));
	Canvas.Font = MainFont;
	Canvas.DrawColor = HUDClass.default.WhiteColor;

	IconScale = Canvas.ClipX/1024;

	if ( PlayerCount <= 0 )
		return;

	// draw lines between sections
	if ( TeamNum == 0 )
		Canvas.DrawColor = HUDClass.default.RedColor;
	else
		Canvas.DrawColor = HUDClass.default.BlueColor;
	if ( OwnerOffset >= PlayerCount )
		LastLine = PlayerCount+1;
	else
		LastLine = PlayerCount;
	for ( i=1; i<LastLine; i++ )
	{
		Canvas.SetPos( NameXPos, HeaderOffsetY + (PlayerBoxSizeY + BoxSpaceY)*i - 0.5*BoxSpaceY);
		Canvas.DrawTileStretched( Material'InterfaceContent.ButtonBob', 0.9*BoxWidth, ScorebackScale*3);
	}
	Canvas.DrawColor = HUDClass.default.WhiteColor;

	// draw player names
	MaxNamePos = 0.95 * (ScoreXPos - NameXPos);
	for ( i=0; i<PlayerCount; i++ )
	{
		playername[i] = GetDisplayName(PRIArray[i]);
		Canvas.StrLen(playername[i], XL, YL);
		if ( XL > FMax(LongestNameLength,MaxNamePos) )
		{
			LongestName = PlayerName[i];
			LongestNameLength = XL;
		}
	}
	if ( OwnerOffset >= PlayerCount )
	{
		playername[OwnerOffset] = GetDisplayName(PRIArray[OwnerOffset]);
		Canvas.StrLen(playername[OwnerOffset], XL, YL);
		if ( XL > FMax(LongestNameLength,MaxNamePos) )
		{
			LongestName = PlayerName[OwnerOffset];
			LongestNameLength = XL;
		}
	}

	if ( LongestNameLength > 0 )
	{
		bNameFontReduction = true;
		Canvas.Font = GetSmallerFontFor(Canvas,FontReduction+1);
		Canvas.StrLen(LongestName, XL, YL);
		if ( XL > MaxNamePos )
		{
			Canvas.Font = GetSmallerFontFor(Canvas,FontReduction+2);
			Canvas.StrLen(LongestName, XL, YL);
			if ( XL > MaxNamePos )
				Canvas.Font = GetSmallerFontFor(Canvas,FontReduction+3);
		}
		ReducedFont = Canvas.Font;
	}

	for ( i=0; i<PlayerCount; i++ )
	{
		Canvas.StrLen(playername[i], XL, YL);
		if ( XL > MaxNamePos )
			playername[i] = LeftKeepColors(playername[i], MaxNamePos/XL * len(PlayerName[i]));
	}
	if ( OwnerOffset >= PlayerCount )
	{
		Canvas.StrLen(playername[OwnerOffset], XL, YL);
		if ( XL > MaxNamePos )
			playername[OwnerOffset] = LeftKeepColors(playername[OwnerOffset], MaxNamePos/XL * len(PlayerName[OwnerOffset]));
	}

	if ( Canvas.ClipX < 512 )
		NameY = 0.5 * YL;
	else if ( !bHaveHalfFont )
		NameY = 0.125 * YL;
	Canvas.Style = ERenderStyle.STY_Normal;
	Canvas.DrawColor = HUDClass.default.WhiteColor;
	Canvas.SetPos(0.5 * Canvas.ClipX, HeaderOffsetY + 4);
	BoxTextOffsetY = HeaderOffsetY + 0.5 * PlayerBoxSizeY - 0.5 * YL;
	Canvas.DrawColor = HUDClass.default.WhiteColor;

	if ( OwnerOffset == -1 )
	{
		for ( i=0; i<PlayerCount; i++ )
			if ( i != OwnerOffset )
			{
				Canvas.SetPos(NameXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY);
				Canvas.DrawText(playername[i],true);
			}
	}
	else
	{
		for ( i=0; i<PlayerCount; i++ )
			if ( i != OwnerOffset )
			{
				Canvas.SetPos(NameXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY - 0.5 * YL + NameY);
				Canvas.DrawText(playername[i],true);
			}
	}
	if ( bNameFontReduction )
		Canvas.Font = GetSmallerFontFor(Canvas,FontReduction);

	// draw scores
	Canvas.DrawColor = HUDClass.default.WhiteColor;
	for ( i=0; i<PlayerCount; i++ )
		if ( i != OwnerOffset )
		{
			Canvas.SetPos(ScoreXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY);
			if ( PRIArray[i].bOutOfLives )
				Canvas.DrawText(OutText,true);
			else
				Canvas.DrawText(int(PRIArray[i].Score),true);
		}

	// draw owner line
	if ( OwnerOffset >= 0 )
	{
		if ( OwnerOffset >= PlayerCount )
		{
			OwnerPos = (PlayerBoxSizeY + BoxSpaceY)*PlayerCount + BoxTextOffsetY;
			// draw extra box
			Canvas.Style = ERenderStyle.STY_Alpha;
			Canvas.SetPos(BoxXPos, HeaderOffsetY + (PlayerBoxSizeY + BoxSpaceY)*PlayerCount);
			Canvas.DrawTileStretched( TeamBoxMaterial[TeamNum], BoxWidth, PlayerBoxSizeY);
			Canvas.Style = ERenderStyle.STY_Normal;
			if ( PRIArray[OwnerOffset].HasFlag != None )
			{
				Canvas.DrawColor = HUDClass.default.WhiteColor;
				Canvas.SetPos(NameXPos - 48*IconScale, OwnerPos - 16*IconScale);
				Canvas.DrawTile( FlagIcon, 64*IconScale, 32*IconScale, 0, 0, 256, 128);
			}
		}
		else
			OwnerPos = (PlayerBoxSizeY + BoxSpaceY)*OwnerOffset + BoxTextOffsetY;

		Canvas.DrawColor = HUDClass.default.GoldColor;
		Canvas.SetPos(NameXPos, OwnerPos-0.5*YL+NameY);
		if ( bNameFontReduction )
			Canvas.Font = ReducedFont;
		Canvas.DrawText(playername[OwnerOffset],true);
		if ( bNameFontReduction )
			Canvas.Font = GetSmallerFontFor(Canvas,FontReduction);
		Canvas.DrawColor = HUDClass.default.GoldColor;
		Canvas.SetPos(ScoreXPos, OwnerPos);
		if ( PRIArray[OwnerOffset].bOutOfLives )
			Canvas.DrawText(OutText,true);
		else
			Canvas.DrawText(int(PRIArray[OwnerOffset].Score),true);
	}

	// draw flag icons
	Canvas.DrawColor = HUDClass.default.WhiteColor;
	if ( TeamNum == 0 )
		OtherTeam = 1;
	if ( (GRI.FlagState[OtherTeam] != EFlagState.FLAG_Home) && (GRI.FlagState[OtherTeam] != EFlagState.FLAG_Down) )
	{
		for ( i=0; i<PlayerCount; i++ )
			if ( (PRIArray[i].HasFlag != None) || (PRIArray[i] == GRI.FlagHolder[TeamNum]) )
			{
				Canvas.SetPos(NameXPos - 48*IconScale, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY - 16*IconScale);
				Canvas.DrawTile( FlagIcon, 64*IconScale, 32*IconScale, 0, 0, 256, 128);
			}
	}

	// draw location and/or orders
	if ( (OwnerOffset >= 0) && (Canvas.ClipX >= 512) )
	{
		BoxTextOffsetY = HeaderOffsetY + 0.5*PlayerBoxSizeY + NameY;
		Canvas.DrawColor = HUDClass.default.CyanColor;
		if ( FontReduction > 3 )
			bHaveHalfFont = false;
		if ( Canvas.ClipX >= 1280 )
			Canvas.Font = GetSmallFontFor(Canvas.ClipX, FontReduction+2);
		else
			Canvas.Font = GetSmallFontFor(Canvas.ClipX, FontReduction+1);
		Canvas.StrLen("Test", XL, YL);
		for ( i=0; i<PlayerCount; i++ )
		{
			LineCount = 0;
			if( PRIArray[i].bBot && (TeamPlayerReplicationInfo(PRIArray[i]) != None) && (TeamPlayerReplicationInfo(PRIArray[i]).Squad != None) )
			{
				LineCount = 1;
				Canvas.SetPos(NameXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY);
				if ( Canvas.ClipX < 800 )
					OrdersText = "("$PRIArray[i].GetCallSign()$") "$TeamPlayerReplicationInfo(PRIArray[i]).Squad.GetShortOrderStringFor(TeamPlayerReplicationInfo(PRIArray[i]));
				else
				{
					OrdersText = TeamPlayerReplicationInfo(PRIArray[i]).Squad.GetOrderStringFor(TeamPlayerReplicationInfo(PRIArray[i]));
					OrdersText = "("$PRIArray[i].GetCallSign()$") "$OrdersText;
					Canvas.StrLen(OrdersText, oXL, oYL);
					if ( oXL >= ScoreXPos - NameXPos )
						OrdersText = "("$PRIArray[i].GetCallSign()$") "$TeamPlayerReplicationInfo(PRIArray[i]).Squad.GetShortOrderStringFor(TeamPlayerReplicationInfo(PRIArray[i]));
				}
				Canvas.DrawText(OrdersText,true);
			}
			if ( bHaveHalfFont || !PRIArray[i].bBot )
			{
				Canvas.SetPos(NameXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY + LineCount*YL);
				Canvas.DrawText(PRIArray[i].GetLocationName(),true);
			}
		}
		if ( OwnerOffset >= PlayerCount )
		{
			Canvas.SetPos(NameXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY);
			Canvas.DrawText(PRIArray[OwnerOffset].GetLocationName(),true);
		}
	}

	if ( Level.NetMode == NM_Standalone )
		return;
	Canvas.Font = MainFont;
	Canvas.StrLen("Test",XL,YL);
	BoxTextOffsetY = HeaderOffsetY + 0.5 * PlayerBoxSizeY - 0.5 * YL;
	DrawNetInfo(Canvas,FontReduction,HeaderOffsetY,PlayerBoxSizeY,BoxSpaceY,BoxTextOffsetY,OwnerOffset,PlayerCount,NetXPos);
}

// Draws ping/packet loss/PPH/time for one row, using as many lines as fit.
// Y is the vertical center of the row.
function DrawPlayerNetLines(Canvas Canvas, PlayerReplicationInfo PRI, int NetXPos, float Y, float YL, int Lines)
{
	local string PPHText, PlayedText;

	PPHText = FPH@Clamp(3600*PRI.Score/FMax(1,FPHTime - PRI.StartTime),-999,9999);
	PlayedText = FormatTime(Max(0,FPHTime - PRI.StartTime));

	if ( Lines >= 4 )
	{
		Canvas.SetPos(NetXPos, Y - 1.9 * YL);
		Canvas.DrawText(PingText@Min(999,4*PRI.Ping),true);
		Canvas.SetPos(NetXPos, Y - 0.9 * YL);
		Canvas.DrawText(PLText@PRI.PacketLoss,true);
		Canvas.SetPos(NetXPos, Y + 0.1 * YL);
		Canvas.DrawText(PPHText,true);
		Canvas.SetPos(NetXPos, Y + 1.1 * YL);
		Canvas.DrawText(PlayedText,true);
	}
	else if ( Lines == 3 )
	{
		Canvas.SetPos(NetXPos, Y - 1.5 * YL);
		Canvas.DrawText(PingText@Min(999,4*PRI.Ping),true);
		Canvas.SetPos(NetXPos, Y - 0.5 * YL);
		Canvas.DrawText(PPHText,true);
		Canvas.SetPos(NetXPos, Y + 0.5 * YL);
		Canvas.DrawText(PlayedText,true);
	}
	else if ( Lines == 2 )
	{
		// The stock board shows time played here; PPH is more useful.
		Canvas.SetPos(NetXPos, Y - YL);
		Canvas.DrawText(PingText@Min(999,4*PRI.Ping),true);
		Canvas.SetPos(NetXPos, Y);
		Canvas.DrawText(PPHText,true);
	}
	else
	{
		Canvas.SetPos(NetXPos, Y - 0.5*YL);
		Canvas.DrawText(PingText@Min(999,4*PRI.Ping),true);
	}
}

function DrawNetInfo(Canvas Canvas,int FontReduction,int HeaderOffsetY,int PlayerBoxSizeY,int BoxSpaceY,int BoxTextOffsetY,int OwnerOffset,int PlayerCount, int NetXPos)
{
	local float XL,YL;
	local int i, Step, Lines;
	local bool bHaveHalfFont, bDrawPL, bHideAdmin;

	if ( RepInfo == None )
		foreach DynamicActors(class'UTComp_ServerReplicationInfo', RepInfo)
			break;
	// Until RepInfo arrives we can't tell, so don't risk outing a silent admin.
	bHideAdmin = RepInfo == None || RepInfo.bSilentAdmin;

	// draw admins
	if ( GRI.bMatchHasBegun && !bHideAdmin )
	{
		Canvas.DrawColor = HUDClass.default.RedColor;
		for ( i=0; i<PlayerCount; i++ )
			if ( PRIArray[i].bAdmin )
				{
					Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY);
					Canvas.DrawText(AdminText,true);
				}
		if ( (OwnerOffset >= PlayerCount) && PRIArray[OwnerOffset].bAdmin )
		{
			Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*PlayerCount + BoxTextOffsetY);
			Canvas.DrawText(AdminText,true);
		}
	}

	Canvas.DrawColor = HUDClass.default.CyanColor;
	Canvas.Font = GetSmallFontFor(Canvas.ClipX, FontReduction);
	Canvas.StrLen("Test", XL, YL);
	BoxTextOffsetY = HeaderOffsetY + 0.5*PlayerBoxSizeY;
	bHaveHalfFont = ( YL < 0.5 * PlayerBoxSizeY);
	// if game hasn't begun, draw ready or not ready
	if ( !GRI.bMatchHasBegun )
	{
		bDrawPL = PlayerBoxSizeY > 3 * YL;
		for ( i=0; i<PlayerCount; i++ )
		{
			if ( bDrawPL )
			{
				Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY - 1.5 * YL);
				Canvas.DrawText(PingText@Min(999,4*PRIArray[i].Ping),true);
				Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY - 0.5 * YL);
				Canvas.DrawText(PLText@PRIArray[i].PacketLoss,true);
				Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY + 0.5 * YL);
			}
			else if ( bHaveHalfFont )
			{
				Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY - YL);
				Canvas.DrawText(PingText@Min(999,4*PRIArray[i].Ping),true);
				Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY);
			}
			else
				Canvas.SetPos(NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY - 0.5*YL);
			if ( PRIArray[i].bReadyToPlay )
				Canvas.DrawText(ReadyText,true);
			else
				Canvas.DrawText(NotReadyText,true);
		}
		return;
	}

	// Pick how many lines to draw. Rows shrink as teams grow, so if ping/PPH/time
	// doesn't fit in the stock font, step the font down a size or two before
	// giving up on it, then fall back to ping and PPH on two lines.
	if ( Canvas.ClipX < 512 )
	{
		PingText = "";
		if ( bHaveHalfFont )
			Lines = 2;
		else
			Lines = 1;
	}
	else
	{
		PingText = Default.PingText;
		if ( PlayerBoxSizeY > 4 * YL )
			Lines = 4;
		else
		{
			for ( Step=1; Step<=NETINFO_MAX_FONT_STEPS && PlayerBoxSizeY <= 3 * YL; Step++ )
			{
				Canvas.Font = GetSmallFontFor(Canvas.ClipX, FontReduction + Step);
				Canvas.StrLen("Test", XL, YL);
			}
			if ( PlayerBoxSizeY > 3 * YL )
				Lines = 3;
			else
			{
				// Three lines don't fit even in the smallest font we allow, so go
				// back to the stock size for two lines.
				Canvas.Font = GetSmallFontFor(Canvas.ClipX, FontReduction);
				Canvas.StrLen("Test", XL, YL);
				if ( bHaveHalfFont )
					Lines = 2;
				else
					Lines = 1;
			}
		}
	}

	if ( ((FPHTime == 0) || (!UnrealPlayer(Owner).bDisplayLoser && !UnrealPlayer(Owner).bDisplayWinner))
		&& (GRI.ElapsedTime > 0) )
		FPHTime = GRI.ElapsedTime;

	for ( i=0; i<PlayerCount; i++ )
		if ( (!PRIArray[i].bAdmin || bHideAdmin) && !PRIArray[i].bOutOfLives )
			DrawPlayerNetLines(Canvas, PRIArray[i], NetXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY, YL, Lines);
	if ( (OwnerOffset >= PlayerCount) && (!PRIArray[OwnerOffset].bAdmin || bHideAdmin) && !PRIArray[OwnerOffset].bOutOfLives )
		DrawPlayerNetLines(Canvas, PRIArray[OwnerOffset], NetXPos, (PlayerBoxSizeY + BoxSpaceY)*PlayerCount + BoxTextOffsetY, YL, Lines);
}
