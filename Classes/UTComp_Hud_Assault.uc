

class UTComp_Hud_Assault extends HUD_Assault;

var UTComp_HUDSettings HUDSettings;

#include Classes\Include\_HudCommon.h.uci
#include Classes\Include\_HudCommon.uci

#include Classes\Include\_Internal\DrawChargeBar.uci
#include Classes\Include\_Internal\DrawCrosshair.uci
#include Classes\Include\Team\Assault\_Internal\DrawHudPassA.uci
#include Classes\Include\Team\Assault\_Internal\DrawTeamVS.uci
#include Classes\Include\_Internal\DrawUDamage.uci
#include Classes\Include\_Internal\DrawVehicleChargeBar.uci
#include Classes\Include\_Internal\DrawWeaponBar.uci
#include Classes\Include\Team\Assault\_Internal\ShowTeamScorePassA.uci
#include Classes\Include\Team\_Internal\ShowVersusIcon.uci
#include Classes\Include\_DrawDamageIndicators.uci

#include Classes\Include\_HudCommon.p.uci

simulated event PostBeginPlay() {
    Super.PostBeginPlay();

    foreach AllObjects(class'UTComp_HUDSettings', HUDSettings)
        break;
    if (HUDSettings == none)
        Warn(self@"HUDSettings object not found!");
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
        DrawSpriteTileWidget (C, CHTexture[i]);
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

simulated function DrawChargeBar(Canvas C)
{
    if(HUDSettings.bEnableWidescreenFix)
        WideDrawChargeBar(C);
    else
        Super.DrawChargeBar(C);
}


simulated function DrawHudPassA(Canvas C)
{
	if (HUDSettings.bEnableWidescreenFix)
		TeamAssaultWideDrawHudPassA(C);
	else
		Super.DrawHudPassA(C);
}

simulated function DrawHudPassC(Canvas C)
{
  Super.DrawHudPassC(C);
  DrawTeamRadar(C);
}

simulated function DrawTeamVS(Canvas C)
{
	if (HUDSettings.bEnableWidescreenFix)
		TeamAssaultWideDrawTeamVS(C);
	else
		Super.DrawTeamVS(C);
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
		TeamAssaultWideShowTeamScorePassA(C);
	else
		Super.ShowTeamScorePassA(C);
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

DefaultProperties
{

}
