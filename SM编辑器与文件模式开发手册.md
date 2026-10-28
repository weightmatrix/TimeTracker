# TimeTracker - SM 编辑器与文件模式开发手册

> 说明：当前代码中没有直接命名为 `SMEditor` 的类型。结合实现，`SM` 可对应为「Markdown/教案双编辑体系 + SmartTextEditor 输入层」。本文基于实际代码梳理该体系。

## 1. 核心定位

TimeTracker 当前有三类主编辑入口：

1. Markdown 文档编辑器：`MarkdownEditorView`
2. 教案/随堂笔记编辑器：`LessonPlanEditorView`
3. 标准表格/任务清单编辑器：`ArchiveDetailTableView` 内部列表编辑

统一文件实体是 `ArchiveTable`，通过 `TableType` 决定编辑器路由。

## 2. 文件模式（TableType）总览

定义：`TimeTracker/TimeTracker/TimeTrackerApp.swift:2079`

```swift
enum TableType: String, Codable, Hashable {
    case standard
    case taskList
    case markdown
    case lessonPlanNodes
    case courseSchedule
}
```

语义：

1. `standard`：标准表格（行值是 `StandardRowData` JSON）
2. `taskList`：任务清单（行值是 `TaskRowData` JSON）
3. `markdown`：Markdown 文档（当前为单行承载全文）
4. `lessonPlanNodes`：教案节点文档（Node CSV 结构）
5. `courseSchedule`：课时费统计

## 3. 编辑器路由分发

分发入口：`ArchiveDetailTableView`，`TimeTracker/TimeTracker/TimeTrackerApp.swift:40197`

路由规则：

1. `table.type == .markdown` -> `MarkdownEditorView`
2. `table.type == .lessonPlanNodes` -> `LessonPlanEditorView(fileURL: ...)`
3. 其他类型 -> 标准表格/任务清单编辑界面

这意味着 UI 层的“文件模式”是由 `ArchiveTable.type` 强约束，而不是通过文件后缀判断。

## 4. SM 编辑器体系（实现拆解）

## 4.1 Markdown 主编辑器

类型：`MarkdownEditorView`（`TimeTracker/TimeTracker/TimeTrackerApp.swift:10112`）

视图模式：`MarkdownViewSettings.ViewMode`（`TimeTracker/TimeTracker/TimeTrackerApp.swift:9100`）

1. `live`：即时渲染
2. `code`：源码模式
3. `preview`：Web 预览
4. `split`：分屏预览（小屏会降级）

持久化：

1. 全局 Markdown 视图设置：`global_markdown_view_settings`
2. Markdown 样式：`global_markdown_style`
3. 单文档编辑状态（光标/滚动）：`md_state_<tableID>`

对应方法（`ArchiveStore` 扩展）：

1. `loadMarkdownSettings` / `saveMarkdownSettings`（`TimeTracker/TimeTracker/TimeTrackerApp.swift:6819`）
2. `loadMarkdownStyle` / `saveMarkdownStyle`（`TimeTracker/TimeTracker/TimeTrackerApp.swift:6817`）

保存策略：

1. 定时自动保存（5 秒）
2. 页面退出 `onDisappear` 收口保存
3. 有内容变更时走 `persistTableChanges`
4. 会触发备份（退出会话时）

## 4.2 教案编辑器（LessonPlan）

类型：`LessonPlanEditorView`（`TimeTracker/TimeTracker/TimeTrackerApp.swift:16856`）

视图模式：内部 `LPViewMode`（`TimeTracker/TimeTracker/TimeTrackerApp.swift:16872`）

1. `live`
2. `code`
3. `preview`
4. `split`

设备级设置（本机，不同步）：`LPDeviceSettings`

字段包括：

1. `lpStyle`
2. `isDarkMode`
3. `viewModeRaw`
4. `bgOverrideEnabled`
5. `bgOverrideHex`

存储文件：`Application Support/TimeTracker/lp_device_settings.json`（由 `lpDeviceSettingsURL()` 生成）

编辑状态按“文件 + 模式”分别保存：

1. key 生成：`lp_state_<fileNameEncoded>_<mode>`
2. 方法：`persistEditorState` / `loadEditorState`
3. 切换模式时先持久化旧模式，再切换 `viewModeRaw`

## 4.3 SmartTextEditor（输入层）

类型：`SmartTextEditor`（`TimeTracker/TimeTracker/TimeTrackerApp.swift:40560` 与 `:40669`）

定位：跨平台 UITextView/NSTextView 包装，提供：

1. 动态高度
2. 智能输入变换（`onSmartInput`）
3. 光标位置矫正
4. 编辑态回调

它是“智能编辑输入内核”，不是顶层文件编辑器路由入口。

## 5. 文件创建模式（CreateTableSheet）

位置：`TimeTracker/TimeTracker/TimeTrackerApp.swift:39004`

`CreationMode`：

1. `empty`：空白模板
2. `autoFill`：自动填写
3. `taskList`：任务清单
4. `markdown`：Markdown 文档

Markdown 创建逻辑（`validateAndCreate`）：

1. 新建 `ArchiveTable(type: .markdown, templateID: nil)`
2. 创建单行 `ArchiveRow`
3. 行值用 `wrapMarkdownContent("")`
4. 插入分类后 `saveTableToFile`

## 6. 磁盘格式与类型识别

## 6.1 CSV 读入

入口：`loadTableFromCSV`（`TimeTracker/TimeTracker/TimeTrackerApp.swift:5093`）

