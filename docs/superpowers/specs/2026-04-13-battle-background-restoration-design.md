# Battle Background Restoration Design

## Goal
Restore the battle arena background so the scene no longer feels like characters are fighting on an empty stage, while preserving the current unit readability and depth-ordering behavior that has already been accepted.

## Scope
This change only covers battle scene background presentation in `scenes/battle/battle_scene.tscn` and related runtime validation. It does not change unit size, spawn layout, combat pacing, or unit overlap sorting.

## Recommended Approach
Restore the full arena presentation stack, but keep it visually subordinate to the units.

This means:
- Re-enable the currently hidden arena nodes, including `ArenaFloor` and supporting decorative arena elements.
- Keep all arena visuals behind the unit layer.
- Use weak/soft presentation values so the arena is visible but does not compete with unit silhouettes.
- Preserve the current runtime script and unit depth-sort behavior.

## Alternatives Considered

### 1. Restore only `ArenaFloor`
- Smallest change.
- Lowest risk.
- Rejected because the user explicitly wants the complete battlefield back, not only the floor texture.

### 2. Restore full arena with weak styling
- Restores scene completeness.
- Keeps units as the main visual subject.
- Recommended because it matches the user request and minimizes regression risk to unit readability.

### 3. Add runtime toggles for arena visibility
- More flexible.
- Adds implementation complexity and unnecessary branching.
- Rejected as over-scoped for the current request.

## Design Details

### Scene composition
The arena-related nodes in `battle_scene.tscn` that are currently hidden should be restored to visible state. These nodes remain static scene dressing and should not be managed by runtime combat logic.

### Visual hierarchy
The arena must remain visually behind all units and combat effects that need to read clearly. Unit readability remains the top priority.

### Styling rule
If any restored arena node feels too strong after re-enabling, weaken it through existing scene properties such as modulation, transparency, or subtle sizing/position tuning. Do not introduce a new background system.

### Runtime behavior
No new runtime switching logic is needed. The arena should be present both during the initialization presentation state and the active combat state.

## Testing Strategy
- Verify the battle scene shows a visible arena background in the initial frame.
- Verify the restored background does not hide or visually overpower the characters.
- Verify accepted unit overlap sorting still reads correctly on top of the restored arena.
- Run the existing Godot startup and test commands after scene changes.

## Success Criteria
- `ArenaFloor` is visible in the battle scene.
- The broader arena presentation is visible again, not just isolated units on a blank field.
- Units remain the dominant readable element.
- Previously accepted depth ordering remains intact.
- Scene startup and test verification succeed.
