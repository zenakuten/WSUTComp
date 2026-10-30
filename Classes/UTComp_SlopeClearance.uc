// Post-physics hook for UTComp_xPawn.ApplySlopeClearance. Queued as the pawn's
// PendingTouch like JumpPad, so the engine calls PostTouch at the end of the pawn's
// physics step wherever that step runs: prediction, replays, ServerMove, standalone.
// Each machine spawns its own (Info is ROLE_None).
class UTComp_SlopeClearance extends Info;

event PostTouch(Actor Other)
{
    local Actor A;

    if (UTComp_xPawn(Other) != None)
        UTComp_xPawn(Other).ApplySlopeClearance();

    // A touch during that Move may have queued itself in front of us, and the engine
    // pops the head without calling it: put ourselves back on top
    A = Other.PendingTouch;
    if (A != self && A != None && A.PendingTouch == self)
    {
        A.PendingTouch = PendingTouch;
        PendingTouch = A;
        Other.PendingTouch = self;
    }
}
