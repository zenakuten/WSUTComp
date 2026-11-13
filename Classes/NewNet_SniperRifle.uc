
class NewNet_SniperRifle extends UTComp_SniperRifle
    HideDropDown
	CacheExempt;

struct ReplicatedRotator
{
    var int Yaw;
    var int Pitch;
};

struct ReplicatedVector
{
    var float X;
    var float Y;
    var float Z;
};

var TimeStamp_Pawn T;
var MutUTComp M;
var float lastDT;

// A NewNet shot the server's refire timer is holding back, see ServerStartFire
var bool bNewNetDelayed;
var byte DelayedMode;
var float DelayStamp;

replication
{
    reliable if(Role < Role_Authority)
        NewNet_ServerStartFire;
    unreliable if(bDemoRecording)
        SpawnLGEffect;
}

function DisableNet()
{
    NewNet_SniperFire(FireMode[0]).bUseEnhancedNetCode = false;
    NewNet_SniperFire(FireMode[0]).PingDT = 0.00;
    ClearClientAim();
}

// Forgets the aim and position a client sent for a shot that hasn't fired
function ClearClientAim()
{
    bNewNetDelayed = false;
    NewNet_SniperFire(FireMode[0]).bUseReplicatedInfo = false;
    NewNet_SniperFire(FireMode[0]).bUseReplicatedRot = false;
}

// A weapon that changes hands must not fire its new owner's first shot from what
// the last owner's client sent
simulated function BringUp(optional Weapon PrevWeapon)
{
    if(Role == ROLE_Authority)
        ClearClientAim();
    Super.BringUp(PrevWeapon);
}

// The engine starts a held-back shot through here (AWeapon::TickAuthoritative) once
// the refire timer allows. A NewNet shot keeps what its client sent, and its rewind
// grows by the time it waited, so it still goes back to when the client fired.
function ServerStartFire(byte Mode)
{
    Super.ServerStartFire(Mode);

    if(bNewNetDelayed && Mode == DelayedMode && !FireMode[Mode].bServerDelayStartFire)
    {
        bNewNetDelayed = false;
        NewNet_SniperFire(FireMode[Mode]).PingDT += M.ClientTimeStamp - DelayStamp;
    }
}

simulated function SpawnLGEffect(class<Actor> tmpHitEmitClass, vector ArcEnd, vector HitNormal, vector HitLocation)
{
    local xEmitter HitEmitter;
    hitEmitter = xEmitter(Spawn(tmpHitEmitClass,,, arcEnd, Rotator(HitNormal)));
    if ( hitEmitter != None )
	  	hitEmitter.mSpawnVecA = HitLocation;
    if(Level.NetMode!=NM_Client)
        Warn("Server should never spawn the client lightningbolt");
}

simulated function ClientStartFire(int mode)
{
    if(Level.NetMode!=NM_Client)
    {
        Super.ClientStartFire(mode);
        return;
    }

    if (mode == 1)
    {
        FireMode[mode].bIsFiring = true;
        if( Instigator.Controller.IsA( 'PlayerController' ) )
            PlayerController(Instigator.Controller).ToggleZoom();
    }
    else
    {
        if(BS_xPlayer(Level.GetLocalPlayerController()).UseNewNet())
            NewNet_ClientStartFire(mode);
        else
            super(Weapon).ClientStartFire(mode);
    }
}

simulated function NewNet_ClientStartFire(int mode)
{
    local ReplicatedRotator R;
    local ReplicatedVector V;
    local vector Start;
  //  local float stamp;
    local byte stamp;
    local bool b;
    local actor A;
    local vector HN,HL;
    local BS_xPlayer bsp;

    if ( Pawn(Owner).Controller.IsInState('GameEnded') || Pawn(Owner).Controller.IsInState('RoundEnded') )
        return;
    if (Role < ROLE_Authority)
    {
        if (ReadyToFire(mode) && StartFire(Mode) )
        {
            // Aligned to the angle the camera is drawn at (see BS_xPlayer.AlignToView)
            R.Pitch = class'BS_xPlayer'.static.AlignAngle(Pawn(Owner).Controller.Rotation.Pitch);
            R.Yaw = class'BS_xPlayer'.static.AlignAngle(Pawn(Owner).Controller.Rotation.Yaw);
            STart=Pawn(Owner).Location + Pawn(Owner).EyePosition();

            V.X = Start.X;
            V.Y = Start.Y;
            V.Z = Start.Z;

            if(T==None)
                foreach DynamicActors(class'TimeStamp_Pawn', T)
                     break;
            Stamp = T.TimeStamp;

            NewNet_SniperFire(FireMode[mode]).DoInstantFireEffect();
            // In 3p the shot follows the crosshair aim (Adjust3pAim), not the raw view
            // rotation; tracing the latter misses the enemy the beam hit (offset by cam-Y), so
            // b stays false and the server reverse-fixes a legitimate hit online.
            bsp = BS_xPlayer(Pawn(Owner).Controller);
            if(bsp != None && bsp.bBehindView)
                A = Trace(HN,HL,Start+Vector(bsp.Adjust3pAim(Start))*40000.0,Start,true);
            else
                A = Trace(HN,HL,Start+Vector(class'BS_xPlayer'.static.AlignToView(Pawn(Owner).Controller.Rotation))*40000.0,Start,true);
            if(A!=None && (A.IsA('xPawn') || A.IsA('Vehicle')))
            {
                b=true;
            }

            NewNet_ServerStartFire(Mode, stamp, T.dt, R, V,b,A);
        }
    }
    else
    {
        StartFire(Mode);
    }
}

