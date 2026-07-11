class TeamColorShockBeamEffect extends ShockBeamEffect;

var int TeamNum;
var bool bColorSet, bAlphaSet;
var ShockBeamCoil Coil;
var Material TeamColorMaterial;
var ColorModifier Alpha;
var UTComp_Settings Settings;

replication
{
    unreliable if(Role == ROLE_Authority)
        TeamNum;
}

simulated function bool CanUseColors()
{
  local UTComp_ServerReplicationInfo RepInfo;

    RepInfo = class'UTComp_Util'.static.GetServerReplicationInfo(Level.GetLocalPlayerController());
    if(RepInfo != None)
        return RepInfo.bAllowColorWeapons;

    return false;
}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();

    if(Level.NetMode == NM_DedicatedServer)
        return;

    Settings = BS_xPlayer(Level.GetLocalPlayerController()).Settings;

    if(Settings.bTeamColorShock)
    {
        if(CanUseColors())
        {
            Alpha = ColorModifier(Level.ObjectPool.AllocateObject(class'ColorModifier'));
            Alpha.Material = TeamColorMaterial;
            Alpha.AlphaBlend = true;
            Alpha.RenderTwoSided = true;
            Alpha.Color.A = 255;
            Skins[0] = Alpha;
            bAlphaSet=true;
        }
    }

    SetColors();
}

simulated function Destroyed()
{
	if ( bAlphaSet )
	{
		Level.ObjectPool.FreeObject(Skins[0]);
		Skins[0] = None;
	}

	super.Destroyed();
}


simulated function SetColors()
{
    local Color color;

    if(Level.NetMode != NM_DedicatedServer)
    {
        if(Settings.bTeamColorShock && !bColorSet)
        {
            if(CanUseColors())
            {
                color = class'TeamColorManager'.static.GetColor(TeamNum, Level.GetLocalPlayerController());
                if(TeamNum == 0 || TeamNum == 1)
                {
                    Alpha.Color.R = color.R;
                    Alpha.Color.G = color.G;
                    Alpha.Color.B = color.B;
                    if(Coil != None)
                    {
                        Coil.mColorRange[0]=color;
                        Coil.mColorRange[1]=color;
                    }
                    bColorSet=true;
                }
            }
        }
    }
}

simulated function Tick(float DT)
{
    super.Tick(DT);
    SetColors();
}

simulated function SpawnEffects()
{
    local xWeaponAttachment Attachment;
	
    if (Instigator != None)
    {
        if ( Instigator.IsFirstPerson() )
        {
			if ( (Instigator.Weapon != None) && (Instigator.Weapon.Instigator == Instigator) )
				SetLocation(Instigator.Weapon.GetEffectStart());
			else
				SetLocation(Instigator.Location);
            Spawn(MuzFlashClass,,, Location);
        }
        else
        {
            Attachment = xPawn(Instigator).WeaponAttachment;
            // Prefer the pawn's settled muzzle-tip cache. It's the live muzzle during normal
            // play (updated every frame), but through the ~0.75s a weapon takes to settle after
            // a switch it holds the PREVIOUS weapon's fully-raised muzzle instead of the fresh
            // attachment's low, still-settling tip bone. That low transitional tip is exactly
            // the "first beam of a fire held through a switch" glitch.
            if (UTComp_xPawn(Instigator) != None && UTComp_xPawn(Instigator).bHasMuzzleTip)
                SetLocation(UTComp_xPawn(Instigator).LastMuzzleTip);
            else if (Attachment != None && (Level.TimeSeconds - Attachment.LastRenderTime) < 1)
                SetLocation(Attachment.GetTipLocation());
            // No usable muzzle (no cached tip and attachment not posed): start from the eye.
            // In 3p the settled muzzle sits at ~eye height, so the eye is a good stand-in and
            // avoids the old crude estimate's low/off-center look.
            else
                SetLocation(Instigator.Location + Instigator.EyePosition());
            Spawn(MuzFlash3Class);
        }
    }

    if ( EffectIsRelevant(mSpawnVecA + HitNormal*2,false) && (HitNormal != Vect(0,0,0)) )
		SpawnImpactEffects(Rotator(HitNormal),mSpawnVecA + HitNormal*2);
	
    if ( (!Level.bDropDetail && (Level.DetailMode != DM_Low) && (VSize(Location - mSpawnVecA) > 40) && !Level.GetLocalPlayerController().BeyondViewDistance(Location,0))
		|| ((Instigator != None) && Instigator.IsFirstPerson()) )
    {
	    Coil = Spawn(CoilClass,,, Location, Rotation);
	    if (Coil != None)
        {
		    Coil.mSpawnVecA = mSpawnVecA;
        }
    }
}

defaultproperties
{

    TeamNum=255

    TeamColorMaterial=Texture'ShockBeamTex_white'
    CoilClass=Class'TeamColorShockBeamCoil'

    bAlwaysRelevant=true
}