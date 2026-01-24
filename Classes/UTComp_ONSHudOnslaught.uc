

class UTComp_ONSHudOnslaught extends ONSHudOnslaught config (WSUTComp);

var UTComp_HUDSettings HUDSettings;

var UTComp_ONSPlayerReplicationInfo OPPRI;

var color TempColour;

struct NodeData
{
	var ONSPowerCore CurNode;
	var bool bDontShowNode;
};

var array<NodeData> NodeDataList;

var float RadarWidth, CenterRadarPosX, CenterRadarPosY;

var float LastCoreCheck;
var float LastVInfoUpdate;

#include Classes\Include\_HudCommon.h.uci
#include Classes\Include\_HudCommon.uci

#include Classes\Include\_Internal\DrawAdrenaline.uci
#include Classes\Include\_Internal\DrawChargeBar.uci
#include Classes\Include\_Internal\DrawCrosshair.uci
#include Classes\Include\Team\_Internal\DrawHudPassA.uci
#include Classes\Include\_Internal\DrawTimer.uci
#include Classes\Include\_Internal\DrawUDamage.uci
#include Classes\Include\_Internal\DrawVehicleChargeBar.uci
#include Classes\Include\_Internal\DrawWeaponBar.uci
#include Classes\Include\Team\Onslaught\_Internal\ShowTeamScorePassA.uci
#include Classes\Include\Team\_Internal\ShowVersusIcon.uci
#include Classes\Include\_DrawDamageIndicators.uci

#include Classes\Include\_HudCommon.p.uci

simulated event PostBeginPlay() {
    Super.PostBeginPlay();

    foreach AllObjects(class'UTComp_HUDSettings', HUDSettings)
        break;
    if (HUDSettings == none)
        Warn(self@"HUDSettings object not found!");

    SaveConfig();
}

simulated function UpdatePrecacheMaterials()
{
	local int i;

    for (i=0; i<HUDSettings.UTCompCrosshairs.Length && HUDSettings.bEnableUTCompCrosshairs; i++ )
		Level.AddPrecacheMaterial(HUDSettings.UTCompCrosshairs[i].CrossTex);

    super.UpdatePrecacheMaterials();
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
    DrawSpriteTileWidget (C, CHTexture);
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

	DrawSpriteTileWidget( C, TimerBackground);
	DrawSpriteTileWidget( C, TimerBackgroundDisc);
	DrawSpriteTileWidget( C, TimerIcon);

	TimerMinutes.OffsetX = default.TimerMinutes.OffsetX - 80;
	TimerSeconds.OffsetX = default.TimerSeconds.OffsetX - 80;
	TimerDigitSpacer[0].OffsetX = Default.TimerDigitSpacer[0].OffsetX;
	TimerDigitSpacer[1].OffsetX = Default.TimerDigitSpacer[1].OffsetX;

	if( Seconds > 3600 )
    {
        Hours = Seconds / 3600;
        Seconds -= Hours * 3600;

		DrawNumericTileWidget( C, TimerHours, DigitsBig);
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
		DrawSpriteTileWidget( C, TimerDigitSpacer[0]);
	}
	DrawSpriteTileWidget( C, TimerDigitSpacer[1]);

	Minutes = Seconds / 60;
    Seconds -= Minutes * 60;

    TimerMinutes.Value = Min(Minutes, 60);
	TimerSeconds.Value = Min(Seconds, 60);

	DrawNumericTileWidget( C, TimerMinutes, DigitsBig);
	DrawNumericTileWidget( C, TimerSeconds, DigitsBig);
}

