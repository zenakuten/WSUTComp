WSUTComp and WS3SPN new config files


All server configuration stored in `UT2004.ini` for these has been moved.  These changes should make it easier to copy UTComp/3SPN configuration between servers by copying the relevant ini files.  


Anything related to WSUTComp is now stored in `WSUTComp_Server.ini`
Anything related to WSUTCompWeaponConfig is now stored in `WSUTCompWeaponConfig.ini`
Anything related to WS3SPN is now stored in `WS3SPN_Server.ini`

`statsext.ini` has been moved to `WS3SPN_Stats.ini`
`statsextfreon.ini` has been moved to `WS3SPN_StatsFreon.ini`


Migration steps

1. Copy any sections starting with `[WSUTCompWeaponConfig` to `WSUTCompWeaponConfig.ini` 
2. Copy any sections starting with `[WSUTComp` to `WSUTComp_Server.ini` 
3. Copy any sections starting with `[WS3SPN` to `WS3SPN_Server.ini` 
4. Rename `statsext.ini` to `WS3SPN_Stats.ini`
5. Rename `statsextfreon.ini` to `WS3SPN_StatsFreon.ini`
6. Copy an sections from `MapLimits3SPNCW.ini` to `WS3SPN_Server.ini` (if it exists)


Cleanup after migration

It's not required but recommended to remove any of the sections copied above from your `UT2004.ini` file, to avoid any confusion on where this config is coming from.