
// Brightskins configuration menu.
//
// Layout modelled after 3SPNvSoL's Menu_TabBrightskins: instead of a single
// "pick one target from a dropdown" editor, the Red and Blue teams are shown as two
// always-visible bands (skin style + R/G/B + model/force + live preview), with a
// compact Spawn-Protected band below. Clan skins are seldom used, so they are folded
// behind a "Clan Skins" toggle that swaps into the bottom region.
//
// The data model (UTComp_Settings) and the skin-color math are unchanged from the old
// menu - only the UI was rebuilt. The skinning helpers read the Pv* context vars
// (set per band by UpdateSpinny) instead of the old shared controls.
class UTComp_Menu_BrightSkins extends UTComp_Menu_MainMenu;

// Top toggles
var automated wsCheckBox ch_EnemySkins, ch_EnemyModels, ch_DarkSkins;

// Red band
var automated GUILabel l_RedHeader, l_RedR, l_RedG, l_RedB;
var automated wsGUIComboBox co_RedStyle, co_RedModel;
var automated wsGUISlider sl_RedR, sl_RedG, sl_RedB;
var automated wsCheckBox ch_RedForce;
var automated GUIImage i_RedBounds;

// Blue band
var automated GUILabel l_BlueHeader, l_BlueR, l_BlueG, l_BlueB;
var automated wsGUIComboBox co_BlueStyle, co_BlueModel;
var automated wsGUISlider sl_BlueR, sl_BlueG, sl_BlueB;
var automated wsCheckBox ch_BlueForce;
var automated GUIImage i_BlueBounds;

// Spawn protected band (enemy + team colors)
var automated GUILabel l_SpawnHeader, l_SpEnemy, l_SpTeam;
var automated GUILabel l_SpEnR, l_SpEnG, l_SpEnB, l_SpTmR, l_SpTmG, l_SpTmB;
var automated wsGUISlider sl_SpEnR, sl_SpEnG, sl_SpEnB, sl_SpTmR, sl_SpTmG, sl_SpTmB;
var automated GUIImage i_SpawnBounds, i_TeamBounds;

// Clan skins (behind toggle, swaps into spawn region)
var automated GUIButton bu_ClanToggle;
var automated GUILabel l_ClanHeader, l_ClanR, l_ClanG, l_ClanB;
var automated wsGUIComboBox co_ClanSelect, co_ClanModel;
var automated GUIButton bu_AddClan, bu_DeleteClan;
var automated GUIEditBox eb_ClanName;
var automated wsGUISlider sl_ClanR, sl_ClanG, sl_ClanB;
var automated GUIImage i_ClanBounds;

var automated GUIButton bu_ResetSkins;

// Preview actors, one per band
var UTComp_SpinnyWeap SpinnyRed, SpinnyBlue, SpinnySpawn, SpinnyTeam, SpinnyClan;
var vector SpinnyOffset;

// Per-preview skinning context (consumed by the ChangeColorOfSkin helpers)
var byte PvSkinMode;       // 0=Epic, 1=Brighter Epic, 2=UTComp
var byte PvColorMode;      // PreferredSkinColor index for this band's team
var byte PvOtherColorMode;
var color PvColor;         // UTComp-style RGB
var UTComp_SpinnyWeap PvDude;

var bool bInitDone;
var bool bClanShown;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    Super.InitComponent(MyController, MyOwner);

    AddComboBoxItems(co_RedModel);
    AddComboBoxItems(co_BlueModel);
    AddComboBoxItems(co_ClanModel);
    co_RedModel.ReadOnly(True);
    co_BlueModel.ReadOnly(True);
    co_ClanModel.ReadOnly(True);

    ch_EnemySkins.Checked(Settings.bEnemyBasedSkins);
    ch_EnemyModels.Checked(Settings.bEnemyBasedModels);
    ch_DarkSkins.Checked(Settings.bEnableDarkSkinning);
}

event Opened(GUIComponent Sender)
{
    Super.Opened(Sender);

    bInitDone=False;

    RefreshControlsFromSettings();
    RebuildClanCombo();
    if(Settings.ClanSkins.Length>0)
    {
        co_ClanSelect.SetIndex(0);
        LoadClanIntoControls();
    }

    InitializeSpinnies();
    bClanShown=False;
    ShowClanPanel(False);
    UpdateHeaders();
    UpdateBandStates();
    UpdateAllPreviews();

    bInitDone=True;
}

function RefreshControlsFromSettings()
{
    ch_EnemySkins.Checked(Settings.bEnemyBasedSkins);
    ch_EnemyModels.Checked(Settings.bEnemyBasedModels);
    ch_DarkSkins.Checked(Settings.bEnableDarkSkinning);

    BuildStyleCombo(co_RedStyle, Settings.ClientSkinModeRedTeammate);
    BuildStyleCombo(co_BlueStyle, Settings.ClientSkinModeBlueEnemy);

    ch_RedForce.Checked(Settings.bRedTeammateModelsForced);
    ch_BlueForce.Checked(Settings.bBlueEnemyModelsForced);

    co_RedModel.SetIndex(co_RedModel.FindIndex(Settings.RedTeammateModelName));
    co_BlueModel.SetIndex(co_BlueModel.FindIndex(Settings.BlueEnemyModelName));

    sl_RedR.SetValue(Settings.RedTeammateUTCompSkinColor.R);
    sl_RedG.SetValue(Settings.RedTeammateUTCompSkinColor.G);
    sl_RedB.SetValue(Settings.RedTeammateUTCompSkinColor.B);

    sl_BlueR.SetValue(Settings.BlueEnemyUTCompSkinColor.R);
    sl_BlueG.SetValue(Settings.BlueEnemyUTCompSkinColor.G);
    sl_BlueB.SetValue(Settings.BlueEnemyUTCompSkinColor.B);

    sl_SpEnR.SetValue(Settings.SpawnProtectedUTCompSkinColor.R);
    sl_SpEnG.SetValue(Settings.SpawnProtectedUTCompSkinColor.G);
    sl_SpEnB.SetValue(Settings.SpawnProtectedUTCompSkinColor.B);

    sl_SpTmR.SetValue(Settings.SpawnProtectedUTCompSkinColorTeam.R);
    sl_SpTmG.SetValue(Settings.SpawnProtectedUTCompSkinColorTeam.G);
    sl_SpTmB.SetValue(Settings.SpawnProtectedUTCompSkinColorTeam.B);
}

function BuildStyleCombo(wsGUIComboBox Combo, byte CurMode)
{
    local UTComp_ServerReplicationInfo RepInfo;

    foreach PlayerOwner().DynamicActors(class'UTComp_ServerReplicationInfo', RepInfo)
        break;

    Combo.Clear();
    Combo.AddItem("Epic Style");
    if(RepInfo==None || RepInfo.EnableBrightSkinsMode>1)
        Combo.AddItem("Brighter Epic Style");
    else
        Combo.AddItem("Brighter Epic Style (Server Disabled)");
    if(RepInfo==None || RepInfo.EnableBrightSkinsMode>2)
        Combo.AddItem("UTComp Style");
    else
        Combo.AddItem("UTComp Style (Server Disabled)");
    Combo.ReadOnly(True);
    Combo.SetIndex(Clamp(int(CurMode)-1, 0, 2));
}

function UpdateHeaders()
{
    if(Settings.bEnemyBasedSkins)
    {
        l_RedHeader.Caption="Teammates";
        l_BlueHeader.Caption="Enemies";
    }
    else
    {
        l_RedHeader.Caption="Red Team";
        l_BlueHeader.Caption="Blue Team";
    }
}

