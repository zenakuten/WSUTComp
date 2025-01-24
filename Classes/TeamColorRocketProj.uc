class TeamColorRocketProj extends RocketProj;

#exec AUDIO IMPORT FILE=Sounds\AirRocket.wav GROUP=Sounds
#exec AUDIO IMPORT FILE=Sounds\torpedo.wav GROUP=Sounds

var int TeamNum;
var bool bColorSet;
var Sound AirRocketSound;
var Sound TorpedoSound;
var Emitter RocketTrail;
var vector InitialLocation;

var bool bKilledPlayerInAir;
var bool bTorpedoedPlayer;
var float torpedoThreshold;
var float torpedoAccuracy;

replication
{
    reliable if( bNetInitial && (Role==ROLE_Authority))
       InitialLocation;

    unreliable if(Role == Role_Authority)
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

function SetupTeam()
{
    if(Instigator != None && Instigator.Controller != None)
    {
        TeamNum=class'TeamColorManager'.static.GetTeamNum(Instigator.Controller, Level);
    }
}

simulated function SetupColor()
{
    local Color c;
    local UTComp_Settings Settings;
    if(!bColorSet && Level.NetMode != NM_DedicatedServer)
    {
        Settings = BS_xPlayer(Level.GetLocalPlayerController()).Settings;
        if(Settings.bTeamColorRockets && CanUseColors())
        {
            if(TeamNum == 0 || TeamNum == 1)
            {
                c = class'TeamColorManager'.static.GetColor(TeamNum, Level.GetLocalPlayerController());
                LightHue=class'TeamColorManager'.static.GetHue(c);
                bColorSet=true;
            }
        }
    }
    //other stuff is done by corona and trails
}

//override PostBeginPlay so we can spawn team color effects
simulated function PostBeginPlay()
{
	if ( Level.NetMode != NM_DedicatedServer)
	{
		SmokeTrail = Spawn(class'RocketTrailSmoke',self);
		Corona = Spawn(class'TeamColorRocketCorona',self);
		RocketTrail = Spawn(class'TeamColorRocketTrail',self);
        if(RocketTrail != None)
            RocketTrail.SetBase(self);
	}

	Dir = vector(Rotation);
	Velocity = speed * Dir;
	if (PhysicsVolume.bWaterVolume)
	{
		bHitWater = True;
		Velocity=0.6*Velocity;
	}

    InitialLocation = Location;

    SetupTeam();

	Super(Projectile).PostBeginPlay();
}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();

    if(Level.NetMode == NM_DedicatedServer)
        return;

    SetupTeam();
}

simulated function Destroyed()
{
    if(RocketTrail != None)
        RocketTrail.Destroy();

    super.Destroyed();
}

simulated function Tick(float DT)
{
    super.Tick(DT);
    SetupColor();
}

// copy from projectile -> hurt radius, return true if anybody killed
simulated function HurtRadiusEx( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation )
{
	local actor Victims;
	local float damageScale, dist;
	local vector rocketdir;
    local EPhysics prePhysics;
    local bool bAboveGround;

	if ( bHurtEntry )
		return;

	bHurtEntry = true;
    prePhysics=PHYS_None;
	foreach VisibleCollidingActors( class 'Actor', Victims, DamageRadius, HitLocation )
	{
		// don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
		if( (Victims != self) && (Hurtwall != Victims) && (Victims.Role == ROLE_Authority) && !Victims.IsA('FluidSurfaceInfo') )
		{
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
            if(Pawn(Victims) != None && Pawn(Victims).Health <= 0)
            {
                if(prePhysics == PHYS_Falling && bAboveGround && Victims != Instigator)
                    bKilledPlayerInAir = true;
                else if(VSize(Location - InitialLocation) > torpedoThreshold && VSize(Location - Victims.Location) < torpedoAccuracy)
                    bTorpedoedPlayer = true; 
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
        if(Pawn(Victims) != None && Pawn(Victims).Health <= 0)
        {
            if(prePhysics == PHYS_Falling && bAboveGround && Victims != Instigator)
                bKilledPlayerInAir = true;
            else if(FlockIndex == 0 && VSize(Location - InitialLocation) > torpedoThreshold && VSize(Location - Victims.Location) < torpedoAccuracy)
                bTorpedoedPlayer = true; 
        }
	}

	bHurtEntry = false;
}

function BlowUp(vector HitLocation)
{
	HurtRadiusEx(Damage, DamageRadius, MyDamageType, MomentumTransfer, HitLocation );
	MakeNoise(1.0);

    if(bKilledPlayerInAir)
    {    
        if(BS_xPlayer(Instigator.Controller) != None)
        {
            BS_xPlayer(Instigator.Controller).ClientReceiveAward(AirRocketSound,0.5, 2.0);
        }
    }
    else if(bTorpedoedPlayer)
    {    
        if(BS_xPlayer(Instigator.Controller) != None)
        {
            BS_xPlayer(Instigator.Controller).ClientReceiveAward(TorpedoSound,0.5, 2.0);
        }
    }
}

defaultproperties
{
    TeamNum=255
    AirRocketSound=Sound'Sounds.AirRocket'
    TorpedoSound=Sound'Sounds.Torpedo'
    torpedoThreshold=1200.0
    torpedoAccuracy=30.0
    bKilledPlayerInAir=false
    bTorpedoedPlayer=false
}