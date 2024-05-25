class UTComp_ONSAVRiLFire extends ONSAVRiLFire;

var config float KickModifier;
var config bool bDisableIfCrouched, bDisableOnGround;

event PreBeginPlay() 
{
	// modify kickmomentum, default: X=-350,Y=0,Z=175
	KickMomentum.X *= KickModifier;
	KickMomentum.Z *= KickModifier;
}

function DoFireEffect() 
{
	Super.DoFireEffect();
	
	if (Instigator != None && (!bDisableOnGround || Instigator.Base == None)
	&& (!bDisableIfCrouched || !Instigator.bIsCrouched))
		Instigator.AddVelocity(KickMomentum >> Instigator.GetViewRotation());
}

function DoFireEffect() 
{
	Super.DoFireEffect();
	
	if (Instigator != None && (!bDisableOnGround || Instigator.Base == None)
	&& (!bDisableIfCrouched || !Instigator.bIsCrouched))
		Instigator.AddVelocity(KickMomentum >> Instigator.GetViewRotation());
}

event ModeDoFire()
{
    local UTComp_PRI uPRI;
    if(weapon.owner.IsA('xPawn') && xPawn(Weapon.Owner).Controller!=None)
    {
        uPRI=class'UTComp_Util'.static.GetUTCompPRIFor(xPawn(Weapon.Owner).Controller);
        if(uPRI!=None)
            uPRI.NormalWepStatsPrim[2]+=1;
    }
    Super.ModeDoFire();
}

defaultproperties
{
	KickModifier=1.000000
}
