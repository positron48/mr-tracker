import Foundation
import SwiftData

/// Группа = задача, объединяющая несколько MR.
@Model
final class TaskGroup {
    var name: String
    var collapsed: Bool
    var sortOrder: Int
    var createdAt: Date

    @Relationship(deleteRule: .nullify)
    var mergeRequests: [MergeRequest]

    @Relationship(deleteRule: .cascade, inverse: \CustomLink.group)
    var links: [CustomLink]

    init(name: String, collapsed: Bool = false, sortOrder: Int = 0, createdAt: Date = .now) {
        self.name = name
        self.collapsed = collapsed
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.mergeRequests = []
        self.links = []
    }

    /// Активные MR группы (не в архиве).
    var activeMRs: [MergeRequest] {
        mergeRequests.filter { !$0.isArchived }
    }

    /// Краткая сводка по статусам MR внутри группы.
    var statusSummary: [(status: MRStatus, count: Int)] {
        let grouped = Dictionary(grouping: mergeRequests, by: { $0.status })
        return MRStatus.allCases.compactMap { st in
            guard let c = grouped[st]?.count, c > 0 else { return nil }
            return (st, c)
        }
    }

    /// Сводный CI: failed важнее running важнее success.
    var aggregateCI: CIStatus {
        let statuses = mergeRequests.map { $0.ciStatus }
        if statuses.contains(.failed) { return .failed }
        if statuses.contains(.running) { return .running }
        if statuses.contains(.pending) { return .pending }
        if !statuses.isEmpty, statuses.allSatisfy({ $0 == .success }) { return .success }
        return .none
    }

    var totalUnresolved: Int {
        mergeRequests.reduce(0) { $0 + $1.unresolvedCount }
    }
}
