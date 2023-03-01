class UTComp_Whitelist extends Object 
    config(UTComp_Whitelist) 
    PerObjectConfig;

// list of playerIdHashes allowed in
var config array<string> WhitelistEntry;

defaultproperties
{
    WhitelistEntry(0)=""
}