// Not the in play map, this is when the player has the menu open
simulated function DrawRadarMapVehicles(Canvas C, float CenterPosX, float CenterPosY, float RadarWidth, bool bShowDisabledNodes)
{
	local float PawnIconSize, PlayerIconSize, CoreIconSize, MapScale, OldHudScale;
	local vector HUDLocation;
	local int i;
	local plane SavedModulation;
    local bool bShouldDrawVehicles;
    local float U, V;
    
    OldHudScale=HudScale;

    if (PlayerOwner.Level.TimeSeconds - LastVInfoUpdate > 3.0)
	{
		LastVInfoUpdate = PlayerOwner.Level.TimeSeconds;

        BS_xPlayer(PlayerOwner).GetVInfoUpdate();
	}

	SavedModulation = C.ColorModulate;

    C.ColorModulate.X = 1;
	C.ColorModulate.Y = 1;
	C.ColorModulate.Z = 1;
	C.ColorModulate.W = 1;

	// Make sure that the canvas style is alpha
	C.Style = ERenderStyle.STY_Alpha;

	if (PawnOwner != None)
	{
		MapCenter.X = 0.0;
		MapCenter.Y = 0.0;
	}
	else
	{
		MapCenter = vect(0,0,0);
	}

	CoreIconSize = IconScale * 16 * C.ClipX * HUDScale/1600;
	PawnIconSize = CoreIconSize * 0.5;
	PlayerIconSize = CoreIconSize * 1.5;
    MapScale = RadarWidth / RadarRange;
    // big hack, need to figure out which map we are drawing, the big one in menu or the little one on hud
    // alternative is to override like 3 other classes and replace them 
    bShouldDrawVehicles=C.ClipX / CenterPosX >= 1.5;
    OPPRI = UTComp_ONSPlayerReplicationInfo(Level.GetLocalPlayerController().PlayerReplicationInfo);
    if(OPPRI != none && bShouldDrawVehicles)
    {
        HudScale=1.0;
        for (i=0; i<OPPRI.ClientVSpawnList.Length; i++)
        {
            if (OPPRI.ClientVSpawnList[i].CurFactoryTeam == PlayerOwner.GetTeamNum() && OPPRI.ClientVSpawnList[i].bSpawned)
            {
                HUDLocation = OPPRI.ClientVSpawnList[i].Factory.Location - MapCenter;

                //draw larger black icon for outline
                C.SetPos(CenterPosX + (HUDLocation.X * MapScale) - (PlayerIconSize * 0.35) + 1.0, CenterPosY + (HUDLocation.Y * MapScale) - (PlayerIconSize * 0.35) + 1.0);
                C.DrawColor.R = 0;
                C.DrawColor.G = 0;
                C.DrawColor.B = 0;
                C.DrawColor.A = 255;
                C.DrawTile(Material'NewHUDIcons', PlayerIconSize * 0.35, PlayerIconSize * 0.35, U, V, 32, 32);

                //draw colored icon
                C.SetPos(CenterPosX + (HUDLocation.X * MapScale) - (PlayerIconSize * 0.25), CenterPosY + (HUDLocation.Y * MapScale) - (PlayerIconSize * 0.25));
                SetRadarVehicleData(OPPRI.ClientVSpawnList[i].VehicleClass, C.DrawColor);
                C.DrawColor.A = 255;
                C.DrawTile(Material'NewHUDIcons', PlayerIconSize * 0.25, PlayerIconSize * 0.25, U, V, 32, 32);
            }
        }    
        HudScale=OldHudScale;
    }

    C.ColorModulate = SavedModulation;
}

