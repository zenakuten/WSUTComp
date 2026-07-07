//-----------------------------------------------------------
//  A preview-only variant of XEffects.DeResPart for the extra
//  menu's ghost fx preview dude.
//
//  The stock DeResPart does a one-shot initial burst and has
//  AutoDestroy=True. In the menu the emitter is spawned before
//  the preview dude is moved in front of the camera, so that
//  burst spawns off-screen; all its particles share the same
//  0.9s lifetime and die together, which trips AutoDestroy and
//  removes the emitter before it is ever seen.
//
//  This variant emits continuously (like MutantGlow) and never
//  auto-destroys, so it keeps a steady particle cloud at the
//  dude's current skeletal location for as long as the menu is
//  open. Emitters[0] stays a SpriteEmitter with three ColorScale
//  stops so UTComp_Menu_Extra.UpdateGhostColors can tint it from
//  the ghost fx sliders exactly like UTComp_xPawn.StartDeRes.
//-----------------------------------------------------------
class UTComp_DeResPreview extends Emitter;

#exec OBJ LOAD FILE=EpicParticles.utx

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=SpriteEmitter0
         UseColorScale=True
         FadeOut=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         // All spatial params below are the stock XEffects.DeResPart values multiplied by
         // the preview dude's DrawScale (0.28, set in UTComp_Menu_Extra.LinkDude). Skeletal
         // bone positions are DrawScale-independent (mesh-local space), while the rendered
         // dude scales with DrawScale, so scaling these by 0.28 makes the particle cloud
         // cover the shrunk dude just like the stock effect covers a full-size pawn.
         // gravity: -50 * 0.28
         Acceleration=(Z=-14.000000)
         ColorScale(0)=(Color=(B=6,G=255,R=6))
         ColorScale(1)=(RelativeTime=0.700000,Color=(B=190,G=190))
         ColorScale(2)=(RelativeTime=1.000000,Color=(B=190,G=190))
         ColorMultiplierRange=(Z=(Min=0.500000,Max=0.500000))
         FadeOutStartTime=0.700000
         MaxParticles=200
         // ±4 * 0.28
         StartLocationRange=(X=(Min=-1.120000,Max=1.120000),Y=(Min=-1.120000,Max=1.120000),Z=(Min=-1.120000,Max=1.120000))
         UseRotationFrom=PTRS_Actor
         SizeScale(0)=(RelativeSize=1.700000)
         SizeScale(1)=(RelativeTime=1.000000)
         // (2-3) * 0.28
         StartSizeRange=(X=(Min=0.560000,Max=0.840000),Y=(Min=0.560000,Max=0.840000))
         // The preview dude is teleported to the camera every frame. Independent-space
         // particles would be left behind by that teleport, so use relative coords (like
         // MutantGlow) and spawn AT the skeletal bones so particles ride with the dude.
         CoordinateSystem=PTCS_Relative
         UseSkeletalLocationAs=PTSU_Location
         // 0.38 * 0.28
         SkeletalScale=(X=0.106000,Y=0.106000,Z=0.106000)
         Texture=Texture'EpicParticles.Flares.BurnFlare1'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.900000,Max=0.900000)
         // Continuous emission instead of a one-shot burst: spawn steadily so the
         // cloud stays populated and particle deaths are staggered (no synchronized
         // die-off that would trip AutoDestroy).
         AutomaticInitialSpawning=False
         InitialParticlesPerSecond=300.000000
         Name="SpriteEmitter0"
     End Object
     Emitters(0)=SpriteEmitter'SpriteEmitter0'

     // Never self-destruct; the menu destroys us in Free().
     AutoDestroy=False
     bNoDelete=False
     bNetTemporary=True
     bHardAttach=True
}
