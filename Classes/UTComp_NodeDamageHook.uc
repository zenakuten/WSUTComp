class UTComp_NodeDamageHook extends Actor;

function Trigger(Actor Other, Pawn EventInstigator)
{
    local ONSPowerCore N;
    local BS_xPlayer player;
    local Controller C;
    N = ONSPowerCore(Other);

    if(EventInstigator != None && N != None)
    { 
        if(EventInstigator.Controller != None && EventInstigator.Controller == Owner)
        {
            player = BS_xPlayer(EventInstigator.Controller);
            if(player != None)
            {
                player.DamageIndicatorHit(N.AccumulatedDamage, N, EventInstigator);
                player.ClientGroupDamageSound(N.AccumulatedDamage, true);
            }
        }

        for(C = Level.ControllerList; C != None; C = C.NextController)
        {
            player = BS_xPlayer(C);
            if(player != None && player.PlayerReplicationInfo != None && player.PlayerReplicationInfo.bOnlySpectator)
            {
                if(player.ViewTarget == EventInstigator)
                {
                    player.DamageIndicatorHit(N.AccumulatedDamage, N, EventInstigator);
                    player.ClientGroupDamageSound(N.AccumulatedDamage, true);
                }
            }
        }
    }
}

defaultproperties
{
    bHidden=true;
    Tag='UTComp_ONSNodeDamaged';
}