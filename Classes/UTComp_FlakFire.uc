

class UTComp_FlakFire extends FlakFire;

event ModeDoFire()
{
    local UTComp_PRI uPRI;
    if(weapon.owner.IsA('xPawn') && xPawn(Weapon.Owner).Controller!=None)
    {
        uPRI=class'UTComp_Util'.static.GetUTCompPRIFor(xPawn(Weapon.Owner).Controller);
        if(uPRI!=None)
            uPRI.NormalWepStatsPrim[7]+=9;
    }
    Super.ModeDoFire();
}

defaultproperties
{
    ProjectileClass=Class'UTComp_FlakChunk'
}
