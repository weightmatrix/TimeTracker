from pathlib import Path
import subprocess,tempfile,os
repo=Path(__file__).resolve().parents[1]
source=(repo/'TimeTracker/TimeTrackerApp.swift').read_text()
def method(name,next_name):
 start=source.index('    func '+name+'(')
 end=source.index('    func '+next_name+'(',start)
 return source[start:end]
start_method=source[source.index('    func start(category:'):source.index('    private func rejectRecordMutation(')]
reject=source[source.index('    private func rejectRecordMutation('):source.index('    func editRecord(')]
prepare=source[source.index('    private func prepareForRecordEdit('):source.index('    private func requestMonth(')]
code='''import Foundation
final class CloudFileManager {
 static let shared = CloudFileManager()
 var next: MonthlyRecordArchive.Loaded!
 var fails = false
 func loadMonthlyRecords(months: Set<String>?) throws -> MonthlyRecordArchive.Loaded {
  if fails { throw CocoaError(.fileReadNoSuchFile) }
  return next
 }
}
final class TransactionFixture {
 var records: [TimeRecord] = []
 var currentRecord: TimeRecord? { records.last(where: { $0.isOngoing && $0.startTime <= Date() }) }
 var loadedMonths = MonthlyRecordArchive.homeMonths()
 var requestedMonths = MonthlyRecordArchive.homeMonths()
 var latestRecordEditAt = Date()
 var isSyncingFromCloud = false, isInitialLoading = false
 var recordEditErrorMessage = ""
 var recordMutationFailure: String?
 func load() { }
 func prepare(from: Date, through: Date) -> Bool { prepareForRecordEdit(from: from, through: through) }
 let lock = NSRecursiveLock()
 var isUndoGrouping = false
 struct UndoSnapshot { let records: [TimeRecord] }
 var undoStack: [UndoSnapshot] = [], redoStack: [UndoSnapshot] = []
 var snapshots: [[TimeRecord]] = []
 func save() { snapshots.append(records) }
 func syncToAppGroup() { }
'''+method('sortAndSave','performBatchUpdate')+method('performBatchUpdate','undo')+prepare+reject+start_method+'''}
@main struct Verify {
 static func main() {
  let store = TransactionFixture(), now = Date()
  let bad = TimeRecord(category: "工作", startTime: now.addingTimeInterval(86400), endTime: .distantFuture)
  let next = TimeRecord(category: "生活", startTime: now.addingTimeInterval(-1), endTime: .distantFuture)
  store.records = [bad]
  if CommandLine.arguments.contains("--unwritable-log") {
   let accepted = store.performBatchUpdate { store.records = [next] }
   precondition(!accepted && store.snapshots.isEmpty)
   print("PASS: failed diagnostic persistence prevents discarding invalid input or publishing a transaction")
   return
  }
  store.start(category: "生活", at: next.startTime)
  precondition(store.snapshots.count == 1, "One switch published intermediate snapshots")
  precondition(store.snapshots[0].count == 1 && store.snapshots[0][0].category == "生活" && store.snapshots[0][0].startTime == next.startTime)
  store.performBatchUpdate { store.sortAndSave() }
  precondition(store.snapshots.count == 1, "No-op action saved an extra transaction")
  let older = TimeRecord(category: "工作", startTime: now.addingTimeInterval(-86400 * 100), endTime: now.addingTimeInterval(-86400 * 100 + 3600))
  CloudFileManager.shared.next = MonthlyRecordArchive.Loaded(records: [older, next], months: [], headData: Data(), editedAt: now.addingTimeInterval(-3600))
  store.performBatchUpdate {
   precondition(store.prepare(from: older.startTime, through: older.endTime))
   let index = store.records.firstIndex(where: { $0.id == older.id })!
   store.records[index].category = "生活"
   store.sortAndSave()
  }
  precondition(store.snapshots.count == 2)
  precondition(store.undoStack.last!.records.first(where: { $0.id == older.id })?.category == "工作", "Undo forgot newly loaded history")
  precondition(store.snapshots.last!.first(where: { $0.id == older.id })?.category == "生活")
  CloudFileManager.shared.fails = true
  let beforeFailure = store.records
  store.performBatchUpdate {
   precondition(!store.prepare(from: now.addingTimeInterval(-86400 * 200), through: now))
  }
  precondition(store.records == beforeFailure && store.snapshots.count == 2)
  precondition(!store.recordEditErrorMessage.isEmpty)
  CloudFileManager.shared.fails = false
  let boundaryOld = TimeRecord(category: "生活", startTime: now.addingTimeInterval(-7200), endTime: now.addingTimeInterval(-3600))
  let boundaryCurrent = TimeRecord(category: "工作", startTime: boundaryOld.endTime, endTime: .distantFuture)
  store.records = [boundaryOld, boundaryCurrent]
  let changedBoundary = now.addingTimeInterval(-1800)
  let beforePair = store.snapshots.count
  store.performBatchUpdate {
   let changedOld = TimeRecord(id: boundaryOld.id, category: boundaryOld.category, startTime: boundaryOld.startTime, endTime: changedBoundary)
   store.records = try! RecordMutationEngine.replace(records: store.records, id: boundaryOld.id, with: changedOld, now: now)
   store.sortAndSave()
   let changedCurrent = TimeRecord(id: boundaryCurrent.id, category: boundaryCurrent.category, startTime: changedBoundary, endTime: .distantFuture)
   store.records = try! RecordMutationEngine.replace(records: store.records, id: boundaryCurrent.id, with: changedCurrent, now: now)
  }
  precondition(store.snapshots.count == beforePair + 1)
  precondition(store.records.first(where: { $0.id == boundaryOld.id })?.endTime == changedBoundary)
  print("PASS: explicit paired-boundary edits validate and publish atomically without exposing intermediate overlap")
  let savedBeforeInvalid = store.snapshots.count
  let stateBeforeInvalid = store.records
  let acceptedInvalid = store.performBatchUpdate { store.records[0].endTime = Date().addingTimeInterval(86400) }
  precondition(!acceptedInvalid && store.records == stateBeforeInvalid && store.snapshots.count == savedBeforeInvalid)
  let countBeforeFutureClick = store.snapshots.count
  store.start(category: "工作", at: Date().addingTimeInterval(86400))
  precondition(store.snapshots.count == countBeforeFutureClick && !store.recordEditErrorMessage.isEmpty)
  print("PASS: future click is diagnosed and cannot write a transaction")
  print("PASS: invalid mutation is diagnosed and the complete transaction rolls back before saving")
  print("PASS: lazy edit loads history, undo preserves it, unavailable months cannot cause partial writes")
  print("PASS: production batch/save methods publish exactly one final snapshot; future ongoing is excluded")
 }
}
'''
with tempfile.TemporaryDirectory(prefix='record-transaction-') as folder:
 test=Path(folder)/'test.swift';test.write_text(code);binary=Path(folder)/'test'
 subprocess.run(['swiftc','-module-cache-path','/tmp/latest-sync-module-cache',*[str(repo/'TimeTracker'/name) for name in ['TimeRecord.swift','RecordIntegrity.swift','RecordTimeDiagnostics.swift','RecordMutationEngine.swift','LatestCloudFile.swift','MonthlyRecordArchive.swift']],str(test),'-o',str(binary)],check=True)
 env={**os.environ,'TIME_TRACKER_DIAGNOSTICS_DIR':str(Path(folder)/'diagnostics')}
 subprocess.run([str(binary)],check=True,env=env)
 blocked=Path(folder)/'blocked';blocked.write_text('not a directory')
 subprocess.run([str(binary),'--unwritable-log'],check=True,env={**env,'TIME_TRACKER_DIAGNOSTICS_DIR':str(blocked)})
