# Pipeline 04 — 论文撰写

## 入口条件

- `modeling_plan.md` 已落盘。
- `execution_log.md` 已落盘且 ≥ 50% 子任务状态为 `ok`。
- `figures/` 下至少有 1 张图。

## 阶段任务

### 1. 加载 writer 角色

- prompt：`prompts/writer.md`
- 守则：`references/roles/writer-guide.md`
- 模板：根据 `intake.json.language`（默认 `zh`）选择
  `templates/paper_zh.md` 或 `templates/paper_en.md`。
- 章节大纲：`templates/chapter_outline.toml`。

### 2. 上游论文参考（条件性）

若 `thesis_match.json.match_level != internal`，列出 `thesis_dir/` 下的
PDF 文件名给 writer 作为风格参考。writer 仅可参考结构与表述方式，
**不复制原文**；如需引用某个公式或观点，必须以 `{[^N] ...}` 学术格式标注。

### 3. 输入物聚合

writer 收到的输入包括：
- `intake.json`（题目语义层）
- `modeling_plan.md`（建模方案层）
- `execution_log.md`（哪些 quesN 有结果）
- `figures/` 下所有图片的**文件名清单**
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

### 5. 强制规则（来自 writer prompt）

- 段落式写作，正文严禁 bullet / numbered list。
- `figures/` 下每张图都必须以 `![描述](文件名.png)` 出现至少一次。
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
| `workdir/{task_id}/paper.md` | 是 | 论文 markdown |
| `workdir/{task_id}/paper.humanized.md` | 否 | 若启用 humanizer，去 AI 味重写版（详见 `tools/humanizer/SKILL.md`） |
| `workdir/{task_id}/refs/external_context.md` | 否 | 若启用 external-context，多领域并行检索的文献列表 |

## 失败诊断

| 情况 | 处理 |
|---|---|
| 缺少某 quesN 的图 | 论文中省略该子小节的图引用，质量门记入未通过项 |
| `paper-search skill` 不可用 | writer 改用通用文献模板（"经典教材 + 综述"），并在诊断中注明 |
| paper.md 字数 < 3000 | 不打断，质量门会标记字数不足 |
| 论文中出现 bullet 列表 | 写完后做一遍正则扫描，若发现 → writer 重写一次 |

## 下一阶段入口

`pipeline/05-quality-audit.md`。


