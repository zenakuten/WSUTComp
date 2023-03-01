

class UTComp_LinkFire extends LinkFire;

var UTComp_ServerReplicationInfo RepInfo;
var int VehicleHealScore;
var int NodeHealBonusPct;
var bool bNodeHealBonusForLockedNodes;
var bool bNodeHealBonusForConstructor;

var float totalBonus;

event ModeDoFire()
{
    local UTComp_PRI uPRI;
    if(weapon.owner.IsA('xPawn') && xPawn(Weapon.Owner).Controller!=None)
    {
        uPRI=class'UTComp_Util'.static.GetUTCompPRIFor(xPawn(Weapon.Owner).Controller);
        if(uPRI!=None)
            uPRI.NormalWepStatsAlt[9]+=1;
    }
    Super.ModeDoFire();
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if(UTComp_LinkGun(Weapon) != none)
        RepInfo = UTComp_LinkGun(Weapon).GetRepInfo();

    if(RepInfo != None)
    {
        VehicleHealScore=RepInfo.VehicleHealScore;
        NodeHealBonusPct=RepInfo.NodeHealBonusPct;
        bNodeHealBonusForLockedNodes=RepInfo.bNodeHealBonusForLockedNodes;
        bNodeHealBonusForConstructor=RepInfo.bNodeHealBonusForConstructor;
    }
}

