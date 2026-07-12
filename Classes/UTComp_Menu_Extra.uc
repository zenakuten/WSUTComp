
class UTComp_Menu_Extra extends UTComp_Menu_MainMenu;

var automated wsComboBox co_DamageSelect;
var automated GUILabel lb_DamageSelect;
var automated wsCheckBox ch_EnableAwards;
var automated wsCheckBox ch_FastGhost;
var automated wsCheckBox ch_ColorGhost;
var automated GUILabel ghost, ghostFX, ghostR, ghostG, ghostB, ghostA, ghostFXR, ghostFXG, ghostFXB, ghostFXA;
var automated GUISlider ghostRSlide, ghostGSlide, ghostBSlide, ghostASlide, ghostFXRSlide, ghostFXGSlide, ghostFXBSlide, ghostFXASlide;

var automated GUISlider thirdPersonCamDistanceSlide, thirdPersonCamOffsetXSlide, thirdPersonCamOffsetYSlide, thirdPersonCamOffsetZSlide;
var automated GUILabel thirdPersonCamDistLabel, thirdPersonCamOffsetXLabel, thirdPersonCamOffsetYLabel, thirdPersonCamOffsetZLabel;
var automated GUIButton bu_Default3P;

// Live preview dude drawn next to the ghost color sliders. It renders as a solid player
// mesh tinted with the ghost colors (via ColorModifier over the DeRez materials, exactly
// like the in-game ghost), and updates as the sliders move.
var automated GUIImage i_GhostPreview;
var UTComp_SpinnyWeap SpinnyGhost;
var ColorModifier GhostMod0, GhostMod1;
var vector SpinnyOffset;

// The in-game ghost fx is a DeResPart particle system attached to the player's body
// (see UTComp_xPawn.StartDeRes). We attach the same emitter to the preview dude and tint
// it from the ghost-fx sliders so the extra menu previews the ghost fx as well.
var Emitter GhostFXEmitter;
// Downward (camera-up axis) world-unit nudge applied to the ghost fx emitter so the
// particle cloud lines up with the dude's body instead of its head. Tuned for the
// preview dude's 0.28 draw scale.
var float GhostFXBodyOffset;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    local UTComp_ServerReplicationInfo RepInfo;

    super.InitComponent(MyController,MyOwner);

    co_DamageSelect.AddItem("Disabled");
	co_DamageSelect.AddItem("Centered");
	co_DamageSelect.AddItem("Floating");
	co_DamageSelect.ReadOnly(True);
	co_DamageSelect.SetIndex(HUDSettings.DamageIndicatorType - 1);

    RepInfo = BS_xPlayer(PlayerOwner()).RepInfo;
    if(RepInfo != None && !RepInfo.bDamageIndicator)
    {
        co_DamageSelect.DisableMe();
        co_DamageSelect.SetHint("Server disabled");
    }

    ch_EnableAwards.Checked(Settings.bEnableAwards);
    ch_FastGhost.Checked(Settings.bFastGhost);
    ch_ColorGhost.Checked(Settings.bColorGhost);
    MatchSlidersToColors();
    MatchTextToSliders();
    MatchSlidersToThirdPerson();
}

function bool IsWSFixRelevant()
{
    return Left(PlayerOwner().Level.EngineVersion,4) == "3369";
}

function InternalOnChange( GUIComponent C )
{
    switch(C)
    {
		case co_DamageSelect: HUDSettings.DamageIndicatorType = co_DamageSelect.GetIndex() + 1;
			break;

        case ch_EnableAwards: Settings.bEnableAwards=ch_EnableAwards.IsChecked(); 
            break;

        case ch_FastGhost: Settings.bFastGhost=ch_FastGhost.IsChecked(); 
            break;

        case ch_ColorGhost: Settings.bColorGhost=ch_ColorGhost.IsChecked(); 
            break;

        case GhostRSlide: Settings.DeResColor.R = GhostRSlide.Value;
            MatchTextToSliders();
            break;

        case GhostGSlide: Settings.DeResColor.G = GhostGSlide.Value;
            MatchTextToSliders();
            break;

        case GhostBSlide: Settings.DeResColor.B = GhostBSlide.Value;
            MatchTextToSliders();
            break;

        case GhostASlide: Settings.DeResColor.A = GhostASlide.Value;
            MatchTextToSliders();
            break;

        case GhostFXRSlide: Settings.DeResFXColor.R = GhostFXRSlide.Value;
            MatchTextToSliders();
            break;

        case GhostFXGSlide: Settings.DeResFXColor.G = GhostFXGSlide.Value;
            MatchTextToSliders();
            break;

        case GhostFXBSlide: Settings.DeResFXColor.B = GhostFXBSlide.Value;
            MatchTextToSliders();
            break;

        case GhostFXASlide: Settings.DeResFXColor.A = GhostFXASlide.Value;
            MatchTextToSliders();
            break;

        case thirdPersonCamDistanceSlide: Settings.TPCamDistance = thirdPersonCamDistanceSlide.Value;
            UpdatePawnCamDistance();
            break;

        case thirdPersonCamOffsetXSlide: Settings.TPCamWorldOffset.X = thirdPersonCamOffsetXSlide.Value;
            UpdatePawnCamDistance();
            break;

        case thirdPersonCamOffsetYSlide: Settings.TPCamWorldOffset.Y = thirdPersonCamOffsetYSlide.Value;
            UpdatePawnCamDistance();
            break;

        case thirdPersonCamOffsetZSlide: Settings.TPCamWorldOffset.Z = thirdPersonCamOffsetZSlide.Value;
            UpdatePawnCamDistance();
            break;
    }

    SaveSettings();
    SaveHUDSettings();
    UpdateServerCamDistance();
}

