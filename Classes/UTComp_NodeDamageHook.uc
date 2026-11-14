class UTComp_NodeDamageHook extends Actor;

// One hook exists per BS_xPlayer and TriggerEvent fires every hook sharing this Tag,
// so each hook must only report to its own Owner. Looping over all spectators here
// used to deliver the damage once per connected player (wrong numbers and hit pitch).
function Trigger(Actor Other, Pawn EventInstigator)
{
    local ONSPowerCore N;
    local BS_xPlayer player;
    local UTComp_ONSPlayerReplicationInfo ONSPRI;

    if (EventInstigator == None)
        return;

    N = ONSPowerCore(Other);
    if (N == None)
        return;

    player = BS_xPlayer(Owner);
    if (player == None)
        return;

    if (EventInstigator.Controller == player)
    {
        player.DamageIndicatorHit(N.AccumulatedDamage, N, EventInstigator);
        player.ClientGroupDamageSound(N.AccumulatedDamage, true);
        ONSPRI = UTComp_ONSPlayerReplicationInfo(player.PlayerReplicationInfo);
        if (ONSPRI != None)
            ONSPRI.NodeDamagePoints += (float(N.AccumulatedDamage) / N.DamageCapacity * N.Score);
    }
    else if (player.ViewTarget == EventInstigator && player.PlayerReplicationInfo != None
        && player.PlayerReplicationInfo.bOnlySpectator)
    {
        player.DamageIndicatorHit(N.AccumulatedDamage, N, EventInstigator);
        player.ClientGroupDamageSound(N.AccumulatedDamage, true);
    }
}

defaultproperties
{
    bHidden=true;
    Tag='UTComp_ONSNodeDamaged';
}