simulated function UTComp_DrawRadarMap(Canvas C, float CenterPosX, float CenterPosY, float RadarWidth, bool bShowDisabledNodes, bool bIsTab)
{
	local float PawnIconSize, PlayerIconSize, CoreIconSize, MapScale, MapRadarWidth;
	local vector HUDLocation;
	local FinalBlend PlayerIcon;
	local Actor A;
	local ONSPowerCore CurCore;
	local int i;
	local plane SavedModulation;

	SavedModulation = C.ColorModulate;

	C.ColorModulate.X = 1;
	C.ColorModulate.Y = 1;
	C.ColorModulate.Z = 1;
	C.ColorModulate.W = 1;

	// Make sure that the canvas style is alpha
	C.Style = ERenderStyle.STY_Alpha;

	MapRadarWidth = RadarWidth;
    if (PawnOwner != None)
    {
//    	MapCenter.X = FClamp(PawnOwner.Location.X, -RadarMaxRange + RadarRange, RadarMaxRange - RadarRange);
//    	MapCenter.Y = FClamp(PawnOwner.Location.Y, -RadarMaxRange + RadarRange, RadarMaxRange - RadarRange);
        MapCenter.X = 0.0;
        MapCenter.Y = 0.0;
    }
    else
        MapCenter = vect(0,0,0);

	HUDLocation.X = RadarWidth;
	HUDLocation.Y = RadarRange;
	HUDLocation.Z = RadarTrans;

	DrawMapImage( C, Level.RadarMapImage, CenterPosX, CenterPosY, MapCenter.X, MapCenter.Y, HUDLocation );

	if (Node == None)
		return;

	CurCore = Node;
	do
	{
		if ( CurCore.HasHealthBar() )
			DrawHealthBar(C, CurCore, CurCore.Health, CurCore.DamageCapacity, HealthBarPosition);

		CurCore = CurCore.NextCore;
	} until ( CurCore == None || CurCore == Node );

	CoreIconSize = IconScale * 16 * C.ClipX * HUDScale/1600;
	PawnIconSize = CoreIconSize * 0.5;
	PlayerIconSize = CoreIconSize * 1.5;
    MapScale = MapRadarWidth/RadarRange;
    C.Font = GetConsoleFont(C);

	Node.UpdateHUDLocation( CenterPosX, CenterPosY, RadarWidth, RadarRange, MapCenter );
	for ( i = 0; i < PowerLinks.Length; i++ )
		PowerLinks[i].Render(C, ColorPercent, bShowDisabledNodes);

	CurCore = Node;
	do
	{
		if (!bShowDisabledNodes && (CurCore.CoreStage == 255 || CurCore.PowerLinks.Length == 0))	//hide unused powernodes
		{
			if (PlayerOwner==none || !PlayerOwner.bDemoOwner)
			{
				CurCore = CurCore.NextCore;
				continue;
			}
		}

		C.DrawColor = LinkColor[CurCore.DefenderTeamIndex];

		// Draw appropriate icon to represent the current state of this node
	    if (CurCore.bUnderAttack || (CurCore.CoreStage == 0 && CurCore.bSevered))
	    	DrawAttackIcon( C, CurCore, CurCore.HUDLocation, IconScale, HUDScale, ColorPercent );

		if (CurCore.bFinalCore)
			DrawCoreIcon( C, CurCore.HUDLocation, PowerCoreAttackable(CurCore), IconScale, HUDScale, ColorPercent );
		else
		{
			DrawNodeIcon( C, CurCore.HUDLocation, PowerCoreAttackable(CurCore), CurCore.CoreStage, IconScale, HUDScale, ColorPercent );
			DrawNodeLabel(C, CurCore.HUDLocation, IconScale, HUDScale, C.DrawColor, CurCore.NodeNum);
		}

		CurCore = CurCore.NextCore;

	} until ( CurCore == None || CurCore == Node );

    // Draw PlayerIcon
    if (PawnOwner != None)
    	A = PawnOwner;
    else if (PlayerOwner.IsInState('Spectating'))
        A = PlayerOwner;
    else if (PlayerOwner.Pawn != None)
    	A = PlayerOwner.Pawn;

    if (A != None)
    {
    	PlayerIcon = FinalBlend'CurrentPlayerIconFinal';
    	TexRotator(PlayerIcon.Material).Rotation.Yaw = -A.Rotation.Yaw - 16384;
        HUDLocation = A.Location - MapCenter;
        HUDLocation.Z = 0;
    	if (HUDLocation.X < (RadarRange * 0.95) && HUDLocation.Y < (RadarRange * 0.95))
    	{
        	C.SetPos( CenterPosX + HUDLocation.X * MapScale - PlayerIconSize * 0.5,
                          CenterPosY + HUDLocation.Y * MapScale - PlayerIconSize * 0.5 );

            C.DrawColor = C.MakeColor(40,255,40);
            C.DrawTile(PlayerIcon, PlayerIconSize, PlayerIconSize, 0, 0, 64, 64);
        }
    }


    if(!bIsTab)
    {
        UTComp_DrawRadarMapPawns(C, CenterPosX, CenterPosY, RadarWidth, RadarRange, RadarTrans, HUDScale, IconScale);
    }


//    // VERY SLOW DEBUGGING CODE for showing all the dynamic actors that exist in the level in real-time
//    ForEach DynamicActors(class'Actor', A)
//    {
//        if (A.IsA('Projectile')) //(A.IsA('Projector') || A.IsA('Emitter') || A.IsA('xEmitter'))
//        {
//            HUDLocation = A.Location - MapCenter;
//            HUDLocation.Z = 0;
//        	C.SetPos(CenterPosX + HUDLocation.X * MapScale - PlayerIconSize * 0.5 * 0.25, CenterPosY + HUDLocation.Y * MapScale - PlayerIconSize * 0.5 * 0.25);
//            C.DrawColor = C.MakeColor(255,255,0);
//            C.DrawTile(Material'NewHUDIcons', PlayerIconSize * 0.25, PlayerIconSize * 0.25, 0, 0, 32, 32);
//        }
//        if (A.IsA('Pawn'))
//        {
//            if (Pawn(A).PlayerReplicationInfo != None && Pawn(A).PlayerReplicationInfo.Team != None)
//            {
//                if (Pawn(A).PlayerReplicationInfo.Team.TeamIndex == 0)
//                    C.DrawColor = C.MakeColor(255,0,0);
//                else if (Pawn(A).PlayerReplicationInfo.Team.TeamIndex == 1)
//                    C.DrawColor = C.MakeColor(0,0,255);
//                else
//                    C.DrawColor = C.MakeColor(255,0,255);
//            }
//            else
//                C.DrawColor = C.MakeColor(255,255,255);
//
//            HUDLocation = A.Location - MapCenter;
//            HUDLocation.Z = 0;
//
//            if (A.IsA('Vehicle'))
//            {
//            	C.SetPos(CenterPosX + HUDLocation.X * MapScale - PlayerIconSize * 0.5 * 0.5, CenterPosY + HUDLocation.Y * MapScale - PlayerIconSize * 0.5 * 0.5);
//                C.DrawTile(Material'NewHUDIcons', PlayerIconSize * 0.5, PlayerIconSize * 0.5, 0, 0, 32, 32);
//            }
//            else
//            {
//            	C.SetPos(CenterPosX + HUDLocation.X * MapScale - PlayerIconSize * 0.5 * 0.25, CenterPosY + HUDLocation.Y * MapScale - PlayerIconSize * 0.5 * 0.25);
//                C.DrawTile(Material'NewHUDIcons', PlayerIconSize * 0.25, PlayerIconSize * 0.25, 0, 0, 32, 32);
//            }
//        }
//    }

    // Draw Border
    C.DrawColor = C.MakeColor(200,200,200);
	C.SetPos(CenterPosX - RadarWidth, CenterPosY - RadarWidth);
	C.DrawTile(BorderMat,
               RadarWidth * 2.0,
               RadarWidth * 2.0,
               0,
               0,
               256,
               256);

    if(bIsTab)
        DrawRadarMapVehicles(C, CenterPosX, CenterPosY, RadarWidth, bShowDisabledNodes);

    C.ColorModulate = SavedModulation;
}


