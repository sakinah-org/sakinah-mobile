---
name: flutter-state-management-selector
description: Decides whether a Flutter feature should use Cubit or Bloc for state management. Use this skill whenever you are designing, scaffolding, or reviewing a Flutter feature and need to choose between Cubit and Bloc — even if the user just says "should I use Cubit or Bloc for X?", "what state management fits this screen?", or describes a new feature without explicitly asking. Always consult this skill before writing any Cubit or Bloc code to ensure consistent, non-over-engineered architectural decisions across the project.
---

# Flutter State Management Selector

Analyzes a Flutter feature and recommends the appropriate state management pattern — **Cubit** or **Bloc** — based on the feature's behavior, interaction complexity, and event flow.

---

## Core Rule

### Use Cubit when:
The feature is mainly responsible for **showing data** or handling **simple state changes** without meaningful user-driven event flows.

Typical cases:
- Displaying a list of items
- Showing read-only content
- Loading simple detail screens
- Refreshing displayed data

Cubit is preferred because it is simpler, has less boilerplate, and is easier to maintain for straightforward flows.

---

### Use Bloc when:
The feature contains **user interactions** that should be modeled as explicit events and may trigger different logic branches or workflows.

Typical cases:
- Search input
- Filtering and sorting
- Forms
- Multi-step workflows
- Real-time interactions
- Interaction-heavy features

Bloc is preferred because it clearly separates events from states, is better suited for complex interaction-driven features, and improves maintainability in large features.

---

## Decision Steps

### Step 1 — Identify Feature Purpose
- Is this feature mainly displaying data?
- Or does it depend heavily on user interaction?

### Step 2 — Identify Interaction Complexity
- Are there user actions like typing, filtering, selecting, submitting, retrying, toggling, or sending data?
- Do these interactions represent meaningful events that should be modeled explicitly?

### Step 3 — Choose the Pattern

Choose **Cubit** if:
- The feature is mostly read-only
- State changes are simple
- There is no meaningful event workflow
- The UI mainly loads and displays data

Choose **Bloc** if:
- The feature has meaningful user interaction
- Multiple user actions affect the same screen state
- The feature contains workflow logic
- Interaction events must be explicitly modeled

> **Important:** Choose based on the **current complexity of the feature**, not hypothetical future complexity.

---

## Skill Behavior

When this skill is used:

1. Analyze the described Flutter feature
2. Identify whether the feature is **display-oriented** or **interaction-driven**
3. Recommend **Cubit** or **Bloc**
4. Provide a short architectural justification
5. Suggest the next implementation steps

---

## Output Format

### State Management Recommendation
`Cubit` or `Bloc`

### Reason
Explain why this choice fits the feature.

### Key Signals
List the indicators that influenced the decision. Examples:
- User interactions present / absent
- Form submissions
- Search or filter events
- Real-time updates
- Read-only data display

### Next Steps
Actionable guidance such as:
- Create state model
- Define Cubit methods or Bloc events
- Separate UI from business logic
- Map user interactions to events (for Bloc)
