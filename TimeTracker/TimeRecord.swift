import Foundation

nonisolated struct TimeRecord: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var category: String
    var subCategory: String? // 【核心新增】记录具体项，如“数学”
    var startTime: Date { didSet { RecordTimeDiagnostics.observe(self, phase: "mutation.start") } }
    var endTime: Date { didSet { RecordTimeDiagnostics.observe(self, phase: "mutation.end") } }

    var isGap: Bool { category == "空" }
    var isOngoing: Bool {
        endTime.timeIntervalSinceReferenceDate.isFinite && abs(endTime.timeIntervalSince(Date.distantFuture)) <= 1
    }

    var duration: TimeInterval {
        let realEnd = isOngoing ? Date() : endTime
        return realEnd.timeIntervalSince(startTime)
    }

    init(id: UUID = UUID(), category: String, subCategory: String? = nil, startTime: Date, endTime: Date, file: String = #fileID, function: String = #function, line: UInt = #line) {
        self.id = id
        self.category = category
        self.subCategory = subCategory // 初始化赋值
        self.startTime = startTime
        self.endTime = endTime
        RecordTimeDiagnostics.observe(self, phase: "creation", file: file, function: function, line: line)
    }
}
