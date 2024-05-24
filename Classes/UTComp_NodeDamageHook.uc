class UTComp_NodeDamageHook extends Actor;

function Trigger(Actor Other, Pawn EventInstigator)
{
    local ONSPowerCore N;
    N = ONSPowerCore(Other);

    if(EventInstigator != None && N != None && EventInstigator.Controller != None && EventInstigator.Controller == Owner)
    {
        BS_xPlayer(EventInstigator.Controller).DamageIndicatorHit(N.AccumulatedDamage, N, EventInstigator);
        BS_xPlayer(EventInstigator.Controller).ReceiveHitSound(N.AccumulatedDamage, 1);
    }
}

defaultproperties
{
    bHidden=true;
    Tag='UTComp_ONSNodeDamaged';
}