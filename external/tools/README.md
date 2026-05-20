# external/tools

工具决策状态目录。仓库默认仅含 `.gitkeep`，运行时由 pipeline 00 写入标记
文件，记录用户对外部工具的选择。

## 标记文件

| 文件 | 含义 |
|---|---|
| `.tools_decided` | 首次询问已完成；本会话不再追问 |
| `<domain>.free` | 该域只用免费 / 零配置工具（pdf / scholar / dataset / webcrawl） |
| `<domain>.skip` | 该域本次跳过 |
| `tools_decision_log.md` | 决策时间 / 用户选择 / 当时 env var 状态 |

四个 domain：`pdf`、`scholar`、`dataset`、`webcrawl`。

## 与 git 的关系

`.gitignore` 已排除 `external/tools/*` 但保留 `.gitkeep`，运行时产生的标记
文件不会被追踪。

## 与 catalog 的关系

工具元信息（价格 / 配置 / 何时启用）单一信息源是
`references/external-tools-catalog.md`；本目录只保存"用户决策快照"。
