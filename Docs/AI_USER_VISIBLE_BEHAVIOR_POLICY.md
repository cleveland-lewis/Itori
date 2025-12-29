AI User-Visible Behavior Policy

Purpose
- Define the only three user-visible AI behaviors and their boundaries.
- Prevent invisible AI leaks by enforcing calm, predictable UX.

Allowed behaviors
1. Smart defaults
   - Pre-filled values the user can edit.
2. Soft suggestions
   - Non-blocking chips/tooltips that say "Suggested: …".
3. Background improvements
   - Future defaults get better; current state does not jump.

Not allowed
- Values changing under the cursor.
- Sudden reordering of lists.
- Auto-creating events without explicit apply action.
- Any "AI said…" phrasing.

Policy enum
- `AIMergePolicy.defaultOnly` maps to Smart defaults.
- `AIMergePolicy.suggestOnly` maps to Soft suggestions.
- `AIMergePolicy.explicitApplyRequired` maps to Explicit apply.

Guiding principle
- Invisible does not mean instant. It means predictable and calm.
