class TeamColorManager extends Object;

// skin colors go from 0-100?
static function byte cscale(byte in)
{
    return byte(float(in)/100.0*255.0);
}

static function byte GetTeamNum(Controller InstigatorController, LevelInfo Level)
{
    local Controller LocalController;
    if(Level != None && Level.GRI != None)
    {
        if(Level.GRI.bTeamGame)
        {
            if(InstigatorController != None)
            {
                return InstigatorController.GetTeamNum();
            }
        }
        else
        {
            // for single player game, player is red team, enemy is blue team
            LocalController = Level.GetLocalPlayerController();
            if(LocalController == InstigatorController)
                return 0;
            else
                return 1;
        }
    }

    return 255;
}

static function Color GetColor(int TeamNum, PlayerController PC)
{
    local Color retval;
    local int PlayerTeam;
    local UTComp_Settings Settings;

    if(PC == None)
        return retval;

    PlayerTeam = PC.GetTeamNum();
    if(BS_xPlayer(PC) != None)
    {
        Settings = BS_xPlayer(PC).Settings;
    }
    
    if(TeamNum == 0)
        retval = Settings.TeamColorRed;
    else
        retval = Settings.TeamColorBlue;

    if(!Settings.bTeamColorUseTeam)
    {
        if(TeamNum == PlayerTeam)
        {
            //blue or ally
            retval = Settings.TeamColorBlue;
        }
        else
        {
            //red or enemy
            retval = Settings.TeamColorRed;
        }
    }

    return retval;
}

static function byte GetHue(Color c)
{
    local float cmin,cmax, hue;
    local int red,green,blue;

    red=c.R;
    green=c.G;
    blue=c.B;

    cmin = min(min(red, green), blue);
    cmax = max(max(red, green), blue);

    if (cmin == cmax) {
        return 0;
    }

    hue = 0;
    if (cmax == red) {
        hue = (green - blue) / (cmax - cmin);

    } else if (cmax == green) {
        hue = 2f + (blue - red) / (cmax - cmin);

    } else {
        hue = 4f + (red - green) / (cmax - cmin);
    }

    hue = hue * 42.5;
    if (hue < 0) hue = hue + 255;

    hue= round(hue);
    return hue;
}

defaultproperties
{
}