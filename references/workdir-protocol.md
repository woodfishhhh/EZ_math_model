# 工作目录协议

每次运行 ez-math-model 都会创建一个独立工作目录，所有阶段产物都落在
其中。失败定位、断点重试、最终打包都依赖此协议。

## 目录命名

```
workdir/{YYYYMMDD-HHMMSS}-{8位 hex hash}/
```

- 时间戳精确到秒，避免同分钟内多次运行冲突。
- hash 用任务标题 + 当前时间戳的 sha1 前 8 位，便于人快速区分多个任务。
- 目录创建脚本：`scripts/runtime/init_workdir.ps1`（POSIX 用 sh 等价版）。

## 目录结构

```
workdir/{name}/
├── README.md                # 本任务的元信息（来自 templates/readme_workdir.md）
├── problem.md               # intake 阶段：题目原文（清洗后的 markdown）
├── intake.json              # intake 阶段：拆题结构化结果（schema 见下文）
├── attachments/             # intake 阶段：用户上传的所有附件原件
│   ├── data.csv
│   └── ...
├── modeling_plan.md         # modeling 阶段：建模方案
├── thesis_match.json        # modeling 阶段：上游优秀论文匹配结果
├── src/                     # coding 阶段：所有可运行脚本
│   ├── eda.py
│   ├── q1_solve.py
│   ├── q2_solve.py
│   └── sensitivity.py
├── results/                 # coding 阶段：计算结果
│   ├── q1_summary.csv
│   ├── q2_predictions.csv
│   └── sensitivity.json
├── figures/                 # coding 阶段：所有图表（PNG，300dpi）
│   ├── fig_eda_corr.png
│   ├── fig_q1_fit.png
│   └── ...
├── execution_log.md         # coding 阶段：每次脚本运行的命令、stdout 摘要、状态
├── paper.md                 # writer 阶段：论文 markdown
├── paper.docx               # packaging 阶段：通过 docx skill 转换的 docx
├── quality_report.md        # quality 阶段：质量门评分与未通过项
├── diagnostics.md           # 任意阶段：失败诊断（无失败时也要存空报告）
└── deliverable.zip          # packaging 阶段：最终交付包
```

## intake.json schema

```json
{
  "is_math_modeling": true,
  "title": "...",
  "background": "...",
  "ques_count": 3,
  "ques1": "...",
  "ques2": "...",
  "ques3": "...",
  "contest": "cumcm | mcm | gradmcm | unknown",
  "year": 2024,
  "problem_letter": "B",
  "attachments": [{"name": "data.csv", "kind": "csv", "note": "..."}],
  "language": "zh"
}
```

## thesis_match.json schema

由 `scripts/runtime/match_thesis.py` 产出：

```json
{
  "match_level": "exact | year | series | fallback | internal",
  "thesis_dir": "<绝对路径或 INTERNAL>",
  "template_dir": "<绝对路径或 INTERNAL>",
  "signals": {"contest": "cumcm", "year": 2024, "problem": "B"},
  "checked_at": "2026-05-19T10:30:00+08:00"
}
```

`match_level` 取值约定：

- `exact` ：(赛事, 年份, 题号) 全命中。
- `year` ：(赛事, 年份) 命中，题号未命中或题号不存在子目录。
- `series` ：仅赛事命中，回落到该赛事下最新可用年份。
- `fallback` ：赛事未识别，回落到 `2024年数模悉知&论文模版` + `数学建模Latex模版`。
- `internal` ：zhanwen 仓库未下载或目标路径不存在，使用仓库内置 markdown 模板。

## quality_report.md 必备字段

固定 7 项检查（细节见 `pipeline/05-quality-audit.md`）：

| 检查项 | 通过条件 |
|---|---|
| 拆题完整 | `intake.json.ques_count > 0` 且每个 quesN 文本 ≥ 30 字 |
| 建模方案齐全 | `modeling_plan.md` 包含每个 quesN 的方案小节 |
| 代码可执行 | `execution_log.md` 中每个脚本的最终状态为 `ok` |
| 结果文件齐全 | `results/` 至少有 1 个 CSV 或 JSON |
| 图表齐全 | `figures/` 与 `paper.md` 中 `![]()` 引用一致 |
| 章节齐全 | `paper.md` 含摘要、问题重述、问题分析、模型假设、符号说明、模型建立与求解、敏感性、模型评价、参考文献 |
| 文献唯一 | `paper.md` 中 `[^N]` 编号无重复 |

## diagnostics.md

无失败时仍然存一份空的诊断说明，便于打包阶段一致地包含此文件：

```markdown
# 失败诊断

无失败项。本次运行所有阶段均通过。
```

有失败时按以下结构记录：

```markdown
# 失败诊断

## 阶段：03-coding-solve
- 脚本：q2_solve.py
- 时间：2026-05-19T11:02:13+08:00
- 错误摘要：[一行]
- 已尝试：[简述重试逻辑]
- 影响：q2 的 figures/fig_q2_xxx.png 缺失
- 用户建议动作：检查附件 data.csv 编码 / 安装 xgboost / ...
```

## 路径安全

- 工作目录路径不得包含上级跳转（`..`）。
- 附件名落盘前由 `init_workdir` 脚本做基本清洗（去掉路径分隔符与控制字符）。
- 所有相对路径以工作目录为根。

## 重试与续跑

- 每个 pipeline 阶段开始时检查自身入口条件文件是否齐全，缺失直接打断。
- 若用户希望从中间阶段重跑，可手动复制工作目录后从对应阶段启动；ez-math-model
  默认每次都新建工作目录，不在原目录覆盖。

