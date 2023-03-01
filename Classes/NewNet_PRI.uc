/*
UTComp - UT2004 Mutator
Copyright (C) 2004-2005 Aaron Everitt & Jo�l Moffatt

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

replication
{
    reliable if(Role<Role_Authority)
        Ping;
    reliable if(Role == Role_Authority && bNetOwner)
        Pong;
}

simulated function PostBeginPlay()
{
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
}

simulated function Ping()
{
    Pong();
}

simulated function Pong()
{
    bPingReceived = true;
    PredictedPing = (2.0*PredictedPing + (Level.TimeSeconds - PingSendTime))/PingTweenTime;
    default.predictedping=predictedping;
    numPings++;
    if(NumPings < 8)
        default.PredictedPing = (Level.TimeSeconds - PingSendTime);
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
     PingTweenTime=3.0
}
