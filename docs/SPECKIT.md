# Spec-Kit (GitHub) — Einrichtung für FuelNow

Dieses Repo nutzt [GitHub Spec-Kit](https://github.com/github/spec-kit) **optional** für Spec-Driven Development (Phasen, Templates, Agent-Integration). Die **inhaltliche** Produkt-Spezifikation bleibt in [`docs/PRODUCT_SPEC.md`](PRODUCT_SPEC.md); Spec-Kit ergänzt **Arbeitsablauf-Artefakte** (z. B. `.specify/`, Cursor-Regeln/Skills), sobald die CLI einmalig eingerichtet wurde.

## Was bereits im Repo liegt

| Artefakt | Zweck |
| --- | --- |
| [`.spec-kit.md`](../.spec-kit.md) | Kurz-Hub: Links zu `PRODUCT_SPEC`, Abo-Doku, Agent-Regeln |
| [`docs/PRODUCT_SPEC.md`](PRODUCT_SPEC.md) | Kanonischer Produkt- und Konstanten-Index |
| **`.specify/`** | Spec-Kit-Templates, Scripts, Workflows, **`memory/constitution.md`** (FuelNow-Inhalt) |
| **`.cursor/rules/specify-rules.mdc`** | Cursor **alwaysApply** — verweist auf die Repo-Specs |

Falls **`.specify/`** bei dir noch fehlt: Abschnitt *„2. Einmalig im Repo-Root initialisieren“* ausführen.

## 1. Specify CLI installieren

Offiziell nur aus dem GitHub-Repo installieren (PyPI-Pakete gleichen Namens sind **nicht** das Spec-Kit-Projekt):

```bash
# Variante A: uv (empfohlen) — https://docs.astral.sh/uv/
brew install uv
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

# Variante B: pipx
brew install pipx
pipx install git+https://github.com/github/spec-kit.git
```

Prüfen:

```bash
specify version
specify integration list
```

## 2. Einmalig im Repo-Root initialisieren (Cursor)

Im Klone von **FuelNow** / **TankRadar** (dieses Verzeichnis):

```bash
cd /path/to/TankRadar   # z. B. …/Documents/Dev/iOS/TankRadar
specify init --here --integration cursor-agent --ignore-agent-tools
```

| Flag | Bedeutung |
| --- | --- |
| `--integration cursor-agent` | Offizieller Integrations-Key für **Cursor** (siehe [integrations.md](https://github.com/github/spec-kit/blob/main/docs/reference/integrations.md)). |
| `--ignore-agent-tools` | Kein harter Check auf ein Cursor-CLI im `PATH` — für reine IDE-Nutzung ausreichend. |

**Hinweis:** Wenn `.specify/` schon existiert, vermeide blindes erneutes `init` ohne `--force` — ggf. `specify integration upgrade` nutzen (siehe Upstream-Doku).

## 3. Nach erfolgreichem `init`

Typisch entstehen u. a.:

- **`.specify/`** — Presets, Templates, `integration.json`
- **`.cursor/rules/specify-rules.mdc`** — Spec-Kit-kontextuelle Cursor-Regel
- ggf. **`.cursor/skills`** mit Speckit-Skills (je nach CLI-Version)

Ergänze in [`.spec-kit.md`](../.spec-kit.md) einen kurzen Vermerk, dass **`.specify/` aktiv** ist (Pflege-Hinweis für das Team).

## 4. Wechsel / mehrere Agenten

Siehe Upstream: `specify integration install`, `switch`, `use`, `upgrade` — Details in der [Specify CLI Reference](https://github.com/github/spec-kit#-specify-cli-reference).

## Quellen

- [github/spec-kit](https://github.com/github/spec-kit)
- [Supported AI Coding Agent Integrations](https://github.com/github/spec-kit/blob/main/docs/reference/integrations.md)
