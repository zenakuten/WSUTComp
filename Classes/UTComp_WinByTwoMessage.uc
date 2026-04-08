// UTComp_WinByTwoMessage.uc
// HUD center message for win-by-two deuce situations.
// Switch 0 = "Must win by two!"
// Extends CriticalEventPlus so it renders centre-screen, not in chat.

class UTComp_WinByTwoMessage extends CriticalEventPlus;

var() localized string MustWinByTwo;

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    return default.MustWinByTwo;
}

DefaultProperties
{
    MustWinByTwo="Must win by two!"
    DrawColor=(R=255,G=200,B=0)
    StackMode=SM_Down
    PosY=0.400000
    FontSize=1
    bIsConsoleMessage=False
}