function UpdateBandStates()
{
    local bool bRedUTComp, bBlueUTComp;

    // Derive the auto Epic presets from the chosen style (same rule as the old menu).
    if(Settings.ClientSkinModeRedTeammate==1)
        Settings.PreferredSkinColorRedTeammate=1;   // Red
    else
        Settings.PreferredSkinColorRedTeammate=5;   // Brighter Red

    if(Settings.ClientSkinModeBlueEnemy==1)
        Settings.PreferredSkinColorBlueEnemy=2;     // Blue
    else
        Settings.PreferredSkinColorBlueEnemy=6;     // Brighter Blue

    // The R/G/B sliders only affect the UTComp style (mode 3), so only show them there.
    bRedUTComp = (Settings.ClientSkinModeRedTeammate==3);
    l_RedR.bVisible=bRedUTComp;  l_RedG.bVisible=bRedUTComp;  l_RedB.bVisible=bRedUTComp;
    sl_RedR.bVisible=bRedUTComp; sl_RedG.bVisible=bRedUTComp; sl_RedB.bVisible=bRedUTComp;

    bBlueUTComp = (Settings.ClientSkinModeBlueEnemy==3);
    l_BlueR.bVisible=bBlueUTComp;  l_BlueG.bVisible=bBlueUTComp;  l_BlueB.bVisible=bBlueUTComp;
    sl_BlueR.bVisible=bBlueUTComp; sl_BlueG.bVisible=bBlueUTComp; sl_BlueB.bVisible=bBlueUTComp;

    if(ch_RedForce.IsChecked())
        co_RedModel.EnableMe();
    else
        co_RedModel.DisableMe();

    if(ch_BlueForce.IsChecked())
        co_BlueModel.EnableMe();
    else
        co_BlueModel.DisableMe();
}

function SaveAll()
{
    class'UTComp_xPawn'.static.StaticSaveConfig();
    SaveSettings();
    if(BS_xPlayer(PlayerOwner()) != None)
    {
        BS_xPlayer(PlayerOwner()).ReSkinAll();
        BS_xPlayer(PlayerOwner()).MatchHudColor();
    }
}

function InternalOnChange(GUIComponent C)
{
    if(!bInitDone)
        return;

    ApplyControl(C);
    UpdateBandStates();
    UpdateAllPreviews();
    SaveAll();
}

// Live preview while dragging a color slider: apply the value and re-skin the preview
// dudes, but defer the config save + player re-skin until the slider is released (OnChange).
function OnSlide(GUIComponent C)
{
    if(!bInitDone)
        return;

    ApplyControl(C);

    // Only re-skin the one dude this slider drives, color-only (no mesh relink),
    // so dragging stays cheap.
    switch(C)
    {
        case sl_RedR:  case sl_RedG:  case sl_RedB:  UpdateSpinny(SpinnyRed, 0, true);   break;
        case sl_BlueR: case sl_BlueG: case sl_BlueB: UpdateSpinny(SpinnyBlue, 1, true);  break;
        case sl_SpEnR: case sl_SpEnG: case sl_SpEnB: UpdateSpinny(SpinnySpawn, 2, true); break;
        case sl_SpTmR: case sl_SpTmG: case sl_SpTmB: UpdateSpinny(SpinnyTeam, 4, true);  break;
        case sl_ClanR: case sl_ClanG: case sl_ClanB: UpdateSpinny(SpinnyClan, 3, true);  break;
    }
}

function ApplyControl(GUIComponent C)
{
    switch(C)
    {
        case ch_EnemySkins:  Settings.bEnemyBasedSkins=ch_EnemySkins.IsChecked(); UpdateHeaders(); break;
        case ch_EnemyModels: Settings.bEnemyBasedModels=ch_EnemyModels.IsChecked(); UpdateHeaders(); break;
        case ch_DarkSkins:   Settings.bEnableDarkSkinning=ch_DarkSkins.IsChecked(); break;

        case co_RedStyle:    Settings.ClientSkinModeRedTeammate=co_RedStyle.GetIndex()+1; break;
        case co_BlueStyle:   Settings.ClientSkinModeBlueEnemy=co_BlueStyle.GetIndex()+1; break;

        case sl_RedR: Settings.RedTeammateUTCompSkinColor.R=sl_RedR.Value; break;
        case sl_RedG: Settings.RedTeammateUTCompSkinColor.G=sl_RedG.Value; break;
        case sl_RedB: Settings.RedTeammateUTCompSkinColor.B=sl_RedB.Value; break;

        case sl_BlueR: Settings.BlueEnemyUTCompSkinColor.R=sl_BlueR.Value; break;
        case sl_BlueG: Settings.BlueEnemyUTCompSkinColor.G=sl_BlueG.Value; break;
        case sl_BlueB: Settings.BlueEnemyUTCompSkinColor.B=sl_BlueB.Value; break;

        case sl_SpEnR: Settings.SpawnProtectedUTCompSkinColor.R=sl_SpEnR.Value; break;
        case sl_SpEnG: Settings.SpawnProtectedUTCompSkinColor.G=sl_SpEnG.Value; break;
        case sl_SpEnB: Settings.SpawnProtectedUTCompSkinColor.B=sl_SpEnB.Value; break;

        case sl_SpTmR: Settings.SpawnProtectedUTCompSkinColorTeam.R=sl_SpTmR.Value; break;
        case sl_SpTmG: Settings.SpawnProtectedUTCompSkinColorTeam.G=sl_SpTmG.Value; break;
        case sl_SpTmB: Settings.SpawnProtectedUTCompSkinColorTeam.B=sl_SpTmB.Value; break;

        case ch_RedForce:  Settings.bRedTeammateModelsForced=ch_RedForce.IsChecked(); break;
        case ch_BlueForce: Settings.bBlueEnemyModelsForced=ch_BlueForce.IsChecked(); break;
        case co_RedModel:  Settings.RedTeammateModelName=co_RedModel.GetText(); break;
        case co_BlueModel: Settings.BlueEnemyModelName=co_BlueModel.GetText(); break;

        case co_ClanSelect: LoadClanIntoControls(); break;
        case co_ClanModel:  if(SelClan()>=0) Settings.ClanSkins[SelClan()].ModelName=co_ClanModel.GetText(); break;
        case sl_ClanR: if(SelClan()>=0) Settings.ClanSkins[SelClan()].PlayerColor.R=sl_ClanR.Value; break;
        case sl_ClanG: if(SelClan()>=0) Settings.ClanSkins[SelClan()].PlayerColor.G=sl_ClanG.Value; break;
        case sl_ClanB: if(SelClan()>=0) Settings.ClanSkins[SelClan()].PlayerColor.B=sl_ClanB.Value; break;
    }
}

function bool InternalOnClick(GUIComponent Sender)
{
    local int n;

    switch(Sender)
    {
        case bu_ClanToggle:
            bClanShown=!bClanShown;
            ShowClanPanel(bClanShown);
            UpdateAllPreviews();
            return super.InternalOnClick(Sender);

        case bu_AddClan:
            bInitDone=False;
            n=Settings.ClanSkins.Length;
            Settings.ClanSkins.Length=n+1;
            Settings.ClanSkins[n].PlayerColor.G=128;
            Settings.ClanSkins[n].ModelName="Arclite";
            Settings.ClanSkins[n].PlayerName="Player"$n;
            RebuildClanCombo();
            co_ClanSelect.SetIndex(n);
            LoadClanIntoControls();
            bInitDone=True;
            break;

        case bu_DeleteClan:
            bInitDone=False;
            n=SelClan();
            if(n>=0)
            {
                Settings.ClanSkins.Remove(n, 1);
                RebuildClanCombo();
                if(Settings.ClanSkins.Length>0)
                    co_ClanSelect.SetIndex(0);
                LoadClanIntoControls();
            }
            bInitDone=True;
            break;

        case bu_ResetSkins:
            bInitDone=False;
            Settings.bEnemyBasedSkins=False;
            Settings.bEnemyBasedModels=False;
            Settings.ClientSkinModeRedTeammate=2;
            Settings.ClientSkinModeBlueEnemy=2;
            Settings.PreferredSkinColorRedTeammate=5;
            Settings.PreferredSkinColorBlueEnemy=6;
            Settings.bRedTeammateModelsForced=False;
            Settings.bBlueEnemyModelsForced=False;
            // Team (red column) spawn-protected -> red; Enemy (blue column) -> blue.
            Settings.SpawnProtectedUTCompSkinColorTeam.R=128;
            Settings.SpawnProtectedUTCompSkinColorTeam.G=0;
            Settings.SpawnProtectedUTCompSkinColorTeam.B=0;
            Settings.SpawnProtectedUTCompSkinColor.R=0;
            Settings.SpawnProtectedUTCompSkinColor.G=0;
            Settings.SpawnProtectedUTCompSkinColor.B=128;
            RefreshControlsFromSettings();
            UpdateHeaders();
            bInitDone=True;
            break;
    }

    UpdateBandStates();
    UpdateAllPreviews();
    SaveAll();
    return super.InternalOnClick(Sender);
}

