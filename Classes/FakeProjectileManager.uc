class FakeProjectileManager extends Actor;

struct FPindex
{
    var Projectile FP;
    var int index;
};

var array<FPIndex> FP;

simulated function RegisterFakeProjectile(Projectile P, optional int index)
{
    local int i;
    i= FP.Length+1;
    FP.Length =i;
    FP[i-1].FP=P;
    FP[i-1].index = index;
}

simulated function bool AllowFakeProjectile(class<projectile> pClass, optional int index)
{
   local int i;
   CleanUpProjectiles();
   for(i=0; i<FP.Length; i++)
      if(FP[i].FP!=None && FP[i].FP.class == pClass && FP[i].index == index)
          return false;
   return true;
}

simulated function CleanUpProjectiles()
{
   local int i;

   for(i=FP.Length-1; i>=0; i--)
      if(FP[i].FP==None)
          FP.Remove(i,1);
}

simulated function RemoveProjectile(Projectile P)
{
    local int i;
    for(i=FP.Length-1; i>=0; i--)
    {
        if(FP[i].FP==None || FP[i].FP==P)
            FP.Remove(i,1);
    }
    P.Destroy();
}

simulated function Projectile GetFP(class<Projectile> CP, optional int index)
{
   local int i;
   for(i=0; i<FP.Length; i++)
      if(FP[i].FP!=None && FP[i].FP.class == CP && FP[i].index == index)
         return FP[i].FP;
   return none;
}

// Like GetFP, but when multiple fakes share an index (e.g. a lingering fake from a
// previous shot that hasn't expired yet), return the one nearest to loc. This is the
// just-fired fake, keeping reconciliation deltas small for ordered spreads (SS_Line).
simulated function Projectile GetClosestFP(class<Projectile> CP, int index, vector loc)
{
   local int i, best;
   local float bestDist, d;

   best = -1;
   for(i=0; i<FP.Length; i++)
      if(FP[i].FP!=None && FP[i].FP.class == CP && FP[i].index == index)
      {
         d = VSize(FP[i].FP.Location - loc);
         if(best < 0 || d < bestDist)
         {
            best = i;
            bestDist = d;
         }
      }
   if(best >= 0)
      return FP[best].FP;
   return none;
}

defaultproperties
{
     bHidden=True
}
