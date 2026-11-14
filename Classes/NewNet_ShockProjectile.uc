
class NewNet_ShockProjectile extends UTComp_ShockProjectile;

var PlayerController PC;
var vector DesiredDeltaFake;
var float CurrentDeltaFakeTime;
var bool bInterpFake;
var bool bOwned;
var bool bMoved;

var float ping;

var FakeProjectileManager FPM;
var float FakeSearchEndTime; // owned: give up looking for a matching fake after this

const INTERP_TIME = 0.70;
const PLACEBO_FIX = 0.025;

replication
{
    unreliable if(bDemoRecording)
       DoMove, DoSetLoc;
}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();
    if(Level.NetMode != NM_Client)
        return;
    DoPostNet();
}

simulated function DoPostNet()
{
    PC = Level.GetLocalPlayerController();
    if (CheckOwned())
    {
        FakeSearchEndTime = Level.TimeSeconds + FMax(1.0, 2.0*class'NewNet_PRI'.default.PredictedPing);
        if( !CheckForFakeProj())
        {
            bMoved = true;
            DoMove(FMax(0.00, (class'NewNet_PRI'.default.PredictedPing - 1.5*class'TimeStamp'.default.AverDT))*Velocity);
        }
    }
}

// The client Tick is done once colouring is settled and there is no fake to find or follow.
simulated function bool ClientTickDone()
{
    return !bInterpFake && !bOwned && super.ClientTickDone();
}

simulated function DoMove(Vector V)
{
    Move(V);
}

simulated function DoSetLoc(Vector V)
{
    SetLocation(V);
}

simulated function bool CheckOwned()
{
    local UTComp_Settings S;
    S = class'UTComp_Settings'.default.instance;

    if(S != none && S.bEnableEnhancedNetCode==false)
        return false;
    bOwned = (PC!=None && PC.Pawn!=None && PC.Pawn == Instigator);
    return bOwned;
}

simulated function bool CheckForFakeProj()
{
     local Projectile FP;

     ping = FMax(0.0, class'NewNet_PRI'.default.PredictedPing - 1.50*class'TimeStamp'.default.AverDT);
     if(FPM == none)
        FindFPM();
     FP = FPM.GetFP(class'NewNet_Fake_ShockProjectile');
     if(FP != none)
     {
         bInterpFake=true;
         if(bMoved)
             DesiredDeltaFake = Location - FP.Location;
         else
             DesiredDeltaFake = (Location+Velocity*ping) - FP.Location;
         DoSetLoc(FP.Location);
         FPM.RemoveProjectile(FP);
         bOwned=False;
         return true;
     }
     return false;
}

simulated function FindFPM()
{
    foreach DynamicActors(class'FakeProjectileManager', FPM)
        break;
}


simulated function Tick(float deltatime)
{
    // Fake projectile matching and colouring are client-side, so a dedicated
    // server stops ticking this. The bot combo Tick in state WaitForCombo is
    // separate and still runs there.
    if(Level.NetMode == NM_DedicatedServer)
    {
        Disable('Tick');
        return;
    }
    super.Tick(deltatime);
    if(Level.NetMode != NM_Client)
        return;
    DoTick(deltatime);
}

simulated function DoTick(float deltatime)
{
    if(bInterpFake)
        FakeInterp(deltatime);
    else if(bOwned && !CheckForFakeProj() && Level.TimeSeconds > FakeSearchEndTime)
        bOwned = false; // a matching fake would have spawned by now; stop searching
}

simulated function FakeInterp(float dt)
{
    local vector V;
    local float OldDeltaFakeTime;

    V=DesiredDeltaFake*dt/INTERP_TIME;

    OldDeltaFakeTime = CurrentDeltaFakeTime;
    CurrentDeltaFakeTime+=dt;

    if(CurrentDeltaFakeTime < INTERP_TIME)
        Domove(V);
    else // (We overshot)
    {
        DoMove((INTERP_TIME - OldDeltaFakeTime)/dt*V);
        bInterpFake=False;
        //Turn off checking for fakes
    }
}



defaultproperties
{
}
