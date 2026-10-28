import SwiftUI
import Combine

struct NMSnapshotBrowserConfiguration: Equatable {
    var useLazyStack: Bool = true
    var enableTextSelection: Bool = true
    var showLineNumbers: Bool = false
    var lineSpacing: CGFloat = 0
    var horizontalPadding: CGFloat = 10
    var verticalPadding: CGFloat = 2
    var bottomSpacerFactor: CGFloat = 0.6
}

struct NMSnapshotLine: Identifiable, Equatable {
    let id: Int
    let text: String
}

struct NMSnapshotDocument: Equatable {
    let source: String
    let lines: [NMSnapshotLine]
}

enum NMSnapshotParser {
    static func buildDocument(from rawText: String) -> NMSnapshotDocument {
        var lines: [NMSnapshotLine] = []
        lines.reserveCapacity(512)

        var start = rawText.startIndex
        var index = 0

        while start < rawText.endIndex {
            if let newline = rawText[start...].firstIndex(of: "\n") {
                lines.append(NMSnapshotLine(id: index, text: String(rawText[start..<newline])))
                index += 1
                start = rawText.index(after: newline)
            } else {
                lines.append(NMSnapshotLine(id: index, text: String(rawText[start...])))
                index += 1
                start = rawText.endIndex
            }
        }

        if rawText.isEmpty || rawText.hasSuffix("\n") {
            lines.append(NMSnapshotLine(id: index, text: ""))
        }

        return NMSnapshotDocument(source: rawText, lines: lines)
    }
}

struct NMSnapshotTheme {
    let foreground: Color
    let background: Color
    let secondary: Color

    static func make(isDarkMode: Bool) -> NMSnapshotTheme {
        NMSnapshotTheme(
            foreground: isDarkMode ? .white : .black,
            background: isDarkMode ? .black : .white,
            secondary: isDarkMode ? .gray : .secondary
        )
    }
}

@MainActor
final class NMSnapshotViewModel: ObservableObject {
    @Published private(set) var document: NMSnapshotDocument = NMSnapshotDocument(source: "", lines: [NMSnapshotLine(id: 0, text: "")])

    func refreshIfNeeded(rawText: String) {
        guard document.source != rawText else { return }
        document = NMSnapshotParser.buildDocument(from: rawText)
    }
}

struct NMSnapshotLineRowView: View {
    let line: NMSnapshotLine
    let config: NMSnapshotBrowserConfiguration
    let theme: NMSnapshotTheme

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if config.showLineNumbers {
                Text("\(line.id + 1)")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(theme.secondary.opacity(0.8))
                    .frame(width: 44, alignment: .trailing)
                    .padding(.trailing, 4)
            }

            Text(verbatim: line.text)
                .font(.system(size: 14, weight: .regular, design: .monospaced))
                .foregroundColor(theme.foreground)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, config.horizontalPadding)
        .padding(.vertical, config.verticalPadding)
    }
}

struct NMSnapshotContentView: View {
    let lines: [NMSnapshotLine]
    let viewportHeight: CGFloat
    let config: NMSnapshotBrowserConfiguration
    let theme: NMSnapshotTheme

    var body: some View {
        Group {
            if config.useLazyStack {
                LazyVStack(alignment: .leading, spacing: config.lineSpacing) {
                    rows
                }
            } else {
                VStack(alignment: .leading, spacing: config.lineSpacing) {
                    rows
                }
            }
        }
    }

    @ViewBuilder
    private var rows: some View {
        ForEach(lines) { line in
            NMSnapshotLineRowView(line: line, config: config, theme: theme)
        }
        Color.clear.frame(height: viewportHeight * max(0, config.bottomSpacerFactor))
    }
}

struct NodeMarkdownBrowserView: View {
    let rawText: String
    let isDarkMode: Bool
    let viewportHeight: CGFloat
    var config: NMSnapshotBrowserConfiguration = NMSnapshotBrowserConfiguration()

    @StateObject private var viewModel = NMSnapshotViewModel()

    private var theme: NMSnapshotTheme {
        NMSnapshotTheme.make(isDarkMode: isDarkMode)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            NMSnapshotContentView(
                lines: viewModel.document.lines,
                viewportHeight: viewportHeight,
                config: config,
                theme: theme
            )
        }
        .background(theme.background)
        .modifier(NMSnapshotTextSelectionModifier(isEnabled: config.enableTextSelection))
        .onAppear {
            viewModel.refreshIfNeeded(rawText: rawText)
        }
        .onChange(of: rawText) { _, newValue in
            viewModel.refreshIfNeeded(rawText: newValue)
        }
    }
}

private struct NMSnapshotTextSelectionModifier: ViewModifier {
    let isEnabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content.textSelection(.enabled)
        } else {
            content.textSelection(.disabled)
        }
    }
}
