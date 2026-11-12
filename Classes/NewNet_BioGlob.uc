
class NewNet_BioGlob extends TeamColorBioGlob
	HideDropDown
	CacheExempt;

var PlayerController PC;
var vector DesiredDeltaFake;
var float CurrentDeltaFakeTime;
var bool bInterpFake;
var bool bOwned;

var FakeProjectileManager FPM;
var float FakeSearchEndTime; // owned: give up looking for a matching fake after this

const INTERP_TIME = 0.50;
var int index;

replication
{
    unreliable if(bDemoRecording)
       DoMove, DoSetLoc;
    reliable if(Role == Role_Authority && bNetInitial)
       index;

}

simulated function DoMove(Vector V)
{
    Move(V);
}

simulated function DoSetLoc(Vector V)
{
    SetLocation(V);
}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();
    if(Level.NetMode!=NM_Client)
        return;

    PC = Level.GetLocalPlayerController();
    if (CheckOwned())
    {
        FakeSearchEndTime = Level.TimeSeconds + FMax(1.0, 2.0*class'NewNet_PRI'.default.PredictedPing);
        CheckForFakeProj();
    }
}

// The client Tick is done once colouring is settled and there is no fake to find or follow.
simulated function bool ClientTickDone()
{
    return !bInterpFake && !bOwned && super.ClientTickDone();
}

simulated function bool CheckOwned()
{
    local UTComp_Settings S;
    S=class'UTComp_Settings'.default.instance;
    if(S != none && S.bEnableEnhancedNetCode==false)
        return false;
    bOwned = (PC!=None && PC.Pawn!=None && PC.Pawn == Instigator);
    return bOwned;
}

simulated function bool CheckForFakeProj()
{
     local Projectile FP;

     if(FPM == none)
        FindFPM();
     FP = FPM.GetFP(class'NewNet_Fake_BioGlob', Index);
     if(FP != none)
     {
         bInterpFake=true;
         DesiredDeltaFake = Location - FP.Location;
         doSetLoc(FP.Location);
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
    // server stops ticking this
    if(Level.NetMode == NM_DedicatedServer)
    {
        Disable('Tick');
        return;
    }
    super.Tick(deltatime);
    if(Level.NetMode != NM_Client)
        return;
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
