import Foundation

// MARK: - CloudFileManager IO Skeleton

extension CloudFileManager {
    /// 原子写入（骨架）
    func writeDataAtomically(_ data: Data, to url: URL) {
        NSFileCoordinator(filePresenter: nil).coordinate(writingItemAt: url, options: .forReplacing, error: nil) { newURL in
            try? data.write(to: newURL, options: .atomic)
        }
    }

    /// 原子读取（骨架）
    func readDataAtomically(from url: URL) -> Data? {
        var result: Data?
        NSFileCoordinator(filePresenter: nil).coordinate(readingItemAt: url, options: [.withoutChanges], error: nil) { newURL in
            result = try? Data(contentsOf: newURL)
        }
        return result
    }

    /// 触发 iCloud 下载（骨架）
    func ensureUbiquitousItemDownloaded(at url: URL) {
        try? FileManager.default.startDownloadingUbiquitousItem(at: url)
    }

    /// 冲突检测入口（骨架）
    func resolveUbiquityConflictsIfNeeded(at url: URL) {
        guard let conflicts = NSFileVersion.unresolvedConflictVersionsOfItem(at: url), !conflicts.isEmpty else { return }
        let currentVersion = NSFileVersion.currentVersionOfItem(at: url)
        let allCandidates = conflicts + (currentVersion.map { [$0] } ?? [])
        let winner = allCandidates.max(by: { ($0.modificationDate ?? Date.distantPast) < ($1.modificationDate ?? Date.distantPast) })
        if let winnerURL = winner?.url, winnerURL != url, let winnerData = try? Data(contentsOf: winnerURL) {
            writeDataAtomically(winnerData, to: url)
        }
        try? NSFileVersion.removeOtherVersionsOfItem(at: url)
        conflicts.forEach { $0.isResolved = true }
    }
}
