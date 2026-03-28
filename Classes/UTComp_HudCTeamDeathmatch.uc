

class UTComp_HudCTeamDeathmatch extends HudCTeamDeathmatch;

var UTComp_HUDSettings HUDSettings;

#include Classes\Include\_HudCommon.uci

simulated event PostBeginPlay() {
    Super.PostBeginPlay();

    foreach AllObjects(class'UTComp_HUDSettings', HUDSettings)
        break;
    if (HUDSettings == none)
        Warn(self@"HUDSettings object not found!");
}

simulated function DrawSpectatingHud (Canvas C)
{
	Super.DrawSpectatingHud(c);
	DrawTimer(C);
    DrawDamageIndicators(C);
}

simulated function UpdatePrecacheMaterials()
{
	local int i;

    for (i=0; i<HUDSettings.UTCompCrosshairs.Length && HUDSettings.bEnableUTCompCrosshairs; i++ )
		Level.AddPrecacheMaterial(HUDSettings.UTCompCrosshairs[i].CrossTex);

    super.UpdatePrecacheMaterials();
}

exec function NextStats()
{
    if (ScoreBoard == none || bShowScoreBoard == false)
        Super.NextStats();
    else
        ScoreBoard.NextStats();
}

function DisplayEnemyName(Canvas C, PlayerReplicationInfo PRI)
{
	PlayerOwner.ReceiveLocalizedMessage(class'UTComp_PlayerNameMessage',0,PRI);
}

simulated function DrawUTCompCrosshair (Canvas C)
{
    local int i;
    local float OldScale,OldW;
	local array<SpriteWidget> CHtexture;

	if ( PawnOwner.bSpecialCrosshair )
	{
		PawnOwner.SpecialDrawCrosshair( C );
		return;
	}

	if (!bCrosshairShow)
        return;

    for(i=0; i<HUDSettings.UTCompCrosshairs.Length; i++)
    {
        CHTexture.Length=i+1;
        CHTexture[i].WidgetTexture=HUDSettings.UTCompCrosshairs[i].CrossTex;
        CHTexture[i].RenderStyle=STY_Alpha;
        CHTexture[i].TextureCoords.X2=64;
        CHTexture[i].TextureCoords.Y2=64;
        CHTexture[i].TextureScale=HUDSettings.UTCompCrosshairs[i].CrossScale*0.50;
        CHTexture[i].DrawPivot=DP_MiddleMiddle;
        CHTexture[i].PosX=HUDSettings.UTCompCrosshairs[i].OffsetX;
        CHTexture[i].PosY=HUDSettings.UTCompCrosshairs[i].OffsetY;
        CHTexture[i].ScaleMode = SM_None;
        CHTexture[i].Scale=1.00;
        CHTexture[i].Tints[0]=HUDSettings.UTCompCrosshairs[i].CrossColor;
        CHTexture[i].Tints[1]=HUDSettings.UTCompCrosshairs[i].CrossColor;
    }

    if ( HUDSettings.bEnableCrosshairSizing && LastPickupTime > Level.TimeSeconds - 0.4 )
	{
		if ( LastPickupTime > Level.TimeSeconds - 0.2 )
			for(i=0; i<CHTexture.Length; i++)
                CHTexture[i].TextureScale *= (1 + 5 * (Level.TimeSeconds - LastPickupTime));
		else
			for(i=0; i<CHTexture.Length; i++)
                CHTexture[i].TextureScale *= (1 + 5 * (LastPickupTime + 0.4 - Level.TimeSeconds));
	}
    OldScale = HudScale;
    HudScale=1;
    OldW = C.ColorModulate.W;
    C.ColorModulate.W = 1;
    for(i=0; i<CHTexture.Length; i++)
        DrawSpriteWidget (C, CHTexture[i]);
    C.ColorModulate.W = OldW;
	HudScale=OldScale;

	DrawEnemyName(C);
}


simulated function DrawCrosshair (Canvas C)
{
    if(HUDSettings.bEnableUTCompCrosshairs && HUDSettings.UTCompCrosshairs.Length>0)
        DrawUTCompCrosshair(C);
    else
        OldDrawCrosshair(C);
}