simulated function Actor LocateSpawnArea(float PosX, float PosY, float RadarWidth)
{
	local float WorldToMapScaleFactor, Distance, LowestDistance;
	local vector WorldLocation, DistanceVector;
	local ONSPowerCore Core;
	local int i;
	local actor BestSpawnArea;

	if (Node == none)
		return None;

	WorldToMapScaleFactor = RadarRange / RadarWidth;

	WorldLocation.X = PosX * WorldToMapScaleFactor;
	WorldLocation.Y = PosY * WorldToMapScaleFactor;

	LowestDistance = 2500.0;


	// Search for nearest powercore
	Core = Node;

	do
	{
		DistanceVector = Core.Location - WorldLocation;
		DistanceVector.Z = 0;
		Distance = VSize(DistanceVector);

		if (Distance < LowestDistance)
		{
			BestSpawnArea = Core;
			LowestDistance = Distance;
		}

		Core = Core.NextCore;
	} until (Core == None || Core == Node);


	// If the lowest distance hasn't changed then set it to a half of the original size so that vehicle factory selection area is smaller
	LowestDistance = 1250;

	if (OPPRI == none && PlayerOwner != none && PlayerOwner.PlayerReplicationInfo != none && UTComp_ONSPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo) != none)
		OPPRI = UTComp_ONSPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo);

    if(OPPRI != None)
    {
        // See if there is a vehiclespawn even closer-by (note: this will also account for team-based selections)
        for (i=0; i<OPPRI.ClientVSpawnList.Length; i++)
        {
            if (OPPRI.ClientVSpawnList[i].CurFactoryTeam == PlayerOwner.GetTeamNum() && OPPRI.ClientVSpawnList[i].bSpawned)
            {
                DistanceVector = OPPRI.ClientVSpawnList[i].Factory.Location - WorldLocation;
                DistanceVector.Z = 0;
                Distance = VSize(DistanceVector);

                if (Distance < LowestDistance)
                {
                    BestSpawnArea = OPPRI.ClientVSpawnList[i].Factory;
                    LowestDistance = Distance;
                }
            }
        }
    }

	return BestSpawnArea;
}