识别机制：

1. 优先判断首行是否为教案节点头：`UUID,Prefix,Content,SourceID`
2. 再读 `[META_TYPE]`
3. 映射到 `TableType`

类型映射：`tableTypeFromMeta`（`TimeTracker/TimeTracker/TimeTrackerApp.swift:5190`）

1. `TableDocument` -> `.standard`
2. `ChecklistDocument` -> `.taskList`
3. `NodesMarkdown` -> `.lessonPlanNodes`
4. `StandardMarkdown` -> `.markdown`
5. `课时费统计` -> `.courseSchedule`

## 6.2 CSV 写出

入口：`generateCSVString`（`TimeTracker/TimeTracker/TimeTrackerApp.swift:5211`）

特点：

1. 各 `TableType` 使用不同表头
2. 文末统一追加 `[META_*]`
3. `META_TYPE` 由 `documentTypeLabel(for:)` 输出

Markdown 写出格式：

1. 表头：`UUID,内容`
2. 当前只写首行内容
3. 内容经 `unwrapMarkdownContent` 反包

## 6.3 全量加载流程

入口：`loadDataFromFileSystem`（`TimeTracker/TimeTracker/TimeTrackerApp.swift:4664`）

流程：

1. 遍历 `CloudFileManager.getCloudDir(.tables)` 下所有目录（支持子目录）
2. 每个 CSV 读成 `ArchiveTable`
3. 按逻辑 ID 去重（保留较新修改时间）
4. 回填到 `categories` 并排序

## 7. 数据落盘与一致性

关键写接口：

1. `persistTableChanges(table:categoryID:oldTitle:)`（重命名/覆盖）
2. `saveTableToFile(_:, categoryTitle:)`

机制要点：

1. 重命名使用 `CloudFileManager.atomicRenameTable`
2. 普通保存使用 `CloudFileManager.saveTableDual`
3. 配合 `CloudSyncManager.ignoreNextUpdate` 做回声抑制
4. Markdown 与教案在退出编辑时都附带备份动作

## 8. 模式排序与列表标签

排序权重：`tableTypeSortRank`（`TimeTracker/TimeTracker/TimeTrackerApp.swift:4333`）

1. `standard` -> 0
2. `markdown` -> 1
3. `taskList` -> 2
4. `lessonPlanNodes` -> 3
5. `courseSchedule` -> 4

列表标签与图标（`ArchiveTableCell`）：`TimeTracker/TimeTracker/TimeTrackerApp.swift:38741`

1. Markdown：`doc.text.fill` / 标签 `MARKDOWN`
2. LessonPlan：`book.closed.fill` / 标签 `随堂笔记`

## 9. 给另一个 AI 的扩展约束

如果要新增文件模式或编辑器，请按以下顺序补全，避免半成品状态：

1. 扩展 `TableType`
2. 扩展 CSV 元数据映射（`tableTypeFromMeta` + `documentTypeLabel`）
3. 扩展 `loadTableFromCSV` 的解析分支
4. 扩展 `generateCSVString` 的写出分支
5. 在 `ArchiveDetailTableView` 增加路由
6. 在 `CreateTableSheet.CreationMode` 增加创建入口
7. 补齐图标、标签、排序权重
8. 补齐自动保存与退出备份策略

## 10. 常见坑位

1. Markdown 当前是“单行承载全文”模型，误按多行 ArchiveRow 处理会丢数据。
2. `wrapMarkdownContent` 目前是直通；`unwrapMarkdownContent` 有旧结构兼容逻辑，改动时要保留向后兼容。
3. 教案编辑器状态是“按 mode 分桶存储”，切模式前不持久化会造成光标/滚动丢失。
4. 新增模式若只改 UI 不改 CSV meta，会在下次加载被识别成错误类型。

## 11. 关键定位索引

1. `TableType`：`TimeTracker/TimeTracker/TimeTrackerApp.swift:2079`
2. `ArchiveTable`：`TimeTracker/TimeTracker/TimeTrackerApp.swift:2116`
3. Markdown 视图模式定义：`TimeTracker/TimeTracker/TimeTrackerApp.swift:9095`
4. `MarkdownEditorView`：`TimeTracker/TimeTracker/TimeTrackerApp.swift:10112`
5. `LessonPlanEditorView` + `LPViewMode`：`TimeTracker/TimeTracker/TimeTrackerApp.swift:16856`
6. 编辑器状态模型 `EditorViewState`：`TimeTracker/TimeTracker/TimeTrackerApp.swift:12425`
7. 路由分发 `ArchiveDetailTableView`：`TimeTracker/TimeTracker/TimeTrackerApp.swift:40197`
8. 新建模式 `CreateTableSheet.CreationMode`：`TimeTracker/TimeTracker/TimeTrackerApp.swift:39004`
9. 读盘入口 `loadDataFromFileSystem`：`TimeTracker/TimeTracker/TimeTrackerApp.swift:4664`
10. 读 CSV `loadTableFromCSV`：`TimeTracker/TimeTracker/TimeTrackerApp.swift:5093`
11. 写 CSV `generateCSVString`：`TimeTracker/TimeTracker/TimeTrackerApp.swift:5211`
12. Markdown 包装兼容：`TimeTracker/TimeTracker/TimeTrackerApp.swift:6822`
13. SmartTextEditor：`TimeTracker/TimeTracker/TimeTrackerApp.swift:40560`
