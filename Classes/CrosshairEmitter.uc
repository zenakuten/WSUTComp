//=============================================================================
// CrosshairEmitter - Can be scaled dynamically to keep apparent size constant
// with distance.
// http://come.to/MrEvil
//=============================================================================
// adapted for utcomp - snarf
class CrosshairEmitter extends Emitter;

var float MaxCrosshairDist;
var Weapon LastWeapon;
var PlayerController C;
var Texture CurrentCrosshairTexture, LastCrosshairTexture;
var color CurrentCrosshairColor, LastCrosshairColor;
var float CurrentCrosshairScale;

function PostBeginPlay()
{
	Super.PostBeginPlay();
	C = Level.GetLocalPlayerController();
	if(C == None)
	{
		Destroy();
		return;
	}
}

//Use the normal, ever-decreasing-circles crosshair.
function SetNormalCrosshair()
{
	Emitters[0].UseSizeScale = true;
	Emitters[0].FadeIn = true;

	CurrentCrosshairColor = C.myhud.CrossHairColor;
	CurrentCrosshairScale = 1.0;

	CurrentCrosshairTexture = Texture'Crosshairs.HUD.Crosshair_Circle1';
}

//Use standard crosshair settings.
function SetStandardCrosshair()
{
	Emitters[0].UseSizeScale = false;
	Emitters[0].FadeIn = false;

	CurrentCrosshairColor = C.myhud.CrossHairColor;
	CurrentCrosshairScale = C.myhud.CrosshairScale;

    if(C.Pawn != None && C.Pawn.Weapon != None)
        CurrentCrosshairTexture = C.Pawn.Weapon.CustomCrosshairTexture;
}

//Use per-weapon custom crosshairs
function SetCustomCrosshair()
{
	local int CurrentCrosshair;

	Emitters[0].UseSizeScale = false;
	Emitters[0].FadeIn = false;

	if(C.Pawn.Weapon == LastWeapon)
		return;

	LastWeapon = C.Pawn.Weapon;

	CurrentCrosshair =  C.Pawn.Weapon.CustomCrosshair;
	CurrentCrosshairColor = C.Pawn.Weapon.CustomCrosshairColor;
	CurrentCrosshairScale = C.Pawn.Weapon.CustomCrosshairScale;

	if(C.Pawn != None && C.Pawn.Weapon != None && C.Pawn.Weapon.CustomCrosshairTextureName != "")
	{
		if(C.Pawn.Weapon.CustomCrosshairTexture == None)
		{
			C.Pawn.Weapon.CustomCrosshairTexture = Texture(DynamicLoadObject(C.Pawn.Weapon.CustomCrosshairTextureName,class'Texture'));

			if(C.Pawn.Weapon.CustomCrosshairTexture == None)
				C.Pawn.Weapon.CustomCrosshairTextureName = "";
		}

		CurrentCrosshairTexture = C.Pawn.Weapon.CustomCrosshairTexture;
	}
	else
		SetStandardCrosshair();
}

function SetCrosshairStyle()
{
	if(C == None)
	{
		Destroy();
		return;
	}

	if(C.myhud == None)
		return;

	//Decide which style of crosshair to use.
    if(HudBase(C.myhud).bUseCustomWeaponCrosshairs && C.Pawn != None && C.Pawn.Weapon != None)
        SetCustomCrosshair();
    else
        SetStandardCrosshair();

	if(CurrentCrosshairTexture != LastCrosshairTexture)
	{
		Emitters[0].Texture = CurrentCrosshairTexture;

		LastCrosshairTexture = CurrentCrosshairTexture;
	}

	if(CurrentCrosshairColor != LastCrosshairColor)
	{
		Emitters[0].ColorMultiplierRange.X.Max = CurrentCrosshairColor.R / 255.0;
		Emitters[0].ColorMultiplierRange.X.Min = Emitters[0].ColorMultiplierRange.X.Max;
		Emitters[0].ColorMultiplierRange.Y.Max = CurrentCrosshairColor.G / 255.0;
		Emitters[0].ColorMultiplierRange.Y.Min = Emitters[0].ColorMultiplierRange.Y.Max;
		Emitters[0].ColorMultiplierRange.Z.Max = CurrentCrosshairColor.B / 255.0;
		Emitters[0].ColorMultiplierRange.Z.Min = Emitters[0].ColorMultiplierRange.Z.Max;

		LastCrosshairColor = CurrentCrosshairColor;
	}
}

//Increase scale at long range, to prevent getting too small.
function DistanceScale(float Distance)
{
	local float ScaleFactor;
	local int i;

	if(Emitters[0].Particles.length > 0)
	{
		ScaleFactor = Distance / FMin(Distance, MaxCrosshairDist);
		ScaleFactor *= 0.5;
		ScaleFactor += 0.5;
		ScaleFactor *= CurrentCrosshairScale;

		for(i = 0; i < Emitters[0].Particles.length; i++)
			Emitters[0].Particles[i].StartSize = vect(30, 30, 30) * ScaleFactor;
	}

	Emitters[0].StartSizeRange.X.Min = 30 * ScaleFactor;
	Emitters[0].StartSizeRange.X.Max = Emitters[0].StartSizeRange.X.Min;
}

defaultproperties
{
     MaxCrosshairDist=2048.000000
     Begin Object Class=SpriteEmitter Name=SpriteEmitter0
         FadeIn=True
         DisableFogging=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         ColorMultiplierRange=(Y=(Min=0.000000,Max=0.000000),Z=(Min=0.000000,Max=0.000000))
         FadeInEndTime=2.000000
         CoordinateSystem=PTCS_Relative
         MaxParticles=3
         SizeScale(0)=(RelativeSize=1.000000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=0.100000)
         StartSizeRange=(X=(Min=30.000000,Max=30.000000))
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'Crosshairs.HUD.Crosshair_Circle2'
         LifetimeRange=(Min=8.000000,Max=8.000000)
         WarmupTicksPerSecond=1.000000
         RelativeWarmupTime=1.000000
     End Object
     Emitters(0)=SpriteEmitter'SpriteEmitter0'

     bHidden=True
     bNoDelete=False
}
