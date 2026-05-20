# Pipeline 05 — 质量审查

## 入口条件

- `paper.md` 已落盘。
- `execution_log.md` 已落盘。

## 阶段任务

按 `references/workdir-protocol.md` 的"quality_report.md 必备字段"逐项
评估，输出 `quality_report.md`。本阶段同时**汇总 L3 影子评估**：读取
`workdir/{task_id}/eval_shadow.md`（若存在），把每个角色的评分附在质量门
末尾作为参考。

**容错协议**：本阶段遵守 `references/fault-tolerance.md` 的全文。L4 反馈
重跑只有在 `intake.json.strict_quality == true` 或 `EZMM_STRICT=1` 时启用，
否则即使有评分不达标的子任务也不阻塞 packaging。

**verification 强化**：若用户启用了继承 skill 集（`external/tools/inherited_skills.{yes,recommended}` 存在）
且检测到 `verification-before-completion`，本阶段必须用其"证据 - 断言"
对齐机制审核 quality_report.md 的每条"通过项"，详见
`tools/verification-before-completion/SKILL.md`。**禁止**口头声称通过。

### 检查项与判定逻辑

| # | 检查项 | 通过条件 | 判定 |
|---|---|---|---|
| 1 | 拆题完整 | `intake.json.ques_count > 0` 且每个 quesN 文本 ≥ 30 字 | 解析 intake.json |
| 2 | 建模方案齐全 | `modeling_plan.md` 包含每个 quesN 的方案小节 | grep 章节标题 |
| 3 | 代码可执行 | `execution_log.md` 中每个脚本最终状态 `ok` 占比 ≥ 50% | 解析 log 表格 |
| 4 | 结果文件齐全 | `results/` 至少 1 个 csv 或 json | `Get-ChildItem` |
| 5 | 图表齐全 | `figures/` 实际文件名集合 ⊇ `paper.md` 中的所有 `![]()` 引用 | 双向比对 |
| 6 | 章节齐全 | `paper.md` 含 9 个固定章节标题 | grep 章节标题 |
| 7 | 文献唯一 | `paper.md` 中每个 `[^N]` 编号不重复定义 | 正则统计 |

### quality_report.md 格式

```markdown
# 质量审查报告

| # | 检查项 | 状态 | 详情 |
|---|---|---|---|
| 1 | 拆题完整 | ✓ | ques_count=3，每问 ≥ 30 字 |
| 2 | 建模方案齐全 | ✓ | 已覆盖 q1/q2/q3 |
| 3 | 代码可执行 | ⚠ | 4/5 子任务 ok，q2 失败 |
| 4 | 结果文件齐全 | ✓ | 共 6 个结果文件 |
| 5 | 图表齐全 | ⚠ | paper 引用 fig_q3_main.png 但 figures/ 缺失 |
| 6 | 章节齐全 | ✓ | 9 章俱在 |
| 7 | 文献唯一 | ✓ | 共 8 条文献，无重复 |

## 总体评估

通过：5 / 7
警告：2 / 7（不打断，packaging 阶段照常进行）
失败：0 / 7

## 未通过项的影响

- 检查 3：q2 子任务失败 → 论文中 q2 章节可能数据不足。
- 检查 5：fig_q3_main.png 缺失 → 论文中该引用需在打包前清理或保留为占位。
```

### 状态符号

- `✓` 通过
- `⚠` 警告（非阻塞，记录但不打断）
- `✗` 失败（阻塞，必须由用户确认是否继续打包）

## 产出文件

| 路径 | 必须 | 说明 |
|---|---|---|
| `workdir/{task_id}/quality_report.md` | 是 | 质量审查结果 |

## 失败诊断

| 情况 | 处理 |
|---|---|
| 检查 1 失败 | **打断**，让用户确认 intake 阶段产出 |
| 检查 6 失败 | **打断**，让用户决定是否打包不完整论文 |
| 检查 7 失败 | 不打断，记入诊断；packaging 阶段会去重提示 |
| 其他检查警告 | 不打断 |

## 下一阶段入口

`pipeline/06-packaging-output.md`。

