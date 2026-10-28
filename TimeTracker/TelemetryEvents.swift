import Foundation

enum TelemetryLevel: String {
    case debug
    case info
    case warn
    case error
}

struct TelemetryEvent {
    let name: String
    let level: TelemetryLevel
    let fields: [String: String]
}

enum Telemetry {
    static func log(_ event: TelemetryEvent) {
        let payload = event.fields.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        DebugLogCenter.appendCloud("[Telemetry][\(event.level.rawValue)] \(event.name) { \(payload) }")
    }
}

enum TelemetryEvents {
    static func icloudContainerResolve(attempt: Int, success: Bool, containerId: String) -> TelemetryEvent {
        TelemetryEvent(name: "icloud.container.resolve", level: .info, fields: [
            "attempt": String(attempt),
            "success": success ? "1" : "0",
            "containerId": containerId
        ])
    }

    static func icloudIdentityChanged(reason: String) -> TelemetryEvent {
        TelemetryEvent(name: "icloud.container.identity_changed", level: .warn, fields: [
            "reason": reason
        ])
    }

    static func icloudReadFailed(file: String, error: String) -> TelemetryEvent {
        TelemetryEvent(name: "icloud.read.failed", level: .error, fields: [
            "file": file,
            "error": error
        ])
    }

    static func icloudWriteFailed(file: String, error: String) -> TelemetryEvent {
        TelemetryEvent(name: "icloud.write.failed", level: .error, fields: [
            "file": file,
            "error": error
        ])
    }

    static func icloudConflictResolved(file: String, winner: String) -> TelemetryEvent {
        TelemetryEvent(name: "icloud.conflict.resolved", level: .info, fields: [
            "file": file,
            "winner": winner
        ])
    }
}
