// Copyright (c) 2007-2023 Eliot van Uytfanghe. All rights reserved.
class EmoticonsReplicationInfo extends ReplicationInfo
    dependson(Emoticons);

// Emoticons that have been replicated to the client.
var array<Emoticons.sSmileyMessageType> Smileys;
// Copy of Smileys[i].Event, kept in step with Smileys. FindNextSmile scans this
// instead of Smileys, because reading a member of a struct in an array copies the
// whole struct (including its string) on every access.
var array<string> Events;

var Emoticons EmoteActor;
var transient int nextIndex;
var transient float SendTimer;
var int TotalSmileys; // Number of smileys in Emoticons.ini

// Client-side cache of strings already split into text/emoticon runs (see
// GetParsedText). Searching every Smileys entry is expensive with hundreds of
// emoticons, and the HUD, scoreboards and overlay redraw the same chat lines and
// player names every frame, so each distinct string is only searched once.
// Entries are reused objects (no garbage), hashed into buckets and LRU-evicted.
// The size must comfortably exceed the strings drawn per frame (scoreboard names
// + overlay names + chat lines + typing prompt) or LRU will thrash.
const PARSE_CACHE_SIZE = 128;
var transient array<EmoticonsParsedText> ParseCache;
var transient EmoticonsParsedText ParseCacheHead[64]; // hash buckets; keep GetParsedText's mask in sync
var transient int ParseCacheClock;

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
	Events[i] = event;
	Smileys[i].Icon = Texture(DynamicLoadObject(icon, Class'Texture', true));

	// Not an icon then try if its an material icon.
	if (Smileys[i].Icon == none) {
		Smileys[i].MatIcon = Material(DynamicLoadObject(matIcon, Class'Material', true));
    }

	// Cached parses were made without this emoticon.
	FlushParseCache();
}

// Returns S split into text runs and emoticon icons, parsing it only on the
// first request (or after it has been evicted / the cache was flushed).
simulated function EmoticonsParsedText GetParsedText(string S)
{
	local int L, b;
	local EmoticonsParsedText P;

	L = Len(S);
	b = (L * 31 + Asc(S)) & 63;
	for (P = ParseCacheHead[b]; P != None; P = P.NextInBucket)
	{
		if (P.SourceLen == L && P.Source == S)
		{
			P.LastUsed = ++ParseCacheClock;
			return P;
		}
	}

	P = AllocParsedText();
	P.Source = S;
	P.SourceLen = L;
	P.Bucket = b;
	P.NextInBucket = ParseCacheHead[b];
	ParseCacheHead[b] = P;
	P.LastUsed = ++ParseCacheClock;
	ParseText(P, S);
	return P;
}

// Returns an unlinked cache entry: a new one while the cache is filling,
// otherwise the least recently used one.
simulated function EmoticonsParsedText AllocParsedText()
{
	local int i, oldest;
	local EmoticonsParsedText P, Q;

	if (ParseCache.Length < PARSE_CACHE_SIZE)
	{
		P = new class'EmoticonsParsedText';
		ParseCache[ParseCache.Length] = P;
		return P;
	}

	oldest = 0;
	for (i = 1; i < ParseCache.Length; i++)
	{
		if (ParseCache[i].LastUsed < ParseCache[oldest].LastUsed)
			oldest = i;
	}
	P = ParseCache[oldest];

	// Unlink from its bucket (flushed entries are no longer in any bucket).
	if (ParseCacheHead[P.Bucket] == P)
		ParseCacheHead[P.Bucket] = P.NextInBucket;
	else
	{
		for (Q = ParseCacheHead[P.Bucket]; Q != None; Q = Q.NextInBucket)
		{
			if (Q.NextInBucket == P)
			{
				Q.NextInBucket = P.NextInBucket;
				break;
			}
		}
	}
	P.NextInBucket = None;
	return P;
}

// Invalidates every cached parse, keeping the entry objects for reuse.
simulated function FlushParseCache()
{
	local int i;

	for (i = 0; i < ArrayCount(ParseCacheHead); i++)
		ParseCacheHead[i] = None;

	for (i = 0; i < ParseCache.Length; i++)
	{
		ParseCache[i].SourceLen = -1;
		ParseCache[i].LastUsed = 0; // evict these first
		ParseCache[i].NextInBucket = None;
	}
}

