class UTComp_Menu_HUD extends UTComp_Menu_MainMenu;

var automated wsCheckBox ch_EnableMapTeamRadar;
var automated wsCheckBox ch_EnableTeamRadar;
var automated GUILabel radar, radarVehicle, radarR, radarG, radarB, radarA, radarVehicleR, radarVehicleG, radarVehicleB, radarVehicleA;
var automated GUISlider radarRSlide, radarGSlide, radarBSlide, radarASlide, radarVehicleRSlide, radarVehicleGSlide, radarVehicleBSlide, radarVehicleASlide;
var automated GUILabel radarMapScaleLabel, radarMapAlphaLabel, radarMapXLabel, radarMapYLabel;
var automated GUISlider radarMapScaleSlide, radarMapAlphaSlide, radarMapXSlide, radarMapYSlide;

// Live preview dudes drawn to the right of the through-wall color sliders. They render
// as wireframe/colored silhouettes in the radar color, matching the in-game through-wall
// effect (DrawTeamRadar in _HudCommon.uci), so they track the sliders in real time.
var automated GUIImage i_PlayerPreview, i_VehiclePreview;
var UTComp_SpinnyWeap SpinnyPlayer, SpinnyVehicle;
var vector SpinnyOffset;
var Engine UEngine;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    super.InitComponent(MyController, MyOwner);

    ch_EnableMapTeamRadar.Checked(HUDSettings.bEnableMapTeamRadar);
    ch_EnableTeamRadar.Checked(HUDSettings.bEnableTeamRadar);
    MatchSlidersToColors();
    MatchTextToSliders();

    if(!CanUseTeamRadar())
    {
        ch_EnableTeamRadar.DisableMe();
        ch_EnableTeamRadar.SetHint("Server disabled");
        radar.Hide(); 
        radarVehicle.Hide(); 
        radarR.Hide();
        radarG.Hide();
        radarB.Hide();
        radarA.Hide();
        radarVehicleR.Hide();
        radarVehicleG.Hide();
        radarVehicleB.Hide();
        radarVehicleA.Hide();
        radarRSlide.Hide();
        radarGSlide.Hide();
        radarBSlide.Hide();
        radarASlide.Hide();
        radarVehicleRSlide.Hide();
        radarVehicleGSlide.Hide();
        radarVehicleBSlide.Hide();
        radarVehicleASlide.Hide();
        i_PlayerPreview.Hide();
        i_VehiclePreview.Hide();
    }

    if(!CanUseTeamRadarMap())
    {
        ch_EnableMapTeamRadar.DisableMe();
        ch_EnableMapTeamRadar.SetHint("Server disabled");
        radarMapScaleLabel.Hide();
        radarMapScaleSlide.Hide();
        radarMapAlphaLabel.Hide();
        radarMapAlphaSlide.Hide();
        radarMapXLabel.Hide();
        radarMapXSlide.Hide();
        radarMapYLabel.Hide();
        radarMapYSlide.Hide();
    }
}



event Opened(GUIComponent sender)
{
    ch_EnableMapTeamRadar.Checked(HUDSettings.bEnableMapTeamRadar);
    ch_EnableTeamRadar.Checked(HUDSettings.bEnableTeamRadar);
    MatchSlidersToColors();
    MatchTextToSliders();
    InitSpinnies();

    super.Opened(sender);
}

simulated function bool CanUseTeamRadar()
{
    local UTComp_ServerReplicationInfo RepInfo;

    RepInfo = BS_xPlayer(PlayerOwner()).RepInfo;
    if(RepInfo != None)
        return RepInfo.bAllowTeamRadar;

    return false;
}

simulated function bool CanUseTeamRadarMap()
{
    local UTComp_ServerReplicationInfo RepInfo;

    RepInfo = BS_xPlayer(PlayerOwner()).RepInfo;
    if(RepInfo != None)
        return RepInfo.bAllowTeamRadarMap;

    return false;
}

