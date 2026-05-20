# Artifact Manifest

每次运行必须登记所有关键产物。manifest 是质量门、打包和用户排查的共同依据。

## 文件位置

```text
runtime/{task_id}/artifact_manifest.json
output/manifest.json
```

`runtime` 版本记录全过程，`output` 版本只记录最终交付物。

## schema

```json
{
  "task_id": "...",
  "run_mode": "formal | demo | blocked",
  "setup_status": "user_confirmed | temporary_default | skipped | incomplete",
  "artifacts": [
    {
      "path": "output/paper/paper.pdf",
      "type": "paper_pdf",
      "source": "runtime/.../paper.md",
      "stage": "packaging",
      "formal": true,
      "verified": true,
      "created_at": "...",
      "notes": ""
    }
  ]
}
```

## 必登产物

| 类型 | 路径 |
|---|---|
| `problem_markdown` | `runtime/{task_id}/problem.md` |
| `intake_json` | `runtime/{task_id}/intake.json` |
| `run_state` | `runtime/{task_id}/run_state.json` |
| `modeling_plan` | `runtime/{task_id}/modeling_plan.md` |
| `source_code` | `output/source code/` |
| `paper_md` | `output/paper/paper.md` |
| `paper_docx` | `output/paper/paper.docx` |
| `paper_txt` | `output/paper/paper.txt` |
| `paper_pdf` | `output/paper/paper.pdf` |
| `figures` | `output/附件文件夹/figures/` |
| `results` | `output/附件文件夹/results/` |
| `quality_report` | `output/附件文件夹/质量检查报告.md` |
| `diagnostics` | `output/附件文件夹/失败诊断.md` |
| `project_zip` | `项目总文件夹/output.zip`，内容为总文件夹内全部内容（排除 output.zip 自身） |

## 质量门要求

质量审查不得只依赖文件系统扫描。它必须读取 manifest，确认每个必登产物：

- 存在；
- 类型正确；
- `verified=true`；
- `formal` 与 `run_mode` 一致；
- demo 产物没有被标成 formal。
