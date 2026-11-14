

class UTComp_InWarmupMessage extends LocalMessage;

// Switch 1 removes a shown warmup message (BS_xPlayer.NotifyEndWarmup). The class is
// bIsUnique, so HudBase.LocalizedMessage puts it in the shown message's slot, and with
// a zero lifetime DisplayLocalMessages culls it before anything is drawn.
static function float GetLifeTime(int Switch)
{
    if(Switch==1)
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
      if(Switch==1)
          return "";
      if(OptionalObject!=None && PlayerController(OptionalObject)!=None && class'GameInfo'.Static.GetKeyBindName("mymenu", PlayerController(OptionalObject))!= "mymenu")
          return class'GameInfo'.static.MakeColorCode(class'Hud'.default.WhiteColor)$"You are in warmup, press '"$class'GameInfo'.static.MakeColorCode(class'Hud'.default.GoldColor)$class'GameInfo'.Static.GetKeyBindName("mymenu", PlayerController(OptionalObject))$class'GameInfo'.static.MakeColorCode(class'Hud'.default.WhiteColor)$"' to ready up.";
      else
          return class'GameInfo'.static.MakeColorCode(class'Hud'.default.WhiteColor)$"You are in warmup, type "$class'GameInfo'.static.MakeColorCode(class'Hud'.default.GoldColor)$"'ready'"$class'GameInfo'.static.MakeColorCode(class'Hud'.default.WhiteColor)$" in the console to ready up";
}

DefaultProperties
{
      bIsUnique=True
      bIsConsoleMessage=False
      bFadeMessage=True
      LifeTime=4
      StackMode=SM_Down
      PosY=0.92
      FontSize=-2
}