//ONSPlus

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
	local int AdjustedDamage, i;
    local float DamageAmount;
	local LinkBeamEffect LB;
	local DestroyableObjective HealObjective;
	local Vehicle LinkedVehicle;
    local int score;
    local ONSPowerNode Node;

	if (!bIsFiring)
	{
		bInitAimError = true;
		return;
	}

	if (Weapon != none)
		LinkGun = UTComp_LinkGun(Weapon);

	if (LinkGun.Links < 0)
	{
		Log("warning:"@Instigator@"linkgun had"@LinkGun.Links@"links");
		LinkGun.Links = 0;
	}

	ls = LinkScale[Min(LinkGun.Links, 5)];

	// Clean out the lockingpawns list
	for (i=0; i<LinkGun.LockingPawns.Length; i++)
		if (LinkGun.LockingPawns[i] == none)
			LinkGun.LockingPawns.Remove(i, 1);

	if (myHasAmmo(LinkGun) && (UpTime > 0.0 || Instigator.Role < ROLE_Authority))
	{
		UpTime -= dt;

		// the to-hit trace always starts right in front of the eye
		LinkGun.GetViewAxes(X, Y, Z);
		StartTrace = GetFireStart(X, Y, Z);
		TraceRange = default.TraceRange + LinkGun.Links * 250;

		if (Instigator.Role < ROLE_Authority)
		{
			if (Beam == None && Weapon != none)
			{
				foreach Weapon.DynamicActors(class'LinkBeamEffect', LB)
				{
					if (!LB.bDeleteMe && LB.Instigator != None && LB.Instigator == Instigator)
					{
						Beam = LB;
						break;
					}
				}
			}

			if (Beam != None)
				LockedPawn = Beam.LinkedPawn;
		}

		if (LockedPawn != None)
			TraceRange *= 1.5;

		if (Instigator.Role == ROLE_Authority)
		{
			if (bDoHit)
				LinkGun.ConsumeAmmo(ThisModeNum, AmmoPerFire);

			B = Bot(Instigator.Controller);

			if (B != None && PlayerController(B.Squad.SquadLeader) != None && B.Squad.SquadLeader.Pawn != None)
			{
				if (IsLinkable(B.Squad.SquadLeader.Pawn) && B.Squad.SquadLeader.Pawn.Weapon != None && B.Squad.SquadLeader.Pawn.Weapon.GetFireMode(1).bIsFiring
					&& VSize(B.Squad.SquadLeader.Pawn.Location - StartTrace) < TraceRange)
				{
					if (Weapon != none)
						Other = Weapon.Trace(HitLocation, HitNormal, B.Squad.SquadLeader.Pawn.Location, StartTrace, true);

					if (Other == B.Squad.SquadLeader.Pawn)
					{
						B.Focus = B.Squad.SquadLeader.Pawn;

						if (B.Focus != LockedPawn)
							SetLinkTo(B.Squad.SquadLeader.Pawn);

						B.SetRotation(Rotator(B.Focus.Location - StartTrace));
 						X = Normal(B.Focus.Location - StartTrace);
 					}
 					else if (B.Focus == B.Squad.SquadLeader.Pawn)
						bShouldStop = true;
				}
 				else if (B.Focus == B.Squad.SquadLeader.Pawn)
					bShouldStop = true;
			}
		}

		if (LockedPawn != None)
		{
			EndTrace = LockedPawn.Location + LockedPawn.BaseEyeHeight * Vect(0,0,0.5); // beam ends at approx gun height

			if (Instigator.Role == ROLE_Authority)
			{
				V = Normal(EndTrace - StartTrace);

				if (V dot X < LinkFlexibility || LockedPawn.Health <= 0 || LockedPawn.bDeleteMe || VSize(EndTrace - StartTrace) > 1.5 * TraceRange)
					SetLinkTo(None);
			}
		}

		if (LockedPawn == None)
		{
			if (Bot(Instigator.Controller) != None)
			{
				if (bInitAimError)
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

				if (DesiredAimError.Yaw ClockWiseFrom CurrentAimError.Yaw)
				{
					CurrentAimError.Yaw += Step;

					if (!(DesiredAimError.Yaw ClockWiseFrom CurrentAimError.Yaw))
					{
						CurrentAimError.Yaw = DesiredAimError.Yaw;
						DesiredAimError = AdjustAim(StartTrace, AimError);
					}
				}
				else
				{
					CurrentAimError.Yaw -= Step;

					if (DesiredAimError.Yaw ClockWiseFrom CurrentAimError.Yaw)
					{
						CurrentAimError.Yaw = DesiredAimError.Yaw;
						DesiredAimError = AdjustAim(StartTrace, AimError);
					}
				}

				CurrentAimError.Yaw = CurrentAimError.Yaw - Instigator.Rotation.Yaw;

				if (BoundError())
					DesiredAimError = AdjustAim(StartTrace, AimError);

				CurrentAimError.Yaw = CurrentAimError.Yaw + Instigator.Rotation.Yaw;

				if (Instigator.Controller.Target == None)
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

		if (Weapon != none)
			Other = Weapon.Trace(HitLocation, HitNormal, EndTrace, StartTrace, true);

		if (Other != None && Other != Instigator)
			EndEffect = HitLocation;
		else
			EndEffect = EndTrace;

		if (Beam != None)
			Beam.EndEffect = EndEffect;

		if (Instigator.Role < ROLE_Authority)
		{
			if (LinkGun.ThirdPersonActor != None)
			{
				if (LinkGun.Linking || (Other != None && Instigator.PlayerReplicationInfo.Team != None && Other.TeamLink(Instigator.PlayerReplicationInfo.Team.TeamIndex)))
				{
					if (Instigator.PlayerReplicationInfo.Team == None || Instigator.PlayerReplicationInfo.Team.TeamIndex == 0)
						LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor(LC_Red);
					else
						LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor(LC_Blue);
				}
				else
				{
					if (LinkGun.Links > 0)
						LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor(LC_Gold);
					else
						LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor(LC_Green);
				}
			}

			return;
		}

		if (Other != None && Other != Instigator)
		{
			// target can be linked to
			if (IsLinkable(Other))
			{
				if (Other != lockedpawn)
					SetLinkTo(Pawn(Other));

				if (lockedpawn != None)
					LinkBreakTime = LinkBreakDelay;
			}
			else
			{
				// stop linking
				if (lockedpawn != None)
				{
					if (LinkBreakTime <= 0.0)
						SetLinkTo(None);
					else
						LinkBreakTime -= dt;
				}

				// beam is updated every frame, but damage is only done based on the firing rate
				if (bDoHit)
				{
					if (Beam != None)
						Beam.bLockedOn = false;

					Instigator.MakeNoise(1.0);

					AdjustedDamage = AdjustLinkDamage(LinkGun, Other, Damage);

					if (!Other.bWorldGeometry)
					{
						if (Level.Game.bTeamGame && Pawn(Other) != None && Pawn(Other).PlayerReplicationInfo != None
							&& Pawn(Other).PlayerReplicationInfo.Team == Instigator.PlayerReplicationInfo.Team) // even if friendly fire is on you can't hurt teammates
							AdjustedDamage = 0;

						HealObjective = DestroyableObjective(Other);

						if (HealObjective == None)
							HealObjective = DestroyableObjective(Other.Owner);



						if (HealObjective != None && HealObjective.TeamLink(Instigator.GetTeamNum()))
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
						//else if (HealObjective != None && OPGRI != none && OPGRI.bNodeHealScoreFix)
						else if (HealObjective != None)
						{
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
                            Other.TakeDamage(AdjustedDamage, Instigator, HitLocation, MomentumTransfer * X, DamageType);
						}

						if (Beam != None)
							Beam.bLockedOn = true;
					}
				}
			}
		}

		// vehicle healing
		LinkedVehicle = Vehicle(LockedPawn);

		if (LinkedVehicle != None && bDoHit)
		{
			AdjustedDamage = Damage * (1.5 * Linkgun.Links + 1) * Instigator.DamageScaling;

			if (Instigator.HasUDamage())
				AdjustedDamage *= 2;

			if (!LinkedVehicle.HealDamage(AdjustedDamage / (LinkGun.LockingPawns.Length + 1), Instigator.Controller, DamageType))
				LinkGun.ConsumeAmmo(ThisModeNum, -AmmoPerFire);
			else
            {
                score = 1;
                if(LinkedVehicle.default.Health >= VehicleHealScore)
                    score = LinkedVehicle.default.Health / VehicleHealScore;
                 DamageAmount = (AdjustedDamage/1.5)/(LinkGun.LockingPawns.Length+1);

                if (ONSPlayerReplicationInfo(Instigator.Controller.PlayerReplicationInfo) != None && !LinkedVehicle.IsVehicleEmpty())
                    ONSPlayerReplicationInfo(Instigator.Controller.PlayerReplicationInfo).AddHealBonus(DamageAmount / LinkedVehicle.default.Health * score);

				for (i=0; i<LinkGun.LockingPawns.Length; i++)
                {
					if(LinkedVehicle.HealDamage(AdjustedDamage / (LinkGun.LockingPawns.Length + 1), LinkGun.LockingPawns[i].Controller, DamageType))
                    {
                        //if (OPGRI != None && OPGRI.bVehicleHealScoreFix && ONSPlayerReplicationInfo(LinkGun.LockingPawns[i].Controller.PlayerReplicationInfo) != None && !LinkedVehicle.IsVehicleEmpty())
                        if (ONSPlayerReplicationInfo(LinkGun.LockingPawns[i].Controller.PlayerReplicationInfo) != None && !LinkedVehicle.IsVehicleEmpty())
                            ONSPlayerReplicationInfo(LinkGun.LockingPawns[i].Controller.PlayerReplicationInfo).AddHealBonus(DamageAmount / LinkedVehicle.default.Health * score);
                    }
                }
            }
		}

		if (Weapon != none)
			LinkGun(Weapon).Linking = LockedPawn != None || bIsHealingObjective;

		if (bShouldStop)
		{
			B.StopFiring();
		}
		else
		{
			// beam effect is created and destroyed when firing starts and stops
			if (Beam == None && bIsFiring)
			{
				if (Weapon != none)
					Beam = Weapon.Spawn(BeamEffectClass, Instigator);

				// vary link volume to make sure it gets replicated (in case owning player changed it client side)
				if (SentLinkVolume == Default.LinkVolume)
					SentLinkVolume = Default.LinkVolume + 1;
				else
					SentLinkVolume = Default.LinkVolume;
			}

			if (Beam != None)
			{
				if (LinkGun.Linking || (Other != None && Instigator.PlayerReplicationInfo.Team != None && Other.TeamLink(Instigator.PlayerReplicationInfo.Team.TeamIndex)))
				{
					Beam.LinkColor = Instigator.PlayerReplicationInfo.Team.TeamIndex + 1;

					if (LinkGun.ThirdPersonActor != None)
					{
						if (Instigator.PlayerReplicationInfo.Team == None || Instigator.PlayerReplicationInfo.Team.TeamIndex == 0)
							LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor(LC_Red);
						else
							LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor(LC_Blue);
					}
				}
				else
				{
					Beam.LinkColor = 0;

					if (LinkGun.ThirdPersonActor != None)
					{
						if (LinkGun.Links > 0)
							LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor(LC_Gold);
						else
							LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor(LC_Green);
					}
				}

				Beam.Links = LinkGun.Links;
				Instigator.AmbientSound = BeamSounds[Min(Beam.Links, 3)];
				Instigator.SoundVolume = SentLinkVolume;
				Beam.LinkedPawn = LockedPawn;
				Beam.bHitSomething = Other != None;
				Beam.EndEffect = EndEffect;
			}
		}
	}
	else
	{
		StopFiring();
	}

	bStartFire = false;
	bDoHit = false;
}

simulated function bool ShouldGetHealBonus(Controller controller, ONSPowerNode node)
{
    if(controller == none || node == none)
        return false;

    if(controller == node.Constructor && !bNodeHealBonusForConstructor)
        return false;

    return true;    
}

function bool AddLink(int Size, Pawn Starter)
{
	local Inventory Inv;

	if (LockedPawn != None && !bFeedbackDeath)
	{
		if (LockedPawn == Starter)
		{
			return false;
		}
		else
		{
			Inv = LockedPawn.FindInventoryType(class'UTComp_LinkGun');

			if (Inv != None)
			{
				if (LinkFire(LinkGun(Inv).GetFireMode(1)).AddLink(Size, Starter))
				{
					LinkGun(Inv).Links += Size;

					if (Weapon != None && Weapon.Owner != None && Pawn(Weapon.Owner) != None)
					{
						UTComp_LinkGun(Weapon).LockingPawns[UTComp_LinkGun(Weapon).LockingPawns.Length] = Pawn(Weapon.Owner);

						UTComp_LinkGun(Inv).LockingPawns = UTComp_LinkGun(Weapon).LockingPawns;

						UTComp_LinkGun(Weapon).LockingPawns.Length = 0;
					}
				}
				else
				{
					return false;
				}
			}
		}
	}

	return true;
}

function SetLinkTo(Pawn Other)
{
	if (LockedPawn != None && Weapon != None)
	{
		RemoveLinkPlus(1 + LinkGun(Weapon).Links, Instigator, Pawn(Weapon.Owner));
		LinkGun(Weapon).Linking = false;
	}

	LockedPawn = Other;

	if (Weapon != none && LockedPawn != None)
	{
		if (!AddLink(1 + LinkGun(Weapon).Links, Instigator))
			bFeedbackDeath = true;

		LinkGun(Weapon).Linking = true;

		LockedPawn.PlaySound(MakeLinkSound, SLOT_None);
	}
}

function RemoveLinkPlus(int Size, Pawn Starter, Pawn LostLinker)
{
	local Inventory Inv;
	local int i;

	if (Weapon != none && Weapon.Owner != LostLinker)
	{
		for (i=0; i<UTComp_LinkGun(Weapon).LockingPawns.Length; i++)
		{
			if (UTComp_LinkGun(Weapon).LockingPawns[i] == LostLinker)
			{
				UTComp_LinkGun(Weapon).LockingPawns.Remove(i, 1);
				i--;
			}
		}
	}

	if (LockedPawn != None && !bFeedbackDeath)
	{
		if (LockedPawn != Starter)
		{
			Inv = LockedPawn.FindInventoryType(class'UTComp_LinkGun');

			if (Inv != None)
			{
				UTComp_LinkFire(UTComp_LinkGun(Inv).GetFireMode(1)).RemoveLinkPlus(Size, Starter, LostLinker);
				LinkGun(Inv).Links -= Size;
			}
		}
	}
}
//END ONSPlus

defaultproperties
{
    VehicleHealScore=500
}
