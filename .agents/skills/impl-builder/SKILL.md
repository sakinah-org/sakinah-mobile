---
name: impl-planner
description: Generates detailed, structured implementation plans for large Flutter/Dart development tasks before any code is written. Use this skill whenever Codex is asked to build a feature, write unit tests, integration tests, API integrations, business logic, refactor code, migrate a database, or set up CI/CD pipelines. Always trigger this skill before starting implementation on any non-trivial task — if a task has more than one moving part, plan it first. Also trigger when the user says things like "plan this", "how should I approach", "break this down", "where do I start", or "implementation plan".
---

# impl-planner

A skill that turns large, ambiguous Flutter/Dart tasks into clear, ordered implementation plans — before a single line of code is written.

## When to use this skill

Trigger for ANY of the following:
- Building a new feature or screen
- Writing unit or integration tests
- Integrating an external API or service
- Implementing pure business logic / domain layer
- Refactoring or paying down tech debt
- Migrating database schemas (e.g. Drift, Isar, Hive, Firebase)
- Setting up or modifying CI/CD pipelines

If in doubt: plan first, code second.

---

## How to produce a plan

### Step 1 — Classify the task type

Identify which category the task falls under. This determines the planning template to use. See [`references/task-types.md`](references/task-types.md) for per-type guidance.

| Type | Keywords |
|---|---|
| Feature | screen, widget, flow, page, UI, user story |
| Unit Tests | test, mock, bloc test, widget test, unit |
| Integration Tests | e2e, integration, patrol, golden |
| API Integration | REST, GraphQL, endpoint, HTTP, Dio, retrofit |
| Business Logic | use case, domain, repository, service, calculation |
| Refactor | clean up, extract, decouple, rename, restructure |
| Database Migration | schema, migration, Drift, Isar, Hive, Firestore |
| CI/CD | pipeline, GitHub Actions, Fastlane, deploy, build |

### Step 2 — Ask clarifying questions (if needed)

Before planning, confirm the following if not already clear:
- What is the **goal** of this task? (user-facing or technical)
- What **already exists** that this task touches?
- Are there **known constraints** (deadline, architecture rules, dependency limits)?
- What is **out of scope**?

Skip this step if the task description is already detailed enough.

### Step 3 — Generate the plan

Use the output format below. Always produce all sections.

---

## Output Format

```
## Implementation Plan — [Task Name]

**Type:** [Feature / Unit Tests / Integration Tests / API Integration / Business Logic / Refactor / DB Migration / CI/CD]
**Estimated Total Effort:** [e.g. 3–5 hours / 1 day / 2–3 days]
**Complexity:** [Low / Medium / High]

---

### Context
Brief 2–3 sentence summary of what this task is, why it exists, and what success looks like.

---

### Dependencies & Risks
- **Depends on:** [other tasks, packages, APIs, or team members this task relies on]
- **Risks:** [what could go wrong or block this — be specific]
- **Assumptions:** [what we're taking for granted]

---

### Steps

#### Step 1 — [Step Title]
**Effort:** [e.g. 30 min]
**Description:** What to do and why.

**Sub-tasks:**
- [ ] Sub-task A
- [ ] Sub-task B

**Files / Modules:**
- `lib/features/[feature]/...` — [what to create or modify]

**Test Strategy:**
- [What to test for this step, if applicable]

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2

---

[Repeat for each step]

---

### Definition of Done

- [ ] All steps completed and reviewed
- [ ] All acceptance criteria met
- [ ] Tests written and passing (unit + integration where applicable)
- [ ] No new lint warnings introduced
- [ ] Code reviewed and approved
- [ ] Feature works on both iOS and Android (if UI-related)
- [ ] Relevant documentation updated (if applicable)
```

---

## Flutter/Dart-Specific Planning Rules

Always follow these rules when generating plans for Flutter/Dart projects:

### Architecture
- Assume **feature-first folder structure** unless told otherwise: `lib/features/[feature]/data/`, `domain/`, `presentation/`
- Assume **BLoC or Riverpod** for state management — ask if unclear
- Separate concerns: UI → BLoC/Provider → Use Case → Repository → Data Source

### Testing
- Unit tests live in `test/` mirroring the `lib/` structure
- Widget tests use `flutter_test`
- Integration/e2e tests use `patrol` or `integration_test`
- Always mock external dependencies (APIs, local storage)
- Reference [`references/test-strategy.md`](references/test-strategy.md) for detailed test guidance

### API Integrations
- Prefer `Dio` + `Retrofit` (or `chopper`) for HTTP
- Always plan for error handling: network errors, parse errors, timeouts
- Plan DTOs (data transfer objects) and mappers separately from domain models

### Database Migrations
- Reference [`references/db-migration.md`](references/db-migration.md) for Drift/Isar/Hive migration patterns
- Always plan a rollback strategy for schema changes

### CI/CD
- Assume GitHub Actions unless told otherwise
- Always include: lint → test → build → (optional) deploy steps

---

## Effort Estimation Guidelines

| Task Complexity | Signals | Rough Estimate |
|---|---|---|
| Low | Single widget, one use case, isolated logic | 30 min – 2 hours |
| Medium | Multi-layer change (UI + BLoC + repo), new API endpoint | 2 hours – 1 day |
| High | New feature end-to-end, migration, architecture change | 1–3+ days |

Always express effort as a range, not a single number. Flag high-uncertainty estimates explicitly.

---

## Example invocations

- "Plan the implementation of a user profile screen"
- "How should I approach adding offline support?"
- "Break down writing tests for the auth flow"
- "Create an impl plan for integrating Stripe payments"
- "Plan refactoring the cart feature to clean architecture"

For per-task-type detailed guidance, read:
- [`references/task-types.md`](references/task-types.md) — type-specific planning checklists
- [`references/test-strategy.md`](references/test-strategy.md) — Flutter test planning in depth
- [`references/db-migration.md`](references/db-migration.md) — database migration patterns