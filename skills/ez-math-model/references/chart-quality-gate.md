# Chart Quality Gate

图表不是“有 PNG 就算完成”。每张图必须经过数据有效性检查，并生成 chart manifest。

## chart manifest

每张图生成后，必须在 `runtime/{task_id}/figures/chart_manifest.json` 中登记：

```json
{
  "figure": "fig_q2_spill_movement.png",
  "source": "results/q2_summary.csv",
  "rows_before": 6,
  "rows_after_filter": 4,
  "filtered_zero_rows": 2,
  "all_zero": false,
  "all_equal": false,
  "synthetic": false,
  "usable_in_paper": true,
  "reason": ""
}
```

## 必须过滤

| 情况 | 处理 |
|---|---|
| 指标列全为 0 | 不画图，写诊断，改用文字说明 |
| 指标列全相等 | 不画柱状图，改用表格或文字说明 |
| 任务行 `synthetic=true` 且 run_mode=formal | 阻塞，不能入论文 |
| 过滤后有效行 < 2 | 不画对比图，写诊断 |
| 缺少单位或指标名 | 图表不可入论文 |

## coder 约束

生成图前必须先构造待绘图数据，并写出：

```text
rows_before
rows_after_filter
filtered_zero_rows
all_zero
all_equal
usable_in_paper
```

writer 只能引用 `usable_in_paper=true` 的图。若图不可用，writer 应引用结果表或诊断，
不得为了凑图把无信息图写入正文。

## quality audit 约束

质量门必须读取 `chart_manifest.json`，并把以下情况标为失败或警告：

- `paper.md` 引用了 `usable_in_paper=false` 的图；
- `figures/` 有图但未登记 manifest；
- chart manifest 显示全 0 / 全相等仍被画成柱状图；
- demo/synthetic 图被用于 formal 结论。
