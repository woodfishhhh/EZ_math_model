# Pipeline 03 — 代码求解

## 入口条件

- `modeling_plan.md` 已落盘且包含每个 quesN 的小节。
- `thesis_match.json` 已落盘。

## 阶段任务

### 1. 加载 coder 角色

- prompt：`prompts/coder.md`
- 守则：`references/roles/coder-guide.md`

### 2. 任务清单生成

按 `modeling_plan.md` 的小节切分子任务：

| 子任务 | 输入 | 产出 |
|---|---|---|
| `eda` | `attachments/`、modeling_plan §0 | `src/eda.py`、`figures/fig_eda_*.png`、`results/eda_summary.csv`（数据驱动题） |
| `q1` | modeling_plan §1 | `src/q1_solve.py`、`figures/fig_q1_*.png`、`results/q1_*.{csv,json}` |
| `q2..qN` | modeling_plan §i | 同上 |
| `sensitivity` | modeling_plan §N+1 | `src/sensitivity.py`、`figures/fig_sensitivity_*.png`、`results/sensitivity.json` |

### 3. 逐子任务执行

容错策略：依据 `references/fault-tolerance.md` 的 L1+L2+L3 协议。**绝不**在
本阶段实现自定义重试，必须复用 fault-tolerance 的统一约束。

每个子任务循环（伪代码）：

```
attempt = 0
while attempt < EZMM_MAX_RETRIES_CODER:   # 默认 2
    生成代码 → 落盘 src/{name}.py
    执行：python src/{name}.py
    if 退出码 == 0:
        记 execution_log.md：name=ok, retries=attempt
        触发 L3 影子评估（quality_audit 阶段读取）
        break
    else:
        attempt += 1
        # 修复策略：
        #   第 1 次：读异常 + 改局部
        #   第 2 次：换思路（更简单算法 / 更小数据集 / 更宽松约束）
        记 execution_log.md：name=retry-{attempt}, error_summary=<一行>
        if attempt == EZMM_MAX_RETRIES_CODER:
            进 L2 fallback：库缺失尝试同类替代（详见 references/fault-tolerance.md L2）
            if L2 仍失败:
                记 execution_log.md：name=failed
                写诊断到 diagnostics.md（含错误摘要、影响、建议）
                break  # 不打断，继续下一子任务
```

**库缺失 L2 降级表**（节选自 fault-tolerance.md，便于本阶段查阅）：

| 缺失库 | 替代方案 |
|---|---|
| xgboost | sklearn `GradientBoostingRegressor / Classifier` |
| lightgbm | sklearn `HistGradientBoosting*` |
| seaborn | matplotlib + 全局 rcParams |
| statsmodels | sklearn 简单回归；ARIMA 改 `pmdarima` |
| networkx | scipy.sparse.csgraph |
| pulp | scipy.optimize.linprog（整数规划用 milp） |

降级动作必须在脚本开头注释里写：`# 替换 xgboost -> sklearn.GradientBoosting (库缺失)`。

### 4. Sub-agent 派单细节（可选）

派单决策由 `external/tools/agent_mode.{single,multi,hybrid}` 标记决定。
**single 模式跳过本节**，按顺序执行所有子任务；**multi / hybrid 模式**按下文派单。

详细派单协议见 `references/agent-mode.md`。如宿主已安装
`dispatching-parallel-agents` skill，按其指引判定"是否真正独立"再派单
（详见 `tools/dispatching-parallel-agents/SKILL.md`）。

若主对话上下文已超过 60% 上限，或 modeling_plan.md 拆出 ≥ 5 个子任务，
**应派 coder sub-agent**：每个子任务一个 subagent，并发上限默认 2（避免内核
争用与文件竞写）。派单模板：

```
subagent_type = general-purpose
description   = "ez-math-model coder for {task_name}"
prompt        = (
    "工作目录：{workdir}\n"
    "请按 prompts/coder.md + references/roles/coder-guide.md 完成子任务 {task_name}。\n"
    "modeling_plan 第 {section} 节、附件清单：{attachments}\n"
    "落盘要求：src/{task_name}.py + results/{task_name}_*.csv + figures/fig_{task_name}_*.png\n"
    "完成后输出一行 'DONE {task_name}' 到 stdout。\n"
    "受 fault-tolerance L1 约束，最多重试 2 次。"
)
```

主流程等 subagent 全部 DONE 后聚合 `execution_log.md`，再进 pipeline 04。

### 4. 数据特征文本输出（强制）

每段绑图代码后必须 `print` 关键数据特征（模板见 `prompts/coder.md`）。
没有 print 的图后续 writer 无法解读，质量门会扣分。

### 5. 工程优化约束（优化类问题强制）

若 `intake.json` 中识别出"优化类"（关键词：最优 / 优化 / 极值 / 最大化 /
最小化 / 调度 / 选择），coder 必须在 `print` 中包含"无约束 vs 物理约束"对比
段落（详见 `prompts/coder.md`）。

### 6. 执行日志

`execution_log.md` 是 markdown 表格 + 详细记录块：

```markdown
| 子任务 | 状态 | 重试 | 耗时 | 关键产出 |
|---|---|---|---|---|
| eda | ok | 0 | 12s | fig_eda_corr.png, eda_summary.csv |
| q1 | ok | 1 | 45s | fig_q1_fit.png, q1_metrics.csv |
| q2 | failed | 2 | 60s | （见诊断） |
| sensitivity | ok | 0 | 18s | fig_sensitivity.png |
```

## 产出文件

| 路径 | 必须 | 说明 |
|---|---|---|
| `workdir/{task_id}/src/*.py` | 是 | 每个子任务一个脚本 |
| `workdir/{task_id}/results/` | 是 | 至少 1 个结果文件 |
| `workdir/{task_id}/figures/` | 是 | 至少 EDA + 每问 1 张关键图 |
| `workdir/{task_id}/execution_log.md` | 是 | 执行状态汇总 |

## 失败诊断

| 情况 | 处理 |
|---|---|
| 单个脚本 2 次重试仍失败 | L1 用尽 → 若 `external/tools/inherited_skills.{yes,recommended}` 存在且检测到 systematic-debugging，调 `tools/systematic-debugging/SKILL.md` 做根因分析；否则记 `diagnostics.md`，**不打断**，跳到下一子任务 |
| 全部脚本失败（≥ 80% 子任务 failed） | **打断**，输出最常见错误类型，让用户检查环境 |
| 关键库（如 xgboost）缺失 | 不打断，coder 自动 fallback 到 sklearn 同类模型（参考本文件 §3 L2 降级表） |
| 附件读取失败 | 不打断，相关子任务标记 skip 并写诊断 |
| simplify skill 已启用 | 所有子任务完成后调 `tools/simplify/SKILL.md` 写 `simplify_report.md`（不修代码） |

## 下一阶段入口

`pipeline/04-paper-writing.md`。

