class UTComp_Whitelist extends Object 
    config(WSUTComp_Whitelist) 
    PerObjectConfig;

// list of playerIdHashes allowed in
var config array<string> WhitelistEntry;

defaultproperties
{
    WhitelistEntry(0)=""
}