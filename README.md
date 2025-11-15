# WSUTComp

Wicked Sick UTComp, based on [UTCompOmni 1.71](https://github.com/zenakuten/UTCompOmni)


Release Notes

V17
- fix channel leak when controllers join/leave

V16
- emote menu improvements
- fix floating/ghost players appearing in some ONS games

V15
- fix bug where custom skins didn't work
- add bullseye award, get hs kill with center (0.25*r) hit  

V14
- Add starting health, armor as options
- show tick rate in server info
- cleanup webadmin 
- revert moving server configs to own file
- fix bug where you received awards for shooting dead bodies
- revert 1.7a flak primary change and use 1.8c deaod fix 
- fix the extra countdown at warmup end

V13
- Fix bug where sometimes you cant set spawn protected bright skin for teammates
- Change 'from downtown' award to eagleeye
- Better support for foxwsfix (dodge issue)

V12
- Fix setting/changing scoreboard types bug
- Add reset skins button to bright skins menu
- Add feature to allow team radar
- Add feature to allow minimap team radar (ONS)
- Add feature to allow mutant style team radar
- Load default weapon configs (crosshairs, etc) on new version of utcomp
- Add airsnot, torpedo, EagleEye, shredded awards

V11
- Fix some stats carrying over from warmup
- Fix rare bug where weapons won't fire in TAM/Freon

V10
- Fix ONS node score offset when score >= 100
- Add option to show kills instead of net on UTComp scoreboard
- Fix bug when switching weapons while rocket launcher alt fire is active
- Fix bug where custom hitsounds didn't load correctly
- Fix bug where shock beam doesn't always render
- Fix bug in ONS minimap where vehicle dots had wrong color/info in randomizers
- Move server configuration to its own file
- Fix some log spamming bugs

V9
- Fix custom stats like OLStats not working for ONS game type

V8
- Fix headshotted config not working
- Fix brightskin on dead body
- Add 'fast ghost' option to make dead turn to ghost immediately
- Add 'color ghost' option to allow configure ghost colors

V7
- hit sounds/indicators for spectators spectating a vehicle
- hit sounds/indicators for spectators on node damage
- Add award sounds for 'air rocket', 'impressive combo'
- Add sound when you get headshotted 

V6
- Fix bug with bright skins when switching teams
- new feature 'Limit taunts', limit the number of voice taunts allowed (default off)
- cosmetic UI updates
- fix log spamming 'accessed None 'Game''
- add utcompomni ONS scoreboard
- add color names on HUD setting
- use utcomp 1.7a netcode for flak
- fix flak hitsound on powernodes
- fix flak hitsound for spectators
- add award sounds for air rocket, impressive combo

V5
- Really fix damage indicators
- Fix issue with timestamp_controller getting clobbered end of round / end of game
- add > 2K resolution fix for overlay

V4
- fix friendly fire damage indicators
- fix negative damage indicators
- Add alternate MoveErrorAccum algorithm, default disabled.  
- Add more knobs for movement (gliding movement, NetMoveDelta, MaxSavedMoves, MaxResponseTime, MoveErrorAccum) 
- move movement config to separate config section
- Add missing NetMoveDelta, MaxSavedMoves to WebAdmin
- fix negative damage showing when changing view target
- fix negative damage not showing when doing friendly fire
- add config bChargedWeaponsNoSpawnProtection to disable spawn protection when charging rox, bio
- fix flak primary/secondary visual showing too many/wrong shards

V3 
- Fix 'Use UTComp style gliding movement' logic, was backwards
- Fix damage indicators for vehicles
- Add damage indicators for power nodes
- Add checkbox to enable / disable view smoothing when using new eyeheight algorithm
- Fix issue with no view smoothing in new eyeheight algoritm when landing shake was enabled
- Add option to disable team from knocking you around
- Add option to disable team from knocking you around in a vehicle
- Fix kick momentum for avril when online
- disable dynamic netspeed
- Add NetMoveDelta config 
- Add MaxSavedMoves config to webadmin

V2
- add kokuei's SSR fixes
- add spawn protected bright skin option for teammates
- update default damage indicator from disabled to centered
- increase max netspeed to 1000000
- remove wormbo's utplus assault grenade causing glitches
- fix flak primary having unreg on non-pawns (powernode, etc)
- fix 'use' not working (enter vehicle, powernode warp, etc)

V1
- add spawn protected bright skin option
- fix grouped hit sounds for flak
- add server control for colored weapon config
- support warmup for non standard game modes (e.g. tam/freon)
- add hint text to gui
- fix issue with wrong skin color
- remove utcomp movement, superceded by warping fix
- use newnet SSR when using XGame.MutInstagib
- settings cleanup
- make fast weap switch configurable
- hit sounds for spectators
- make all settings available in config for single and multiplayer game
- code cleanup
- gui style update


WSUTComp fork

UTCompOmni

1.71
- Fix F5 'extra' menu button

1.70
- add client side config for emoticons

1.69
- add emoticons
- fix SSR not spawning

1.68
- fix potential crash from color weapons

1.67
- add the *real* fix for unregs issue in second round for ONS and AS game types.

1.66
- Scoreboard updates for various gametypes (thanks pooty!)

1.65
- fix a bug with teamcolorbio spamming the logs

1.64
- add some code to try and fix the unregs issue after first round.

1.63
- Actually use MaxSavedMoves (oops)
- Add fix for player sounds not playing when they are out of view (thanks kokuei!)

1.62
- Fix F5 not working after code clean up broke stuff.
- Add MaxSavedMoves config option for rubberbanding issue, lower default value from 750 to 350

1.61
- Fix for rubberbanding when there is high fps or high ping (thanks kokuei!)

1.60
- remove package name refs

1.59
- fix vehicle health display bug when health > 999

1.58
- Add team color weapons
- Add widescreen fixes
- Add damage indicators

1.57
 - ? pooty! :)

