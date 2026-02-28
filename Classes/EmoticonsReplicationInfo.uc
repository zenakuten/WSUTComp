// Copyright (c) 2007-2023 Eliot van Uytfanghe. All rights reserved.
class EmoticonsReplicationInfo extends ReplicationInfo
    dependson(Emoticons);

// Emoticons that have been replicated to the client.
var array<Emoticons.sSmileyMessageType> Smileys;

var Emoticons EmoteActor;
var transient int nextIndex;
var transient float SendTimer;
var int TotalSmileys; // Number of smileys in Emoticons.ini

replication
{
    // Replicate the total smiley count to the client
    reliable if (bNetInitial && Role == ROLE_Authority)
        TotalSmileys;

	reliable if (Role == ROLE_Authority)
		ClientAddEmoticon;
}

// Send Smileys to client.
event Tick(float deltaTime)
{
	if (Owner == none) {
		Destroy();
		return;
	}

	// Get Smileys array size from Emoticons.ini
    if (TotalSmileys == 0 && EmoteActor != None) {
        TotalSmileys = EmoteActor.Smileys.Length;
    }

	// Wait a few seconds before sending emotes to account for the initial replication burst.
	// 3369 64bit has extremely slow storage performance which fucks the replication;
	// 3369 32bit doesn't suffer from this issue.
	if (nextIndex == 0) {
		SendTimer += deltaTime;
		if (SendTimer < 5.0) {
			return;
		}
	}

	// Stop ticking once we've sent everything
	if (nextIndex == EmoteActor.Smileys.Length) {
        bTearOff = true; // Stop replication
        Disable('Tick');
		//NetUpdateFrequency = 1;
		return;
    }

	// Unthrottled sending approach
	ClientAddEmoticon(EmoteActor.Smileys[nextIndex].Event, string(EmoteActor.Smileys[nextIndex].Icon), string(EmoteActor.Smileys[nextIndex].MatIcon));
	nextIndex ++;

/*
	// Throttled sending approach (this caused an issue where trying to join mid-game would essentially lock you until loading was complete, probably due to UTComp_xPawn.PointOfView()
	SendTimer += deltaTime;
	// Limit to 33 sends per second to be safe
	if (SendTimer > 0.03)
	{
		SendTimer = 0;
		ClientAddEmoticon(EmoteActor.Smileys[nextIndex].Event, string(EmoteActor.Smileys[nextIndex].Icon), string(EmoteActor.Smileys[nextIndex].MatIcon));
		nextIndex ++;
	}
*/
}

// Add a smiley on the client array.
simulated function ClientAddEmoticon(string event, string icon, string matIcon)
{
	local int i;

	i = Smileys.Length;
	Smileys.Length = i + 1;
	Smileys[i].Event = event;
	Smileys[i].Icon = Texture(DynamicLoadObject(icon, Class'Texture', true));

	// Not an icon then try if its an material icon.
	if (Smileys[i].Icon == none) {
		Smileys[i].MatIcon = Material(DynamicLoadObject(matIcon, Class'Material', true));
    }
}

defaultproperties
{
     bOnlyRelevantToOwner=True
//	 NetUpdateFrequency=200 // Emote replication fails at high tick rate so this is required
//	 NetPriority=3.0
}