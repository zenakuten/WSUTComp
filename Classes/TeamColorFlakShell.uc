class TeamColorFlakShell extends FlakShell;

#exec TEXTURE IMPORT NAME=NewFlakSkinWhite FILE=textures\NewFlakSkin_white.dds MIPS=off ALPHA=1 DXT=5
#exec AUDIO IMPORT FILE=Sounds\shredded.wav GROUP=Sounds

var int TeamNum;
var Material TeamColorMaterial;
var ColorModifier Alpha;
var bool bColorSet, bAlphaSet;
var UTComp_Settings Settings;

var vector InitialLocation;
var bool bKilledPlayerInAir;
var bool bEagleEyedPlayer;
var float EagleEyeThreshold;
var float EagleEyeAccuracy;
var int ShreddedThreshold;

var Sound EagleEyeSound;
var Sound ShreddedSound;

replication
{
    unreliable if(Role == Role_Authority)
       TeamNum, InitialLocation;
}

function SetupTeam()
{
    if(Instigator != None && Instigator.Controller != None)
    {
        TeamNum=class'TeamColorManager'.static.GetTeamNum(Instigator.Controller, Level);
    }
}

simulated function bool CanUseColors()
{
   local UTComp_ServerReplicationInfo RepInfo;

    RepInfo = class'UTComp_Util'.static.GetServerReplicationInfo(Level.GetLocalPlayerController());
    if(RepInfo != None)
        return RepInfo.bAllowColorWeapons;

    return false;
}

simulated function PostBeginPlay()
{
    local Rotator R;
	local PlayerController PC;
	
	if ( !PhysicsVolume.bWaterVolume && (Level.NetMode != NM_DedicatedServer))
	{
		PC = Level.GetLocalPlayerController();
		if ( (PC.ViewTarget != None) && VSize(PC.ViewTarget.Location - Location) < 6000 )
			Trail = Spawn(class'FlakShellTrail',self);
		Glow = Spawn(class'FlakGlow', self);
	}

	Super(Projectile).PostBeginPlay();
	Velocity = Vector(Rotation) * Speed;  
	R = Rotation;
	R.Roll = 32768;
	SetRotation(R);
	Velocity.z += TossZ; 
	initialDir = Velocity;

    SetupTeam();

}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();

    if(Level.NetMode == NM_DedicatedServer)
        return;

    Settings = BS_XPlayer(Level.GetLocalPlayerController()).Settings;

    if(Settings.bTeamColorFlak && CanUseColors())
    {
        Alpha = ColorModifier(Level.ObjectPool.AllocateObject(class'ColorModifier'));
        Alpha.Material = TeamColorMaterial;
        Alpha.AlphaBlend = true;
        Alpha.RenderTwoSided = true;
        Alpha.Color.A = 255;
        Skins[0] = Alpha;
        bAlphaSet=true;
    }

    SetupTeam();
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

