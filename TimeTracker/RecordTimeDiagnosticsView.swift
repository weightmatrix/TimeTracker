import SwiftUI

struct RecordTimeDiagnosticsView: View {
    @State private var files: [URL] = []
    @State private var error: String?
    var body: some View {
        List {
            Section("自动检查") {
                Text("开始时间或已结束记录的终点超过当前时间时，会保存诊断现场并拦截修改。进行中任务的未结束标记除外。")
                Text("异常诊断始终开启；正常切换的详细记录可在调试设置中选择开启。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            if let error { Section("诊断写入失败") { Text(error).foregroundStyle(.orange).textSelection(.enabled) } }
            Section("诊断日志与现场") {
                Button("刷新") { refresh() }
                if files.isEmpty { Text("尚无异常诊断文件。开启正常切换诊断后，也会在这里生成日志。") }
                ForEach(files, id: \.path) { file in
                    ShareLink(item: file) {
                        Label(file.lastPathComponent, systemImage: "square.and.arrow.up").lineLimit(2)
                    }
                }
            }
        }
        .navigationTitle("记录时间诊断")
        .task { refresh() }
    }
    private func refresh() {
        files = RecordTimeDiagnostics.shared.files()
        error = RecordTimeDiagnostics.shared.lastWriteError
    }
}
