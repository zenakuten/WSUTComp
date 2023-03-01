
//-----------------------------------------------------------
//
//-----------------------------------------------------------
class NewNet_LinkFire extends UTComp_LinkFire;

var float PingDT;
var bool bUseEnhancedNetCode;

simulated function ModeTick(float dt)
{
	local Vector StartTrace, EndTrace, V, X, Y, Z;
	local Vector HitLocation, HitNormal, EndEffect;
	local Actor Other;
	local Rotator Aim;
	local UTComp_LinkGun LinkGun;
	local float Step, ls;
	local bot B;
	local bool bShouldStop, bIsHealingObjective;
	local LinkBeamEffect LB;
	local DestroyableObjective HealObjective;
	local Vehicle LinkedVehicle;
	local bool bNeedRevert;
	local vector PawnHitLocation;
    local int AdjustedDamage, i;
    local float DamageAmount;
    local float score;
    local ONSPowerNode Node;

    if(!bUseEnhancedNetCode || Instigator.Role < Role_Authority)
    {
        super.ModeTick(dt);
        return;
    }

    if ( !bIsFiring )
    {
		bInitAimError = true;
        return;
    }

    LinkGun = UTComp_LinkGun(Weapon);

    if ( LinkGun.Links < 0 )
    {
        //log("warning:"@Instigator@"linkgun had"@LinkGun.Links@"links");
        LinkGun.Links = 0;
    }

    ls = LinkScale[Min(LinkGun.Links,5)];
    
    // Clean out the lockingpawns list
	for (i=0; i<LinkGun.LockingPawns.Length; i++)
		if (LinkGun.LockingPawns[i] == none)
			LinkGun.LockingPawns.Remove(i, 1);

    if ( myHasAmmo(LinkGun) && ((UpTime > 0.0) || (Instigator.Role < ROLE_Authority)) )
    {
        UpTime -= dt;

		// the to-hit trace always starts right in front of the eye
		LinkGun.GetViewAxes(X, Y, Z);
		StartTrace = GetFireStart( X, Y, Z);
        TraceRange = default.TraceRange + LinkGun.Links*250;

        if ( Instigator.Role < ROLE_Authority )
        {
			if ( Beam == None )
				ForEach Weapon.DynamicActors(class'LinkBeamEffect', LB )
					if ( !LB.bDeleteMe && (LB.Instigator != None) && (LB.Instigator == Instigator) )
					{
						Beam = LB;
						break;
					}

			if ( Beam != None )
				LockedPawn = Beam.LinkedPawn;
		}

        if ( LockedPawn != None )
			TraceRange *= 1.5;

        if ( Instigator.Role == ROLE_Authority )
		{
		    if ( bDoHit )
			    LinkGun.ConsumeAmmo(ThisModeNum, AmmoPerFire);

			B = Bot(Instigator.Controller);
			if ( (B != None) && (PlayerController(B.Squad.SquadLeader) != None) && (B.Squad.SquadLeader.Pawn != None) )
			{
				if ( IsLinkable(B.Squad.SquadLeader.Pawn)
					&& (B.Squad.SquadLeader.Pawn.Weapon != None && B.Squad.SquadLeader.Pawn.Weapon.GetFireMode(1).bIsFiring)
					&& (VSize(B.Squad.SquadLeader.Pawn.Location - StartTrace) < TraceRange) )
				{
					Other = Weapon.Trace(HitLocation, HitNormal, B.Squad.SquadLeader.Pawn.Location, StartTrace, true);
					if ( Other == B.Squad.SquadLeader.Pawn )
					{
						B.Focus = B.Squad.SquadLeader.Pawn;
						if ( B.Focus != LockedPawn )
							SetLinkTo(B.Squad.SquadLeader.Pawn);
						B.SetRotation(Rotator(B.Focus.Location - StartTrace));
 						X = Normal(B.Focus.Location - StartTrace);
 					}
 					else if ( B.Focus == B.Squad.SquadLeader.Pawn )
						bShouldStop = true;
				}
 				else if ( B.Focus == B.Squad.SquadLeader.Pawn )
					bShouldStop = true;
			}
		}

		if ( LockedPawn != None )
		{
			EndTrace = LockedPawn.Location + LockedPawn.BaseEyeHeight*Vect(0,0,0.5); // beam ends at approx gun height
			if ( Instigator.Role == ROLE_Authority )
			{
				V = Normal(EndTrace - StartTrace);
				if ( (V dot X < LinkFlexibility) || LockedPawn.Health <= 0 || LockedPawn.bDeleteMe || (VSize(EndTrace - StartTrace) > 1.5 * TraceRange) )
				{
					SetLinkTo( None );
				}
			}
		}

        if ( LockedPawn == None )
        {
            if ( Bot(Instigator.Controller) != None )
            {
				if ( bInitAimError )
				{
					CurrentAimError = AdjustAim(StartTrace, AimError);
					bInitAimError = false;
				}
				else
				{
					BoundError();
					CurrentAimError.Yaw = CurrentAimError.Yaw + Instigator.Rotation.Yaw;
				}

				// smooth aim error changes
				Step = 7500.0 * dt;
				if ( DesiredAimError.Yaw ClockWiseFrom CurrentAimError.Yaw )
				{
					CurrentAimError.Yaw += Step;
					if ( !(DesiredAimError.Yaw ClockWiseFrom CurrentAimError.Yaw) )
					{
						CurrentAimError.Yaw = DesiredAimError.Yaw;
						DesiredAimError = AdjustAim(StartTrace, AimError);
					}
				}
				else
				{
					CurrentAimError.Yaw -= Step;
					if ( DesiredAimError.Yaw ClockWiseFrom CurrentAimError.Yaw )
					{
						CurrentAimError.Yaw = DesiredAimError.Yaw;
						DesiredAimError = AdjustAim(StartTrace, AimError);
					}
				}
				CurrentAimError.Yaw = CurrentAimError.Yaw - Instigator.Rotation.Yaw;
				if ( BoundError() )
					DesiredAimError = AdjustAim(StartTrace, AimError);
				CurrentAimError.Yaw = CurrentAimError.Yaw + Instigator.Rotation.Yaw;

				if ( Instigator.Controller.Target == None )
					Aim = Rotator(Instigator.Controller.FocalPoint - StartTrace);
				else
					Aim = Rotator(Instigator.Controller.Target.Location - StartTrace);

				Aim.Yaw = CurrentAimError.Yaw;

				// save difference
				CurrentAimError.Yaw = CurrentAimError.Yaw - Instigator.Rotation.Yaw;
			}
			else
	            Aim = GetPlayerAim(StartTrace, AimError);

            X = Vector(Aim);
            EndTrace = StartTrace + TraceRange * X;
        }

    //    Other = Weapon.Trace(HitLocation, HitNormal, EndTrace, StartTrace, true);

        if(PingDT <=0.0)
            Other = Weapon.Trace(HitLocation,HitNormal,EndTrace,StartTrace,true);
        else
        {
            TimeTravel(PingDT);
            bNeedRevert=true;
            Other = DoTimeTravelTrace(HitLocation, HitNormal, EndTrace, StartTrace);
        }

        if(Other!=None && Other.IsA('PawnCollisionCopy'))
        {
             PawnHitLocation = HitLocation + PawnCollisionCopy(Other).CopiedPawn.Location - Other.Location;
             Other=PawnCollisionCopy(Other).CopiedPawn;
        }
        else
        {
            PawnHitLocation = HitLocation;
        }

        if ( Other != None && Other != Instigator )
			EndEffect = HitLocation;
		else
			EndEffect = EndTrace;

		if ( Beam != None )
			Beam.EndEffect = EndEffect;

		if ( Instigator.Role < ROLE_Authority )
		{
			if ( LinkGun.ThirdPersonActor != None )
			{
				if ( LinkGun.Linking || ((Other != None) && (Instigator.PlayerReplicationInfo.Team != None) && Other.TeamLink(Instigator.PlayerReplicationInfo.Team.TeamIndex)) )
				{
					if (Instigator.PlayerReplicationInfo.Team == None || Instigator.PlayerReplicationInfo.Team.TeamIndex == 0)
						LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Red );
					else
						LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Blue );
				}
				else
				{
					if ( LinkGun.Links > 0 )
						LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Gold );
					else
						LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Green );
				}
			}
    	    if(bNeedRevert)
                 UnTimeTravel();
			return;
		}
        if ( Other != None && Other != Instigator )
        {
            // target can be linked to
            if ( IsLinkable(Other) )
            {
                if ( Other != lockedpawn )
                    SetLinkTo( Pawn(Other) );

                if ( lockedpawn != None )
                    LinkBreakTime = LinkBreakDelay;
            }
            else
            {
                // stop linking
                if ( lockedpawn != None )
                {
                    if ( LinkBreakTime <= 0.0 )
                        SetLinkTo( None );
                    else
                        LinkBreakTime -= dt;
                }

                // beam is updated every frame, but damage is only done based on the firing rate
                if ( bDoHit )
                {
                    if ( Beam != None )
						Beam.bLockedOn = false;

                    Instigator.MakeNoise(1.0);

                    AdjustedDamage = AdjustLinkDamage( LinkGun, Other, Damage );

                    if ( !Other.bWorldGeometry )
                    {
                        if ( Level.Game.bTeamGame && Pawn(Other) != None && Pawn(Other).PlayerReplicationInfo != None
							&& Pawn(Other).PlayerReplicationInfo.Team == Instigator.PlayerReplicationInfo.Team) // so even if friendly fire is on you can't hurt teammates
                            AdjustedDamage = 0;

						HealObjective = DestroyableObjective(Other);
						if ( HealObjective == None )
							HealObjective = DestroyableObjective(Other.Owner);
						if ( HealObjective != None && HealObjective.TeamLink(Instigator.GetTeamNum()) )
						{
							SetLinkTo(None);
							bIsHealingObjective = true;

                            // snarf healbonus
                            //NodeHealBonus
                            Node = ONSPowerNode(HealObjective);
                            DamageAmount = (AdjustedDamage*NodeHealBonusPct/100)/(LinkGun.LockingPawns.Length+1)*2;

                            //if node has shield, check config value and disable bonus if needed
                            if(!bNodeHealBonusForLockedNodes && Node.Shield != none && !Node.Shield.bHidden)
                                DamageAmount = 0;

                            if (!HealObjective.HealDamage(AdjustedDamage / (LinkGun.LockingPawns.Length + 1), Instigator.Controller, DamageType))
                            {
                                LinkGun.ConsumeAmmo(ThisModeNum, -AmmoPerFire);
                            }
                            else
                            {
                                if (ShouldGetHealBonus(Instigator.Controller, Node) && ONSPlayerReplicationInfo(Instigator.Controller.PlayerReplicationInfo) != None && Node != None)
                                {
                                    ONSPlayerReplicationInfo(Instigator.Controller.PlayerReplicationInfo).AddHealBonus(DamageAmount / Node.DamageCapacity * Node.Score);
                                }
                                for (i=0; i<LinkGun.LockingPawns.Length; i++)
                                {
                                    HealObjective.HealDamage(AdjustedDamage / (LinkGun.LockingPawns.Length+1), LinkGun.LockingPawns[i].Controller, DamageType);
                                    //snarf healbonus
                                    if (ShouldGetHealBonus(LinkGun.LockingPawns[i].Controller, Node))
                                    {
                                        if (ONSPlayerReplicationInfo(LinkGun.LockingPawns[i].Controller.PlayerReplicationInfo) != None)
                                        {
                                            ONSPlayerReplicationInfo(LinkGun.LockingPawns[i].Controller.PlayerReplicationInfo).AddHealBonus(DamageAmount / Node.DamageCapacity * Node.Score);
                                        }
                                    }                                                
                                }
                            }
						}
						else if(HealObjective != None)
                        {
                            // snarf from ONSPlus
                            DamageAmount = AdjustedDamage;

							if (DamageType != None)
								DamageAmount *= DamageType.default.VehicleDamageScaling;

							if (Instigator != None)
							{
								if (Instigator.HasUDamage())
									DamageAmount *= 2;

								DamageAmount *= Instigator.DamageScaling;
							}

							DamageAmount = FMin(HealObjective.Health, DamageAmount) / HealObjective.DamageCapacity;

							for (i=0; i<LinkGun.LockingPawns.Length; i++)
								HealObjective.AddScorer(LinkGun.LockingPawns[i].Controller, DamageAmount / (LinkGun.LockingPawns.Length + 1));

							// Remove players added score but give him credit for destruction of node :)
							if (Weapon != none)
								HealObjective.AddScorer(Pawn(Weapon.Owner).Controller, -(DamageAmount - (DamageAmount / (LinkGun.LockingPawns.Length + 1))));

							Other.TakeDamage(AdjustedDamage, Instigator, HitLocation, MomentumTransfer * X, DamageType);                            
                        }
                        else
                        {
							Other.TakeDamage(AdjustedDamage, Instigator, PawnHitLocation, MomentumTransfer*X, DamageType);
                        }

						if ( Beam != None )
							Beam.bLockedOn = true;
					}
				}
			}
		}

		// vehicle healing
		LinkedVehicle = Vehicle(LockedPawn);
		if ( LinkedVehicle != None && bDoHit )
		{
			AdjustedDamage = Damage * (1.5*Linkgun.Links+1) * Instigator.DamageScaling;
			if (Instigator.HasUDamage())
				AdjustedDamage *= 2;
			if (!LinkedVehicle.HealDamage(AdjustedDamage, Instigator.Controller, DamageType))
				LinkGun.ConsumeAmmo(ThisModeNum, -AmmoPerFire);
            else
            {
                score = 1;
                if(LinkedVehicle.default.Health >= VehicleHealScore)
                    score = LinkedVehicle.default.Health / VehicleHealScore;
                DamageAmount = (AdjustedDamage*NodeHealBonusPct/100)/(LinkGun.LockingPawns.Length+1);

                if (ONSPlayerReplicationInfo(Instigator.Controller.PlayerReplicationInfo) != None && !LinkedVehicle.IsVehicleEmpty())
                    ONSPlayerReplicationInfo(Instigator.Controller.PlayerReplicationInfo).AddHealBonus(DamageAmount / LinkedVehicle.default.Health * score);

				for (i=0; i<LinkGun.LockingPawns.Length; i++)
                {
					if(LinkedVehicle.HealDamage(AdjustedDamage / (LinkGun.LockingPawns.Length + 1), LinkGun.LockingPawns[i].Controller, DamageType))
                    {
                        if (ONSPlayerReplicationInfo(LinkGun.LockingPawns[i].Controller.PlayerReplicationInfo) != None && !LinkedVehicle.IsVehicleEmpty())
                            ONSPlayerReplicationInfo(LinkGun.LockingPawns[i].Controller.PlayerReplicationInfo).AddHealBonus(DamageAmount / LinkedVehicle.default.Health * score);
                    }
                }                
            }
		}
		LinkGun(Weapon).Linking = (LockedPawn != None) || bIsHealingObjective;

		if ( bShouldStop )
			B.StopFiring();
		else
		{
			// beam effect is created and destroyed when firing starts and stops
			if ( (Beam == None) && bIsFiring )
			{
				Beam = Weapon.Spawn( BeamEffectClass, Instigator );

				// vary link volume to make sure it gets replicated (in case owning player changed it client side)
				if ( SentLinkVolume == Default.LinkVolume )
					SentLinkVolume = Default.LinkVolume + 1;
				else
					SentLinkVolume = Default.LinkVolume;
			}

			if ( Beam != None )
			{
				if ( LinkGun.Linking || ((Other != None) && (Instigator.PlayerReplicationInfo.Team != None) && Other.TeamLink(Instigator.PlayerReplicationInfo.Team.TeamIndex)) )
				{
					Beam.LinkColor = Instigator.PlayerReplicationInfo.Team.TeamIndex + 1;
					if ( LinkGun.ThirdPersonActor != None )
					{
						if ( Instigator.PlayerReplicationInfo.Team == None || Instigator.PlayerReplicationInfo.Team.TeamIndex == 0 )
							LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Red );
						else
							LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Blue );
					}
				}
				else
				{
					Beam.LinkColor = 0;
					if ( LinkGun.ThirdPersonActor != None )
					{
						if ( LinkGun.Links > 0 )
							LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Gold );
						else
							LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Green );
					}
				}

				Beam.Links = LinkGun.Links;
				Instigator.AmbientSound = BeamSounds[Min(Beam.Links,3)];
				Instigator.SoundVolume = SentLinkVolume;
				Beam.LinkedPawn = LockedPawn;
				Beam.bHitSomething = (Other != None);
				Beam.EndEffect = EndEffect;
			}
		}
    }
    else
        StopFiring();

    bStartFire = false;
    bDoHit = false;
    if(bNeedRevert)
        UnTimeTravel();
}