simulated function OldDrawCrosshair(Canvas C)
{
    local float NormalScale;
    local int i, CurrentCrosshair;
    local float OldScale,OldW, CurrentCrosshairScale;
    local color CurrentCrosshairColor;
	local SpriteWidget CHtexture;

	if ( PawnOwner.bSpecialCrosshair )
	{
		PawnOwner.SpecialDrawCrosshair( C );
		return;
	}

	if (!bCrosshairShow)
        return;

	if ( bUseCustomWeaponCrosshairs && (PawnOwner != None) && (PawnOwner.Weapon != None) )
	{
		CurrentCrosshair = PawnOwner.Weapon.CustomCrosshair;
		if (CurrentCrosshair == -1 || CurrentCrosshair == Crosshairs.Length)
		{
			CurrentCrosshair = CrosshairStyle;
			CurrentCrosshairColor = CrosshairColor;
			CurrentCrosshairScale = CrosshairScale;
		}
		else
		{
			CurrentCrosshairColor = PawnOwner.Weapon.CustomCrosshairColor;
			CurrentCrosshairScale = PawnOwner.Weapon.CustomCrosshairScale;
			if ( PawnOwner.Weapon.CustomCrosshairTextureName != "" )
			{
				if ( PawnOwner.Weapon.CustomCrosshairTexture == None )
				{
					PawnOwner.Weapon.CustomCrosshairTexture = Texture(DynamicLoadObject(PawnOwner.Weapon.CustomCrosshairTextureName,class'Texture'));
					if ( PawnOwner.Weapon.CustomCrosshairTexture == None )
					{
						log(PawnOwner.Weapon$" custom crosshair texture not found!");
						PawnOwner.Weapon.CustomCrosshairTextureName = "";
					}
				}
				CHTexture = Crosshairs[0];
				CHTexture.WidgetTexture = PawnOwner.Weapon.CustomCrosshairTexture;
			}
		}
	}
	else
	{
		CurrentCrosshair = CrosshairStyle;
		CurrentCrosshairColor = CrosshairColor;
		CurrentCrosshairScale = CrosshairScale;
	}

	CurrentCrosshair = Clamp(CurrentCrosshair, 0, Crosshairs.Length - 1);

    NormalScale = Crosshairs[CurrentCrosshair].TextureScale;
	if ( CHTexture.WidgetTexture == None )
		CHTexture = Crosshairs[CurrentCrosshair];
    CHTexture.TextureScale *= 0.5 * CurrentCrosshairScale;

    for( i = 0; i < ArrayCount(CHTexture.Tints); i++ )
        CHTexture.Tints[i] = CurrentCrossHairColor;

	if (  HUDSettings.bEnableCrosshairSizing && LastPickupTime > Level.TimeSeconds - 0.4 )
	{
		if ( LastPickupTime > Level.TimeSeconds - 0.2 )
			CHTexture.TextureScale *= (1 + 5 * (Level.TimeSeconds - LastPickupTime));
		else
			CHTexture.TextureScale *= (1 + 5 * (LastPickupTime + 0.4 - Level.TimeSeconds));
	}
    OldScale = HudScale;
    HudScale=1;
    OldW = C.ColorModulate.W;
    C.ColorModulate.W = 1;
    DrawSpriteWidget (C, CHTexture);
    C.ColorModulate.W = OldW;
	HudScale=OldScale;
    CHTexture.TextureScale = NormalScale;

	DrawEnemyName(C);
}

simulated function DrawTimer(Canvas C)
{
	local GameReplicationInfo GRI;
	local int Minutes, Hours, Seconds;
    local UTComp_Warmup uWarmup;

	GRI = PlayerOwner.GameReplicationInfo;
    if(GRI == None)
        return;

    if(BS_xPlayer(PlayerOwner)!=None)
    {
        if(BS_xPlayer(PlayerOwner).uWarmup!=None)
           uWarmup=BS_xPlayer(PlayerOwner).uWarmup;
    }

    if(GRI.TimeLimit==0)
        Seconds=GRI.ElapsedTime;
    else if(GRI.RemainingTime>0 || GRI.ElapsedTime<60 || (uWarmup!=None && uWarmup.bInWarmup))
        Seconds=GRI.RemainingTime;
    else
        Seconds=GRI.ElapsedTime-GRI.TimeLimit*60-1;

	TimerBackground.Tints[TeamIndex] = HudColorBlack;
    TimerBackground.Tints[TeamIndex].A = 150;

	DrawSpriteWidget( C, TimerBackground);
	DrawSpriteWidget( C, TimerBackgroundDisc);
	DrawSpriteWidget( C, TimerIcon);

	TimerMinutes.OffsetX = default.TimerMinutes.OffsetX - 80;
	TimerSeconds.OffsetX = default.TimerSeconds.OffsetX - 80;
	TimerDigitSpacer[0].OffsetX = Default.TimerDigitSpacer[0].OffsetX;
	TimerDigitSpacer[1].OffsetX = Default.TimerDigitSpacer[1].OffsetX;

	if( Seconds > 3600 )
    {
        Hours = Seconds / 3600;
        Seconds -= Hours * 3600;

		DrawNumericWidget( C, TimerHours, DigitsBig);
        TimerHours.Value = Hours;

		if(Hours>9)
		{
			TimerMinutes.OffsetX = default.TimerMinutes.OffsetX;
			TimerSeconds.OffsetX = default.TimerSeconds.OffsetX;
		}
		else
		{
			TimerMinutes.OffsetX = default.TimerMinutes.OffsetX -40;
			TimerSeconds.OffsetX = default.TimerSeconds.OffsetX -40;
			TimerDigitSpacer[0].OffsetX = Default.TimerDigitSpacer[0].OffsetX - 32;
			TimerDigitSpacer[1].OffsetX = Default.TimerDigitSpacer[1].OffsetX - 32;
		}
		DrawSpriteWidget( C, TimerDigitSpacer[0]);
	}
	DrawSpriteWidget( C, TimerDigitSpacer[1]);

	Minutes = Seconds / 60;
    Seconds -= Minutes * 60;

    TimerMinutes.Value = Min(Minutes, 60);
	TimerSeconds.Value = Min(Seconds, 60);

	DrawNumericWidget( C, TimerMinutes, DigitsBig);
	DrawNumericWidget( C, TimerSeconds, DigitsBig);
}