function InternalOnChange( GUIComponent C )
{
    switch(C)
    {
        case ch_EnableMapTeamRadar: HUDSettings.bEnableMapTeamRadar=ch_EnableMapTeamRadar.IsChecked(); 
            break;

        case ch_EnableTeamRadar: HUDSettings.bEnableTeamRadar=ch_EnableTeamRadar.IsChecked(); 
            break;

        case radarRSlide: HUDSettings.TeamRadarPlayer.R = radarRSlide.Value;
            MatchTextToSliders();
            break;

        case radarGSlide: HUDSettings.TeamRadarPlayer.G = radarGSlide.Value;
            MatchTextToSliders();
            break;

        case radarBSlide: HUDSettings.TeamRadarPlayer.B = radarBSlide.Value;
            MatchTextToSliders();
            break;

        case radarASlide: HUDSettings.TeamRadarPlayer.A = radarASlide.Value;
            MatchTextToSliders();
            break;

        case radarVehicleRSlide: HUDSettings.TeamRadarVehicle.R = radarVehicleRSlide.Value;
            MatchTextToSliders();
            break;

        case radarVehicleGSlide: HUDSettings.TeamRadarVehicle.G = radarVehicleGSlide.Value;
            MatchTextToSliders();
            break;

        case radarVehicleBSlide: HUDSettings.TeamRadarVehicle.B = radarVehicleBSlide.Value;
            MatchTextToSliders();
            break;

        case radarVehicleASlide: HUDSettings.TeamRadarVehicle.A = radarVehicleASlide.Value;
            MatchTextToSliders();
            break;

        case radarMapScaleSlide: HUDSettings.MapTeamRadarScale = radarMapScaleSlide.Value;
            break;

        case radarMapAlphaSlide: HUDSettings.MapTeamRadarAlpha = radarMapAlphaSlide.Value;
            break;

        case radarMapXSlide: HUDSettings.MapTeamRadarX = radarMapXSlide.Value;
            break;

        case radarMapYSlide: HUDSettings.MapTeamRadarY = radarMapYSlide.Value;
            break;
    }

    SaveSettings();
    SaveHUDSettings();
}

// Live preview while dragging a color slider: recolor the label text as the slider
// moves. The config save is deferred to release (InternalOnChange).
function OnSlide( GUIComponent C )
{
    switch(C)
    {
        case radarRSlide: HUDSettings.TeamRadarPlayer.R = radarRSlide.Value; MatchTextToSliders(); break;
        case radarGSlide: HUDSettings.TeamRadarPlayer.G = radarGSlide.Value; MatchTextToSliders(); break;
        case radarBSlide: HUDSettings.TeamRadarPlayer.B = radarBSlide.Value; MatchTextToSliders(); break;
        case radarASlide: HUDSettings.TeamRadarPlayer.A = radarASlide.Value; MatchTextToSliders(); break;

        case radarVehicleRSlide: HUDSettings.TeamRadarVehicle.R = radarVehicleRSlide.Value; MatchTextToSliders(); break;
        case radarVehicleGSlide: HUDSettings.TeamRadarVehicle.G = radarVehicleGSlide.Value; MatchTextToSliders(); break;
        case radarVehicleBSlide: HUDSettings.TeamRadarVehicle.B = radarVehicleBSlide.Value; MatchTextToSliders(); break;
        case radarVehicleASlide: HUDSettings.TeamRadarVehicle.A = radarVehicleASlide.Value; MatchTextToSliders(); break;
    }
}

function MatchSlidersToColors()
{
    radarRSlide.Value = HUDSettings.TeamRadarPlayer.R;
    radarGSlide.Value = HUDSettings.TeamRadarPlayer.G;
    radarBSlide.Value = HUDSettings.TeamRadarPlayer.B;
    radarASlide.Value = HUDSettings.TeamRadarPlayer.B;

    radarVehicleRSlide.Value = HUDSettings.TeamRadarVehicle.R;
    radarVehicleGSlide.Value = HUDSettings.TeamRadarVehicle.G;
    radarVehicleBSlide.Value = HUDSettings.TeamRadarVehicle.B;
    radarVehicleASlide.Value = HUDSettings.TeamRadarVehicle.B;

    radarMapScaleSlide.Value = HUDSettings.MapTeamRadarScale;
    radarMapAlphaSlide.Value = HUDSettings.MapTeamRadarAlpha;
    radarMapXSlide.Value = HUDSettings.MapTeamRadarX;
    radarMapYSlide.Value = HUDSettings.MapTeamRadarY;
}

function MatchTextToSliders()
{
    radar.TextColor = HUDSettings.TeamRadarPlayer;
    radarVehicle.TextColor = HUDSettings.TeamRadarVehicle;
}

// ---- through-wall color preview dudes ----

