

class UTComp_Warmup_CountDown extends CriticalEventPlus;

var name CountDown[10];

// Switch 0 removes the number still on screen when the match starts
// (BS_xPlayer.NotifyEndWarmup). The class is bIsUnique (CriticalEventPlus), so
// HudBase.LocalizedMessage puts it in the shown number's slot, and with a zero
// lifetime DisplayLocalMessages culls it before anything is drawn.
static function float GetLifeTime(int Switch)
{
    if(Switch==0)
        return 0.0;
    return default.LifeTime;
}

static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
    if(Switch==0)
        return "";
    return string(Switch);
}

static simulated function ClientReceive(
	PlayerController P,
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
    // Was Switch<9, which left "ten" and "nine" silent.
    if(Switch>0 && Switch<=ArrayCount(default.CountDown))
        P.QueueAnnouncement( default.CountDown[Switch-1], 1, AP_InstantOrQueueSwitch, 1 );
    super.ClientReceive(P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
}

defaultproperties
{
     CountDown(0)="one"
     CountDown(1)="two"
     CountDown(2)="three"
     CountDown(3)="four"
     CountDown(4)="five"
     CountDown(5)="six"
     CountDown(6)="seven"
     CountDown(7)="eight"
     CountDown(8)="nine"
     CountDown(9)="ten"
}
