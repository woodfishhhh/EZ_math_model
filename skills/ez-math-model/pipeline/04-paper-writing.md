# Pipeline 04 — 论文撰写

## 入口条件

- `modeling_plan.md` 已落盘。
- `execution_log.md` 已落盘且 ≥ 50% 子任务状态为 `ok`。
- `figures/` 下至少有 1 张图。
- `run_state.json.run_mode != blocked`。
- 若 `run_mode=formal`，`figures/chart_manifest.json` 中至少有 1 张
  `usable_in_paper=true` 且 `synthetic=false` 的图。

## 阶段任务

### 1. 加载 writer 角色

- prompt：`prompts/writer.md`
- 守则：`references/roles/writer-guide.md`
- 协议：`references/run-mode-protocol.md`、`references/chart-quality-gate.md`
- 模板：根据 `intake.json.language`（默认 `zh`）选择
  `templates/paper_zh.md` 或 `templates/paper_en.md`。
- 章节大纲：`templates/chapter_outline.toml`。

### 2. 上游论文参考（条件性）

若 `thesis_match.json.match_level != internal`，列出 `thesis_dir/` 下的
PDF 文件名给 writer 作为风格参考。writer 仅可参考结构与表述方式，
**不复制原文**；如需引用某个公式或观点，必须以 `{[^N] ...}` 学术格式标注。

### 3. 输入物聚合

writer 收到的输入包括：
- `run_state.json`（run_mode、formal_result、setup_status）
- `intake.json`（题目语义层）
- `modeling_plan.md`（建模方案层）
- `execution_log.md`（哪些 quesN 有结果）
- `figures/` 下所有图片的**文件名清单**
- `figures/chart_manifest.json` 中 `usable_in_paper=true` 的图片清单
- `src/*.py` 中每个脚本末尾的 `print` 输出（特别是数据特征块）
- `results/` 下的 csv / json（用于复述具体数值）
- `thesis_dir/` 的 PDF 文件名清单（可选）
- `external/user-corpus/AGENTS.md`（若存在）：用户钦定参考资料的索引；
  writer 在引用文献候选阶段优先查这里的论文是否能匹配到 DOI。

### 4. 撰写流程

按章节顺序写：

1. 标题 + 摘要 + 关键词
2. 一、问题重述
3. 二、问题分析
4. 三、模型假设
5. 四、符号说明与数据预处理
6. 五、模型的建立与求解（每个 quesN 一节）
7. 六、敏感性分析
8. 七、模型评价
9. 参考文献

若 `run_mode=demo`，标题、摘要、结果章节和结论必须显式写明“流程验证 / 非正式
结果”，不得使用“最优”“最终”“正式结论”等措辞。若 `run_mode=blocked`，不得生成
正式论文，只能输出 `diagnostics.md`。

### 5. 强制规则（来自 writer prompt）

- 段落式写作，正文严禁 bullet / numbered list。
- `figures/` 下每张图都必须以 `![描述](文件名.png)` 出现至少一次。
- 仅允许引用 `chart_manifest.json` 中 `usable_in_paper=true` 的图。
- 每张图前后至少 3 行解读分析，分析数值必须来自 `print` 输出，禁止编造。
- 文献编号 `[^N]` 全文唯一，不重复引用。
- 公式参数必须写来源（数据 / 文献 / 校准）。
- 优化类问题必须包含"无约束解 vs 物理约束解"段落。

### 6. 文献检索

理论性章节（"为什么选模型"、"敏感性分析方法论"、"评价模型理论基础"）必须
调 `tools/paper_search/SKILL.md` 获取至少 3 条参考文献。检索关键词从
`modeling_plan.md` 的模型名抽取。

## 产出文件

| 路径 | 必须 | 说明 |
|---|---|---|
| `runtime/{task_id}/paper.md` | 是 | 论文 markdown；demo 模式必须标注非正式 |
| `runtime/{task_id}/paper.humanized.md` | 否 | 若启用 humanizer，去 AI 味重写版（详见 `tools/humanizer/SKILL.md`） |
| `runtime/{task_id}/refs/external_context.md` | 否 | 若启用 external-context，多领域并行检索的文献列表 |

## 失败诊断

| 情况 | 处理 |
|---|---|
| 缺少某 quesN 的图 | 论文中省略该子小节的图引用，质量门记入未通过项 |
| chart manifest 无可用图 | 停止写正式论文，写诊断；demo 可写流程验证文档 |
| `paper-search skill` 不可用 | writer 改用通用文献模板（"经典教材 + 综述"），并在诊断中注明 |
| paper.md 字数 < 3000 | 不打断，质量门会标记字数不足 |
| 论文中出现 bullet 列表 | 写完后做一遍正则扫描，若发现 → writer 重写一次 |

## 下一阶段入口

`pipeline/05-quality-audit.md`。


