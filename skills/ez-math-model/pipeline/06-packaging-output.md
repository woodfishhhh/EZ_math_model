# Pipeline 06 — 打包交付

## 入口条件

- `quality_report.md` 已落盘。
- 检查项 1（拆题完整）与检查项 6（章节齐全）均未失败（失败时 05 阶段已经
  打断，不会进入此阶段）。

## 阶段任务

### 1. Markdown → DOCX 转换

调 `tools/docx/SKILL.md` 将 `paper.md` 转为 `paper.docx`。

转换要点：
- 图片走相对路径 `figures/xxx.png`，所以转换前要 `cd workdir/{task_id}` 或
  在转换器命令里指定 resource path。
- 数学公式：`$...$` 与 `$$...$$` 必须正确转换为 docx 公式对象（OMML），
  详见 `tools/docx/SKILL.md` 的 pandoc 调用约定。
- 模板：若 `thesis_match.json.template_dir` 指向 zhanwen 的论文模板包，
  优先把 docx / Latex 模板作为 `--reference-doc`；否则使用 pandoc 默认。

### 2. 写诊断报告

无失败时 `diagnostics.md` 仍要落盘空报告：

```markdown
# 失败诊断

无失败项。本次运行所有阶段均通过。
```

有失败时按 `references/workdir-protocol.md` 中的"diagnostics.md"格式记录。

### 3. 打包

调 `scripts/runtime/pack_deliverable.ps1` 把以下文件 / 目录打包为
`workdir/{task_id}/deliverable.zip`：

```
deliverable.zip/
├── 论文.md            # paper.md 重命名
├── 论文.docx          # paper.docx 重命名（转换失败则缺该项）
├── results/
├── figures/
├── src/
├── 质量检查报告.md    # quality_report.md 重命名
├── 失败诊断.md        # diagnostics.md 重命名
└── README.md          # 工作目录的 README.md 副本
```

中文文件名是产出层的最终对外名称，便于用户分发。

### 4. 输出最终消息

向用户报告：

```
任务完成。交付包：workdir/{task_id}/deliverable.zip
- 论文：论文.md / 论文.docx
- 图表：figures/（共 N 张）
- 结果：results/（共 M 个文件）
- 质量门通过：X / 7
- 警告：Y 项（详见质量检查报告.md）
- 失败：Z 项（详见失败诊断.md）
```

## 产出文件

| 路径 | 必须 | 说明 |
|---|---|---|
| `workdir/{task_id}/paper.docx` | 否 | docx 转换失败时缺失 |
| `workdir/{task_id}/diagnostics.md` | 是 | 无失败也要存空报告 |
| `workdir/{task_id}/deliverable.zip` | 是 | 最终交付包 |

## 失败诊断

| 情况 | 处理 |
|---|---|
| pandoc / docx skill 不可用 | 不打断，仅交付 markdown，写诊断 |
| 公式转换异常 | 不打断，docx 中保留 `$...$` 文本，提示用户手动修正 |
| 打包脚本失败 | 不打断，列出工作目录路径让用户手动收集 |

## 下一阶段入口

无。本阶段是 pipeline 终点。

完成后 ez-math-model 一次运行结束，下次运行新建工作目录。