function InitSpinnies()
{
    local xUtil.PlayerRecord Rec;

    if(PlayerOwner().PlayerReplicationInfo != None)
        Rec = class'xutil'.static.FindPlayerRecord(PlayerOwner().PlayerReplicationInfo.CharacterName);
    else
        Rec = class'xutil'.static.FindPlayerRecord("Gorge");

    SpinnyPlayer  = SpawnDude(SpinnyPlayer);
    SpinnyVehicle = SpawnDude(SpinnyVehicle);

    // Player preview: the player's own character. Vehicle preview: the PRV chassis mesh
    // (a real vehicle), with no idle anim (vehicles have none - draw in reference pose).
    // The vehicle mesh is much larger than a character, so it needs a smaller draw scale.
    LinkDude(SpinnyPlayer,  Rec.MeshName,               0.22, true);
    LinkDude(SpinnyVehicle, "ONSVehicles-A.PRVchassis", 0.13, false);
}

function UTComp_SpinnyWeap SpawnDude(UTComp_SpinnyWeap D)
{
    local vector X, Y, Z, X2, Y2, V;
    local rotator R2, R;

    if(D == None)
        D = PlayerOwner().Spawn(class'UTComp_SpinnyWeap');
    if(D != None)
    {
        D.SetDrawType(DT_Mesh);
        D.SpinRate = 4000;
        D.AmbientGlow = 45;
        // Hide from the world-scene pass so the dude doesn't render in the 3D viewport
        // behind the menu; DrawActorClipped renders it into the preview pane regardless.
        D.bHidden = true;

        R = PlayerOwner().Rotation;
        GetAxes(R, X, Y, Z);
        R2.Yaw = 32768;
        V = vector(R2);
        X2 = V.X*X + V.Y*Y;
        Y2 = V.X*Y - V.Y*X;
        R2 = OrthoRotation(X2, Y2, Z);
        D.SetRotation(R2);
    }
    return D;
}

function LinkDude(UTComp_SpinnyWeap Dude, string MeshName, float Scale, bool bLoopIdle)
{
    local Mesh M;

    if(Dude == None)
        return;

    Dude.SetDrawScale(Scale);

    M = Mesh(DynamicLoadObject(MeshName, class'Mesh'));
    if(M == None)
        return;

    Dude.LinkMesh(M);
    if(bLoopIdle)
        Dude.LoopAnim('Idle_Rest', 1.0/Dude.Level.TimeDilation);
}

function bool OnDrawPlayer(Canvas C)
{
    return DrawSpinnyTinted(C, SpinnyPlayer, i_PlayerPreview, HUDSettings.TeamRadarPlayer);
}

function bool OnDrawVehicle(Canvas C)
{
    return DrawSpinnyTinted(C, SpinnyVehicle, i_VehiclePreview, HUDSettings.TeamRadarVehicle);
}

// Draw the dude as a wireframe/colored silhouette in TintColor, exactly like the in-game
// through-wall render. C_AnimMesh (skeletal mesh) / C_BrushWire (weapon) are global engine
// colors, so save and restore them around the draw to avoid tinting other rendering.
function bool DrawSpinnyTinted(Canvas Canvas, UTComp_SpinnyWeap Dude, GUIImage Bounds, color TintColor)
{
    local vector CamPos, X, Y, Z;
    local rotator CamRot;
    local color oAnimMesh, oBrushWire;
    local float fov;

    if(Dude == None || Bounds == None || !Bounds.bVisible)
        return true;

    if(UEngine == None)
        foreach AllObjects(class'Engine', UEngine)
            break;
    if(UEngine == None)
        return true;

    Canvas.GetCameraLocation(CamPos, CamRot);
    GetAxes(CamRot, X, Y, Z);
    Dude.SetLocation(SpinnyPaneLoc(Canvas, Bounds, CamPos, X, Y, Z, SpinnyOffset.X, 15.0, fov));

    oAnimMesh  = UEngine.C_AnimMesh;
    oBrushWire = UEngine.C_BrushWire;
    UEngine.C_AnimMesh  = TintColor;
    UEngine.C_BrushWire = TintColor;

    // DrawActor (not DrawActorClipped) via the shared projection helper - avoids the
    // RI SetViewport side effect that drifted the focused control / tab buttons. Wireframe
    // stays on (the HUD previews render as wireframe player/vehicle).
    Canvas.DrawActor(Dude, true, true, fov);

    UEngine.C_AnimMesh  = oAnimMesh;
    UEngine.C_BrushWire = oBrushWire;

    return true;
}