simulated function DrawHudPassC(Canvas C)
{
    //Super.DrawHudPassC(C);
	DrawHUDPassCUTComp(C);
    DrawTeamRadar(C);
}

// override "Now viewing" 
simulated function DrawHudPassCUTComp (Canvas C)
{
	local VoiceChatRoom VCR;
	local float PortraitWidth,PortraitHeight, X, Y, XL, YL, Abbrev, SmallH, NameWidth;
	local string PortraitString;

	// portrait
	if ( (bShowPortrait || (bShowPortraitVC && Level.TimeSeconds - LastPlayerIDTalkingTime < 2.0)) && (Portrait != None) )
	{
		PortraitWidth = 0.125 * C.ClipY;
		PortraitHeight = 1.5 * PortraitWidth;
		C.DrawColor = WhiteColor;

		C.SetPos(-PortraitWidth*PortraitX + 0.025*PortraitWidth,0.5*(C.ClipY-PortraitHeight) + 0.025*PortraitHeight);
		C.DrawTile( Portrait, PortraitWidth, PortraitHeight, 0, 0, 256, 384);

		C.SetPos(-PortraitWidth*PortraitX,0.5*(C.ClipY-PortraitHeight));
		C.Font = GetFontSizeIndex(C,-2);
		
		if ( PortraitPRI != None )
		{
			PortraitString = PortraitPRI.PlayerName;
			C.StrLen(PortraitString,XL,YL);
			if ( XL > PortraitWidth )
			{
				C.Font = GetFontSizeIndex(C,-4);
				C.StrLen(PortraitString,XL,YL);
				if ( XL > PortraitWidth )
				{
					Abbrev = float(len(PortraitString)) * PortraitWidth/XL;
					PortraitString = left(PortraitString,Abbrev);
					C.StrLen(PortraitString,XL,YL);
				}
			}
		}
		C.DrawColor = C.static.MakeColor(160,160,160);
		C.SetPos(-PortraitWidth*PortraitX + 0.025*PortraitWidth,0.5*(C.ClipY-PortraitHeight) + 0.025*PortraitHeight);
		C.DrawTile( Material'XGameShaders.ModuNoise', PortraitWidth, PortraitHeight, 0.0, 0.0, 512, 512 );

		C.DrawColor = WhiteColor;
		C.SetPos(-PortraitWidth*PortraitX,0.5*(C.ClipY-PortraitHeight));
		C.DrawTileStretched(texture 'InterfaceContent.Menu.BorderBoxA1', 1.05 * PortraitWidth, 1.05*PortraitHeight);

		C.DrawColor = WhiteColor;

		X = C.ClipY/256-PortraitWidth*PortraitX;
		Y = 0.5*(C.ClipY+PortraitHeight) + 0.06*PortraitHeight;
		C.SetPos( X + 0.5 * (PortraitWidth - XL), Y );

		if ( PortraitPRI != None )
		{
			if ( PortraitPRI.Team != None )
			{
				if ( PortraitPRI.Team.TeamIndex == 0 )
					C.DrawColor = RedColor;
				else
					C.DrawColor = TurqColor;
			}

			C.DrawText(PortraitString,true);

			if ( Level.TimeSeconds - LastPlayerIDTalkingTime < 2.0
				&& PortraitPRI.ActiveChannel != -1
				&& PlayerOwner.VoiceReplicationInfo != None )
			{
				VCR = PlayerOwner.VoiceReplicationInfo.GetChannelAt(PortraitPRI.ActiveChannel);
				if ( VCR != None )
				{
					PortraitString = "(" @ VCR.GetTitle() @ ")";
					C.StrLen( PortraitString, XL, YL );
					if ( PortraitX == 0 )
						C.SetPos( Max(0, X + 0.5 * (PortraitWidth - XL)), Y + YL );
					else C.SetPos( X + 0.5 * (PortraitWidth - XL), Y + YL );
					C.DrawText( PortraitString );
				}
			}
		}
	}

    if( bShowWeaponInfo && (PawnOwner != None) && (PawnOwner.Weapon != None) )
		PawnOwner.Weapon.NewDrawWeaponInfo(C, 0.86 * C.ClipY);

	if ( (PawnOwner != PlayerOwner.Pawn) && (PawnOwner != None)
		&& (PawnOwner.PlayerReplicationInfo != None) )
	{
		// draw viewed player name
	    C.Font = GetMediumFontFor(C);
        C.SetDrawColor(255,255,0,255);

		if(PawnOwner.PlayerReplicationInfo.Team.TeamIndex == 0)
			C.SetDrawColor(255,39,13,255);
		else if(PawnOwner.PlayerReplicationInfo.Team.TeamIndex == 1)
			C.SetDrawColor(0,150,255,255);
		else
			C.SetDrawColor(255,243,0,255);

		C.StrLen(PawnOwner.PlayerReplicationInfo.PlayerName,NameWidth,SmallH);
		NameWidth = FMax(NameWidth, 0.15 * C.ClipX);
		//snarf move "now viewing" down some
		if ( C.ClipX >= 640 )
		{
			C.Font = GetConsoleFont(C);
			C.StrLen("W",XL,SmallH);
			//C.SetPos(79*C.ClipX/80 - NameWidth,C.ClipY * 0.68);
			C.SetPos(79*C.ClipX/80 - NameWidth,C.ClipY * 0.82);
			C.DrawText(NowViewing,false);
		}

        C.Font = GetMediumFontFor(C);
        //C.SetPos(79*C.ClipX/80 - NameWidth,C.ClipY * 0.68 + SmallH);
        C.SetPos(79*C.ClipX/80 - NameWidth,C.ClipY * 0.82 + SmallH);
        C.DrawText(PawnOwner.PlayerReplicationInfo.PlayerName,false);
	}

     DrawCrosshair(C);
}

