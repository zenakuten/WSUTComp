//-----------------------------------------------------------
// Server-only child of each public voice channel (MutUTComp.bSpectatorVoiceChat)
//-----------------------------------------------------------
// Membership is one bit per VoiceID in a 32-bit mask (3369 servers wrap IDs past 31 to 0; 3374
// servers keep counting and the shift uses VoiceID & 31). Stock VoiceChatRoom.ValidMask() is
// GetMask() > 0, so once anyone on bit 31 joins a channel (32+ players, spectators and bots), its
// mask goes negative and UnrealChatRoom.IsMember() is false for everyone for the rest of the map.
// Players still get team chat through bLargeGameVOIP's team check; spectators have no team.
// The native router (UVoiceChannel::AllowVoiceTransmission) calls IsMember() with cascading, which
// asks the channel's children, so this answers by the member bit alone.
class UTComp_SpecVoiceMaskFix extends VoiceChatRoom;

simulated event bool IsMember(PlayerReplicationInfo PRI, optional bool bNoCascade)
{
    return Parent != None && PRI != None && bool(Parent.GetMask() & (1 << (PRI.VoiceID & 31)));
}
