class UTComp_NodeDamageHook extends Actor;

function Trigger(Actor Other, Pawn EventInstigator)
{
    local ONSPowerCore N;
    local BS_xPlayer player;
    N = ONSPowerCore(Other);

    if(EventInstigator != None && N != None && EventInstigator.Controller != None && EventInstigator.Controller == Owner)
    {
        player = BS_xPlayer(EventInstigator.Controller);
        if(player != None)
        {
            player.DamageIndicatorHit(N.AccumulatedDamage, N, EventInstigator);
            player.ClientGroupDamageSound(N.AccumulatedDamage, true);
        }
    }
}

defaultproperties
{
    bHidden=true;
    Tag='UTComp_ONSNodeDamaged';
}