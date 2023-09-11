class TeamColorShockBeamFire extends ShockBeamFire;

function SpawnBeamEffect(Vector Start, Rotator Dir, Vector HitLocation, Vector HitNormal, int ReflectNum)
{
    local ShockBeamEffect Beam;

    if (Weapon != None)
    {
        Beam = Weapon.Spawn(BeamEffectClass,,, Start, Dir);
        if(Instigator != None && Instigator.Controller != None && TeamColorShockBeamEffect(beam) != None)
        {
            TeamColorShockBeamEffect(Beam).TeamNum = class'TeamColorManager'.static.GetTeamNum(Instigator.Controller, Level);
        }
            
        if (ReflectNum != 0) 
            Beam.Instigator = None; // prevents client side repositioning of beam start

        Beam.AimAt(HitLocation, HitNormal);
    }
}


defaultproperties
{
    BeamEffectClass=class'TeamColorShockBeamEffect'
}