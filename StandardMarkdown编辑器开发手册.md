# StandardMarkdown 编辑器开发手册（给 AI 开发用）

## 1. 范围定义

本手册仅描述 `TableType.markdown`（磁盘元类型 `StandardMarkdown`）相关实现。

对应代码位置：

1. `TableType.markdown`：`TimeTracker/TimeTracker/TimeTrackerApp.swift:2082`
2. 元类型映射：`tableTypeFromMeta("StandardMarkdown") -> .markdown`：`TimeTracker/TimeTracker/TimeTrackerApp.swift:5195`
3. 写出元类型：`.markdown -> "StandardMarkdown"`：`TimeTracker/TimeTracker/TimeTrackerApp.swift:5206`

---

## 2. 编辑器入口与路由

统一详情页是 `ArchiveDetailTableView`，路由规则：

1. `liveTable.type == .markdown` 时进入 `MarkdownEditorView`
2. `liveTable.type == .lessonPlanNodes` 时进入 `LessonPlanEditorView`
3. 其他类型走标准表格/清单编辑

代码：`TimeTracker/TimeTracker/TimeTrackerApp.swift:40197`

---

## 3. StandardMarkdown 编辑器功能（MarkdownEditorView）

主类型：`MarkdownEditorView`
代码：`TimeTracker/TimeTracker/TimeTrackerApp.swift:10112`

### 3.1 视图模式

`MarkdownViewSettings.ViewMode` 提供四种模式：

1. `live`：即时渲染编辑
2. `code`：源码编辑
3. `preview`：Web 预览
4. `split`：分屏（源码+预览，可横/竖切）

定义：`TimeTracker/TimeTracker/TimeTrackerApp.swift:9095`

### 3.2 顶栏能力

`MarkdownEditorView` 顶栏包含：

1. 明暗切换
2. 样式面板（Palette）
3. TOC 面板
4. 模式切换（live/code/preview/split）
5. 分屏方向切换（split 下）
6. 导出菜单

代码集中在：`TimeTracker/TimeTracker/TimeTrackerApp.swift:10176`

### 3.3 导出能力

导出选项：

1. `Markdown (.md)`
2. `长图 (.png)`
3. `PDF (.pdf) 导出`

代码：`TimeTracker/TimeTracker/TimeTrackerApp.swift:10207`

### 3.4 自动保存与会话保存

保存机制：

1. 1分钟自动保存（`autoSaveTimer`）
2. 会话结束时做单表备份 + 全量快照

代码：`TimeTracker/TimeTracker/TimeTrackerApp.swift:10374`

### 3.5 状态持久化

保存内容：

1. 视图配置（模式/暗色等）：`Setting`
2. 样式配置：`Setting`

接口：

1. `loadMarkdownSettings/saveMarkdownSettings`：`TimeTracker/TimeTracker/TimeTrackerApp.swift:6819`
2. `loadMarkdownStyle/saveMarkdownStyle`：`TimeTracker/TimeTracker/TimeTrackerApp.swift:6817`
3. 编辑状态模型 `EditorViewState`：`TimeTracker/TimeTracker/TimeTrackerApp.swift:12425`

---

## 4. StandardMarkdown 数据模型（内存）

核心约束：**一个 Markdown 文档按“单行 ArchiveRow”存储全文**。

`ArchiveTable` 结构：

1. `type = .markdown`
2. `rows` 理论上只使用 `first`
3. `rows.first.value` 持有 Markdown 正文

关键兼容函数：

1. `wrapMarkdownContent(_:)` 当前为直通（直接返回文本）
2. `unwrapMarkdownContent(_:)` 兼容旧 JSON 包装（若可解码 `StandardRowData` 则取 `.content`）

代码：`TimeTracker/TimeTracker/TimeTrackerApp.swift:6822`

---

## 5. 文件格式（CSV）规范

## 5.1 写入格式（generateCSVString）

当 `t.type == .markdown`：

1. 表头固定：`UUID,内容`
2. 写入一条正文行：`<rowKey>,<markdown content>`
3. 附加 META：`[META_ID] [META_TITLE] [META_TEMPLATE] [META_CREATED] [META_TYPE]`
4. `META_TYPE` 固定为 `StandardMarkdown`