function bool InternalOnClick(GUIComponent Sender)
{
    if(Sender == bu_Default3P)
        ResetThirdPersonToDefaults();

    return Super.InternalOnClick(Sender);
}

// Restore the four 3p camera sliders (distance + X/Y/Z world offset) to the
// authoritative default view values, which live on the pawn class UTComp_xPawn.
function ResetThirdPersonToDefaults()
{
    Settings.TPCamDistance = class'UTComp_xPawn'.default.TPCamDistance;
    Settings.TPCamWorldOffset = class'UTComp_xPawn'.default.TPCamWorldOffset;

    MatchSlidersToThirdPerson();
    UpdatePawnCamDistance();
    UpdateServerCamDistance();
    SaveSettings();
}

// Live preview while dragging a color slider: recolor the label text as the slider
// moves. The config save is deferred to release (InternalOnChange).
function OnSlide( GUIComponent C )
{
    switch(C)
    {
        case GhostRSlide: Settings.DeResColor.R = GhostRSlide.Value; MatchTextToSliders(); break;
        case GhostGSlide: Settings.DeResColor.G = GhostGSlide.Value; MatchTextToSliders(); break;
        case GhostBSlide: Settings.DeResColor.B = GhostBSlide.Value; MatchTextToSliders(); break;
        case GhostASlide: Settings.DeResColor.A = GhostASlide.Value; MatchTextToSliders(); break;

        case GhostFXRSlide: Settings.DeResFXColor.R = GhostFXRSlide.Value; MatchTextToSliders(); break;
        case GhostFXGSlide: Settings.DeResFXColor.G = GhostFXGSlide.Value; MatchTextToSliders(); break;
        case GhostFXBSlide: Settings.DeResFXColor.B = GhostFXBSlide.Value; MatchTextToSliders(); break;
        case GhostFXASlide: Settings.DeResFXColor.A = GhostFXASlide.Value; MatchTextToSliders(); break;
    }
}

function MatchSlidersToColors()
{
    GhostRSlide.Value = Settings.DeResColor.R;
    GhostGSlide.Value = Settings.DeResColor.G;
    GhostBSlide.Value = Settings.DeResColor.B;
    GhostASlide.Value = Settings.DeResColor.B;

    GhostFXRSlide.Value = Settings.DeResFXColor.R;
    GhostFXGSlide.Value = Settings.DeResFXColor.G;
    GhostFXBSlide.Value = Settings.DeResFXColor.B;
    GhostFXASlide.Value = Settings.DeResFXColor.B;
}

function MatchSettingsToThirdPerson()
{
    Settings.TPCamDistance = thirdPersonCamDistanceSlide.Value;
    Settings.TPCamWorldOffset.X = thirdPersonCamOffsetXSlide.Value;
    Settings.TPCamWorldOffset.Y = thirdPersonCamOffsetYSlide.Value;
    Settings.TPCamWorldOffset.Z = thirdPersonCamOffsetZSlide.Value;
}

function MatchSlidersToThirdPerson()
{
    thirdPersonCamDistanceSlide.Value = Settings.TPCamDistance;
    thirdPersonCamOffsetXSlide.Value = Settings.TPCamWorldOffset.X;
    thirdPersonCamOffsetYSlide.Value = Settings.TPCamWorldOffset.Y;
    thirdPersonCamOffsetZSlide.Value = Settings.TPCamWorldOffset.Z;
}

