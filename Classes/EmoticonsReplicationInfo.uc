// Copyright (c) 2007-2023 Eliot van Uytfanghe. All rights reserved. 
class EmoticonsReplicationInfo extends ReplicationInfo
    dependson(Emoticons);

// Emoticons that have been replicated to the client.
var array<Emoticons.sSmileyMessageType> Smileys;

var Emoticons EmoteActor;
var transient int nextIndex;
var float SendTimer; // For throttled sending approach

replication
{
	unreliable if (Role == ROLE_Authority) // unreliable is necessary here otherwise it fails at high tick rate
		ClientAddEmoticon;
}

// Send Smileys to client.
event Tick(float deltaTime)
{
	if (Owner == none) {
		Destroy();
		return;
	}

	if (nextIndex == EmoteActor.Smileys.Length) {
        // bTearOff = true;
        Disable('Tick');
		return;
    }

//  Unthrottled sending approach, not recommended
//	ClientAddEmoticon(EmoteActor.Smileys[nextIndex].Event, string(EmoteActor.Smileys[nextIndex].Icon), string(EmoteActor.Smileys[nextIndex].MatIcon));
//	nextIndex ++;

	// Throttled sending approach (e.g. thousand[s] of emotes)
	SendTimer += deltaTime;
	// Limit to 33 sends per second to be safe
	if (SendTimer > 0.03) 
	{
		SendTimer = 0;
		ClientAddEmoticon(EmoteActor.Smileys[nextIndex].Event, string(EmoteActor.Smileys[nextIndex].Icon), string(EmoteActor.Smileys[nextIndex].MatIcon));
		nextIndex ++;
	}
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
//     NetUpdateFrequency=500 // Emote replication fails at high tick rate so this is required
}