simulated function bool AltReadyToFire(int Mode)
{
    local int alt;
    local float f;

    //There is a very slight descynchronization error on the server
    // with weapons due to differing deltatimes which accrues to a pretty big
    // error if people just hold down the button...
    // This will never cause the weapon to actually fire slower
    f = 0.015;

    if(!ReadyToFire(Mode))
        return false;

    if ( Mode == 0 )
        alt = 1;
    else
        alt = 0;

    if ( ((FireMode[alt] != FireMode[Mode]) && FireMode[alt].bModeExclusive && FireMode[alt].bIsFiring)
		|| !FireMode[Mode].AllowFire()
		|| (FireMode[Mode].NextFireTime > Level.TimeSeconds + FireMode[Mode].PreFireTime - f) )
    {
        return false;
    }

	return true;
}

function NewNet_ServerStartFire(byte Mode, byte ClientTimeStamp, float DT, ReplicatedRotator R, ReplicatedVector V, bool bBelievesHit, optional actor A)
{
	if ( (Instigator != None) && (Instigator.Weapon != self) )
	{
		if ( Instigator.Weapon == None )
			Instigator.ServerChangedWeapon(None,self);
		else
			Instigator.Weapon.SynchronizeWeapon(self);
		return;
	}

	if(M==None)
        foreach DynamicActors(class'MutUTComp', M)
	        break;

    NewNet_SniperFire(FireMode[Mode]).PingDT = M.ClientTimeStamp - M.GetStamp(ClientTimeStamp)-DT + 0.5*M.AverDT;
    NewNet_SniperFire(FireMode[Mode]).AverDT = M.AverDT;
    //Log("Firing with"@M.ClientTimeStamp@M.GetStamp(ClientTimeStamp)@DT);
   // Log(PlayerController(Pawn(Owner).Controller).ExactPing);
    if(bBelievesHit)
    {
        newNet_sniperFire(FireMode[Mode]).bBelievesHit=true;
        newNet_SniperFire(FireMode[Mode]).BelievedHitActor=A;
    }
    else
    {
        newNet_sniperFire(FireMode[Mode]).bBelievesHit=false;
    }
    NewNet_SniperFire(FireMode[Mode]).bUseEnhancedNetCode = true;
    NewNet_SniperFire(FireMode[Mode]).bFirstGo = true;

    // Saved before the refire test, so a shot the server holds back keeps them too.
    // The aim is always the client's; its eye position only when it is believable.
    bNewNetDelayed = false;
    NewNet_SniperFire(FireMode[Mode]).SavedVec.X = V.X;
    NewNet_SniperFire(FireMode[Mode]).SavedVec.Y = V.Y;
    NewNet_SniperFire(FireMode[Mode]).SavedVec.Z = V.Z;
    NewNet_SniperFire(FireMode[Mode]).SavedRot.Yaw = R.Yaw;
    NewNet_SniperFire(FireMode[Mode]).SavedRot.Pitch = R.Pitch;
    NewNet_SniperFire(FireMode[Mode]).bUseReplicatedInfo=M.IsReasonableFireStart(Pawn(Owner), NewNet_SniperFire(FireMode[Mode]).SavedVec);
    NewNet_SniperFire(FireMode[Mode]).bUseReplicatedRot=true;

    if ( (FireMode[Mode].NextFireTime <= Level.TimeSeconds + FireMode[Mode].PreFireTime)
		&& StartFire(Mode) )
    {
        FireMode[Mode].ServerStartFireTime = Level.TimeSeconds;
        FireMode[Mode].bServerDelayStartFire = false;
   //     NewNet_SniperFire(FireMode[Mode]).bBelievesHit=bBelievesHit;
   //     NewNet_SniperFire(FireMode[Mode]).bCount=true;
   /*     NewNet_SniperFire(FireMode[Mode]).BelievedHLDelta.X = BelievedHLDelta.X;
        NewNet_SniperFire(FireMode[Mode]).BelievedHLDelta.Y = BelievedHLDelta.Y;
        NewNet_SniperFire(FireMode[Mode]).BelievedHLDelta.Z = BelievedHLDelta.Z;
        NewNet_SniperFire(FireMode[Mode]).SavedVec = Pawn(Owner).Location;
        NewNet_SniperFire(FireMode[Mode]).SavedRot = class'BS_xPlayer'.static.AlignToView(Pawn(Owner).Controller.Rotation);
    */
    }
    else if ( FireMode[Mode].AllowFire() )
    {
        FireMode[Mode].bServerDelayStartFire = true;
        bNewNetDelayed = true;
        DelayedMode = Mode;
        DelayStamp = M.ClientTimeStamp;
	}
	else
	{
		ClearClientAim();
		ClientForceAmmoUpdate(Mode, AmmoAmount(Mode));
	}
}

simulated function Weapontick(float deltatime)
{
   lastDT = deltatime;
}

//// client & server ////
simulated function bool StartFire(int Mode)
{
    local int alt;

    if (!ReadyToFire(Mode))
        return false;

    if (Mode == 0)
        alt = 1;
    else
        alt = 0;

    FireMode[Mode].bIsFiring = true;

    FireMode[Mode].NextFireTime = Level.TimeSeconds-LastDT*0.5 + FireMode[Mode].PreFireTime;

    if (FireMode[alt].bModeExclusive)
    {
        // prevents rapidly alternating fire modes
        FireMode[Mode].NextFireTime = FMax(FireMode[Mode].NextFireTime, FireMode[alt].NextFireTime);
    }

    if (Instigator.IsLocallyControlled())
    {
        if (FireMode[Mode].PreFireTime > 0.0 || FireMode[Mode].bFireOnRelease)
        {
            FireMode[Mode].PlayPreFire();
        }
        FireMode[Mode].FireCount = 0;
    }

    return true;
}


defaultproperties
{
    FireModeClass(0) = class'NewNet_SniperFire'
    PickupClass=Class'NewNet_SniperRiflePickup'
}
