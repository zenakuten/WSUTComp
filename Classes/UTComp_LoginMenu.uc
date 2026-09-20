// Standard login/mid-game menu with our own join/spectate panel.
Class UTComp_LoginMenu extends UT2K4PlayerLoginMenu;

function AddPanels()
{
    Panels[0].ClassName = string(Class'UTComp_TabPlayerLoginControlsStd');
    Super.AddPanels();
}

defaultproperties
{
}
