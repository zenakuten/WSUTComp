
class NewNet_ClassicSniperRifle extends UTComp_ClassicSniperRifle
    HideDropDown
	CacheExempt;

var TimeStamp_Pawn T;
var MutUTComp M;

// A NewNet shot the server's refire timer is holding back, see ServerStartFire
var bool bNewNetDelayed;
var float DelayStamp;

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

replication
{
    reliable if( Role<ROLE_Authority )
        NewNet_ServerStartFire;
}

function DisableNet()
{
    NewNet_ClassicSniperFire(FireMode[0]).bUseEnhancedNetCode = false;
    NewNet_ClassicSniperFire(FireMode[0]).PingDT = 0.00;
    ClearClientAim();
}

// Forgets the aim and position a client sent for a shot that hasn't fired
function ClearClientAim()
{
    bNewNetDelayed = false;
    NewNet_ClassicSniperFire(FireMode[0]).bUseReplicatedInfo = false;
    NewNet_ClassicSniperFire(FireMode[0]).bUseReplicatedRot = false;
    NewNet_ClassicSniperFire(FireMode[0]).bFirstGo = false;
}

// A weapon that changes hands must not fire its new owner's first shot from what
// the last owner's client sent
simulated function BringUp(optional Weapon PrevWeapon)
{
    if(Role == ROLE_Authority)
        ClearClientAim();
    Super.BringUp(PrevWeapon);
}

simulated function ClientStartFire(int mode)
{
    if (mode == 1)
    {
        FireMode[mode].bIsFiring = true;
        if( Instigator.Controller.IsA( 'PlayerController' ) )
            PlayerController(Instigator.Controller).ToggleZoom();
    }
    else
    {
        SuperClientStartFire(mode);
    }
}

simulated event SuperClientStartFire(int Mode)
{
    if(Level.NetMode!=NM_Client || !BS_xPlayer(Level.GetLocalPlayerController()).UseNewNet())
        super(Weapon).ClientStartFire(mode);
    else
        NewNet_ClientStartFire(mode);
}

simulated event NewNet_ClientStartFire(int Mode)
{
    local ReplicatedRotator R;
    local ReplicatedVector V;
    local vector Start, HN, HL;
    local bool b;
    local Actor A;
    local BS_xPlayer bsp;

    if ( Pawn(Owner).Controller.IsInState('GameEnded') || Pawn(Owner).Controller.IsInState('RoundEnded') )
        return;
    if (Role < ROLE_Authority)
    {
        if (StartFire(Mode))
        {
            // Aligned to the angle the camera is drawn at (see BS_xPlayer.AlignToView)
            R.Pitch = class'BS_xPlayer'.static.AlignAngle(Pawn(Owner).Controller.Rotation.Pitch);
            R.Yaw = class'BS_xPlayer'.static.AlignAngle(Pawn(Owner).Controller.Rotation.Yaw);
            Start = Pawn(Owner).Location + Pawn(Owner).EyePosition();
            V.X = Start.X;
            V.Y = Start.Y;
            V.Z = Start.Z;

            if(T==None)
                foreach DynamicActors(class'TimeStamp_pawn', T)
                     break;

            // What this client's own shot hits, so the server can check its answer. In
            // 3p the shot follows the crosshair aim (Adjust3pAim), not the view rotation.
            bsp = BS_xPlayer(Pawn(Owner).Controller);
            if(bsp != None && bsp.bBehindView)
                A = Trace(HL,HN,Start+Vector(bsp.Adjust3pAim(Start))*40000.0,Start,true);
            else
                A = Trace(HL,HN,Start+Vector(class'BS_xPlayer'.static.AlignToView(Pawn(Owner).Controller.Rotation))*40000.0,Start,true);
            b = A != None && (A.IsA('xPawn') || A.IsA('Vehicle'));

            NewNet_ServerStartFire(Mode, T.TimeStamp, T.dt, R, V, b, A);
        }
    }
    else
    {
        StartFire(Mode);
    }
}

function NewNet_ServerStartFire(byte Mode, byte ClientTimeStamp, float dt, ReplicatedRotator R, ReplicatedVector V, bool bBelievesHit, optional Actor A)
{
    local NewNet_ClassicSniperFire F;

    F = NewNet_ClassicSniperFire(FireMode[Mode]);
    if(F == None)
    {
        ServerStartFire(Mode);
        return;
    }

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

    F.PingDT = M.ClientTimeStamp - M.GetStamp(ClientTimeStamp)-DT + 0.5*M.AverDT;
    F.bUseEnhancedNetCode = true;
    F.AverDT = M.AverDT;
    F.bBelievesHit = bBelievesHit;
    F.BelievedHitActor = A;
    F.bFirstGo = true;

    // Saved before the refire test, so a shot the server holds back keeps them too.
    // The aim is always the client's; its eye position only when it is believable.
    bNewNetDelayed = false;
    F.SavedVec.X = V.X;
    F.SavedVec.Y = V.Y;
    F.SavedVec.Z = V.Z;
    F.SavedRot.Yaw = R.Yaw;
    F.SavedRot.Pitch = R.Pitch;
    F.SavedRot.Roll = 0;
    F.bUseReplicatedInfo = M.IsReasonableFireStart(Pawn(Owner), F.SavedVec);
    F.bUseReplicatedRot = true;

    if ( (F.NextFireTime <= Level.TimeSeconds + F.PreFireTime) && StartFire(Mode) )
    {
        F.ServerStartFireTime = Level.TimeSeconds;
        F.bServerDelayStartFire = false;
    }
    else if ( F.AllowFire() )
    {
        F.bServerDelayStartFire = true;
        bNewNetDelayed = true;
        DelayStamp = M.ClientTimeStamp;
    }
    else
    {
        ClearClientAim();
        ClientForceAmmoUpdate(Mode, AmmoAmount(Mode));
    }
}

// The engine starts a held-back shot through here (AWeapon::TickAuthoritative) once
// the refire timer allows. A NewNet shot keeps what its client sent, and its rewind
// grows by the time it waited, so it still goes back to when the client fired.
function ServerStartFire(byte Mode)
{
    Super.ServerStartFire(Mode);

    if(bNewNetDelayed && Mode == 0 && !FireMode[0].bServerDelayStartFire)
    {
        bNewNetDelayed = false;
        NewNet_ClassicSniperFire(FireMode[0]).PingDT += M.ClientTimeStamp - DelayStamp;
    }
}

DefaultProperties
{
     PickupClass=Class'NewNet_ClassicSniperRiflePickup'
     FireModeClass(0)=class'NewNet_ClassicSniperFire'
}