// Splits S into P's text runs and icons.
simulated function ParseText(EmoticonsParsedText P, string S)
{
	local int i, n, k, matchLen;
	local string D;

	P.Texts.Length = 0;
	P.VisTexts.Length = 0;
	P.IconTex.Length = 0;
	P.IconMat.Length = 0;

	i = FindNextSmile(S, n, matchLen);
	// matchLen guard: an empty Event would otherwise match forever.
	while (i != -1 && matchLen > 0)
	{
		D = Left(S, i);
		S = Mid(S, i + matchLen);
		P.Texts[k] = D;
		P.VisTexts[k] = StripColorForTTS(D);
		P.IconTex[k] = Smileys[n].Icon;
		P.IconMat[k] = Smileys[n].MatIcon;
		k++;
		i = FindNextSmile(S, n, matchLen);
	}
	P.Texts[k] = S;
	P.VisTexts[k] = StripColorForTTS(S);
}

// Borrowed from AssaultPlus by Marco a.k.a .:..:
simulated function string StripColorForTTS( string s )
{
	local int p;

	p = InStr(s,chr(27));
	while ( p>=0 )
	{
		s = left(s,p)$mid(S,p+4);
		p = InStr(s,Chr(27));
	}
	return s;
}

// Borrowed from AssaultPlus by Marco a.k.a .:..:, reworked to be color-code
// aware without per-character scanning. We strip color codes to a visible-only
// copy and match with the native InStr, then map the visible hit back to a raw
// offset. Stripping first means an event can never false-match inside a color
// code's RGB bytes, and the raw mapping still spans any color codes interspersed
// within the event (multicolor names like "=dart" that get a code between every
// letter). MatchLen is the raw length consumed in S so the caller advances past
// the whole matched region. This scans every entry in Events, so it is only called
// when parsing a string into the cache, never per frame.
simulated function int FindNextSmile( string S, optional out int SmileNr, optional out int MatchLen )
{
	local string vis;
	local int i,j,p,bp,rawStart;

	j = Events.Length;

	// Fast path: no color codes present. Match on the raw string with the native
	// InStr and no string allocations.
	if( InStr(S, Chr(27)) == -1 )
	{
		bp = -1;
		for( i = 0; i < j; i++ )
		{
			p = InStr( S, Events[i] );
			if( p != -1 && (bp == -1 || p < bp) )
			{
				bp = p;
				SmileNr = i;
			}
		}
		if( bp != -1 )
			MatchLen = Len(Events[SmileNr]);
		return bp;
	}

	// Slow path: color codes present. Strip to a visible-only copy so events
	// can't false-match inside a code, match, then map the hit back to a raw
	// offset (spanning any codes interspersed within the event).
	vis = StripColorForTTS(S);
	bp = -1;
	for( i = 0; i < j; i++ )
	{
		p = InStr( vis, Events[i] );
		if( p != -1 && (bp == -1 || p < bp) )
		{
			bp = p;
			SmileNr = i;
		}
	}
	if( bp == -1 )
		return -1;

	rawStart = VisibleToRaw( S, bp );
	MatchLen = VisibleToRaw( S, bp + Len(Events[SmileNr]) ) - rawStart;
	return rawStart;
}

// Maps an index in the color-code-stripped (visible) string back to the raw
// index in S, accounting for color codes (Chr(27) + 3 bytes) skipped along the way.
simulated function int VisibleToRaw( string S, int VisibleIndex )
{
	local int raw,p;

	raw = 0;
	p = InStr( Mid(S,raw), Chr(27) );
	while( p != -1 && VisibleIndex > p )
	{
		VisibleIndex -= p;
		raw += p + 4;
		p = InStr( Mid(S,raw), Chr(27) );
	}
	return raw + VisibleIndex;
}

defaultproperties
{
     bOnlyRelevantToOwner=True
//	 NetUpdateFrequency=200 // Emote replication fails at high tick rate so this is required
//	 NetPriority=3.0
}