function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
    if(Key == 0x1B)
        return false;

    // Backspace handling for the clan-name edit box
    if(Key==8 && eb_ClanName.bHasFocus)
    {
        if(eb_ClanName.CaretPos>0)
        {
            if(eb_ClanName.bAllSelected)
            {
                eb_ClanName.TextStr="";
                eb_ClanName.CaretPos=0;
                eb_ClanName.bAllSelected=False;
                eb_ClanName.TextChanged();
            }
            else
            {
                eb_ClanName.CaretPos--;
                eb_ClanName.DeleteChar();
            }
        }
    }

    if(SelClan()>=0)
        Settings.ClanSkins[SelClan()].PlayerName=eb_ClanName.GetText();
    SaveAll();
    return true;
}

function int SelClan()
{
    if(co_ClanSelect.GetIndex()>=0 && Settings.ClanSkins.Length>co_ClanSelect.GetIndex())
        return co_ClanSelect.GetIndex();
    return -1;
}

function RebuildClanCombo()
{
    local int i;

    co_ClanSelect.ReadOnly(False);
    co_ClanSelect.Clear();
    for(i=0; i<Settings.ClanSkins.Length; i++)
    {
        if(Settings.ClanSkins[i].PlayerName=="")
            co_ClanSelect.AddItem("_");
        else
            co_ClanSelect.AddItem(Settings.ClanSkins[i].PlayerName);
    }
    co_ClanSelect.ReadOnly(True);
}

function LoadClanIntoControls()
{
    local int n;

    n=SelClan();
    if(n<0)
    {
        eb_ClanName.SetText("");
        return;
    }
    eb_ClanName.SetText(Settings.ClanSkins[n].PlayerName);
    co_ClanModel.SetIndex(co_ClanModel.FindIndex(Settings.ClanSkins[n].ModelName));
    sl_ClanR.SetValue(Settings.ClanSkins[n].PlayerColor.R);
    sl_ClanG.SetValue(Settings.ClanSkins[n].PlayerColor.G);
    sl_ClanB.SetValue(Settings.ClanSkins[n].PlayerColor.B);
}

// Swap the bottom region between the Spawn-Protected band and the Clan-Skins editor.
function ShowClanPanel(bool b)
{
    l_SpawnHeader.bVisible=!b;
    l_SpEnemy.bVisible=!b;
    l_SpTeam.bVisible=!b;
    l_SpEnR.bVisible=!b; l_SpEnG.bVisible=!b; l_SpEnB.bVisible=!b;
    l_SpTmR.bVisible=!b; l_SpTmG.bVisible=!b; l_SpTmB.bVisible=!b;
    sl_SpEnR.bVisible=!b; sl_SpEnG.bVisible=!b; sl_SpEnB.bVisible=!b;
    sl_SpTmR.bVisible=!b; sl_SpTmG.bVisible=!b; sl_SpTmB.bVisible=!b;
    i_SpawnBounds.bVisible=!b;
    i_TeamBounds.bVisible=!b;

    l_ClanHeader.bVisible=b;
    l_ClanR.bVisible=b; l_ClanG.bVisible=b; l_ClanB.bVisible=b;
    co_ClanSelect.bVisible=b;
    co_ClanModel.bVisible=b;
    bu_AddClan.bVisible=b;
    bu_DeleteClan.bVisible=b;
    eb_ClanName.bVisible=b;
    sl_ClanR.bVisible=b; sl_ClanG.bVisible=b; sl_ClanB.bVisible=b;
    i_ClanBounds.bVisible=b;

    if(b)
        bu_ClanToggle.Caption="Hide Clan Skins";
    else
        bu_ClanToggle.Caption="Clan Skins";
}

// ---- preview actors ----

function InitializeSpinnies()
{
    SpinnyRed=SpawnDude(SpinnyRed);
    SpinnyBlue=SpawnDude(SpinnyBlue);
    SpinnySpawn=SpawnDude(SpinnySpawn);
    SpinnyTeam=SpawnDude(SpinnyTeam);
    SpinnyClan=SpawnDude(SpinnyClan);
}

function UTComp_SpinnyWeap SpawnDude(UTComp_SpinnyWeap D)
{
    local vector X, Y, Z, X2, Y2, V;
    local rotator R2, R;

    if(D==None)
        D=PlayerOwner().Spawn(class'UTComp_SpinnyWeap');
    if(D!=None)
    {
        D.SetDrawType(DT_Mesh);
        D.SetDrawScale(0.18);
        D.SpinRate=4000;
        D.AmbientGlow=45;

        R=PlayerOwner().Rotation;
        GetAxes(R, X, Y, Z);
        R2.Yaw=32768;
        V=vector(R2);
        X2=V.X*X + V.Y*Y;
        Y2=V.X*Y - V.Y*X;
        R2=OrthoRotation(X2, Y2, Z);
        D.SetRotation(R2);
    }
    return D;
}

function UpdateAllPreviews()
{
    UpdateSpinny(SpinnyRed, 0);
    UpdateSpinny(SpinnyBlue, 1);
    if(!bClanShown)
    {
        UpdateSpinny(SpinnySpawn, 2);
        UpdateSpinny(SpinnyTeam, 4);
    }
    else
        UpdateSpinny(SpinnyClan, 3);
}

// bColorOnly: reuse the already-linked mesh/anim and only refresh the skin colors.
// Used by the live slider drag so we don't relink the mesh every frame.
function UpdateSpinny(UTComp_SpinnyWeap Dude, byte Band, optional bool bColorOnly)
{
    local xUtil.PlayerRecord Rec;
    local Mesh PlayerMesh;
    local Material BodySkin, HeadSkin;
    local string ModelName;
    local bool bForce;
    local int idx;

    if(Dude==None)
        return;

    switch(Band)
    {
        case 0:
            PvSkinMode=Settings.ClientSkinModeRedTeammate-1;
            PvColorMode=Settings.PreferredSkinColorRedTeammate;
            PvOtherColorMode=Settings.PreferredSkinColorBlueEnemy;
            PvColor=Settings.RedTeammateUTCompSkinColor;
            ModelName=Settings.RedTeammateModelName;
            bForce=Settings.bRedTeammateModelsForced;
            break;
        case 1:
            PvSkinMode=Settings.ClientSkinModeBlueEnemy-1;
            PvColorMode=Settings.PreferredSkinColorBlueEnemy;
            PvOtherColorMode=Settings.PreferredSkinColorRedTeammate;
            PvColor=Settings.BlueEnemyUTCompSkinColor;
            ModelName=Settings.BlueEnemyModelName;
            bForce=Settings.bBlueEnemyModelsForced;
            break;
        case 2:
            PvSkinMode=2;
            PvColor=Settings.SpawnProtectedUTCompSkinColor;
            ModelName=Settings.BlueEnemyModelName;
            bForce=Settings.bBlueEnemyModelsForced;
            break;
        case 4:
            PvSkinMode=2;
            PvColor=Settings.SpawnProtectedUTCompSkinColorTeam;
            ModelName=Settings.RedTeammateModelName;
            bForce=Settings.bRedTeammateModelsForced;
            break;
        case 3:
            idx=SelClan();
            if(idx<0)
                return;
            PvSkinMode=2;
            PvColor=Settings.ClanSkins[idx].PlayerColor;
            ModelName=Settings.ClanSkins[idx].ModelName;
            bForce=True;
            break;
    }
    PvDude=Dude;

    if(bForce)
        Rec=class'xutil'.static.FindPlayerRecord(class'UTComp_xPawn'.static.IsAcceptable(ModelName));
    else if(PlayerOwner().PlayerReplicationInfo!=None)
        Rec=class'xutil'.static.FindPlayerRecord(PlayerOwner().PlayerReplicationInfo.CharacterName);
    else
        Rec=class'xutil'.static.FindPlayerRecord("Gorge");

    PlayerMesh=Mesh(DynamicLoadObject(Rec.MeshName, class'Mesh'));
    if(PlayerMesh==None)
        return;

    BodySkin=ChangeColorOfSkin(Material(DynamicLoadObject(Rec.BodySkinName, class'Material')), 0);
    HeadSkin=ChangeColorOfSkin(Material(DynamicLoadObject(Rec.FaceSkinName, class'Material')), 1);
    if(BodySkin==None || HeadSkin==None)
        return;

    if(!bColorOnly)
        Dude.LinkMesh(PlayerMesh);
    Dude.Skins[0]=BodySkin;
    Dude.Skins[1]=HeadSkin;
    if(!bColorOnly)
        Dude.LoopAnim('Idle_Rest', 1.0/Dude.Level.TimeDilation);
}

