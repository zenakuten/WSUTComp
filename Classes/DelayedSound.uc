class DelayedSound extends Info;

var Sound SoundToPlay;
var PlayerController PC;
var float Atten;

function Timer()
{
    if(PC != None && SoundToPlay != None)
    {
        if(PC.ViewTarget != None)
            PC.ClientPlaySound(SoundToPlay, true, Atten);
        else
            PC.PlayOwnedSound(SoundToPlay, SLOT_Pain, Atten,,,,false);    
    }

}

defaultproperties
{
    bHidden=true
    Atten=1.0
}