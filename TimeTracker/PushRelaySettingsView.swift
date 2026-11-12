import SwiftUI

struct PushRelaySettingsView: View {
    @State private var pairingCode = ""
    @State private var newCode = ""
    @State private var paired = false
    @State private var busy = false
    @State private var status = ""

    var body: some View {
        Form {
            Section("跨设备实时通知") {
                Text(paired ? "本设备已配对。切换记录会逐条排队并经服务器通知其他设备。" : "输入另一台已配对设备生成的配对码。完整时间记录仍保存在 iCloud。")
                    .font(.caption)
                if !paired {
                    TextField("配对码", text: $pairingCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    Button("配对本设备") {
                        busy = true
                        Task {
                            do {
                                try await PushRelayClient.shared.enroll(code: pairingCode)
                                paired = true
                                pairingCode = ""
                                status = "配对成功。"
                            } catch { status = error.localizedDescription }
                            busy = false
                        }
                    }.disabled(pairingCode.isEmpty || busy)
                } else {
                    Button("为另一台设备生成配对码") {
                        busy = true
                        Task {
                            do {
                                newCode = try await PushRelayClient.shared.createPairingCode()
                                status = "配对码十分钟内有效，只能使用一次。"
                            } catch { status = error.localizedDescription }
                            busy = false
                        }
                    }.disabled(busy)
                    if !newCode.isEmpty {
                        Text(newCode).font(.system(.title3, design: .monospaced)).textSelection(.enabled)
                    }
                }
                if !status.isEmpty { Text(status).font(.caption).foregroundStyle(.secondary) }
            }
        }
        .navigationTitle("跨设备实时通知")
        .task { paired = await PushRelayClient.shared.isPaired() }
    }
}
