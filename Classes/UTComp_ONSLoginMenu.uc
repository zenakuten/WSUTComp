Class UTComp_ONSLoginMenu extends UT2k4OnslaughtLoginMenu;

function InitComponent(GUIController MyController, GUIComponent MyComponent)
{
    log("UTComp_OnsLoginMenu - init component");
	// Moved from defaultproperties so I can easily recompile the package with a different packagename
	OnslaughtMapPanel.ClassName = string(Class'UTComp_TabOnslaughtMap');

	Super.InitComponent(MyController, MyComponent);
}

function AddPanels()
{
    log("UTComp_OnsLoginMenu - add panels");
	Panels.Insert(0,1);
	Panels[0] = OnslaughtMapPanel;
	Panels[1].ClassName = string(Class'UTComp_TabPlayerLoginControls');//"ONSPlus.ONSPlusTab_PlayerLoginControls";
    //Panels[1].ClassName = "GUI2K4.UT2K4Tab_PlayerLoginControlsOnslaught";

	Super(UT2k4PlayerLoginMenu).AddPanels();
}

defaultProperties
{
	OnslaughtMapPanel=(/*ClassName="ONSPlus.ONSPlusTab_OnslaughtMap",*/Caption="Map",Hint="Map of the area")
}