class ModernPawn extends xPawn;
var int DyingTimer;

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


State Dying
{
    simulated function Timer()
	{
		local KarmaParamsSkel skelParams;

        // since we are setting LastRenderTime, this breaks PlayerCanSeeMe (native and final)
        // resulting in dead pawns floating around.  Add an 8 sec safety catch,
        // after 8 sec always destroy
        DyingTimer++;
		if ( !PlayerCanSeeMe() || DyingTimer >= 8 )
        {
			Destroy();
        }
        // If we are running out of life, bute we still haven't come to rest, force the de-res.
        // unless pawn is the viewtarget of a player who used to own it
        else if ( LifeSpan <= DeResTime && bDeRes == false )
        {
			skelParams = KarmaParamsSkel(KParams);

			// check not viewtarget
			if ( (PlayerController(OldController) != None) && (PlayerController(OldController).ViewTarget == self)
				&& (Viewport(PlayerController(OldController).Player) != None) )
			{
				skelParams.bKImportantRagdoll = true;
				LifeSpan = FMax(LifeSpan,DeResTime + 2.0);
				SetTimer(1.0, false);
				return;
			}
			else
			{
				skelParams.bKImportantRagdoll = false;
			}
            // spawn derez
            StartDeRes();
        }
		else
        {
			SetTimer(1.0, false);
        }
	}   
}

// Notify the owning client about damage momentum so client-side prediction
// stays in sync. Without this, the client predicts with old velocity and
// the next server correction causes a snap/hiccup.
function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
    local vector VelBefore;
    local BS_xPlayer PC;

    VelBefore = Velocity;
    super.TakeDamage(Damage, instigatedBy, hitlocation, momentum, damageType);

    // Send the velocity delta to the owning client
    if(Role == ROLE_Authority && Controller != None)
    {
        PC = BS_xPlayer(Controller);
        if(PC != None && Velocity != VelBefore)
        {
            PC.ClientDamageImpulse(Velocity - VelBefore);
            PC.LastDamageImpulseTime = Level.TimeSeconds;
        }
    }
}

defaultproperties
{
    DyingTimer=0
}