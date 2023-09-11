
class NewNet_Fake_FlakShell extends TeamColorFlakShell;

simulated function Explode(vector HitLocation, vector HitNormal)
{
    Destroy();
}

defaultproperties
{
     bNetTemporary=False
}