simulated function DrawAdrenaline(Canvas C)
{
    if (HUDSettings.bEnableWidescreenFix)
        WideDrawAdrenaline(C);
    else
        Super.DrawAdrenaline(C);
}

simulated function DrawChargeBar(Canvas C)
{
    if (HUDSettings.bEnableWidescreenFix)
        WideDrawChargeBar(C);
    else
        Super.DrawChargeBar(C);
}

simulated function DrawHudPassA(Canvas C)
{
    if (HUDSettings.bEnableWidescreenFix)
        TeamWideDrawHudPassA(C);
    else
        Super.DrawHudPassA(C);
}

simulated function DrawHudPassC(Canvas C)
{
  Super.DrawHudPassC(C);
  DrawTeamRadar(C);
}

simulated function DrawUDamage(Canvas C)
{
    if (HUDSettings.bEnableWidescreenFix)
        WideDrawUDamage(C);
    else
        Super.DrawUDamage(C);
}

simulated function DrawVehicleChargeBar(Canvas C)
{
    if (HUDSettings.bEnableWidescreenFix)
        WideDrawVehicleChargeBar(C);
    else
        Super.DrawVehicleChargeBar(C);
}

simulated function DrawWeaponBar(Canvas C)
{
	if (HUDSettings.bEnableWidescreenFix)
		WideDrawWeaponBar(C);
	else
		Super.DrawWeaponBar(C);
}

simulated function ShowTeamScorePassA(Canvas C)
{
	if (HUDSettings.bEnableWidescreenFix)
		TeamOnslaughtWideShowTeamScorePassA(C);
	else
		Super.ShowTeamScorePassA(C);
}

simulated function ShowTeamScorePassC(Canvas C)
{
    local float RWidth, CRadarPosX, CRadarPosY;

    if (Level.bShowRadarMap && !bMapDisabled)
    {
        RWidth = 0.5 * RadarScale * HUDScale * C.ClipX;
        CRadarPosX = (RadarPosX * C.ClipX) - RWidth;
        CRadarPosY = (RadarPosY * C.ClipY) + RWidth;
        UTComp_DrawRadarMap(C, CRadarPosX, CRadarPosY, RWidth, false, false);
    }
}

simulated function ShowVersusIcon(Canvas C)
{
	if (HUDSettings.bEnableWidescreenFix)
		TeamWideShowVersusIcon(C);
	else
		Super.ShowVersusIcon(C);
}

simulated function DrawSpectatingHud (Canvas C)
{
	Super.DrawSpectatingHud(C);
    DrawDamageIndicators(C);
}

defaultproperties
{
}
