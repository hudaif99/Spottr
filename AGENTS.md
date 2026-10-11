# Spottr development guide

## Read first

- Read `docs/product.md` and `docs/roadmap.md` before changing behavior.
- Read `docs/design.md` before UI work.
- Work one phase at a time. Keep decisions and phase status current.
- Treat the user's instructions as the final authority.

## Product standard

- Optimize for logging while tired: little typing, large controls, obvious next steps.
- Weight uses kilograms only. Notes are optional and visible beside the exercise.
- Keep offline operation, existing workout data, and session recovery reliable.
- Consider the user flow, data ownership, failure cases, and visual behavior before implementation.
- Introduce new ideas when they simplify the experience; discuss material scope changes first.

## Architecture and code

- Keep BLoC for state and get_it at the composition boundary unless a concrete need justifies a change.
- Keep workout rules out of widgets. Inject dependencies into logic classes.
- Access storage and platform services through focused repositories or services.
- Keep application models independent of Hive and future backend SDKs as features are rebuilt.
- Use immutable state and explicit ownership of writes. Await persistence and handle failures.
- Serialize related session mutations, including edits, finish, cancel, and restore.
- Add abstractions only for real boundaries or shared behavior. Avoid speculative backend code.
- Use descriptive names, small cohesive widgets, and Dart formatting and lint conventions.
- Comments should briefly explain a non-obvious reason or constraint. Avoid narration and decorative banners.
- Add dependencies only for a concrete benefit; check Android/iOS support and licensing.
- Preserve Hive type/field IDs until a verified migration replaces the format. Regenerate adapters using tooling.

## UI quality

- Use shared colors, typography, spacing, and components from the agreed design system.
- Design for available width, text scaling, keyboard visibility, safe areas, and rotation.
- Use appropriate Android/iOS interactions; make tablet layouts deliberate.
- Provide visible alternatives to gestures, accessible labels, and clear selected states.
- Use brief motion to explain state changes. Respect reduced motion and never delay logging.
- Review actual rendered screens and interactions, including loading, empty, and error states.

## Verification

- Test behavior that can lose data, miscount progress, or break a core user flow.
- Prioritize save/resume/finish/cancel, migration/restore, completed-set totals, and reminder dates.
- Use focused widget tests for important interactions and layout regressions.
- Avoid tests that merely repeat implementation or assert decorative details.
- Run format checks, analysis, and relevant tests for code changes. Do not broaden testing without a reason.
- Keep clock and platform boundaries replaceable where tests need deterministic behavior.
- Verify Android and iOS on their supported tooling before release; Windows checks do not verify an iOS build.
- Report exactly what passed, failed, or could not run. Never equate source review with device validation.

## Git and delivery

- `spottr-classic` preserves the original app; do redesign work on `spottr-redesign`.
- Do not include `codex` in branch names.
- Keep commits small and use short, clear messages.
- Protect unrelated changes. Do not reset or overwrite them.
- Merge into `main` only after the agreed review and testing. Do not push or publish without authorization.
- Keep user updates short: outcome, important limitation, next step.

## References and skills

- Use only skills relevant to the current task; inspect their instructions before adopting them.
- Adapt external examples to these project rules. A skill is not a reason to replace BLoC or add infrastructure.
- Prefer official Flutter/Dart documentation and the resources linked in `docs/design.md` and `docs/product.md`.