function MatchTextToSliders()
{
    ghost.TextColor = Settings.DeResColor;
    ghostFX.TextColor = Settings.DeResFXColor;
    UpdateGhostColors();
}

// ---- ghost / ghost-fx preview dudes ----

event Opened(GUIComponent sender)
{
    InitSpinnies();
    super.Opened(sender);
}

function InitSpinnies()
{
    local xUtil.PlayerRecord Rec;

    if(SpinnyGhost != None)
        return;

    if(PlayerOwner().PlayerReplicationInfo != None)
        Rec = class'xutil'.static.FindPlayerRecord(PlayerOwner().PlayerReplicationInfo.CharacterName);
    else
        Rec = class'xutil'.static.FindPlayerRecord("Gorge");

    SpinnyGhost   = SpawnDude(SpinnyGhost);

    LinkDude(SpinnyGhost,   Rec.MeshName, 0.28);

    GhostMod0 = MakeMod(FinalBlend'WSUTComp.Shaders.DeRezFinalBody', Settings.DeResColor);
    GhostMod1 = MakeMod(FinalBlend'WSUTComp.Shaders.DeRezFinalHead', Settings.DeResColor);
    if(SpinnyGhost != None)
    {
        SpinnyGhost.Skins[0] = GhostMod0;
        SpinnyGhost.Skins[1] = GhostMod1;
    }

    // Attach the ghost fx particle system to the preview dude, mirroring
    // UTComp_xPawn.StartDeRes: base it to the pawn (here the spinny) and drive its
    // spawn location from the skeletal mesh.
    if(SpinnyGhost != None)
    {
        GhostFXEmitter = PlayerOwner().Spawn(class'UTComp_DeResPreview', SpinnyGhost, , SpinnyGhost.Location);
        if(GhostFXEmitter != None)
        {
            GhostFXEmitter.Emitters[0].SkeletalMeshActor = SpinnyGhost;
            GhostFXEmitter.SetBase(SpinnyGhost);
            // Hide from the normal world-scene pass; we render it into the preview pane
            // ourselves via DrawActorClipped (which ignores bHidden).
            GhostFXEmitter.bHidden = true;
        }
    }

    UpdateGhostColors();
}

