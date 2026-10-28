# Telemetry

这份文档定义应用内的日志事件规范。默认使用 DebugLogCenter 记录；如需对接外部系统，可在此基础上扩展。

## 事件结构
- `name`: 事件名（小写点分）
- `level`: 级别（debug/info/warn/error)
- `fields`: 字段字典

## 事件清单（示例）
1. `icloud.container.resolve`
   - level: `info`
   - fields: `attempt`, `success`, `containerId`
2. `icloud.container.identity_changed`
   - level: `warn`
   - fields: `reason`
3. `icloud.read.failed`
   - level: `error`
   - fields: `file`, `error`
4. `icloud.write.failed`
   - level: `error`
   - fields: `file`, `error`
5. `icloud.conflict.resolved`
   - level: `info`
   - fields: `file`, `winner`

## 使用示例
```swift
Telemetry.log(.icloudContainerResolve(attempt: 2, success: true, containerId: "_default"))
Telemetry.log(.icloudReadFailed(file: "records.json", error: "timeout"))
```