defaultproperties
{
    RadarVehicleData(0)=(Name="Minotaur",RadarColor=(R=255,G=255,B=255,A=255))
    RadarVehicleData(1)=(Name="Omnitaur",RadarColor=(R=255,G=255,B=255,A=255))
    RadarVehicleData(2)=(Name="Badgertaur",RadarColor=(R=255,G=255,B=255,A=255))
    RadarVehicleData(3)=(Name="ONSHoverTank",RadarColor=(R=128,G=0,B=128,A=255))
    RadarVehicleData(4)=(Name="ONSHoverBike",RadarColor=(R=0,G=128,B=0,A=255))
    RadarVehicleData(5)=(Name="ONSAttackCraft",RadarColor=(R=128,G=128,B=0,A=255))
    RadarVehicleData(6)=(Name="ONSDualAttackCraft",RadarColor=(R=128,G=128,B=0,A=255))
    RadarVehicleData(7)=(Name="ONSPRV",RadarColor=(R=0,G=128,B=128,A=255))
    RadarVehicleData(8)=(Name="ONSRV",RadarColor=(R=0,G=32,B=32,A=255))
    RadarBorderMat=Texture'ONSInterface-TX.MapBorderTEX'

    HUDCenterRadarBG=(WidgetTexture=Texture'WSUTComp.Textures.bigcircle',RenderStyle=STY_Alpha,TextureCoords=(X1=255,Y2=255),TextureScale=0.800000,DrawPivot=DP_MiddleMiddle,PosX=0.500000,PosY=0.500000,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    HUDCurrentMutantColor=(B=128,R=255,A=255)
    HUDAboveMutantColor=(B=255,A=255)
    HUDLevelMutantColor=(B=255,G=255,R=255,A=255)
    HUDBelowMutantColor=(R=255,A=255)
    HUDLevelRampRegion=500.000000
    HUDBigDotSize=0.018750
    HUDSmallDotSize=0.011250
    HUDXCen=0.500000
    HUDXRad=0.150000
    HUDYCen=0.500000
    HUDYRad=0.200000
    HudzaxisTex=Texture'WSUTComp.textures.Hudzaxis'	
}
