import Foundation

#if os(watchOS)
import SwiftUI

@main
struct TimeTrackerWatchApp: App {
    @StateObject private var actionStore = WatchActionStore()
    
    var body: some Scene {
        WindowGroup {
            WatchActionRootView()
                .environmentObject(actionStore)
        }
    }
}
#endif
