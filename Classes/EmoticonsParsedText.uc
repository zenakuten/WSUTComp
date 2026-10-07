// A string pre-split into text runs and emoticon icons. Built once per string by
// EmoticonsReplicationInfo.GetParsedText and reused every frame, so drawing chat,
// death messages and player names doesn't re-search every Smileys entry per frame.
//
// Layout: icon i is drawn after Texts[i]. Texts has one more entry than the icon
// arrays; its last entry is the text trailing the final icon.
class EmoticonsParsedText extends Object;

// Cache bookkeeping (owned by EmoticonsReplicationInfo).
var string Source;
var int SourceLen;                      // -1 = flushed, never matches a lookup
var int LastUsed;                       // LRU stamp
var int Bucket;
var EmoticonsParsedText NextInBucket;

var array<string> Texts;
var array<string> VisTexts;             // Texts with color codes stripped, for StrLen
var array<Texture> IconTex;
var array<Material> IconMat;            // used when IconTex[i] is None