function bool DrawSpinnyClipped(Canvas Canvas, UTComp_SpinnyWeap Dude, GUIImage Bounds)
{
    local float oOrgX, oOrgY, oClipX, oClipY;
    local vector CamPos, X, Y, Z;
    local rotator CamRot;

    if(Dude==None || Bounds==None || !Bounds.bVisible)
        return true;

    oOrgX=Canvas.OrgX;
    oOrgY=Canvas.OrgY;
    oClipX=Canvas.ClipX;
    oClipY=Canvas.ClipY;

    Canvas.OrgX=Bounds.ActualLeft();
    Canvas.OrgY=Bounds.ActualTop();
    Canvas.ClipX=Bounds.ActualWidth();
    Canvas.ClipY=Bounds.ActualHeight();

    Canvas.GetCameraLocation(CamPos, CamRot);
    GetAxes(CamRot, X, Y, Z);
    Dude.SetLocation(CamPos + (SpinnyOffset.X * X) + (SpinnyOffset.Y * Y) + (SpinnyOffset.Z * Z));
    Canvas.DrawActorClipped(Dude, false, Bounds.ActualLeft(), Bounds.ActualTop(), Bounds.ActualWidth(), Bounds.ActualHeight(), true, 15);

    Canvas.OrgX=oOrgX;
    Canvas.OrgY=oOrgY;
    Canvas.ClipX=oClipX;
    Canvas.ClipY=oClipY;
    return true;
}

function bool OnDrawRed(Canvas C)   { return DrawSpinnyClipped(C, SpinnyRed, i_RedBounds); }
function bool OnDrawBlue(Canvas C)  { return DrawSpinnyClipped(C, SpinnyBlue, i_BlueBounds); }
function bool OnDrawSpawn(Canvas C) { return DrawSpinnyClipped(C, SpinnySpawn, i_SpawnBounds); }
function bool OnDrawTeam(Canvas C)  { return DrawSpinnyClipped(C, SpinnyTeam, i_TeamBounds); }
function bool OnDrawClan(Canvas C)  { return DrawSpinnyClipped(C, SpinnyClan, i_ClanBounds); }

function Free()
{
    Super.Free();
    if(SpinnyRed!=None)   { SpinnyRed.Destroy();   SpinnyRed=None; }
    if(SpinnyBlue!=None)  { SpinnyBlue.Destroy();  SpinnyBlue=None; }
    if(SpinnySpawn!=None) { SpinnySpawn.Destroy(); SpinnySpawn=None; }
    if(SpinnyTeam!=None)  { SpinnyTeam.Destroy();  SpinnyTeam=None; }
    if(SpinnyClan!=None)  { SpinnyClan.Destroy();  SpinnyClan=None; }
}

// ---- skinning helpers (read the Pv* context set by UpdateSpinny) ----

simulated function material ChangeColorOfSkin(material SkinToChange, byte SkinNum)
{
    switch(PvSkinMode)
    {
        case 0: PvDude.bUnlit=False; return ChangeOnlyColor(SkinToChange);
        case 1: PvDude.bUnlit=True;  return ChangeColorAndBrightness(SkinToChange, SkinNum);
        case 2: PvDude.bUnlit=True;  return ChangeToUTCompSkin(SkinToChange, SkinNum);
    }
    return SkinToChange;
}

simulated function material ChangeOnlyColor(material SkinToChange)
{
    local byte ColorMode;
    local byte OtherColorMode;

    ColorMode=PvColorMode;
    OtherColorMode=PvOtherColorMode;

    if(ColorMode > 3)
        ColorMode-=4;
    if(OtherColorMode > 3)
        OtherColorMode-=4;

    switch ColorMode
    {
        case 0:  return class'UTComp_xPawn'.static.MakeDMSkin(SkinToChange);
        case 1:  return class'UTComp_xPawn'.static.MakeRedSkin(SkinToChange);
        case 2:  return class'UTComp_xPawn'.static.MakeBlueSkin(SkinToChange);
        case 3:  if(OtherColorMode<2)
                     return class'UTComp_xPawn'.static.MakeBlueSkin(SkinToChange);
                 else
                     return class'UTComp_xPawn'.static.MakeRedSkin(SkinToChange);
    }
    return SkinToChange;
}

simulated function material ChangeColorAndBrightness(material SkinToChange, int SkinNum)
{
    local byte ColorMode;

    ColorMode=PvColorMode;
    switch ColorMode
    {
        case 0:  return class'UTComp_xPawn'.static.MakeDMSkin(SkinToChange);  break;
        case 1:  return class'UTComp_xPawn'.static.MakeRedSkin(SkinToChange); break;
        case 2:  return class'UTComp_xPawn'.static.MakeBlueSkin(SkinToChange);  break;
        case 3:  return MakePurpleSkin(SkinToChange);  break;
        case 4:  if(SkinNum==1)
                     return class'UTComp_xPawn'.static.MakeDMSkin(SkinToChange);
                 return class'UTComp_xPawn'.static.MakeBrightDMSkin(SkinToChange);  break;
        case 5:  if(SkinNum==1)
                     return class'UTComp_xPawn'.static.MakeRedSkin(SkinToChange);
                 return class'UTComp_xPawn'.static.MakeBrightRedSkin(SkinToChange);  break;
        case 6:  if(SkinNum==1)
                     return class'UTComp_xPawn'.static.MakeBlueSkin(SkinToChange);
                 return class'UTComp_xPawn'.static.MakeBrightBlueSkin(SkinToChange);  break;
        case 7:  if(SkinNum==1)
                     return SkinToChange;
                 return MakeBrightPurpleSkin(SkinToChange); break;
    }
}

simulated function material ChangeToUTCompSkin(material SkinToChange, byte SkinNum)
{
    local Combiner C;
    local ConstantColor CC;

    if(SkinNum>0)
        return class'UTComp_xPawn'.static.MakeDMSkin(SkinToChange);

    C=New(None)Class'Combiner';
    CC=New(None)Class'ConstantColor';

    C.CombineOperation=CO_Add;
    C.Material1=class'UTComp_xPawn'.static.MakeDMSkin(SkinToChange);
    CC.Color.R=PvColor.R;
    CC.Color.G=PvColor.G;
    CC.Color.B=PvColor.B;
    C.Material2=CC;

    if(C!=None)
        return C;
}

