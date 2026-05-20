# EZ Math Model

[中文说明](README.zh-CN.md) | [Skill Star Map](STAR_MAP.md) | [SkillsMP entry](https://skillsmp.com)

EZ Math Model is a publish-ready Agent Skill for mathematical modeling contests. It turns a problem statement and attachments into a complete modeling workflow: intake, model selection, Python solving, figures, paper writing, quality audit, and packaged deliverables.

It is designed for CUMCM, MCM, ICM, graduate mathematical modeling contests, and course projects that look like contest-style modeling tasks.

## What It Does

- Parses PDF, DOCX, Markdown, CSV, XLSX, and mixed attachments.
- Detects contest signals such as contest, year, problem number, subtasks, data files, and output language.
- Chooses models from a built-in algorithm library covering optimization, prediction, evaluation, graph theory, statistics, comprehensive modeling, and machine learning.
- Writes and runs Python scripts, exports result tables, and generates figures.
- Drafts a modeling paper in Chinese or English from structured templates.
- Runs quality gates before packaging.
- Produces `paper.md`, optional `paper.docx`, `results/`, `figures/`, `src/`, `quality_report.md`, and `diagnostics.md`.

## SkillsMP-Ready Layout

```text
EZ_math_model/
├── SKILL.md                 # main skill entry
├── README.md                # English marketplace README
├── README.zh-CN.md          # Chinese README
├── STAR_MAP.md              # visual capability map
├── package.json             # marketplace/package metadata
├── marketplace.json         # SkillsMP-facing metadata
├── manifest.json            # internal resource index
├── VERSION
├── pipeline/                # seven workflow stages
├── prompts/                 # coordinator/modeler/coder/writer prompts
├── references/              # algorithms, role guides, fault tolerance
├── templates/               # paper and workdir templates
├── tools/                   # sub-skills, each with SKILL.md
├── scripts/                 # install/runtime helpers
└── external/                # runtime-only external references and user corpus
```

## Install

Codex:

```powershell
git clone https://github.com/woodfishhhh/EZ_math_model "$env:USERPROFILE\\.codex\\skills\\ez-math-model"
```

Claude Code:

```bash
git clone https://github.com/woodfishhhh/EZ_math_model ~/.claude/skills/ez-math-model
```

Then ask:

```text
Use ez-math-model to solve this mathematical modeling problem.
```

Attach the problem statement and data files in the same turn.

## Core Pipeline

| Stage | File | Output |
|---|---|---|
| 00 Environment | `pipeline/00-environment-setup.md` | environment check, tool decisions, workdir |
| 01 Intake | `pipeline/01-problem-intake.md` | `problem.md`, `intake.json`, attachments preview |
| 02 Modeling | `pipeline/02-modeling-plan.md` | `modeling_plan.md` |
| 03 Solving | `pipeline/03-coding-solve.md` | `src/*.py`, `results/*`, `figures/*.png` |
| 04 Writing | `pipeline/04-paper-writing.md` | `paper.md` |
| 05 Quality | `pipeline/05-quality-audit.md` | `quality_report.md` |
| 06 Packaging | `pipeline/06-packaging-output.md` | DOCX/Markdown package and diagnostics |

## Built-In Sub-Skills

| Area | Entry |
|---|---|
| PDF and OCR fallback | `tools/pdf/SKILL.md`, `tools/mineru/SKILL.md` |
| Word and spreadsheets | `tools/docx/SKILL.md`, `tools/xlsx/SKILL.md` |
| Literature and web context | `tools/paper_search/SKILL.md`, `tools/scholar/SKILL.md`, `tools/webcrawl/SKILL.md` |
| Dataset discovery | `tools/dataset/SKILL.md` |
| User corpus indexing | `tools/user-corpus-explorer/SKILL.md` |
| Workflow support | `tools/brainstorming/SKILL.md`, `tools/systematic-debugging/SKILL.md`, `tools/verification-before-completion/SKILL.md` |
| Optional polish | `tools/humanizer/SKILL.md`, `tools/simplify/SKILL.md`, `tools/scientific-slides/SKILL.md` |
| Agent orchestration | `tools/dispatching-parallel-agents/SKILL.md`, `tools/subagent-driven-development/SKILL.md`, `tools/external-context/SKILL.md` |

See [STAR_MAP.md](STAR_MAP.md) for the full capability constellation.

## Runtime Policy

The repository does not vendor upstream contest papers or user files. Runtime-only content is placed under `external/` and ignored by git:

- `external/zhanwen-mathmodel/` for optional upstream exemplar papers.
- `external/user-corpus/` for user-provided references.
- `external/tools/` for local tool decisions.

Secrets use `EZMM_` environment variables and should live outside the repository.

## License

MIT. See [LICENSE](LICENSE).
