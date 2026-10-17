# Spottr — current Stitch context
Updated 12 October 2026. Reference-inspired design planning; no implementation, commit, merge or publish.

## Current sources
- [DESIGN.md](../DESIGN.md): current proposed system and workout composition.
- [Semantic tokens](design-tokens.json): exact proposed light/dark colors and dimensions.
- [First workout prompt](stitch-reference-workout-prompt.md): copy-ready anchor prompt.
- [Product](product.md), [roadmap](roadmap.md), [experience](experience.md): behavior and phase status.

## Agreed visual direction
The user agreed to combine the healthcare Behance reference's soft composition/rounded forms with the nutrition reference's warmth and accent treatment. Root DESIGN.md cites both visually inspected projects. Proposed adaptation: cool gray/white surfaces, coral actions, quiet sage completion and clear Inter type.
All earlier generated candidates were rejected. Their files/screens remain historical, not current generation instructions. Do not reuse earlier design-system assets.
Review proposed exact tokens and Focus composition before generating one light ready screen. Subsequent completed/rest/dark/overview/tablet screens follow after anchor review.

## Fixed product contracts
Offline Flutter for Android/iOS, kg only, Today/Plans/Progress tabs and separate workout flow. Visible optional plan-entry note, copied into sessions. Prefill from completed history for existing entry identity or plan targets. One-tap completion; completed sets editable/undoable; removals undoable; additions and session detail edits available; names with logged sets locked.
Free exercise selection, no forced advancement; rest Skip/+30s and continued logging. Finish awaits persistence, errors retain session/input and retry, restart recovers active session; discard separate.
Only explicitly completed sets count, including existing warm-ups; volume sums stored weight×reps. Historical names retained. Session edits remain session-only; plan editor changes routine.
151 offline suggestions with aliases/normalization/prefix-first matches; custom names allowed. Exercise fields: required name; defaults 3 sets / 10 reps / 0 kg; blank rest uses default; note <= 180 characters. No cardio duration/distance contract.
BLoC/get_it, repositories/services, compatible Hive IDs and serialized awaited mutations remain. No speculative backend or sync.

## Scope labels
Planned, omitted now: cross-plan identity, session replacement/reordering, trends/records, secondary settings/onboarding/reminder/backup improvements.
Unapproved: starter plans, ad hoc/repeat sessions, timed/bodyweight entry, dedicated warm-up/drop-set workflows, supersets.
Excluded: accounts, social, nutrition, AI coaching, subscriptions, backend.
Personal profile stays secondary; existing reminder/backup correctness is not assumed verified.

## Assets and validation
No photos or graphics required for workout logging. Reference photos, gauges and presentation hardware are not copied. Future illustration proposals need purpose and complete generation prompt, with technique accuracy checked.
Token contrast arithmetic passed for checked pairs. Rendered compact/large-text/keyboard layouts, screen readers, persistence and Android/iOS native behavior remain unverified by this planning work.