代码：`TimeTracker/TimeTracker/TimeTrackerApp.swift:5225` 与 `:5240`

### 示例（标准输出形态）

```csv
﻿UUID,内容
0E2A0F5F-3C1A-4B08-9D1E-8B5D1E1B22F0,"# 标题{{BR}}正文"

[META_ID],A8CE7B86-6AF3-4C4D-B54D-2A61D6E71E19
[META_TITLE],我的文档
[META_TEMPLATE],nil
[META_CREATED],1732456789.123
[META_TYPE],StandardMarkdown
```

说明：

1. 换行会被转义为 `{{BR}}`
2. 制表符会被转义为 `{{TAB}}`
3. 读取时再还原为真实 `\n` / `\t`

---

## 5.2 读取格式（loadTableFromCSV / parseMarkdownContent）

读取流程：

1. 先看 `[META_TYPE]` 是否 `StandardMarkdown`，映射为 `.markdown`
2. 进入 `parseMarkdownContent`
3. 找到第一条有效正文并 `break`（只读第一条）
4. 若没有正文，自动生成空行

代码：

1. `loadTableFromCSV`：`TimeTracker/TimeTracker/TimeTrackerApp.swift:5093`
2. `parseMarkdownContent`：`TimeTracker/TimeTracker/TimeTrackerApp.swift:5161`

兼容点：

1. 允许 `UUID,内容` 或包含额外列的旧格式
2. 自动判断内容列索引
3. 兜底空内容行，避免编辑器空数组崩溃

---

## 6. 新建 StandardMarkdown 文档

入口：`CreateTableSheet`

`CreationMode.markdown` 行为：

1. 创建 `ArchiveTable(type: .markdown, templateID: nil)`
2. 初始化一条空行，`value = wrapMarkdownContent("")`
3. 插入分类并 `saveTableToFile`

代码：`TimeTracker/TimeTracker/TimeTrackerApp.swift:39114`

---

## 7. 预览与渲染能力

StandardMarkdown 的预览层包含：

1. `marked.min.js` Markdown 解析
2. `katex.min.js + auto-render.min.js` 数学公式渲染
3. 分隔符支持：`$$...$$` 与 `$...$`

HTML 注入模板与脚本：`TimeTracker/TimeTracker/TimeTrackerApp.swift:12394`

项目静态资源目录：`TimeTracker/markdown_assets`

---

## 8. 图片资产语法（对接方必须保留）

导出渲染中对图片占位的识别格式是：

`\(asset:<assetID>)`

解析正则：`\\(asset:([^)]+)\\)`
代码：`TimeTracker/TimeTracker/TimeTrackerApp.swift:40095`

图片文件由 `MarkdownAssetManager` 管理，默认目录：

`CloudFileManager.shared.getCloudDir(.templates)/图片`

代码：`TimeTracker/TimeTracker/TimeTrackerApp.swift:9129`

---

## 9. 对另一个 AI 的硬性约束（必须遵守）

1. 不要把 StandardMarkdown 改成多行 row 模型，除非同步改读写/导出/兼容逻辑。
2. 改 CSV 时必须同时改：
   - `generateCSVString`（写）
   - `tableTypeFromMeta`（类型识别）
   - `parseMarkdownContent`（读）
3. 不要删除 `unwrapMarkdownContent` 的旧 JSON 解码分支。
4. 不要改掉 `META_TYPE=StandardMarkdown`，否则老文件会走错编辑器。
5. 若新增新功能（如 frontmatter、多附件），先保证旧文件可无损打开。

---

## 10. 最小验收清单（给 AI 自测）

1. 新建 Markdown 文档后，`type` 必须是 `.markdown`。
2. 重启 App 后，文档内容、模式、暗色状态能恢复。
3. 导出 `.md/.png/.pdf` 均可正常触发。
4. CSV 中 `META_TYPE` 为 `StandardMarkdown`。
5. 包含 `{{BR}}/{{TAB}}` 的内容读回后应还原。
6. 老数据（value 为 `StandardRowData` JSON）仍可正确显示正文。
