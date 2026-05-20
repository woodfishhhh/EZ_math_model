# Pipeline 01 — 题目解析

## 入口条件

- `workdir/{task_id}/` 已存在。
- `env_check.json` 已落盘。
- 用户附件已复制到 `workdir/{task_id}/attachments/`。

## 阶段任务

1. **抽取题目原文**到 `workdir/{task_id}/problem.md`：
   - PDF：通过 `tools/pdf/SKILL.md` 调宿主 pdf skill；如未安装 pdf skill，
     退化为 `pdfplumber` 直读，并保留原 PDF 在 `attachments/`。
   - DOCX：通过 `tools/docx/SKILL.md` 提取纯文本。
   - Markdown / TXT：直接复制内容。
   - 多文件题目：按用户上传顺序合并并加分隔标题。
2. **加载 coordinator prompt** (`prompts/coordinator.md`)，输入题目原文，得到
   `intake.json`（schema 见 `references/workdir-protocol.md`）。
3. **附件清单分类**：扫描 `attachments/` 目录，把每个文件按扩展名分类
   （csv/xlsx/json/png/jpg/txt/pdf 等），写入 `intake.json.attachments`。
4. **生成附件描述**（数据驱动题）：对 csv / xlsx，调 xlsx skill 读取
   shape、列名、前 3 行预览，写入 `intake.json.attachments[i].preview`。
5. 更新 `workdir/{task_id}/README.md` 的相关字段。
6. **派 corpus explorer**（仅当 pipeline 00 的 corpus 域决策为 `yes`）：
   按 `tools/user-corpus-explorer/SKILL.md` 的"调度方式"派一个 subagent 扫描
   `external/user-corpus/`，产出 `external/user-corpus/AGENTS.md`。
   - 派单后**不阻塞**当前阶段，立即返回。
   - pipeline 02 启动前等待 explorer 完成（典型 30s-3min）。
   - 若 corpus 域决策为 `skip` / `later` / 未决策 → 跳过此步。

## 产出文件

| 路径 | 必须 | 说明 |
|---|---|---|
| `workdir/{task_id}/problem.md` | 是 | 题目原文（清洗后的 markdown） |
| `workdir/{task_id}/intake.json` | 是 | 拆题结构化结果 |
| `workdir/{task_id}/attachments/` | 是 | 用户附件原件（含预览元信息可有可无） |
| `external/user-corpus/AGENTS.md` | 视情况 | corpus 域 = yes 时由 explorer 产出 |
| `external/user-corpus/.corpus_index.json` | 视情况 | 同上，缓存 |

## 失败诊断

| 情况 | 处理 |
|---|---|
| `intake.json.is_math_modeling = false` | **打断**，输出拒绝原因，建议改用其他 skill。 |
| `intake.json.ques_count = 0` 但是是建模题 | **打断**，让用户确认 problem.md 中是否还有未识别的小问。 |
| PDF 抽取乱码 | 不打断，写诊断报告，建议用户提供文本版或重新上传。 |
| 附件读不出 | 不打断，写入 `attachments[i].error`，coder 阶段视情况绕过。 |
| corpus explorer 派单失败 | 不打断，写诊断；pipeline 02 直接走 zhanwen / 内置兜底。 |
| corpus 为空但用户选了 yes | explorer 写"corpus is empty"AGENTS.md，pipeline 继续。 |

## 下一阶段入口

`pipeline/02-modeling-plan.md`。


