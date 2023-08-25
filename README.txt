UTCompOmni - Omnipotents version of UTComp 

Server installation

Copy these folders to the UT2004 folder:

Sounds\
StaticMeshes\
Textures\
System\


The original UTComp help file is in the Help\ folder

Snarf's recommended settings for Omnipotents 2.0 server are in the UT2004.ini file.  
Copy all contents of this file to the bottom of the server's UT2004.ini file.

Clients/players can hit F5 during gameplay to set their own settings (turn off hit sounds, change brightskins, etc).


A list of ignored hit sounds is also in the UT2004.ini file.

To add more sounds to ignore, add a new line with the damage type of the sound to ignore, e.g.

IgnoredHitSounds=FireKill
IgnoredHitSounds=DamTypeChargingBeam    


This would ignore the fire burning of firetank and beam weapon of the hell bender.  

Release Info

1.29
- Add 'SetPreferredExit' command (from ONSPlus) for vehicles
- Make vehicle radar colors configurable

To use SetPreferredExit, you'll need to bind a key to it and combine with the use command, e.g.

in User.ini - 
Q=SetPreferredExit Left 1 | Use
E=SetPreferredExit Right 1 | Use

This would make 'E' exit to the right and 'Q' exit to the left.

Vehicle radar colors can be configured in UTCompOmni.ini file

Here are the defaults:

[UTCompOmni.UTComp_ONSHudOnslaught]
VehicleData=(Name="Minotaur",RadarColor=(B=255,G=255,R=255,A=255))
VehicleData=(Name="Omnitaur",RadarColor=(B=255,G=255,R=255,A=255))
VehicleData=(Name="Badgertaur",RadarColor=(B=255,G=255,R=255,A=255))
VehicleData=(Name="ONSHoverTank",RadarColor=(B=128,G=0,R=128,A=255))
VehicleData=(Name="ONSHoverBike",RadarColor=(B=0,G=128,R=0,A=255))
VehicleData=(Name="ONSAttackCraft",RadarColor=(B=0,G=128,R=128,A=255))
VehicleData=(Name="ONSDualAttackCraft",RadarColor=(B=0,G=128,R=128,A=255))
VehicleData=(Name="ONSPRV",RadarColor=(B=128,G=128,R=0,A=255))
VehicleData=(Name="ONSRV",RadarColor=(B=32,G=32,R=0,A=255))


1.28
- revert changes for enemy based skins so they work again, add more ONS friendly default instead
- if new net is enabled, use old net code when shooting a flak cannon at a node up close, which would have unreg hits previously

1.27
- Fix crashing issue with collision on vehicles
- Fix bug where automatic netspeed didn't work online

1.26
- Fix bug where hit sounds for nodes didn't work online
- Fix bug where hitscan hits against occupied vehicles didn't always work

1.25
- Add damage points for vehicles, default VehicleDamagePoints is 400 health=1 point
- Show vehicle name on map when you hover over the dot
- Hit sounds for nodes


1.24
- Fix bug where linking didn't work on link vehicles with server setting enhancednet=true
- Fix bug where fast movement such as doding may not have worked with server setting enhancednet=true
- If client netspeed is > 10000, automatically set netspeed for client
- Remove bAlwaysRelevant flag for UTComp_xPawn to reduce net load

1.23
- Fix bug where AVRiL launchers were littering the map when player died holding the avril
- Fix performance issue (2ms) with projectiles when newnet=true on the server

1.22
- Fix issue where server setting bEnableEnhancedNet=false did not work
- Fix linkgun not linking vehicles with server setting bEnableEnhancedNet=true
- Change default client setting for bEnableEnhancedNet to be false.  Players must opt-in instead of opt-out. (Server setting must be true for client setting to take affect.)
- Remove all code related to Forward mutator
- Remove all code related to warmups

1.21
- remove changes from 1.19 and 1.20 and fix crashing issue caused by PawnCollisionCopy on vehicles. TODO Verify this change does not cause more unreg hits on vehicles

1.20
 - add bGameRelevant=true flag to PawnCollisionCopy class 
 - add override for PreBeginPlay event for PawnCollisionCopy class

1.19
- Add override for 'alwayskeep' function that was showing in logs after crash

1.18
- Add config value bNodeHealBonusForConstructor.  If true, player starting the node gets NodeHealBonusPct when linking.  Default is false.  
- yet another attempt at fix team color issue caused by evenmatch shuffling teams at round start

1.17
- Multipy NodeHealBonusPct by 2 to match what we expect from scoring (linking only gives 50% of score)
- Fix bug where first person linking receive all the bonus (oops)

1.16
- Show correct power core at end of game
- remove ready/notready/coach buttons for ONS games
- another attempt at fix team color issue

1.15
- fix issue in 1.14 that broke custom scoring from other mutators, like EvenMatchOmni
- fix issue where bNodeHealBonusForLockedNodes was ignored for dedicated servers

1.14
- fix players running around after game ended
- add new config value bNodeHealBonusForLockedNodes.  This turns on the node heal bonus for locked nodes.  Default is false.

1.13 
- fix for team color issue

1.12
- Fix bonus pct for linkers
- add possible? fix for hitsound issue

1.11
- Add new config value NodeHealBonusPct, give extra points for healing nodes, default is 60 percent of node score, so a node score of 5 would give 3 (60% of 5) extra points.
- Update minimap radar colors to be darker, add black outline to make them more visible
- Make minotaur, omnitaur and badgertaur minimap color white so they stand out
- Add new config value NewNetUpdateFrequency, this is the frequency of the new net code update rate, the default is 200.  Lowering this value may help with lag issues.  It may also throw off the aim calculation? (untested)

1.10
- Merge all features we want from ONSPlusOmni into UTCompOmni
- ONSPlus features include 
  - Node isolation bonus for severing nodes (default is 20% of node points)
  - Draw vehicles on radar map
  - shared link bonus so multiple linkers get points
  - vehicle healing bonus, heal vehicle health and receive points (default is 1 point for 500 health)
- Draw different vehicles in different colors on the minimap, use smaller icon for manta and scoprion types
- Add config option for changing PowerNode and PowerCore points (defaults are 5 for node and 10 for core (ONS defaults))
- Included UT2004.ini file updated with new values
- fix issue where teleport was not working
- fix issue where dodge was not working

1.9 
- Fix issue where team change kept wrong team color.  bEnemyBasedSkins ands bEnemyBasedModels are hard coded now.  Changing gui values has no effect. 
- Fix issue where ONSPlusOmni HUD conflicted with UTComp HUD
- Default to bright skins


1.8c 
- Initial Release






