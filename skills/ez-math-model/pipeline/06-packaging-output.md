# Pipeline 06 — 打包交付

## 入口条件

- `quality_report.md` 已落盘。
- `run_state.json.run_mode != blocked`。
- 检查项 3（拆题完整）与检查项 8（章节齐全）均未失败（失败时 05 阶段已经
  打断，不会进入此阶段）。

## 阶段任务

### 1. Markdown → 四格式导出

调 `scripts/runtime/export_paper.ps1` 将 `runtime/{task_id}/paper.md` 导出到
`output/paper/`：

```text
output/paper/
├── paper.md
├── paper.docx
├── paper.txt
└── paper.pdf
```

转换要点：
- 图片走相对路径 `figures/xxx.png`，所以转换前要 `cd runtime/{task_id}` 或
  在转换器命令里指定 resource path。
- 数学公式：`$...$` 与 `$$...$$` 必须正确转换为 docx 公式对象（OMML），
  详见 `tools/docx/SKILL.md` 的 pandoc 调用约定。
- 模板：若 `thesis_match.json.template_dir` 指向 zhanwen 的论文模板包，
  优先把 docx / Latex 模板作为 `--reference-doc`；否则使用 pandoc 默认。
- 若 pandoc 的 PDF 引擎不可用，`export_paper.ps1` 必须生成一个 text-only
  `paper.pdf` 兜底，并在 `diagnostics.md` 中记录高保真 PDF 生成失败原因。
- 若 `paper.docx` 或 `paper.pdf` 仍缺失，质量等级不能高于 `provisional_pass`。

### 2. 写诊断报告

无失败时 `diagnostics.md` 仍要落盘空报告：

```markdown
# 失败诊断

无失败项。本次运行所有阶段均通过。
```

有失败时按 `references/workdir-protocol.md` 中的"diagnostics.md"格式记录。

### 3. 同步标准 output 目录

调 `scripts/runtime/pack_deliverable.ps1 -WorkDir runtime/{task_id}`，把 runtime
产物同步到标准输出目录：

```
output/
├── source code/
│   └── src/
├── paper/
│   ├── paper.md
│   ├── paper.docx
│   ├── paper.txt
│   └── paper.pdf
├── 附件文件夹/
│   ├── figures/
│   ├── results/
│   ├── attachments/
│   ├── 质量检查报告.md
│   └── 失败诊断.md
└── manifest.json
```

中文文件名只用于附件说明类文件；论文四格式统一使用 `paper.*`，便于自动化读取。

### 4. 压缩项目交付

打包脚本必须在项目总文件夹根目录生成：

```text
output.zip
```

压缩包内容为项目总文件夹内的全部内容（`用户输入/`、`runtime/`、`output/` 等），
但排除正在生成的 `output.zip` 自身。脚本也可复制一份到
`runtime/{task_id}/deliverable.zip` 作为兼容别名；面向用户的主交付物是
`项目总文件夹/output.zip`。

### 5. 输出最终消息

向用户报告：

```
任务完成。交付包：output.zip
- 论文：output/paper/paper.md / paper.docx / paper.txt / paper.pdf
- 源代码：output/source code/
- 附件：output/附件文件夹/（图表 N 张，结果 M 个文件）
- 运行模式：formal/demo
- 质量门通过：X / 10
- 警告：Y 项（详见 output/附件文件夹/质量检查报告.md）
- 失败：Z 项（详见失败诊断.md）
```

## 产出文件

| 路径 | 必须 | 说明 |
|---|---|---|
| `output/paper/paper.md` | 是 | Markdown 论文 |
| `output/paper/paper.docx` | 是 | Word 论文；缺失则质量降级并记诊断 |
| `output/paper/paper.txt` | 是 | 纯文本论文 |
| `output/paper/paper.pdf` | 是 | PDF 论文；缺失则质量降级并记诊断 |
| `output/source code/` | 是 | 项目源代码 |
| `output/附件文件夹/` | 是 | 图表、结果、附件、质量报告、诊断 |
| `output/manifest.json` | 是 | 最终产物 manifest |
| `output.zip` | 是 | 最终交付包 |

## 失败诊断

| 情况 | 处理 |
|---|---|
| pandoc / docx skill 不可用 | 不打断，仅交付 markdown，写诊断 |
| 公式转换异常 | 不打断，docx 中保留 `$...$` 文本，提示用户手动修正 |
| PDF 导出失败 | 不打断，但最终等级不能高于 `provisional_pass` |
| 打包脚本失败 | 不打断，列出 `output/` 和 `runtime/{task_id}` 路径让用户手动收集 |

## 下一阶段入口

无。本阶段是 pipeline 终点。

完成后 ez-math-model 一次运行结束，下次运行新建工作目录。