1.56
- Limit vehicle points to damage actually done

1.55
- Remove custom RoundEnded and GameEnded player states from ONSPlus, use defaults instead

1.54
- copy most stuff from ceonss 1.38 version that doesn't have unreg issue, including - 
- remove bAlwaysRelvant change from 1.53 (didn't fix anything)
- remove NetUpdateMaxNetSpeed option (didnt' fix anything)
- remove recent flak cannon changes (didnt' fix anything)
- remove recent PawnCollisionCopy changes (didn't fix anything)
- clean up checkendgame logic in utcomp_gamerules
- clean up netdamage logic in utcomp_onsgamerules (but keep pooty fixes)


1.53
- use bAlwaysRelevant for UTComp_xPawn

1.52
- New config value NetUpdateMaxNetSpeed.  This limits the netspeed used when calculating player movements.  Default is 10000 (default UT max net speed for > 16 players) 

1.51
- revert an old change I made to pawncollisioncopy

1.50
- revert changes for fix attempt of unregs after first round.  linkgun was not linking players

1.49
- another fix attempt for flak primary unregs on nodes.  this one seems to work finally

1.48
- attempt to fix unregs happening after first round

1.47
- another fix attempt for flak primary unregs on nodes

1.46
- Add whois context menu

1.40-1.45 - crash fix attempts, crash fixed in 1.45 (thx pooty!)

1.39
- Change CheckScore function to use while loop instead of for loop to avoid possible None reference.

1.38
- Add whitelist feature.  

New config values:
   bUseWhitelist=False
   bEnableWhitelist=False
   WhitelistBanMessage=Not allowed.  Contact the server administrator to gain access

If 'bEnableWhitelist' is true, white list GUI is enabled.  Admins will see a new Admin button in UTComp F5 menu.  Admins can turn on/off the whitelist.  Default is false.

If 'bUseWhitelist' is true, white list is enabled.  Only players with matching PlayerIDs are allowed into the game.  Default is false.

Banned players will see an auto kicked message when they try to join the server.  Change WhitelistBanMessage accordingly.  

The white list is an ini file called 'UTComp_Whitelist.ini' in the System folder.  

[UTCompOmni.UTComp_Whitelist]
WhitelistEntry=PlayerID1
WhitelistEntry=PlayerID2
WhitelistEntry=PlayerID3
etc...


1.37
- Add PawnCollisionHistoryLength config option.  This is used to determine how much time travel history is recorded when back tracking collision detection for enhanced net code.  Default is 0.35 seconds.

1.36
- Fix UTComp scoreboard showing for spectators that have it turned off
- Fix for ESC menu for non ONS game types

1.35
- Fix 'Accessed None "C"' in CheckScore function which was possibly breaking EvenMatchOmni custom scoring
- cleanup some logs

1.34
- Add bSilentAdmin config value. When set, don't show 'ADMIN' string in scoreboard.  Default is true.  


1.33
- Add 'PingTweenTime' to server config.  Default is 3.0. Higher values place less load on the server

1.32
- unselect show utcomps stats when selecting default scoreboard
- default show stats to false
- fix mult colored names on ESC -> Scoreboard 

1.31
- fix spectate context menu not working
- fix preferred exit not working online
- re-enable utcomp scoreboard (default is off, limited to 16 players)
- default enhanced netcode to false
- remove 'playOwnFootsteps' checkbox (never worked)

1.30
- Fix bug where hitsounds on nodes didn't always work with vehicles
- Add 'spectate' context menu 

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