function Free()
{
    Super.Free();
    if(SpinnyPlayer  != None) { SpinnyPlayer.Destroy();  SpinnyPlayer=None; }
    if(SpinnyVehicle != None) { SpinnyVehicle.Destroy(); SpinnyVehicle=None; }
}

defaultproperties
{
    ActiveMenuButton=5
    SpinnyOffset=(X=280.000000,Y=1.000000,Z=2.000000)

    Begin Object Class=GUIImage Name=PlayerPreviewImage
        Image=Material'2K4Menus.Controls.buttonSquare_b'
        ImageColor=(R=255,G=255,B=255,A=128)
        ImageRenderStyle=MSTY_Alpha
        ImageStyle=ISTY_Stretched
        bScaleToParent=true
        bBoundToParent=true
        WinWidth=0.190000
        WinHeight=0.170000
        WinLeft=0.325000
        WinTop=0.645000
        RenderWeight=0.52
        OnDraw=OnDrawPlayer
    End Object
    i_PlayerPreview=GUIImage'UTComp_Menu_HUD.PlayerPreviewImage'

    Begin Object Class=GUIImage Name=VehiclePreviewImage
        Image=Material'2K4Menus.Controls.buttonSquare_b'
        ImageColor=(R=255,G=255,B=255,A=128)
        ImageRenderStyle=MSTY_Alpha
        ImageStyle=ISTY_Stretched
        bScaleToParent=true
        bBoundToParent=true
        WinWidth=0.190000
        WinHeight=0.170000
        WinLeft=0.720000
        WinTop=0.645000
        RenderWeight=0.52
        OnDraw=OnDrawVehicle
    End Object
    i_VehiclePreview=GUIImage'UTComp_Menu_HUD.VehiclePreviewImage'

    Begin Object Class=wsCheckBox Name=EnableMapTeamRadarCheck
        Caption="Show teammates on the HUD or minimap"
        Hint="Show teammates as a dot on the HUD or minimap"
        OnCreateComponent=EnableMapTeamRadarCheck.InternalOnCreateComponent
        WinWidth=0.500000
        WinHeight=0.030000
        WinLeft=0.250000
        WinTop=0.300000
        OnChange=UTComp_Menu_HUD.InternalOnChange
    End Object
    ch_EnableMapTeamRadar=wsCheckBox'UTComp_Menu_HUD.EnableMapTeamRadarCheck'

    Begin Object Class=wsCheckBox Name=EnableTeamRadarCheck
        Caption="Show teammates through walls"
        Hint="Allows seeing teammates through walls"
        OnCreateComponent=EnableTeamRadarCheck.InternalOnCreateComponent
        WinWidth=0.500000
        WinHeight=0.030000
        WinLeft=0.250000
        WinTop=0.35
        OnChange=UTComp_Menu_HUD.InternalOnChange
    End Object
    ch_EnableTeamRadar=wsCheckBox'UTComp_Menu_HUD.EnableTeamRadarCheck'

    Begin Object Class=GUILabel Name=radarMapScaleSliderLabel
        Caption="Radar Scale"
        TextColor=(R=255,G=255,B=255)
        WinTop=0.40
        WinLeft=0.25
        WinHeight=20.000000
    End Object
    radarMapScaleLabel=GUILabel'UTComp_Menu_HUD.radarMapScaleSliderLabel'

    Begin Object Class=wsGUISlider Name=RadarMapScaleSlider
        bIntSlider=False
        WinTop=0.39500
        WinLeft=0.40000
        WinWidth=0.35000
        OnClick=RadarMapScaleSlider.InternalOnClick
        OnMousePressed=RadarMapScaleSlider.InternalOnMousePressed
        OnMouseRelease=RadarMapScaleSlider.InternalOnMouseRelease
        OnChange=UTComp_Menu_HUD.InternalOnChange
        OnKeyEvent=RadarMapScaleSlider.InternalOnKeyEvent
        OnCapturedMouseMove=RadarMapScaleSlider.InternalCapturedMouseMove
        MaxValue=2.0
    End Object
    radarMapScaleSlide=wsGUISlider'UTComp_Menu_HUD.RadarMapScaleSlider'

    Begin Object Class=GUILabel Name=radarMapAlphaSliderLabel
        Caption="Radar Alpha"
        TextColor=(R=255,G=255,B=255)
        WinTop=0.45
        WinLeft=0.25
        WinHeight=20.000000
    End Object
    radarMapAlphaLabel=GUILabel'UTComp_Menu_HUD.radarMapAlphaSliderLabel'

    Begin Object Class=wsGUISlider Name=RadarMapAlphaSlider
        bIntSlider=True
        WinTop=0.44500
        WinLeft=0.40000
        WinWidth=0.35000
        OnClick=RadarMapAlphaSlider.InternalOnClick
        OnMousePressed=RadarMapAlphaSlider.InternalOnMousePressed
        OnMouseRelease=RadarMapAlphaSlider.InternalOnMouseRelease
        OnChange=UTComp_Menu_HUD.InternalOnChange
        OnKeyEvent=RadarMapAlphaSlider.InternalOnKeyEvent
        OnCapturedMouseMove=RadarMapAlphaSlider.InternalCapturedMouseMove
        MaxValue=255
    End Object
    radarMapAlphaSlide=wsGUISlider'UTComp_Menu_HUD.RadarMapAlphaSlider'

    Begin Object Class=GUILabel Name=radarMapXSliderLabel
        Caption="Radar X"
        TextColor=(R=255,G=255,B=255)
        WinTop=0.50
        WinLeft=0.25
        WinHeight=20.000000
    End Object
    radarMapXLabel=GUILabel'UTComp_Menu_HUD.radarMapXSliderLabel'

    Begin Object Class=wsGUISlider Name=RadarMapXSlider
        bIntSlider=false
        WinTop=0.49500
        WinLeft=0.40000
        WinWidth=0.35000
        OnClick=RadarMapXSlider.InternalOnClick
        OnMousePressed=RadarMapXSlider.InternalOnMousePressed
        OnMouseRelease=RadarMapXSlider.InternalOnMouseRelease
        OnChange=UTComp_Menu_HUD.InternalOnChange
        OnKeyEvent=RadarMapXSlider.InternalOnKeyEvent
        OnCapturedMouseMove=RadarMapXSlider.InternalCapturedMouseMove
        MaxValue=1.0
    End Object
    radarMapXSlide=wsGUISlider'UTComp_Menu_HUD.RadarMapXSlider'

    Begin Object Class=GUILabel Name=radarMapYSliderLabel
        Caption="Radar Y"
        TextColor=(R=255,G=255,B=255)
        WinTop=0.55
        WinLeft=0.25
        WinHeight=20.000000
    End Object
    radarMapYLabel=GUILabel'UTComp_Menu_HUD.radarMapYSliderLabel'

    Begin Object Class=wsGUISlider Name=RadarMapYSlider
        bIntSlider=false
        WinTop=0.54500
        WinLeft=0.40000
        WinWidth=0.35000
        OnClick=RadarMapYSlider.InternalOnClick
        OnMousePressed=RadarMapYSlider.InternalOnMousePressed
        OnMouseRelease=RadarMapYSlider.InternalOnMouseRelease
        OnChange=UTComp_Menu_HUD.InternalOnChange
        OnKeyEvent=RadarMapYSlider.InternalOnKeyEvent
        OnCapturedMouseMove=RadarMapYSlider.InternalCapturedMouseMove
        MaxValue=1.0
    End Object
    radarMapYSlide=wsGUISlider'UTComp_Menu_HUD.RadarMapYSlider'

    /////////////////////

     Begin Object Class=wsGUISlider Name=RedRSlider
          FillImage=Texture'WSUTComp.GUI.WSSliderFillRed'
          StyleName="WSSliderKnobWhite"
         bIntSlider=True
         WinTop=0.6250000
         WinLeft=0.120000
         WinWidth=0.195000
         OnClick=RedRSlider.InternalOnClick
         OnMousePressed=RedRSlider.InternalOnMousePressed
         OnMouseRelease=RedRSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_HUD.InternalOnChange
         OnKeyEvent=RedRSlider.InternalOnKeyEvent
         OnCapturedMouseMove=RedRSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_HUD.OnSlide
         MaxValue=255
     End Object
     radarRSlide=wsGUISlider'UTComp_Menu_HUD.RedRSlider'

     Begin Object Class=wsGUISlider Name=RedGSlider
          FillImage=Texture'WSUTComp.GUI.WSSliderFillGreen'
          StyleName="WSSliderKnobWhite"
         bIntSlider=True
         WinTop=0.6750000
         WinLeft=0.120000
         WinWidth=0.195000
         OnClick=RedGSlider.InternalOnClick
         OnMousePressed=RedGSlider.InternalOnMousePressed
         OnMouseRelease=RedGSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_HUD.InternalOnChange
         OnKeyEvent=RedGSlider.InternalOnKeyEvent
         OnCapturedMouseMove=RedGSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_HUD.OnSlide
         MaxValue=255
     End Object
     radarGSlide=wsGUISlider'UTComp_Menu_HUD.RedGSlider'

     Begin Object Class=wsGUISlider Name=RedBSlider
          FillImage=Texture'WSUTComp.GUI.WSSliderFillBlue'
          StyleName="WSSliderKnobWhite"
         bIntSlider=True
         WinTop=0.7250000
         WinLeft=0.120000
         WinWidth=0.195000
         OnClick=RedBSlider.InternalOnClick
         OnMousePressed=RedBSlider.InternalOnMousePressed
         OnMouseRelease=RedBSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_HUD.InternalOnChange
         OnKeyEvent=RedBSlider.InternalOnKeyEvent
         OnCapturedMouseMove=RedBSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_HUD.OnSlide
         MaxValue=255
     End Object
     radarBSlide=wsGUISlider'UTComp_Menu_HUD.RedBSlider'

     Begin Object Class=wsGUISlider Name=RedASlider
         bIntSlider=True
         WinTop=0.7750000
         WinLeft=0.120000
         WinWidth=0.195000
         OnClick=RedASlider.InternalOnClick
         OnMousePressed=RedASlider.InternalOnMousePressed
         OnMouseRelease=RedASlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_HUD.InternalOnChange
         OnKeyEvent=RedBSlider.InternalOnKeyEvent
         OnCapturedMouseMove=RedASlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_HUD.OnSlide
         MaxValue=255
     End Object
     radarASlide=wsGUISlider'UTComp_Menu_HUD.RedASlider'

     Begin Object Class=wsGUISlider Name=BlueRSlider
          FillImage=Texture'WSUTComp.GUI.WSSliderFillRed'
          StyleName="WSSliderKnobWhite"
         bIntSlider=True
         WinTop=0.6250000
         WinLeft=0.5500000
         WinWidth=0.195000
         OnClick=BlueRSlider.InternalOnClick
         OnMousePressed=BlueRSlider.InternalOnMousePressed
         OnMouseRelease=BlueRSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_HUD.InternalOnChange
         OnKeyEvent=BlueRSlider.InternalOnKeyEvent
         OnCapturedMouseMove=BlueRSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_HUD.OnSlide
         MaxValue=255
     End Object
     radarVehicleRSlide=wsGUISlider'UTComp_Menu_HUD.BlueRSlider'

     Begin Object Class=wsGUISlider Name=BlueGSlider
          FillImage=Texture'WSUTComp.GUI.WSSliderFillGreen'
          StyleName="WSSliderKnobWhite"
         bIntSlider=True
         WinTop=0.6750000
         WinLeft=0.5500000
         WinWidth=0.195000
         OnClick=BlueGSlider.InternalOnClick
         OnMousePressed=BlueGSlider.InternalOnMousePressed
         OnMouseRelease=BlueGSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_HUD.InternalOnChange
         OnKeyEvent=BlueGSlider.InternalOnKeyEvent
         OnCapturedMouseMove=BlueGSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_HUD.OnSlide
         MaxValue=255
     End Object
     radarVehicleGSlide=wsGUISlider'UTComp_Menu_HUD.BlueGSlider'

     Begin Object Class=wsGUISlider Name=BlueBSlider
          FillImage=Texture'WSUTComp.GUI.WSSliderFillBlue'
          StyleName="WSSliderKnobWhite"
         bIntSlider=True
         WinTop=0.7250000
         WinLeft=0.550000
         WinWidth=0.195000
         OnClick=BlueBSlider.InternalOnClick
         OnMousePressed=BlueBSlider.InternalOnMousePressed
         OnMouseRelease=BlueBSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_HUD.InternalOnChange
         OnKeyEvent=BlueBSlider.InternalOnKeyEvent
         OnCapturedMouseMove=BlueBSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_HUD.OnSlide
         MaxValue=255
     End Object
     radarVehicleBSlide=wsGUISlider'UTComp_Menu_HUD.BlueBSlider'

     Begin Object Class=wsGUISlider Name=BlueASlider
         bIntSlider=True
         WinTop=0.7750000
         WinLeft=0.550000
         WinWidth=0.195000
         OnClick=BlueASlider.InternalOnClick
         OnMousePressed=BlueASlider.InternalOnMousePressed
         OnMouseRelease=BlueASlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_HUD.InternalOnChange
         OnKeyEvent=BlueASlider.InternalOnKeyEvent
         OnCapturedMouseMove=BlueASlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_HUD.OnSlide
         MaxValue=255
     End Object
     radarVehicleASlide=wsGUISlider'UTComp_Menu_HUD.BlueASlider'

     Begin Object Class=GUILabel Name=radarLabel
         Caption="Through Wall Player Color"
         TextColor=(R=255,G=255,B=255)
         TextAlign=TXTA_Center
         WinTop=0.6000000
         WinLeft=0.120000
         WinWidth=0.195000
         WinHeight=20.000000
     End Object
     radar=GUILabel'UTComp_Menu_HUD.radarLabel'

     Begin Object Class=GUILabel Name=radarVehicleLabel
         Caption="Through Wall Vehicle Color"
         TextColor=(R=255,G=255,B=255)
         TextAlign=TXTA_Center
         WinTop=0.6000000
         WinLeft=0.550000
         WinWidth=0.195000
         WinHeight=20.000000
     End Object
     radarVehicle=GUILabel'UTComp_Menu_HUD.radarVehicleLabel'

     Begin Object Class=GUILabel Name=RedRLabel
         Caption="R"
         TextColor=(R=255,G=120,B=120)
         WinTop=0.6300000
         WinLeft=0.100000
         WinHeight=20.000000
     End Object
     radarR=GUILabel'UTComp_Menu_HUD.RedRLabel'

     Begin Object Class=GUILabel Name=RedGLabel
         Caption="G"
         TextColor=(R=120,G=255,B=120)
         WinTop=0.6800000
         WinLeft=0.100000
         WinHeight=20.000000
     End Object
     radarG=GUILabel'UTComp_Menu_HUD.RedGLabel'

     Begin Object Class=GUILabel Name=RedBLabel
         Caption="B"
         TextColor=(R=120,G=120,B=255)
         WinTop=0.730000
         WinLeft=0.100000
         WinHeight=20.000000
     End Object
     radarB=GUILabel'UTComp_Menu_HUD.RedBLabel'

     Begin Object Class=GUILabel Name=RedALabel
         Caption="A"
         TextColor=(R=255,G=255,B=255)
         WinTop=0.780000
         WinLeft=0.100000
         WinHeight=20.000000
     End Object
     radarA=GUILabel'UTComp_Menu_HUD.RedALabel'

     Begin Object Class=GUILabel Name=BlueRLabel
         Caption="R"
         TextColor=(R=255,G=120,B=120)
         WinTop=0.6300000
         WinLeft=0.53000
         WinHeight=20.000000
     End Object
     radarVehicleR=GUILabel'UTComp_Menu_HUD.BlueRLabel'

     Begin Object Class=GUILabel Name=BlueGLabel
         Caption="G"
         TextColor=(R=120,G=255,B=120)
         WinTop=0.6800000
         WinLeft=0.53000
         WinHeight=20.000000
     End Object
     radarVehicleG=GUILabel'UTComp_Menu_HUD.BlueGLabel'

     Begin Object Class=GUILabel Name=BlueBLabel
         Caption="B"
         TextColor=(R=120,G=120,B=255)
         WinTop=0.730000
         WinLeft=0.53000
         WinHeight=20.000000
     End Object
     radarVehicleB=GUILabel'UTComp_Menu_HUD.BlueBLabel'

     Begin Object Class=GUILabel Name=BlueALabel
         Caption="A"
         TextColor=(R=255,G=255,B=255)
         WinTop=0.780000
         WinLeft=0.53000
         WinHeight=20.000000
     End Object
     radarVehicleA=GUILabel'UTComp_Menu_HUD.BlueALabel'

}
