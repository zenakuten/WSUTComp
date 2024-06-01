

class UTComp_RocketMultiFire extends RocketMultiFire;

var MutUTComp MutOwner;

event ModeDoFire()
{
    local UTComp_PRI uPRI;
    if(weapon.owner.IsA('xPawn') && xPawn(Weapon.Owner).Controller!=None)
    {
        uPRI=class'UTComp_Util'.static.GetUTCompPRIFor(xPawn(Weapon.Owner).Controller);
        if(uPRI!=None)
            uPRI.NormalWepStatsPrim[6]+=Load;
    }
    Super.ModeDoFire();
}

function ModeHoldFire()
{
    if(MutOwner == None && Weapon != None)
        foreach Weapon.DynamicActors(class'MutUTComp', MutOwner)
            break;

    if(Instigator != none && MutOwner != None && MutOwner.bChargedWeaponsNoSpawnProtection)
        Instigator.DeactivateSpawnProtection();

    super.ModeHoldFire();
}

defaultproperties
{
    ProjectileClass=class'TeamColorRocketProj'
}