function ColorModifier MakeMod(Material Base, color Col)
{
    local ColorModifier M;

    M = ColorModifier(PlayerOwner().Level.ObjectPool.AllocateObject(class'ColorModifier'));
    M.Material = Base;
    M.AlphaBlend = true;
    M.RenderTwoSided = true;
    M.Color = Col;
    return M;
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
        D.AmbientGlow = 254;
        // Hide from the world-scene pass; DrawActorClipped renders it into the preview
        // pane regardless of bHidden.
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

function LinkDude(UTComp_SpinnyWeap Dude, string MeshName, float Scale)
{
    local Mesh M;

    if(Dude == None)
        return;

    Dude.SetDrawScale(Scale);

    M = Mesh(DynamicLoadObject(MeshName, class'Mesh'));
    if(M == None)
        return;

    Dude.LinkMesh(M);
    Dude.LoopAnim('Idle_Rest', 1.0/Dude.Level.TimeDilation);
}

function UpdateGhostColors()
{
    local SpriteEmitter S;

    if(GhostMod0   != None) GhostMod0.Color   = Settings.DeResColor;
    if(GhostMod1   != None) GhostMod1.Color   = Settings.DeResColor;

    // Tint the ghost fx particles from the ghost-fx sliders, matching StartDeRes.
    if(GhostFXEmitter != None)
    {
        S = SpriteEmitter(GhostFXEmitter.Emitters[0]);
        if(S != None)
        {
            S.ColorScale[0].Color = Settings.DeResFXColor;
            S.ColorScale[1].Color = Settings.DeResFXColor;
            S.ColorScale[2].Color = Settings.DeResFXColor;
        }
    }
}

function bool OnDrawGhost(Canvas C)
{
    return DrawSpinny(C, SpinnyGhost, i_GhostPreview);
}

// Draw the dude as a solid tinted mesh (WireFrame=false) clipped into the preview pane.
function bool DrawSpinny(Canvas Canvas, UTComp_SpinnyWeap Dude, GUIImage Bounds)
{
    local vector CamPos, X, Y, Z, DudeLoc;
    local rotator CamRot;
    local float fov;

    if(Dude == None || Bounds == None || !Bounds.bVisible)
        return true;

    Canvas.GetCameraLocation(CamPos, CamRot);
    GetAxes(CamRot, X, Y, Z);

    // Distance / 1.5 renders the ghost preview (and, via DudeLoc, its fx cloud) 50% larger.
    // Apparent size is 1/distance, and SpinnyPaneLoc keeps it centered in the pane regardless.
    DudeLoc = SpinnyPaneLoc(Canvas, Bounds, CamPos, X, Y, Z, SpinnyOffset.X / 1.5, 15.0, fov);
    Dude.SetLocation(DudeLoc);
    Canvas.DrawActor(Dude, false, true, fov);

    // Ghost fx emitter shares the dude's spot (ClearZ=false so it shares depth). The
    // downward nudge lines the particle cloud up with the body instead of the head.
    if(GhostFXEmitter != None)
    {
        GhostFXEmitter.SetLocation(DudeLoc - (GhostFXBodyOffset * Z));
        Canvas.DrawActor(GhostFXEmitter, false, false, fov);
    }

    return true;
}

function Free()
{
    Super.Free();
    if(GhostFXEmitter != None)
    {
        GhostFXEmitter.Emitters[0].SkeletalMeshActor = None;
        GhostFXEmitter.Kill();
        GhostFXEmitter = None;
    }
    if(SpinnyGhost   != None) { SpinnyGhost.Destroy();   SpinnyGhost=None; }
}

function UpdatePawnCamDistance()
{
    local UTComp_xPawn P;
    P = UTComp_xPawn(PlayerOwner().Pawn);
    if(P != None)
    {
        P.TPCamDistance = Settings.TPCamDistance;
        P.TPCamWorldOffset.X = Settings.TPCamWorldOffset.X;
        P.TPCamWorldOffset.Y = Settings.TPCamWorldOffset.Y;
        P.TPCamWorldOffset.Z = Settings.TPCamWorldOffset.Z;
    }
}

function UpdateServerCamDistance()
{
    local BS_xPlayer bsxplayer;
    local UTComp_xPawn P;

    bsxplayer = BS_xPlayer(PlayerOwner());
    if(bsxplayer != None)
    {
        P = UTComp_xPawn(bsxplayer.Pawn);
        if(P != None)
        {
            bsxplayer.ServerSetBehindView(
                bsxplayer.bBehindView,
                P.TPCamDistance,
                P.TPCamWorldOffset.X,
                P.TPCamWorldOffset.Y,
                P.TPCamWorldOffset.Z);
        }
    }
}

// Fired once when a 3p-cam slider is released. During a drag, the CaptureMouseMove handlers
// only update the local pawn/render (live preview); the base slider never fires OnChange on
// drag or release, so the server would otherwise keep the offset from the initial click and
// its 3p aim (which uses the replicated TPCamWorldOffset) would diverge from the client view.
// Push the final value here - one RPC per release, not per drag frame.
function sliderReleaseSendToServer(GUIComponent Sender)
{
    if (GUISlider(Sender) != None)
        GUISlider(Sender).InternalOnMouseRelease(Sender);   // base: recompute value from cursor
    MatchSettingsToThirdPerson();
    UpdatePawnCamDistance();
    UpdateServerCamDistance();
}

function bool thirdDistanceCaptureMouseMove(float dx, float dy)
{
    local bool retval;
    retval = thirdPersonCamDistanceSlide.InternalCapturedMouseMove(dx, dy);
    MatchSettingsToThirdPerson();
    UpdatePawnCamDistance();

    return retval;
}

function bool thirdOffsetXCaptureMouseMove(float dx, float dy)
{
    local bool retval;
    retval = thirdPersonCamOffsetXSlide.InternalCapturedMouseMove(dx, dy);
    MatchSettingsToThirdPerson();
    UpdatePawnCamDistance();

    return retval;
}

function bool thirdOffsetYCaptureMouseMove(float dx, float dy)
{
    local bool retval;
    retval = thirdPersonCamOffsetYSlide.InternalCapturedMouseMove(dx, dy);
    MatchSettingsToThirdPerson();
    UpdatePawnCamDistance();

    return retval;
}

function bool thirdOffsetZCaptureMouseMove(float dx, float dy)
{
    local bool retval;
    retval = thirdPersonCamOffsetZSlide.InternalCapturedMouseMove(dx, dy);
    MatchSettingsToThirdPerson();
    UpdatePawnCamDistance();

    return retval;
}



defaultproperties
{
    ActiveMenuButton=10
    SpinnyOffset=(X=280.000000,Y=1.000000,Z=2.000000)
    GhostFXBodyOffset=10.000000

    Begin Object Class=GUIImage Name=GhostPreviewImage
        Image=Material'2K4Menus.Controls.buttonSquare_b'
        ImageColor=(R=255,G=255,B=255,A=128)
        ImageRenderStyle=MSTY_Alpha
        ImageStyle=ISTY_Stretched
        bScaleToParent=true
        bBoundToParent=true
        WinWidth=0.150000
        WinHeight=0.200000
        WinLeft=0.380000
        WinTop=0.630000
        RenderWeight=0.52
        OnDraw=OnDrawGhost
    End Object
    i_GhostPreview=GUIImage'UTComp_Menu_Extra.GhostPreviewImage'

    Begin Object Class=wsComboBox Name=ComboDamageIndicatorType
         Caption="Damage Indicators:"
         OnCreateComponent=ComboDamageIndicatorType.InternalOnCreateComponent
         WinTop=0.33
         WinLeft=0.12
         WinWidth=0.25
         OnChange=UTComp_Menu_Extra.InternalOnChange
     End Object
     co_DamageSelect=wsComboBox'UTComp_Menu_Extra.ComboDamageIndicatorType'

    Begin Object Class=wsCheckBox Name=EnableAwardsCheck
        Caption="Enable awards"
        Hint="Play sound for air rocket, impressive shock combo"
        OnCreateComponent=EnableAwardsCheck.InternalOnCreateComponent
        WinWidth=0.25
        WinHeight=0.030000
        WinLeft=0.12
        WinTop=0.38
        OnChange=UTComp_Menu_Extra.InternalOnChange
    End Object
    ch_EnableAwards=wsCheckBox'UTComp_Menu_Extra.EnableAwardsCheck'

    Begin Object Class=wsCheckBox Name=FastGhostCheck
        Caption="Fast ghost"
        Hint="Make dead players turn to ghost immediately"
        OnCreateComponent=FastGhostCheck.InternalOnCreateComponent
        WinWidth=0.25
        WinHeight=0.030000
        WinLeft=0.12
        WinTop=0.43
        OnChange=UTComp_Menu_Extra.InternalOnChange
    End Object
    ch_FastGhost=wsCheckBox'UTComp_Menu_Extra.FastGhostCheck'

    Begin Object Class=wsCheckBox Name=ColorGhostCheck
        Caption="Color ghost"
        Hint="Use configured ghost color"
        OnCreateComponent=ColorGhostCheck.InternalOnCreateComponent
        WinWidth=0.25
        WinHeight=0.030000
        WinLeft=0.12
        WinTop=0.48
        OnChange=UTComp_Menu_Extra.InternalOnChange
    End Object
    ch_ColorGhost=wsCheckBox'UTComp_Menu_Extra.ColorGhostCheck'

     Begin Object Class=GUILabel Name=thirdCamDistLabel
         Caption="3p Cam Dist"
         TextColor=(R=255,G=255,B=255)
         WinTop=0.33
         WinLeft=0.55
         WinHeight=20.000000
     End Object
     thirdPersonCamDistLabel=GUILabel'UTComp_Menu_Extra.thirdCamDistLabel'

     Begin Object Class=wsGUISlider Name=thirdCamDistanceSlide
         bIntSlider=True
         WinTop=0.33
         WinLeft=0.68
         WinWidth=0.125
         OnClick=thirdCamDistanceSlide.InternalOnClick
         OnMousePressed=thirdCamDistanceSlide.InternalOnMousePressed
         OnMouseRelease=UTComp_Menu_Extra.sliderReleaseSendToServer
         OnChange=UTComp_Menu_Extra.InternalOnChange
         OnKeyEvent=thirdCamDistanceSlide.InternalOnKeyEvent
         //OnCapturedMouseMove=thirdCamDistanceSlide.InternalCapturedMouseMove
         OnCapturedMouseMove=UTComp_Menu_Extra.thirdDistanceCaptureMouseMove
         // The view breaks past 255 (total camera distance exceeds the 300 fallback in
         // SpecialCalcBehindView), so that is the cap. The 225 default sits at ~88%.
         MinValue=0
         MaxValue=255
     End Object
     thirdPersonCamDistanceSlide=wsGUISlider'UTComp_Menu_Extra.thirdCamDistanceSlide'

     Begin Object Class=GUILabel Name=thirdCamOffXLabel
         Caption="3p Cam X"
         TextColor=(R=255,G=255,B=255)
         WinTop=0.38
         WinLeft=0.55
         WinHeight=20.000000
     End Object
     thirdPersonCamOffsetXLabel=GUILabel'UTComp_Menu_Extra.thirdCamOffXLabel'

     Begin Object Class=wsGUISlider Name=thirdCamOffsetX
         bIntSlider=True
         WinTop=0.38
         WinLeft=0.68
         WinWidth=0.125
         OnClick=thirdCamOffsetX.InternalOnClick
         OnMousePressed=thirdCamOffsetX.InternalOnMousePressed
         OnMouseRelease=UTComp_Menu_Extra.sliderReleaseSendToServer
         OnChange=UTComp_Menu_Extra.InternalOnChange
         OnKeyEvent=thirdCamOffsetX.InternalOnKeyEvent
         //OnCapturedMouseMove=thirdCamOffsetX.InternalCapturedMouseMove
         OnCapturedMouseMove=UTComp_Menu_Extra.thirdOffsetXCaptureMouseMove
         MinValue=-64
         MaxValue=64
     End Object
     thirdPersonCamOffsetXSlide=wsGUISlider'UTComp_Menu_Extra.thirdCamOffsetX'

     Begin Object Class=GUILabel Name=thirdCamOffYLabel
         Caption="3p Cam Y"
         TextColor=(R=255,G=255,B=255)
         WinTop=0.43
         WinLeft=0.55
         WinHeight=20.000000
     End Object
     thirdPersonCamOffsetYLabel=GUILabel'UTComp_Menu_Extra.thirdCamOffYLabel'

     Begin Object Class=wsGUISlider Name=thirdCamOffsetY
         bIntSlider=True
         WinTop=0.43
         WinLeft=0.68
         WinWidth=0.125
         OnClick=thirdCamOffsetY.InternalOnClick
         OnMousePressed=thirdCamOffsetY.InternalOnMousePressed
         OnMouseRelease=UTComp_Menu_Extra.sliderReleaseSendToServer
         OnChange=UTComp_Menu_Extra.InternalOnChange
         OnKeyEvent=thirdCamOffsetY.InternalOnKeyEvent
         //OnCapturedMouseMove=thirdCamOffsetY.InternalCapturedMouseMove
         OnCapturedMouseMove=UTComp_Menu_Extra.thirdOffsetYCaptureMouseMove
         MinValue=-64
         MaxValue=64
     End Object
     thirdPersonCamOffsetYSlide=wsGUISlider'UTComp_Menu_Extra.thirdCamOffsetY'

     Begin Object Class=GUILabel Name=thirdCamOffZLabel
         Caption="3p Cam Z"
         TextColor=(R=255,G=255,B=255)
         WinTop=0.48
         WinLeft=0.55
         WinHeight=20.000000
     End Object
     thirdPersonCamOffsetZLabel=GUILabel'UTComp_Menu_Extra.thirdCamOffZLabel'

     Begin Object Class=wsGUISlider Name=thirdCamOffsetZ
         bIntSlider=True
         WinTop=0.48
         WinLeft=0.68
         WinWidth=0.125
         OnClick=thirdCamOffsetZ.InternalOnClick
         OnMousePressed=thirdCamOffsetZ.InternalOnMousePressed
         OnMouseRelease=UTComp_Menu_Extra.sliderReleaseSendToServer
         OnChange=UTComp_Menu_Extra.InternalOnChange
         OnKeyEvent=thirdCamOffsetZ.InternalOnKeyEvent
         //OnCapturedMouseMove=thirdCamOffsetZ.InternalCapturedMouseMove
         OnCapturedMouseMove=UTComp_Menu_Extra.thirdOffsetZCaptureMouseMove
         MaxValue=64
     End Object
     thirdPersonCamOffsetZSlide=wsGUISlider'UTComp_Menu_Extra.thirdCamOffsetZ'

     // Sits under the 3p sliders, right edge aligned with the slider column (0.68 + 0.125 = 0.805).
     Begin Object Class=GUIButton Name=Default3PButton
         Caption="Default 3P"
         StyleName="WSButton"
         WinWidth=0.125000
         WinHeight=0.040000
         WinLeft=0.680000
         WinTop=0.530000
         OnClick=UTComp_Menu_Extra.InternalOnClick
         OnKeyEvent=Default3PButton.InternalOnKeyEvent
     End Object
     bu_Default3P=GUIButton'UTComp_Menu_Extra.Default3PButton'

    /////////////////////

     Begin Object Class=wsGUISlider Name=RedRSlider
          FillImage=Texture'WSUTComp.GUI.WSSliderFillRed'
          StyleName="WSSliderKnobWhite"
         bIntSlider=True
         WinTop=0.6250000
         WinLeft=0.120000
         WinWidth=0.260000
         OnClick=RedRSlider.InternalOnClick
         OnMousePressed=RedRSlider.InternalOnMousePressed
         OnMouseRelease=RedRSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_Extra.InternalOnChange
         OnKeyEvent=RedRSlider.InternalOnKeyEvent
         OnCapturedMouseMove=RedRSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_Extra.OnSlide
         MaxValue=255
     End Object
     ghostRSlide=wsGUISlider'UTComp_Menu_Extra.RedRSlider'

     Begin Object Class=wsGUISlider Name=RedGSlider
          FillImage=Texture'WSUTComp.GUI.WSSliderFillGreen'
          StyleName="WSSliderKnobWhite"
         bIntSlider=True
         WinTop=0.6750000
         WinLeft=0.120000
         WinWidth=0.260000
         OnClick=RedGSlider.InternalOnClick
         OnMousePressed=RedGSlider.InternalOnMousePressed
         OnMouseRelease=RedGSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_Extra.InternalOnChange
         OnKeyEvent=RedGSlider.InternalOnKeyEvent
         OnCapturedMouseMove=RedGSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_Extra.OnSlide
         MaxValue=255
     End Object
     ghostGSlide=wsGUISlider'UTComp_Menu_Extra.RedGSlider'

     Begin Object Class=wsGUISlider Name=RedBSlider
          FillImage=Texture'WSUTComp.GUI.WSSliderFillBlue'
          StyleName="WSSliderKnobWhite"
         bIntSlider=True
         WinTop=0.7250000
         WinLeft=0.120000
         WinWidth=0.260000
         OnClick=RedBSlider.InternalOnClick
         OnMousePressed=RedBSlider.InternalOnMousePressed
         OnMouseRelease=RedBSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_Extra.InternalOnChange
         OnKeyEvent=RedBSlider.InternalOnKeyEvent
         OnCapturedMouseMove=RedBSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_Extra.OnSlide
         MaxValue=255
     End Object
     ghostBSlide=wsGUISlider'UTComp_Menu_Extra.RedBSlider'

     Begin Object Class=wsGUISlider Name=RedASlider
         bIntSlider=True
         WinTop=0.7750000
         WinLeft=0.120000
         WinWidth=0.260000
         OnClick=RedASlider.InternalOnClick
         OnMousePressed=RedASlider.InternalOnMousePressed
         OnMouseRelease=RedASlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_Extra.InternalOnChange
         OnKeyEvent=RedBSlider.InternalOnKeyEvent
         OnCapturedMouseMove=RedASlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_Extra.OnSlide
         MaxValue=255
     End Object
     ghostASlide=wsGUISlider'UTComp_Menu_Extra.RedASlider'

     Begin Object Class=wsGUISlider Name=BlueRSlider
          FillImage=Texture'WSUTComp.GUI.WSSliderFillRed'
          StyleName="WSSliderKnobWhite"
         bIntSlider=True
         WinTop=0.6250000
         WinLeft=0.5500000
         WinWidth=0.260000
         OnClick=BlueRSlider.InternalOnClick
         OnMousePressed=BlueRSlider.InternalOnMousePressed
         OnMouseRelease=BlueRSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_Extra.InternalOnChange
         OnKeyEvent=BlueRSlider.InternalOnKeyEvent
         OnCapturedMouseMove=BlueRSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_Extra.OnSlide
         MaxValue=255
     End Object
     ghostFXRSlide=wsGUISlider'UTComp_Menu_Extra.BlueRSlider'

     Begin Object Class=wsGUISlider Name=BlueGSlider
          FillImage=Texture'WSUTComp.GUI.WSSliderFillGreen'
          StyleName="WSSliderKnobWhite"
         bIntSlider=True
         WinTop=0.6750000
         WinLeft=0.5500000
         WinWidth=0.260000
         OnClick=BlueGSlider.InternalOnClick
         OnMousePressed=BlueGSlider.InternalOnMousePressed
         OnMouseRelease=BlueGSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_Extra.InternalOnChange
         OnKeyEvent=BlueGSlider.InternalOnKeyEvent
         OnCapturedMouseMove=BlueGSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_Extra.OnSlide
         MaxValue=255
     End Object
     ghostFXGSlide=wsGUISlider'UTComp_Menu_Extra.BlueGSlider'

     Begin Object Class=wsGUISlider Name=BlueBSlider
          FillImage=Texture'WSUTComp.GUI.WSSliderFillBlue'
          StyleName="WSSliderKnobWhite"
         bIntSlider=True
         WinTop=0.7250000
         WinLeft=0.550000
         WinWidth=0.260000
         OnClick=BlueBSlider.InternalOnClick
         OnMousePressed=BlueBSlider.InternalOnMousePressed
         OnMouseRelease=BlueBSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_Extra.InternalOnChange
         OnKeyEvent=BlueBSlider.InternalOnKeyEvent
         OnCapturedMouseMove=BlueBSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_Extra.OnSlide
         MaxValue=255
     End Object
     ghostFXBSlide=wsGUISlider'UTComp_Menu_Extra.BlueBSlider'

     Begin Object Class=wsGUISlider Name=BlueASlider
         bIntSlider=True
         WinTop=0.7750000
         WinLeft=0.550000
         WinWidth=0.260000
         OnClick=BlueASlider.InternalOnClick
         OnMousePressed=BlueASlider.InternalOnMousePressed
         OnMouseRelease=BlueASlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_Extra.InternalOnChange
         OnKeyEvent=BlueASlider.InternalOnKeyEvent
         OnCapturedMouseMove=BlueASlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_Extra.OnSlide
         MaxValue=255
     End Object
     ghostFXASlide=wsGUISlider'UTComp_Menu_Extra.BlueASlider'

     Begin Object Class=GUILabel Name=GhostLabel
         Caption="Ghost"
         TextColor=(R=255,G=255,B=255)
         WinTop=0.6000000
         WinLeft=0.235000
         WinHeight=20.000000
     End Object
     ghost=GUILabel'UTComp_Menu_Extra.GhostLabel'

     Begin Object Class=GUILabel Name=GhostFXLabel
         Caption="Ghost FX"
         TextColor=(R=255,G=255,B=255)
         WinTop=0.6000000
         WinLeft=0.650000
         WinHeight=20.000000
     End Object
     ghostFX=GUILabel'UTComp_Menu_Extra.GhostFXLabel'

     Begin Object Class=GUILabel Name=RedRLabel
         Caption="R"
         TextColor=(R=255,G=120,B=120)
         WinTop=0.6300000
         WinLeft=0.100000
         WinHeight=20.000000
     End Object
     ghostR=GUILabel'UTComp_Menu_Extra.RedRLabel'

     Begin Object Class=GUILabel Name=RedGLabel
         Caption="G"
         TextColor=(R=120,G=255,B=120)
         WinTop=0.6800000
         WinLeft=0.100000
         WinHeight=20.000000
     End Object
     ghostG=GUILabel'UTComp_Menu_Extra.RedGLabel'

     Begin Object Class=GUILabel Name=RedBLabel
         Caption="B"
         TextColor=(R=120,G=120,B=255)
         WinTop=0.730000
         WinLeft=0.100000
         WinHeight=20.000000
     End Object
     ghostB=GUILabel'UTComp_Menu_Extra.RedBLabel'

     Begin Object Class=GUILabel Name=RedALabel
         Caption="A"
         TextColor=(R=255,G=255,B=255)
         WinTop=0.780000
         WinLeft=0.100000
         WinHeight=20.000000
     End Object
     ghostA=GUILabel'UTComp_Menu_Extra.RedALabel'

     Begin Object Class=GUILabel Name=BlueRLabel
         Caption="R"
         TextColor=(R=255,G=120,B=120)
         WinTop=0.6300000
         WinLeft=0.53000
         WinHeight=20.000000
     End Object
     ghostFXR=GUILabel'UTComp_Menu_Extra.BlueRLabel'

     Begin Object Class=GUILabel Name=BlueGLabel
         Caption="G"
         TextColor=(R=120,G=255,B=120)
         WinTop=0.6800000
         WinLeft=0.53000
         WinHeight=20.000000
     End Object
     ghostFXG=GUILabel'UTComp_Menu_Extra.BlueGLabel'

     Begin Object Class=GUILabel Name=BlueBLabel
         Caption="B"
         TextColor=(R=120,G=120,B=255)
         WinTop=0.730000
         WinLeft=0.53000
         WinHeight=20.000000
     End Object
     ghostFXB=GUILabel'UTComp_Menu_Extra.BlueBLabel'

     Begin Object Class=GUILabel Name=BlueALabel
         Caption="A"
         TextColor=(R=255,G=255,B=255)
         WinTop=0.780000
         WinLeft=0.53000
         WinHeight=20.000000
     End Object
     ghostFXA=GUILabel'UTComp_Menu_Extra.BlueALabel'


}