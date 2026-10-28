import Foundation

#if os(watchOS)
import SwiftUI

struct WatchActionRootView: View {
    @EnvironmentObject var actionStore: WatchActionStore
    
    var body: some View {
        VStack(spacing: 10) {
            Text("当前")
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(actionStore.currentCategory)
                .font(.system(size: 20, weight: .bold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            
            HStack(spacing: 6) {
                ForEach(actionStore.quickActions, id: \.self) { item in
                    Button {
                        actionStore.requestSetAction(item)
                    } label: {
                        Text(item.prefix(2))
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Button {
                actionStore.requestNextAction()
            } label: {
                Text("下一个")
                    .font(.system(size: 12, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.15)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
    }
}
#endif
