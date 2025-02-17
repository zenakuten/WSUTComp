class TeamColorBioGlob extends BioGlob;

#exec AUDIO IMPORT FILE=Sounds\AirSnot.wav GROUP=Sounds
#exec AUDIO IMPORT FILE=Sounds\FromDowntown.wav GROUP=Sounds


var int TeamNum;
var Material TeamColorMaterial;
var ColorModifier Alpha;
var bool bColorSet, bAlphaSet;
var UTComp_Settings Settings;

var vector InitialLocation;
var bool bKilledPlayerInAir;
var bool bDowntownedPlayer;
var float FromDowntownThreshold;

var Sound FromDowntownSound;
var Sound AirSnotSound;

replication
{
    unreliable if(Role == Role_Authority)
       TeamNum;
    
    reliable if(Role == ROLE_Authority)
       InitialLocation;       
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

simulated function PostBeginPlay()
{
    SetupTeam();
    InitialLocation=Location;    
    super.PostBeginPlay();

}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();

    if(Level.NetMode == NM_DedicatedServer)
        return;

    Settings = BS_xPlayer(Level.GetLocalPlayerController()).Settings;

    if(Settings.bTeamColorBio && CanUseColors())
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
    local xEmitter emitter;
	if ( bAlphaSet )
	{
		Level.ObjectPool.FreeObject(Skins[0]);
		Skins[0] = None;
	}

    if ( !bNoFX && EffectIsRelevant(Location,false) )
    {
        emitter = Spawn(class'TeamColorGoopSmoke');
        if(emitter != None)
            TeamColorGoopSmoke(emitter).TeamNum=TeamNum;
        emitter = Spawn(class'TeamColorGoopSparks');
        if(emitter != None)
            TeamColorGoopSparks(emitter).TeamNum=TeamNum;
    }
	if ( Fear != None )
		Fear.Destroy();
    if (Trail != None)
        Trail.Destroy();

	super(Projectile).Destroyed();
}

// get replicated team number from owner projectile and set texture
simulated function SetColors()
{
    local Color color;
    if(Level.NetMode != NM_DedicatedServer)
    {
        if(Settings.bTeamColorBio && !bColorSet)
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

function BlowUp(Vector HitLocation)
{
    if (Role == ROLE_Authority)
    {
        Damage = BaseDamage + Damage * GoopLevel;
        DamageRadius = DamageRadius * GoopVolume;
        MomentumTransfer = MomentumTransfer * GoopVolume;
        if (Physics == PHYS_Flying)
            MomentumTransfer *= 0.5;

        DelayedHurtRadiusEx(Damage, DamageRadius, MyDamageType, MomentumTransfer, HitLocation);

        if(bKilledPlayerInAir)
        {    
            if(BS_xPlayer(Instigator.Controller) != None)
            {
                BS_xPlayer(Instigator.Controller).ClientReceiveAward(AirSnotSound,0.5, 2.0);
            }
        }
        else if(bDowntownedPlayer)
        {    
            if(BS_xPlayer(Instigator.Controller) != None)
            {
                BS_xPlayer(Instigator.Controller).ClientReceiveAward(FromDowntownSound,0.5, 2.0);
            }
        }

    }

    PlaySound(ExplodeSound, SLOT_Misc);

    Destroy();
    //GotoState('shriveling');
}

simulated function DelayedHurtRadiusEx( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation )
{
	HurtRadiusEx(DamageAmount, DamageRadius, DamageType, Momentum, HitLocation);
}

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
            if(Pawn(Victims) != None && Pawn(Victims).Health <= 0 && IsInState('Flying') && GoopLevel == MaxGoopLevel)
            {
                if(prePhysics == PHYS_Falling && bAboveGround && Victims != Instigator)
                    bKilledPlayerInAir = true;
                else if(VSize(Location - InitialLocation) > FromDowntownThreshold)
                    bDowntownedPlayer = true; 
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
        if(Pawn(Victims) != None && Pawn(Victims).Health <= 0 && IsInState('Flying') && GoopLevel == MaxGoopLevel)
        {

            if(prePhysics == PHYS_Falling && bAboveGround && Victims != Instigator)
                bKilledPlayerInAir = true;
            else if(VSize(Location - InitialLocation) > FromDowntownThreshold)
                bDowntownedPlayer = true; 
        }
	}

	bHurtEntry = false;
}

defaultproperties
{
    TeamNum=255
    bColorSet=false
    TeamColorMaterial=FinalBlend'GoopFB'

    AirSnotSound=Sound'Sounds.AirSnot'
    FromDowntownSound=Sound'Sounds.FromDowntown'
    FromDowntownThreshold=1500.0
    bKilledPlayerInAir=false
    bDowntownedPlayer=false
}