simulated function material MakePurpleSkin(material SkinToChange)
{
   local combiner C;
   local combiner C2;

   C=New(None)class'Combiner';
   C2=New(None)class'Combiner';
   C.CombineOperation=CO_Subtract;
   C.Material1=class'UTComp_xPawn'.static.MakeRedSkin(SkinToChange);
   C.Material2=class'UTComp_xPawn'.static.MakeBlueSkin(SkinToChange);
   C2.CombineOperation=CO_Add;
   C2.Material1=C;
   C2.Material2=C.Material1;

   if(C.Material1.IsA('Texture'))
       return C2;
   else
       return ChangeOnlyColor(SkinToChange);
}

simulated function material MakeBrightPurpleSkin(material SkinToChange)
{
    local Combiner C;

    C=New(None)class'Combiner';
    C.CombineOperation=CO_Add;
    C.Material1=class'UTComp_xPawn'.static.MakeRedSkin(SkinToChange);
    C.Material2=class'UTComp_xPawn'.static.MakeBlueSkin(SkinToChange);
    if(C.Material1.IsA('Texture'))
        return C;
    else
        return ChangeOnlyColor(SkinToChange);
}

function AddComboBoxItems(wsGUIComboBox Combo)
{
    Combo.AddItem("Abaddon");
    Combo.AddItem("Ambrosia");
    Combo.AddItem("Annika");
    Combo.AddItem("Arclite");
    Combo.AddItem("Aryss");
    Combo.AddItem("Asp");
    Combo.AddItem("Axon");
    Combo.AddItem("Azure");
    Combo.AddItem("Baird");
    Combo.AddItem("Barktooth");
    Combo.AddItem("BlackJack");
    Combo.AddItem("Brock");
    Combo.AddItem("Brutalis");
    Combo.AddItem("Cannonball");
    Combo.AddItem("Cathode");
    Combo.AddItem("ClanLord");
    Combo.AddItem("Cleopatra");
    Combo.AddItem("Cobalt");
    Combo.AddItem("Corrosion");
    Combo.AddItem("Cyclops");
    Combo.AddItem("Damarus");
    Combo.AddItem("Diva");
    Combo.AddItem("Divisor");
    Combo.AddItem("Domina");
    Combo.AddItem("Dominator");
    Combo.AddItem("Drekorig");
    Combo.AddItem("Enigma");
    Combo.AddItem("Faraleth");
    Combo.AddItem("Fate");
    Combo.AddItem("Frostbite");
    Combo.AddItem("Gaargod");
    Combo.AddItem("Garrett");
    Combo.AddItem("Gkublok");
    Combo.AddItem("Gorge");
    Combo.AddItem("Greith");
    Combo.AddItem("Guardian");
    Combo.AddItem("Harlequin");
    Combo.AddItem("Horus");
    Combo.AddItem("Hyena");
    Combo.AddItem("Jakob");
    Combo.AddItem("Kaela");
    Combo.AddItem("Karag");
    Combo.AddItem("Kane");
    Combo.AddItem("Komek");
    Combo.AddItem("Kraagesh");
    Combo.AddItem("Kragoth");
    Combo.AddItem("Lauren");
    Combo.AddItem("Lilith");
    Combo.AddItem("Makreth");
    Combo.AddItem("Malcolm");
    Combo.AddItem("Mandible");
    Combo.AddItem("Matrix");
    Combo.AddItem("Memphis");
    Combo.AddItem("Mekkor");
    Combo.AddItem("Mokara");
    Combo.AddItem("Motig");
    Combo.AddItem("Mr.Crow");
    Combo.AddItem("Nebri");
    Combo.AddItem("Ophelia");
    Combo.AddItem("Othello");
    Combo.AddItem("Outlaw");
    Combo.AddItem("Prism");
    Combo.AddItem("Rae");
    Combo.AddItem("Rapier");
    Combo.AddItem("Ravage");
    Combo.AddItem("Reinha");
    Combo.AddItem("Remus");
    Combo.AddItem("Renegade");
    Combo.AddItem("Riker");
    Combo.AddItem("Roc");
    Combo.AddItem("Romulus");
    Combo.AddItem("Rylisa");
    Combo.AddItem("Sapphire");
    Combo.AddItem("Satin");
    Combo.AddItem("Scarab");
    Combo.AddItem("Selig");
    Combo.AddItem("Siren");
    Combo.AddItem("Skakruk");
    Combo.AddItem("Skrilax");
    Combo.AddItem("Subversa");
    Combo.AddItem("Syzygy");
    Combo.AddItem("Tamika");
    Combo.AddItem("Torch");
    Combo.AddItem("Thannis");
    Combo.AddItem("Thorax");
    Combo.AddItem("Virus");
    Combo.AddItem("Widowmaker");
    Combo.AddItem("Wraith");
    Combo.AddItem("Xan");
    Combo.AddItem("Zarina");
}