// We need to do 2 traces. First, one that ignores the things which have already been copied
// and a second one that looks only for things that are copied
function Actor DoTimeTravelTrace(Out vector Hitlocation, out vector HitNormal, vector End, vector Start)
{
    local Actor Other;
    local bool bFoundPCC;
    local vector NewEnd, WorldHitNormal,WorldHitLocation;
    local vector PCCHitNormal,PCCHitLocation;
    local PawnCollisionCopy PCC, returnPCC;

    //First, lets set the extent of our trace.  End once we hit an actor which won't
    //be checked by an unlagged copy.
    foreach Weapon.TraceActors(class'Actor', Other,WorldHitLocation,WorldHitNormal,End,Start)
    {
       if((Other.bBlockActors || Other.bProjTarget || Other.bWorldGeometry) && !class'MutUTComp'.static.IsPredicted(Other))
       {
           break;
       }
       Other=None;
    }
    if(Other!=None)
        NewEnd=WorldHitlocation;
    else
        NewEnd=End;

    //Now, lets see if we run into any copies, we stop at the location
    //determined by the previous trace.
    foreach Weapon.TraceActors(class'PawnCollisionCopy', PCC, PCCHitLocation, PCCHitNormal, NewEnd,Start)
    {
        if(PCC!=None && PCC.CopiedPawn!=None && PCC.CopiedPawn!=Instigator)
        {
            bFoundPCC=True;
            returnPCC=PCC;
            break;
        }
    }

    // Give back the corresponding info depending on whether or not
    // we found a copy

    if(bFoundPCC)
    {
        HitLocation = PCCHitLocation;
        HitNormal = PCCHitNormal;
        return returnPCC;
    }
    else
    {
        HitLocation = WorldHitLocation;
        HitNormal = WorldHitNormal;
        return Other;
    }
}

function TimeTravel(float delta)
{
    local PawnCollisionCopy PCC;

    if(NewNet_LinkGun(Weapon).M == none)
        foreach Weapon.DynamicActors(class'MutUTComp',NewNet_LinkGun(Weapon).M)
            break;

    for(PCC = NewNet_LinkGun(Weapon).M.PCC; PCC!=None; PCC=PCC.Next)
        PCC.TimeTravelPawn(Delta);
}

function UnTimeTravel()
{
    local PawnCollisionCopy PCC;
    //Now, lets turn off the old hits
    for(PCC = NewNet_LinkGun(Weapon).M.PCC; PCC!=None; PCC=PCC.Next)
        PCC.TurnOffCollision();
}


DefaultProperties
{

}