// get replicated team number from owner projectile and set texture
simulated function SetColors()
{
    local Color color;
    if(Level.NetMode != NM_DedicatedServer)
    {
        if(Settings.bTeamColorFlak && !bColorSet && Alpha != None)
        {
            if(CanUseColors())
            {
                if(TeamNum == 0 || TeamNum == 1)
                {
                    LightBrightness=210;
                    color = class'TeamColorManager'.static.GetColor(TeamNum, Level.GetLocalPlayerController());
                    LightHue = class'TeamColorManager'.static.GetHue(color);

                    Alpha.Color.R = color.R;
                    Alpha.Color.G = color.G;
                    Alpha.Color.B = color.B;
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

simulated function Explode(vector HitLocation, vector HitNormal)
{
	local vector start;
    local rotator rot;
    local int i;
    local FlakChunk NewChunk;

	start = Location + 10 * HitNormal;
	if ( Role == ROLE_Authority )
	{
		HurtRadiusEx(damage, 220, MyDamageType, MomentumTransfer, HitLocation);	
		for (i=0; i<6; i++)
		{
			rot = Rotation;
			rot.yaw += FRand()*32000-16000;
			rot.pitch += FRand()*32000-16000;
			rot.roll += FRand()*32000-16000;
			//NewChunk = Spawn( class 'FlakChunk',, '', Start, rot);
			NewChunk = Spawn( class 'TeamColorFlakChunk',, '', Start, rot);
		}

        if(bKilledPlayerInAir)
        {    
            if(BS_xPlayer(Instigator.Controller) != None)
            {
                BS_xPlayer(Instigator.Controller).ClientReceiveAward(ShreddedSound,0.5, 2.0);
            }
        }
        else if(bEagleEyedPlayer)
        {    
            if(BS_xPlayer(Instigator.Controller) != None)
            {
                BS_xPlayer(Instigator.Controller).ClientReceiveAward(EagleEyeSound,0.5, 2.0);
            }
        }
	}
    Destroy();
}

simulated function HurtRadiusEx( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation )
{
	local actor Victims;
	local float damageScale, dist;
	local vector rocketdir;
    local EPhysics prePhysics;
    local bool bAboveGround;
    local float prevHealth;

	if ( bHurtEntry )
		return;

	bHurtEntry = true;
    prePhysics=PHYS_None;
	foreach VisibleCollidingActors( class 'Actor', Victims, DamageRadius, HitLocation )
	{
		// don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
		if( (Victims != self) && (Hurtwall != Victims) && (Victims.Role == ROLE_Authority) && !Victims.IsA('FluidSurfaceInfo') )
		{
            if(Pawn(Victims) != None)
                prevHealth = Pawn(Victims).Health;

			rocketdir = Victims.Location - HitLocation;
            bAboveGround = Victims.FastTrace(Victims.Location + vect(0,0,-150));
            
			dist = FMax(1,VSize(rocketdir));
			rocketdir = rocketdir/dist;
			damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);
			if ( Instigator == None || Instigator.Controller == None )
				Victims.SetDelayedDamageInstigatorController( InstigatorController );
			if ( Victims == LastTouched )
				LastTouched = None;
            prePhysics = Victims.Physics;
			Victims.TakeDamage
			(
				damageScale * DamageAmount,
				Instigator,
				Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * rocketdir,
				(damageScale * Momentum * rocketdir),
				DamageType
			);
			if (Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
				Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, InstigatorController, DamageType, Momentum, HitLocation);

            // killed player
            if(Pawn(Victims) != None && Pawn(Victims).Health <= 0 && prevHealth > 0 && Victims != Instigator)
            {
                if(prePhysics == PHYS_Falling && bAboveGround || (prevHealth - Pawn(Victims).Health > ShreddedThreshold))
                    bKilledPlayerInAir = true;
                else if(VSize(HitLocation - InitialLocation) > EagleEyeThreshold && VSize(HitLocation - Victims.Location) < EagleEyeAccuracy)
                    bEagleEyedPlayer = true; 
            }
		}
	}
	if ( (LastTouched != None) && (LastTouched != self) && (LastTouched.Role == ROLE_Authority) && !LastTouched.IsA('FluidSurfaceInfo') )
	{
		Victims = LastTouched;
		LastTouched = None;
		rocketdir = Victims.Location - HitLocation;
        bAboveGround = Victims.FastTrace(Victims.Location + vect(0,0,-150));
		dist = FMax(1,VSize(rocketdir));
		rocketdir = rocketdir/dist;
		damageScale = FMax(Victims.CollisionRadius/(Victims.CollisionRadius + Victims.CollisionHeight),1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius));
		if ( Instigator == None || Instigator.Controller == None )
			Victims.SetDelayedDamageInstigatorController(InstigatorController);
        prePhysics = Victims.Physics;
		Victims.TakeDamage
		(
			damageScale * DamageAmount,
			Instigator,
			Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * rocketdir,
			(damageScale * Momentum * rocketdir),
			DamageType
		);
		if (Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
			Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, InstigatorController, DamageType, Momentum, HitLocation);

        // killed player
        if(Pawn(Victims) != None && Pawn(Victims).Health <= 0 && prevHealth > 0 && Victims != Instigator)
        {
            if(prePhysics == PHYS_Falling && bAboveGround || (prevHealth - Pawn(Victims).Health) > ShreddedThreshold )
                bKilledPlayerInAir = true;
            else if(VSize(HitLocation - InitialLocation) > EagleEyeThreshold && VSize(HitLocation - Victims.Location) < EagleEyeAccuracy)
                bEagleEyedPlayer = true; 
        }
	}

	bHurtEntry = false;
}

defaultproperties
{
    TeamNum=255
    bColorSet=false
    TeamColorMaterial=Texture'NewFlakSkinWhite'

    ShreddedSound=Sound'Sounds.Shredded'
    EagleEyeSound=Sound'AnnouncerMale2K4.EagleEye'
    EagleEyeThreshold=5500.0
    EagleEyeAccuracy=30.0
    ShreddedThreshold=85
    bKilledPlayerInAir=false
    bEagleEyedPlayer=false
}