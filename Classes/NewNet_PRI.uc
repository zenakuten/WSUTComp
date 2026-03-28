/*
UTComp - UT2004 Mutator
Copyright (C) 2004-2005 Aaron Everitt & Joel Moffatt

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/
class NewNet_PRI extends LinkedReplicationInfo;

var float PredictedPing;
var float PingSendTime;
var bool bPingReceived;
var int numPings;
var UTComp_ServerReplicationInfo RepInfo;

var float PingTweenTime;

// Sliding window ping measurement
const PING_WINDOW_SIZE = 5;
const MAX_PING = 0.150;           // 150ms cap
const SPIKE_REJECT_MULT = 2.5;    // reject samples > 2.5x current median
var float PingWindow[5];           // circular buffer of recent RTT samples
var int PingWindowIdx;             // next write position
var int PingWindowCount;           // how many valid samples we have (0..5)

replication
{
    reliable if(Role<Role_Authority)
        Ping;
    reliable if(Role == Role_Authority && bNetOwner)
        Pong;
}

simulated function PostBeginPlay()
{
    local int i;

    super.PostBeginPlay();

    if(RepInfo == None)
        ForEach DynamicActors(class'UTComp_ServerReplicationInfo', RepInfo)
            break;

    if(RepInfo != none)
    {
        if(RepInfo.NewNetUpdateFrequency > 0)
        {
            NetUpdateFrequency=RepInfo.NewNetUpdateFrequency;
        }

        if(RepInfo.PingTweenTime > 0)
        {
            PingTweenTime=RepInfo.PingTweenTime;
        }
    }

    // Initialize window to zero
    for(i = 0; i < PING_WINDOW_SIZE; i++)
        PingWindow[i] = 0.0;
    PingWindowIdx = 0;
    PingWindowCount = 0;
}

simulated function Ping()
{
    Pong();
}

simulated function Pong()
{
    local float RawPing;
    local float CurrentMedian;

    bPingReceived = true;
    RawPing = Level.TimeSeconds - PingSendTime;

    // Cap at max ping
    if(RawPing > MAX_PING)
        RawPing = MAX_PING;

    // Spike rejection: if we have enough samples, reject wild outliers
    if(PingWindowCount >= 3)
    {
        CurrentMedian = GetMedianPing();
        if(CurrentMedian > 0.005 && RawPing > CurrentMedian * SPIKE_REJECT_MULT)
            RawPing = CurrentMedian;  // clamp spike to current median
    }

    // Write into circular buffer
    PingWindow[PingWindowIdx] = RawPing;
    PingWindowIdx = (PingWindowIdx + 1) % PING_WINDOW_SIZE;
    if(PingWindowCount < PING_WINDOW_SIZE)
        PingWindowCount++;

    numPings++;

    // Use median for stability — converges in ~2.5s (5 samples x 0.5s)
    PredictedPing = GetMedianPing();
    default.PredictedPing = PredictedPing;
}

// Sort-free median of up to 5 samples using pairwise comparisons
simulated function float GetMedianPing()
{
    local float A, B, C, D, E, Tmp;

    if(PingWindowCount <= 0)
        return 0.0;
    if(PingWindowCount == 1)
        return PingWindow[0];
    if(PingWindowCount == 2)
        return (PingWindow[0] + PingWindow[1]) * 0.5;

    // For 3+ samples, do a partial sort to find the median
    // Copy valid samples into locals
    A = PingWindow[0];
    B = PingWindow[1];
    C = PingWindow[2];

    if(PingWindowCount == 3)
    {
        // Median of 3: sort and return middle
        if(A > B) { Tmp = A; A = B; B = Tmp; }
        if(B > C) { Tmp = B; B = C; C = Tmp; }
        if(A > B) { Tmp = A; A = B; B = Tmp; }
        return B;
    }

    D = PingWindow[3];

    if(PingWindowCount == 4)
    {
        // Median of 4: average of 2nd and 3rd
        if(A > B) { Tmp = A; A = B; B = Tmp; }
        if(C > D) { Tmp = C; C = D; D = Tmp; }
        if(A > C) { Tmp = A; A = C; C = Tmp; }
        if(B > D) { Tmp = B; B = D; D = Tmp; }
        if(B > C) { Tmp = B; B = C; C = Tmp; }
        return (B + C) * 0.5;
    }

    // Median of 5
    E = PingWindow[4];
    // Sorting network for 5 elements — find the 3rd smallest
    if(A > B) { Tmp = A; A = B; B = Tmp; }
    if(C > D) { Tmp = C; C = D; D = Tmp; }
    if(A > C) { Tmp = A; A = C; C = Tmp; Tmp = B; B = D; D = Tmp; }
    // Now A <= C, A is smallest of {A,B,C,D}. E is unsorted.
    if(B > E) { Tmp = B; B = E; E = Tmp; }
    if(B > C) { Tmp = B; B = C; C = Tmp; }
    if(D > E) { Tmp = D; D = E; E = Tmp; }
    if(C > D) { Tmp = C; C = D; D = Tmp; }
    return C;
}

simulated function Tick(float deltatime)
{
    super.Tick(deltatime);
    if(Level.NetMode!=NM_Client)
        return;
    if(bPingReceived && Level.TimeSeconds > PingSendTime + PingTweenTime)
    {
        PingSendTime = Level.TimeSeconds;
        bPingReceived = false;
        Ping();
    }
}

defaultproperties
{
     bPingReceived=True
     NetUpdateFrequency=200.000000
     NetPriority=5.000000
     PingTweenTime=0.5
}