defaultproperties
{
     SpinnyOffset=(X=280.000000,Y=1.000000,Z=2.000000)

     // ---------- top toggles ----------
     Begin Object Class=wsCheckBox Name=EnemyBasedSkinCheck
         Caption="Enemy Based Skins"
         Hint="Color is based on your team/enemy team instead of red/blue"
         OnCreateComponent=EnemyBasedSkinCheck.InternalOnCreateComponent
         WinWidth=0.200000
         WinHeight=0.030000
         WinLeft=0.090000
         WinTop=0.300000
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
     End Object
     ch_EnemySkins=wsCheckBox'UTComp_Menu_BrightSkins.EnemyBasedSkinCheck'

     Begin Object Class=wsCheckBox Name=EnemyBasedModelCheck
         Caption="Enemy Based Models"
         Hint="Model is based on your team/enemy team instead of red/blue"
         OnCreateComponent=EnemyBasedModelCheck.InternalOnCreateComponent
         WinWidth=0.220000
         WinHeight=0.030000
         WinLeft=0.400000
         WinTop=0.300000
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
     End Object
     ch_EnemyModels=wsCheckBox'UTComp_Menu_BrightSkins.EnemyBasedModelCheck'

     Begin Object Class=wsCheckBox Name=DarkSkinCheck
         Caption="Darken Dead Bodies"
         OnCreateComponent=DarkSkinCheck.InternalOnCreateComponent
         WinWidth=0.200000
         WinHeight=0.030000
         WinLeft=0.720000
         WinTop=0.300000
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
     End Object
     ch_DarkSkins=wsCheckBox'UTComp_Menu_BrightSkins.DarkSkinCheck'

     // ---------- red band ----------
     Begin Object Class=GUILabel Name=RedHeaderLabel
         Caption="Red Team"
         TextColor=(R=255,G=80,B=80)
         WinTop=0.330000
         WinLeft=0.090000
     End Object
     l_RedHeader=GUILabel'UTComp_Menu_BrightSkins.RedHeaderLabel'

     Begin Object Class=wsCheckBox Name=RedForceCheck
         Caption="Force Model"
         OnCreateComponent=RedForceCheck.InternalOnCreateComponent
         WinWidth=0.125000
         WinHeight=0.030000
         WinLeft=0.090000
         WinTop=0.385000
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
     End Object
     ch_RedForce=wsCheckBox'UTComp_Menu_BrightSkins.RedForceCheck'

     Begin Object Class=wsGUIComboBox Name=RedStyleCombo
         WinWidth=0.167000
         WinHeight=0.033000
         WinLeft=0.180000
         WinTop=0.345000
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
         OnKeyEvent=RedStyleCombo.InternalOnKeyEvent
     End Object
     co_RedStyle=wsGUIComboBox'UTComp_Menu_BrightSkins.RedStyleCombo'

     Begin Object Class=wsGUIComboBox Name=RedModelCombo
         WinWidth=0.127000
         WinHeight=0.033000
         WinLeft=0.220000
         WinTop=0.385000
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
         OnKeyEvent=RedModelCombo.InternalOnKeyEvent
     End Object
     co_RedModel=wsGUIComboBox'UTComp_Menu_BrightSkins.RedModelCombo'

     Begin Object Class=GUILabel Name=RedRLabel
         Caption="R"
         TextColor=(R=255)
         WinTop=0.450000
         WinLeft=0.090000
     End Object
     l_RedR=GUILabel'UTComp_Menu_BrightSkins.RedRLabel'

     Begin Object Class=GUILabel Name=RedGLabel
         Caption="G"
         TextColor=(G=255)
         WinTop=0.485000
         WinLeft=0.090000
     End Object
     l_RedG=GUILabel'UTComp_Menu_BrightSkins.RedGLabel'

     Begin Object Class=GUILabel Name=RedBLabel
         Caption="B"
         TextColor=(B=255)
         WinTop=0.520000
         WinLeft=0.090000
     End Object
     l_RedB=GUILabel'UTComp_Menu_BrightSkins.RedBLabel'

     Begin Object Class=wsGUISlider Name=RedRSlider
         MaxValue=128.000000
         bIntSlider=True
         WinTop=0.465000
         WinLeft=0.112000
         WinWidth=0.155000
         OnClick=RedRSlider.InternalOnClick
         OnMousePressed=RedRSlider.InternalOnMousePressed
         OnMouseRelease=RedRSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
         OnKeyEvent=RedRSlider.InternalOnKeyEvent
         OnCapturedMouseMove=RedRSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_BrightSkins.OnSlide
     End Object
     sl_RedR=wsGUISlider'UTComp_Menu_BrightSkins.RedRSlider'

     Begin Object Class=wsGUISlider Name=RedGSlider
         MaxValue=128.000000
         bIntSlider=True
         WinTop=0.500000
         WinLeft=0.112000
         WinWidth=0.155000
         OnClick=RedGSlider.InternalOnClick
         OnMousePressed=RedGSlider.InternalOnMousePressed
         OnMouseRelease=RedGSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
         OnKeyEvent=RedGSlider.InternalOnKeyEvent
         OnCapturedMouseMove=RedGSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_BrightSkins.OnSlide
     End Object
     sl_RedG=wsGUISlider'UTComp_Menu_BrightSkins.RedGSlider'

     Begin Object Class=wsGUISlider Name=RedBSlider
         MaxValue=128.000000
         bIntSlider=True
         WinTop=0.535000
         WinLeft=0.112000
         WinWidth=0.155000
         OnClick=RedBSlider.InternalOnClick
         OnMousePressed=RedBSlider.InternalOnMousePressed
         OnMouseRelease=RedBSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
         OnKeyEvent=RedBSlider.InternalOnKeyEvent
         OnCapturedMouseMove=RedBSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_BrightSkins.OnSlide
     End Object
     sl_RedB=wsGUISlider'UTComp_Menu_BrightSkins.RedBSlider'

     Begin Object Class=GUIImage Name=RedBoundsImage
         Image=Material'2K4Menus.Controls.buttonSquare_b'
         ImageColor=(R=255,G=255,B=255,A=128)
         ImageRenderStyle=MSTY_Alpha
         ImageStyle=ISTY_Stretched
         bScaleToParent=true
         bBoundToParent=true
         WinWidth=0.255000
         WinHeight=0.165000
         WinLeft=0.240000
         WinTop=0.418000
         RenderWeight=0.52
         OnDraw=OnDrawRed
     End Object
     i_RedBounds=GUIImage'UTComp_Menu_BrightSkins.RedBoundsImage'

     // ---------- blue band ----------
     Begin Object Class=GUILabel Name=BlueHeaderLabel
         Caption="Blue Team"
         TextColor=(R=80,G=80,B=255)
         WinTop=0.330000
         WinLeft=0.510000
     End Object
     l_BlueHeader=GUILabel'UTComp_Menu_BrightSkins.BlueHeaderLabel'

     Begin Object Class=wsCheckBox Name=BlueForceCheck
         Caption="Force Model"
         OnCreateComponent=BlueForceCheck.InternalOnCreateComponent
         WinWidth=0.125000
         WinHeight=0.030000
         WinLeft=0.510000
         WinTop=0.385000
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
     End Object
     ch_BlueForce=wsCheckBox'UTComp_Menu_BrightSkins.BlueForceCheck'

     Begin Object Class=wsGUIComboBox Name=BlueStyleCombo
         WinWidth=0.167000
         WinHeight=0.033000
         WinLeft=0.600000
         WinTop=0.345000
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
         OnKeyEvent=BlueStyleCombo.InternalOnKeyEvent
     End Object
     co_BlueStyle=wsGUIComboBox'UTComp_Menu_BrightSkins.BlueStyleCombo'

     Begin Object Class=wsGUIComboBox Name=BlueModelCombo
         WinWidth=0.127000
         WinHeight=0.033000
         WinLeft=0.640000
         WinTop=0.385000
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
         OnKeyEvent=BlueModelCombo.InternalOnKeyEvent
     End Object
     co_BlueModel=wsGUIComboBox'UTComp_Menu_BrightSkins.BlueModelCombo'

     Begin Object Class=GUILabel Name=BlueRLabel
         Caption="R"
         TextColor=(R=255)
         WinTop=0.450000
         WinLeft=0.510000
     End Object
     l_BlueR=GUILabel'UTComp_Menu_BrightSkins.BlueRLabel'

     Begin Object Class=GUILabel Name=BlueGLabel
         Caption="G"
         TextColor=(G=255)
         WinTop=0.485000
         WinLeft=0.510000
     End Object
     l_BlueG=GUILabel'UTComp_Menu_BrightSkins.BlueGLabel'

     Begin Object Class=GUILabel Name=BlueBLabel
         Caption="B"
         TextColor=(B=255)
         WinTop=0.520000
         WinLeft=0.510000
     End Object
     l_BlueB=GUILabel'UTComp_Menu_BrightSkins.BlueBLabel'

     Begin Object Class=wsGUISlider Name=BlueRSlider
         MaxValue=128.000000
         bIntSlider=True
         WinTop=0.465000
         WinLeft=0.532000
         WinWidth=0.155000
         OnClick=BlueRSlider.InternalOnClick
         OnMousePressed=BlueRSlider.InternalOnMousePressed
         OnMouseRelease=BlueRSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
         OnKeyEvent=BlueRSlider.InternalOnKeyEvent
         OnCapturedMouseMove=BlueRSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_BrightSkins.OnSlide
     End Object
     sl_BlueR=wsGUISlider'UTComp_Menu_BrightSkins.BlueRSlider'

     Begin Object Class=wsGUISlider Name=BlueGSlider
         MaxValue=128.000000
         bIntSlider=True
         WinTop=0.500000
         WinLeft=0.532000
         WinWidth=0.155000
         OnClick=BlueGSlider.InternalOnClick
         OnMousePressed=BlueGSlider.InternalOnMousePressed
         OnMouseRelease=BlueGSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
         OnKeyEvent=BlueGSlider.InternalOnKeyEvent
         OnCapturedMouseMove=BlueGSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_BrightSkins.OnSlide
     End Object
     sl_BlueG=wsGUISlider'UTComp_Menu_BrightSkins.BlueGSlider'

     Begin Object Class=wsGUISlider Name=BlueBSlider
         MaxValue=128.000000
         bIntSlider=True
         WinTop=0.535000
         WinLeft=0.532000
         WinWidth=0.155000
         OnClick=BlueBSlider.InternalOnClick
         OnMousePressed=BlueBSlider.InternalOnMousePressed
         OnMouseRelease=BlueBSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
         OnKeyEvent=BlueBSlider.InternalOnKeyEvent
         OnCapturedMouseMove=BlueBSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_BrightSkins.OnSlide
     End Object
     sl_BlueB=wsGUISlider'UTComp_Menu_BrightSkins.BlueBSlider'

     Begin Object Class=GUIImage Name=BlueBoundsImage
         Image=Material'2K4Menus.Controls.buttonSquare_b'
         ImageColor=(R=255,G=255,B=255,A=128)
         ImageRenderStyle=MSTY_Alpha
         ImageStyle=ISTY_Stretched
         bScaleToParent=true
         bBoundToParent=true
         WinWidth=0.255000
         WinHeight=0.165000
         WinLeft=0.660000
         WinTop=0.418000
         RenderWeight=0.52
         OnDraw=OnDrawBlue
     End Object
     i_BlueBounds=GUIImage'UTComp_Menu_BrightSkins.BlueBoundsImage'

     // ---------- spawn protected band ----------
     Begin Object Class=GUILabel Name=SpawnHeaderLabel
         Caption=""
         TextColor=(R=255,G=255,B=0)
         WinTop=0.610000
         WinLeft=0.090000
     End Object
     l_SpawnHeader=GUILabel'UTComp_Menu_BrightSkins.SpawnHeaderLabel'

     Begin Object Class=GUILabel Name=SpEnRLabel
         Caption="R"
         TextColor=(R=255)
         WinTop=0.595000
         WinLeft=0.510000
     End Object
     l_SpEnR=GUILabel'UTComp_Menu_BrightSkins.SpEnRLabel'

     Begin Object Class=GUILabel Name=SpEnGLabel
         Caption="G"
         TextColor=(G=255)
         WinTop=0.630000
         WinLeft=0.510000
     End Object
     l_SpEnG=GUILabel'UTComp_Menu_BrightSkins.SpEnGLabel'

     Begin Object Class=GUILabel Name=SpEnBLabel
         Caption="B"
         TextColor=(B=255)
         WinTop=0.665000
         WinLeft=0.510000
     End Object
     l_SpEnB=GUILabel'UTComp_Menu_BrightSkins.SpEnBLabel'

     Begin Object Class=GUILabel Name=SpTmRLabel
         Caption="R"
         TextColor=(R=255)
         WinTop=0.595000
         WinLeft=0.090000
     End Object
     l_SpTmR=GUILabel'UTComp_Menu_BrightSkins.SpTmRLabel'

     Begin Object Class=GUILabel Name=SpTmGLabel
         Caption="G"
         TextColor=(G=255)
         WinTop=0.630000
         WinLeft=0.090000
     End Object
     l_SpTmG=GUILabel'UTComp_Menu_BrightSkins.SpTmGLabel'

     Begin Object Class=GUILabel Name=SpTmBLabel
         Caption="B"
         TextColor=(B=255)
         WinTop=0.665000
         WinLeft=0.090000
     End Object
     l_SpTmB=GUILabel'UTComp_Menu_BrightSkins.SpTmBLabel'

     Begin Object Class=GUILabel Name=SpEnemyLabel
         Caption="Spawn protected"
         TextColor=(R=255,G=255,B=255)
         WinTop=0.560000
         WinLeft=0.510000
     End Object
     l_SpEnemy=GUILabel'UTComp_Menu_BrightSkins.SpEnemyLabel'

     Begin Object Class=GUILabel Name=SpTeamLabel
         Caption="Spawn protected"
         TextColor=(R=255,G=255,B=255)
         WinTop=0.560000
         WinLeft=0.090000
     End Object
     l_SpTeam=GUILabel'UTComp_Menu_BrightSkins.SpTeamLabel'

     Begin Object Class=wsGUISlider Name=SpEnRSlider
         MaxValue=128.000000
         bIntSlider=True
         WinTop=0.610000
         WinLeft=0.532000
         WinWidth=0.155000
         OnClick=SpEnRSlider.InternalOnClick
         OnMousePressed=SpEnRSlider.InternalOnMousePressed
         OnMouseRelease=SpEnRSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
         OnKeyEvent=SpEnRSlider.InternalOnKeyEvent
         OnCapturedMouseMove=SpEnRSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_BrightSkins.OnSlide
     End Object
     sl_SpEnR=wsGUISlider'UTComp_Menu_BrightSkins.SpEnRSlider'

     Begin Object Class=wsGUISlider Name=SpEnGSlider
         MaxValue=128.000000
         bIntSlider=True
         WinTop=0.645000
         WinLeft=0.532000
         WinWidth=0.155000
         OnClick=SpEnGSlider.InternalOnClick
         OnMousePressed=SpEnGSlider.InternalOnMousePressed
         OnMouseRelease=SpEnGSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
         OnKeyEvent=SpEnGSlider.InternalOnKeyEvent
         OnCapturedMouseMove=SpEnGSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_BrightSkins.OnSlide
     End Object
     sl_SpEnG=wsGUISlider'UTComp_Menu_BrightSkins.SpEnGSlider'

     Begin Object Class=wsGUISlider Name=SpEnBSlider
         MaxValue=128.000000
         bIntSlider=True
         WinTop=0.680000
         WinLeft=0.532000
         WinWidth=0.155000
         OnClick=SpEnBSlider.InternalOnClick
         OnMousePressed=SpEnBSlider.InternalOnMousePressed
         OnMouseRelease=SpEnBSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
         OnKeyEvent=SpEnBSlider.InternalOnKeyEvent
         OnCapturedMouseMove=SpEnBSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_BrightSkins.OnSlide
     End Object
     sl_SpEnB=wsGUISlider'UTComp_Menu_BrightSkins.SpEnBSlider'

     Begin Object Class=wsGUISlider Name=SpTmRSlider
         MaxValue=128.000000
         bIntSlider=True
         WinTop=0.610000
         WinLeft=0.112000
         WinWidth=0.155000
         OnClick=SpTmRSlider.InternalOnClick
         OnMousePressed=SpTmRSlider.InternalOnMousePressed
         OnMouseRelease=SpTmRSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
         OnKeyEvent=SpTmRSlider.InternalOnKeyEvent
         OnCapturedMouseMove=SpTmRSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_BrightSkins.OnSlide
     End Object
     sl_SpTmR=wsGUISlider'UTComp_Menu_BrightSkins.SpTmRSlider'

     Begin Object Class=wsGUISlider Name=SpTmGSlider
         MaxValue=128.000000
         bIntSlider=True
         WinTop=0.645000
         WinLeft=0.112000
         WinWidth=0.155000
         OnClick=SpTmGSlider.InternalOnClick
         OnMousePressed=SpTmGSlider.InternalOnMousePressed
         OnMouseRelease=SpTmGSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
         OnKeyEvent=SpTmGSlider.InternalOnKeyEvent
         OnCapturedMouseMove=SpTmGSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_BrightSkins.OnSlide
     End Object
     sl_SpTmG=wsGUISlider'UTComp_Menu_BrightSkins.SpTmGSlider'

     Begin Object Class=wsGUISlider Name=SpTmBSlider
         MaxValue=128.000000
         bIntSlider=True
         WinTop=0.680000
         WinLeft=0.112000
         WinWidth=0.155000
         OnClick=SpTmBSlider.InternalOnClick
         OnMousePressed=SpTmBSlider.InternalOnMousePressed
         OnMouseRelease=SpTmBSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
         OnKeyEvent=SpTmBSlider.InternalOnKeyEvent
         OnCapturedMouseMove=SpTmBSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_BrightSkins.OnSlide
     End Object
     sl_SpTmB=wsGUISlider'UTComp_Menu_BrightSkins.SpTmBSlider'

     Begin Object Class=GUIImage Name=SpawnBoundsImage
         Image=Material'2K4Menus.Controls.buttonSquare_b'
         ImageColor=(R=255,G=255,B=255,A=128)
         ImageRenderStyle=MSTY_Alpha
         ImageStyle=ISTY_Stretched
         bScaleToParent=true
         bBoundToParent=true
         WinWidth=0.255000
         WinHeight=0.165000
         WinLeft=0.660000
         WinTop=0.600000
         RenderWeight=0.52
         OnDraw=OnDrawSpawn
     End Object
     i_SpawnBounds=GUIImage'UTComp_Menu_BrightSkins.SpawnBoundsImage'

     Begin Object Class=GUIImage Name=TeamBoundsImage
         Image=Material'2K4Menus.Controls.buttonSquare_b'
         ImageColor=(R=255,G=255,B=255,A=128)
         ImageRenderStyle=MSTY_Alpha
         ImageStyle=ISTY_Stretched
         bScaleToParent=true
         bBoundToParent=true
         WinWidth=0.255000
         WinHeight=0.165000
         WinLeft=0.240000
         WinTop=0.600000
         RenderWeight=0.52
         OnDraw=OnDrawTeam
     End Object
     i_TeamBounds=GUIImage'UTComp_Menu_BrightSkins.TeamBoundsImage'

     // ---------- clan skins (hidden until toggled) ----------
     Begin Object Class=GUILabel Name=ClanHeaderLabel
         Caption="Clan Skins"
         TextColor=(R=0,G=255,B=255)
         WinTop=0.560000
         WinLeft=0.090000
         bVisible=false
     End Object
     l_ClanHeader=GUILabel'UTComp_Menu_BrightSkins.ClanHeaderLabel'

     Begin Object Class=wsGUIComboBox Name=ClanSelectCombo
         WinWidth=0.220000
         WinHeight=0.033000
         WinLeft=0.090000
         WinTop=0.623000
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
         OnKeyEvent=ClanSelectCombo.InternalOnKeyEvent
         bVisible=false
     End Object
     co_ClanSelect=wsGUIComboBox'UTComp_Menu_BrightSkins.ClanSelectCombo'

     Begin Object Class=GUIButton Name=AddClanButton
         Caption="Add"
         StyleName="WSButton"
         WinWidth=0.080000
         WinHeight=0.040000
         WinLeft=0.325000
         WinTop=0.621000
         OnClick=UTComp_Menu_BrightSkins.InternalOnClick
         OnKeyEvent=AddClanButton.InternalOnKeyEvent
         bVisible=false
     End Object
     bu_AddClan=GUIButton'UTComp_Menu_BrightSkins.AddClanButton'

     Begin Object Class=GUIButton Name=DeleteClanButton
         Caption="Delete"
         StyleName="WSButton"
         WinWidth=0.100000
         WinHeight=0.040000
         WinLeft=0.415000
         WinTop=0.621000
         OnClick=UTComp_Menu_BrightSkins.InternalOnClick
         OnKeyEvent=DeleteClanButton.InternalOnKeyEvent
         bVisible=false
     End Object
     bu_DeleteClan=GUIButton'UTComp_Menu_BrightSkins.DeleteClanButton'

     Begin Object Class=GUIEditBox Name=ClanNameEdit
         StyleName="WSEditBox"
         WinWidth=0.200000
         WinHeight=0.033000
         WinLeft=0.090000
         WinTop=0.660000
         OnActivate=ClanNameEdit.InternalActivate
         OnDeActivate=ClanNameEdit.InternalDeactivate
         OnKeyType=ClanNameEdit.InternalOnKeyType
         OnKeyEvent=UTComp_Menu_BrightSkins.InternalOnKeyEvent
         bVisible=false
     End Object
     eb_ClanName=GUIEditBox'UTComp_Menu_BrightSkins.ClanNameEdit'

     Begin Object Class=wsGUIComboBox Name=ClanModelCombo
         WinWidth=0.200000
         WinHeight=0.033000
         WinLeft=0.305000
         WinTop=0.660000
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
         OnKeyEvent=ClanModelCombo.InternalOnKeyEvent
         bVisible=false
     End Object
     co_ClanModel=wsGUIComboBox'UTComp_Menu_BrightSkins.ClanModelCombo'

     Begin Object Class=GUILabel Name=ClanRLabel
         Caption="R"
         TextColor=(R=255)
         WinTop=0.605000
         WinLeft=0.535000
         bVisible=false
     End Object
     l_ClanR=GUILabel'UTComp_Menu_BrightSkins.ClanRLabel'

     Begin Object Class=GUILabel Name=ClanGLabel
         Caption="G"
         TextColor=(G=255)
         WinTop=0.630000
         WinLeft=0.535000
         bVisible=false
     End Object
     l_ClanG=GUILabel'UTComp_Menu_BrightSkins.ClanGLabel'

     Begin Object Class=GUILabel Name=ClanBLabel
         Caption="B"
         TextColor=(B=255)
         WinTop=0.655000
         WinLeft=0.535000
         bVisible=false
     End Object
     l_ClanB=GUILabel'UTComp_Menu_BrightSkins.ClanBLabel'

     Begin Object Class=wsGUISlider Name=ClanRSlider
         MaxValue=128.000000
         bIntSlider=True
         WinTop=0.620000
         WinLeft=0.565000
         WinWidth=0.130000
         OnClick=ClanRSlider.InternalOnClick
         OnMousePressed=ClanRSlider.InternalOnMousePressed
         OnMouseRelease=ClanRSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
         OnKeyEvent=ClanRSlider.InternalOnKeyEvent
         OnCapturedMouseMove=ClanRSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_BrightSkins.OnSlide
         bVisible=false
     End Object
     sl_ClanR=wsGUISlider'UTComp_Menu_BrightSkins.ClanRSlider'

     Begin Object Class=wsGUISlider Name=ClanGSlider
         MaxValue=128.000000
         bIntSlider=True
         WinTop=0.645000
         WinLeft=0.565000
         WinWidth=0.130000
         OnClick=ClanGSlider.InternalOnClick
         OnMousePressed=ClanGSlider.InternalOnMousePressed
         OnMouseRelease=ClanGSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
         OnKeyEvent=ClanGSlider.InternalOnKeyEvent
         OnCapturedMouseMove=ClanGSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_BrightSkins.OnSlide
         bVisible=false
     End Object
     sl_ClanG=wsGUISlider'UTComp_Menu_BrightSkins.ClanGSlider'

     Begin Object Class=wsGUISlider Name=ClanBSlider
         MaxValue=128.000000
         bIntSlider=True
         WinTop=0.670000
         WinLeft=0.565000
         WinWidth=0.130000
         OnClick=ClanBSlider.InternalOnClick
         OnMousePressed=ClanBSlider.InternalOnMousePressed
         OnMouseRelease=ClanBSlider.InternalOnMouseRelease
         OnChange=UTComp_Menu_BrightSkins.InternalOnChange
         OnKeyEvent=ClanBSlider.InternalOnKeyEvent
         OnCapturedMouseMove=ClanBSlider.InternalCapturedMouseMove
         OnSliding=UTComp_Menu_BrightSkins.OnSlide
         bVisible=false
     End Object
     sl_ClanB=wsGUISlider'UTComp_Menu_BrightSkins.ClanBSlider'

     Begin Object Class=GUIImage Name=ClanBoundsImage
         Image=Material'2K4Menus.Controls.buttonSquare_b'
         ImageColor=(R=255,G=255,B=255,A=128)
         ImageRenderStyle=MSTY_Alpha
         ImageStyle=ISTY_Stretched
         bScaleToParent=true
         bBoundToParent=true
         WinWidth=0.255000
         WinHeight=0.165000
         WinLeft=0.660000
         WinTop=0.600000
         RenderWeight=0.52
         OnDraw=OnDrawClan
         bVisible=false
     End Object
     i_ClanBounds=GUIImage'UTComp_Menu_BrightSkins.ClanBoundsImage'

     // ---------- bottom buttons ----------
     Begin Object Class=GUIButton Name=ClanToggleButton
         Caption="Clan Skins"
         StyleName="WSButton"
         WinWidth=0.240000
         WinHeight=0.045000
         WinLeft=0.090000
         WinTop=0.745000
         OnClick=UTComp_Menu_BrightSkins.InternalOnClick
         OnKeyEvent=ClanToggleButton.InternalOnKeyEvent
     End Object
     bu_ClanToggle=GUIButton'UTComp_Menu_BrightSkins.ClanToggleButton'

     Begin Object Class=GUIButton Name=ResetSkinsButton
         Caption="Reset Skins"
         StyleName="WSButton"
         WinWidth=0.240000
         WinHeight=0.045000
         WinLeft=0.670000
         WinTop=0.745000
         OnClick=UTComp_Menu_BrightSkins.InternalOnClick
         OnKeyEvent=ResetSkinsButton.InternalOnKeyEvent
     End Object
     bu_ResetSkins=GUIButton'UTComp_Menu_BrightSkins.ResetSkinsButton'
}
