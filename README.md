# EZ Math Model

[English README](README.en.md) | [技能星图](STAR_MAP.md) | [SkillsMP](https://skillsmp.com)

EZ Math Model 是一个面向数学建模竞赛的可上架 Agent Skill。它把题目和附件交给智能体后，按固定流程完成：题目解析、模型选择、Python 求解、绘图、论文撰写、质量检查和打包交付。

适用场景包括全国大学生数学建模竞赛、MCM/ICM、美赛、研究生数学建模竞赛，以及课程里的建模作业。

## 能做什么

- 读取 PDF、DOCX、Markdown、CSV、XLSX 和混合附件。
- 识别赛事、年份、题号、小问、数据附件、输出语言等信号。
- 从内置算法库中选择优化、预测、评价、图论、统计、综合建模或机器学习方案。
- 编写并执行 Python 脚本，导出结果表和图片。
- 按中文或英文模板撰写建模论文。
- 在交付前运行质量门检查。
- 产出 `paper.md`、可选 `paper.docx`、`results/`、`figures/`、`src/`、`quality_report.md`、`diagnostics.md`。

## SkillsMP 上架结构

```text
EZ_math_model/
├── README.md                # 中文主 README
├── README.en.md             # 英文 README
├── STAR_MAP.md              # 技能星图
├── package.json             # 包与市场元数据
├── marketplace.json         # SkillsMP 展示元数据
├── manifest.json            # 内部资源索引
├── VERSION
└── skills/
    └── ez-math-model/
        ├── SKILL.md         # skill 主入口
        ├── pipeline/        # 七阶段流程契约
        ├── prompts/         # coordinator/modeler/coder/writer prompts
        ├── references/      # 算法库、角色守则、容错协议
        ├── templates/       # 论文模板和工作目录模板
        ├── tools/           # 子 skills，每个目录都有 SKILL.md
        ├── scripts/         # 安装和运行时辅助脚本
        └── external/        # 运行时外部资料和用户 corpus
```

## 安装

Codex:

```powershell
gh skill install woodfishhhh/EZ_math_model ez-math-model --agent codex --scope user
```

Claude Code:

```bash
gh skill install woodfishhhh/EZ_math_model ez-math-model --agent claude-code --scope user
```

然后在对话里说：

```text
用 ez-math-model 做这道数学建模题。
```

同一轮把题面和数据附件一起发给它。

## 主流程

本节路径均相对 `skills/ez-math-model/`。

| 阶段 | 文件 | 关键产出 |
|---|---|---|
| 00 环境检查 | `pipeline/00-environment-setup.md` | 环境检查、工具决策、工作目录 |
| 01 题目解析 | `pipeline/01-problem-intake.md` | `problem.md`、`intake.json`、附件预览 |
| 02 建模方案 | `pipeline/02-modeling-plan.md` | `modeling_plan.md` |
| 03 代码求解 | `pipeline/03-coding-solve.md` | `src/*.py`、`results/*`、`figures/*.png` |
| 04 论文撰写 | `pipeline/04-paper-writing.md` | `paper.md` |
| 05 质量审查 | `pipeline/05-quality-audit.md` | `quality_report.md` |
| 06 打包交付 | `pipeline/06-packaging-output.md` | DOCX/Markdown 交付包和诊断报告 |

## 内置子 Skills

本节路径均相对 `skills/ez-math-model/`。

| 能力域 | 入口 |
|---|---|
| PDF 与 OCR 兜底 | `tools/pdf/SKILL.md`、`tools/mineru/SKILL.md` |
| Word 与表格 | `tools/docx/SKILL.md`、`tools/xlsx/SKILL.md` |
| 文献与网页上下文 | `tools/paper_search/SKILL.md`、`tools/scholar/SKILL.md`、`tools/webcrawl/SKILL.md` |
| 公开数据集发现 | `tools/dataset/SKILL.md` |
| 用户资料库索引 | `tools/user-corpus-explorer/SKILL.md` |
| 流程辅助 | `tools/brainstorming/SKILL.md`、`tools/systematic-debugging/SKILL.md`、`tools/verification-before-completion/SKILL.md` |
| 结果润色 | `tools/humanizer/SKILL.md`、`tools/simplify/SKILL.md`、`tools/scientific-slides/SKILL.md` |
| Agent 编排 | `tools/dispatching-parallel-agents/SKILL.md`、`tools/subagent-driven-development/SKILL.md`、`tools/external-context/SKILL.md` |

完整能力关系见 [STAR_MAP.md](STAR_MAP.md)。

## 运行时策略

仓库不内置上游优秀论文和用户私有材料。运行时内容放在 `skills/ez-math-model/external/`，并由 `.gitignore` 排除：

- `skills/ez-math-model/external/zhanwen-mathmodel/`：可选拉取的上游优秀论文。
- `skills/ez-math-model/external/user-corpus/`：用户自己的论文、教材、笔记和题解。
- `skills/ez-math-model/external/tools/`：本机工具启用决策。

密钥使用 `EZMM_` 环境变量，不写入仓库。

## 许可

MIT。详见 [LICENSE](LICENSE)。

## Star 趋势图

[![Star History Chart](https://api.star-history.com/svg?repos=woodfishhhh/EZ_math_model&type=Date)](https://www.star-history.com/#woodfishhhh/EZ_math_model&Date)
