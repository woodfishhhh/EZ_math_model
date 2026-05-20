---
name: humanizer
description: Use after EZ_math_model writer creates paper.md and before quality audit when a long modeling paper needs less AI-like prose while preserving formulas, data, citations, tables, and figures.
---

# humanizer — 论文正文去 AI 味

## 何时使用

- writer 已落盘 `paper.md`。
- `quality_audit` 尚未运行。
- 正文长度通常不少于 5000 字。
- 用户或配置要求降低 AI 写作痕迹。

## 调用方式

优先加载宿主 `humanizer` skill。输入 `paper.md` 正文，要求：

- 保留所有数值。
- 保留引用编号。
- 保留公式块和行内公式。
- 保留 Markdown 表格。
- 保留图片标签 `![](xxx.png)`。
- 不修改章节标题。

默认写到：

```text
workdir/{task_id}/paper.humanized.md
workdir/{task_id}/humanizer_diff.md
```

只有用户显式开启 `--humanize-overwrite` 时才覆盖 `paper.md`。

## 检查重点

- 夸张象征语和营销式措辞。
- 空泛转折和堆叠连接词。
- 过度三段式。
- 模糊归因。
- 频繁使用 em dash 或英文 AI 高频词。

## 失败诊断

| 情况 | 处理 |
|---|---|
| 宿主 skill 未安装 | 跳过，不阻塞 packaging |
| 数值、公式、引用被改坏 | 回滚到原 `paper.md` |
| 字数明显缩水 | quality_audit 标记字数风险 |
