class ModernPawn extends xPawn;

simulated function Tick(float DeltaTime)
{
    Super.Tick(DeltaTime);

    if (Level.NetMode != NM_DedicatedServer && PlayerController(Controller) == None)
    {
        // Trick the client that we're always on screen so it does not stop
        // updating animations.
        LastRenderTime = Level.TimeSeconds;
    }
}

defaultproperties
{
}