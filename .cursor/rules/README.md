# Projektregeln (`Project Rules`)

Offizielle Referenz: **[Cursor — Regeln](https://cursor.com/de/docs/rules)** (DE).

## Ordner / Dateien

| Pfad | Zweck |
| --- | --- |
| [`workflow/engineering-ticket-awesome-template.mdc`](workflow/engineering-ticket-awesome-template.mdc) | Strukturierte Linear-Issues (Listen- + GWT-Vorlage); intelligent oder `@`-mention |
| [`ticket-branch-workflow.mdc`](ticket-branch-workflow.mdc) | Branch von `main`, PR, Evidence |
| [`linear-ticket-sync-complete-merge.mdc`](linear-ticket-sync-complete-merge.mdc) | Linear nach Merge |
| [`ios-xcode-zero-warnings-ci.mdc`](ios-xcode-zero-warnings-ci.mdc) | Xcode Merge-Gate |
| [`file-size-limit-300.mdc`](file-size-limit-300.mdc) | Max. Zeilen pro Quellfile |
| [`tankerkoenig-ticket-precheck.mdc`](tankerkoenig-ticket-precheck.mdc) | Tankerkönig-Tickets vor Umsetzung |
| [`typescript-only.mdc`](typescript-only.mdc) | TS-only für Web/Node |

Projektweiter Kontext: **`AGENTS.md`** im Repo-Root.

## `engineering-ticket-awesome-template`

| Feld | Wert |
| --- | --- |
| `alwaysApply` | `false` |
| `globs` | — (Auslösung über Beschreibung / `@`-mention) |

Quelle: [awesome-cursorrules — engineering-ticket-template](https://github.com/PatrickJS/awesome-cursorrules/blob/main/rules/engineering-ticket-template-cursorrules-prompt-file/.cursorrules).
