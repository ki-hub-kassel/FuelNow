---
name: appintents-implementation-review
description: Implements and reviews Apple App Intents integrations across iOS, macOS, and watchOS, including AppIntent, AppEntity, AppShortcuts, parameter resolution, dialog/results, and Siri or Spotlight discoverability. Use when requests mention AppIntents, AppIntent, AppEntity, AppShortcut, Siri, Spotlight, Shortcuts, intent donation, SiriKit migration, or German terms like Kurzbefehle, Siri-Kurzbefehl, Spotlight-Aktionen, Intent-Entität, or App-Intent-Migration.
---

# AppIntents Implementation + Review

## Use This Skill For

- Building new App Intents features.
- Reviewing existing App Intents code for correctness and system discoverability.
- Migrating older SiriKit custom intents to App Intents.

## Common Trigger Phrases (EN + DE)

- EN: "AppIntents", "AppEntity", "AppShortcuts", "Siri integration", "Shortcuts action", "SiriKit migration".
- DE: "Siri-Kurzbefehl", "Kurzbefehle", "Spotlight-Aktion", "Intent-Entität", "AppIntent einbauen", "SiriKit migrieren".

Primary reference: https://developer.apple.com/documentation/appintents

## Default Workflow

Use this checklist and keep exactly one item in progress:

```md
Progress
- [ ] 1) Define capability and invocation surface
- [ ] 2) Model entities and queries
- [ ] 3) Implement intent action and result
- [ ] 4) Wire App Shortcuts and phrases
- [ ] 5) Validate discoverability and edge cases
```

## 1) Define Capability and Surface

- Identify where the action should be available: Siri, Shortcuts, Spotlight, widgets/controls, or Action button.
- Define clear user intent in one sentence: verb + target + expected outcome.
- Prefer one focused intent per user task; avoid overloaded parameters.

## 2) Model Entities and Queries

- Use `AppEntity` for core domain objects users can search/select.
- Add an `EntityQuery` that supports:
  - resolution by identifier
  - text search for disambiguation
  - sensible empty/default result behavior
- Keep display representation consistent and localizable.
- Ensure query logic is fast enough for interactive resolution.

## 3) Implement Intent Action and Result

- Implement `AppIntent` with explicit parameter metadata and titles.
- Use runtime parameter resolution where ambiguity is possible.
- Return a concrete outcome:
  - `ProvidesDialog` for user-facing confirmations/errors
  - `ReturnsValue` for data handoff
  - `OpensIntent` / snippet result when follow-up interaction is needed
- Fail with actionable messaging (`AppIntentError`/dialog), not silent no-ops.

## 4) Wire App Shortcuts and Phrases

- Register intent exposure through `AppShortcutsProvider`.
- Add concise, natural phrases in supported locales.
- Keep phrase vocabulary user-centric (task language, not internal model terms).
- Confirm title/subtitle/parameter prompts are localized and readable in Siri + Shortcuts.

## 5) Validate Discoverability and Edge Cases

- Verify intent appears in Shortcuts search.
- Verify Siri invocation behavior for happy path and ambiguous input.
- Verify Spotlight/entity discoverability when entities are intended to be searchable.
- Verify behavior for:
  - missing permissions
  - unavailable/deleted entities
  - empty result sets
  - network failure/offline mode

## Review Checklist

- **Intent shape**: one clear action, cohesive parameters, no ambiguous semantics.
- **Entity design**: stable IDs, consistent display representation, localizable labels.
- **Resolution quality**: disambiguation and fallback prompts are actionable.
- **Result quality**: dialog/result type matches user expectation and caller context.
- **Discoverability**: App Shortcuts and phrases are present, natural, and localized.
- **Reliability**: errors are explicit, edge cases handled, no blocking main-thread work.

## Output Format For Responses

When using this skill, structure responses as:

1. What was implemented/reviewed.
2. Findings or changes (highest impact first).
3. Validation performed.
4. Remaining risks or next checks.
