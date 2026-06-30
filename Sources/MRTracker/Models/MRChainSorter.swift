import Foundation
import SwiftData

enum MRChainSorter {
    static func sorted(_ mergeRequests: [MergeRequest]) -> [MergeRequest] {
        let unique = Array(Dictionary(grouping: mergeRequests, by: \.persistentModelID).compactMap { $0.value.first })
        let sourceToMRs = Dictionary(grouping: unique.filter { !$0.sourceBranch.isEmpty }, by: \.sourceBranch)
        let ids = Set(unique.map(\.persistentModelID))

        var predecessorByID: [PersistentIdentifier: MergeRequest] = [:]
        var hasSuccessorIDs = Set<PersistentIdentifier>()

        for mr in unique where !mr.targetBranch.isEmpty {
            guard let successor = sourceToMRs[mr.targetBranch]?.sorted(by: baseSort).first else { continue }
            guard successor.persistentModelID != mr.persistentModelID else { continue }
            predecessorByID[successor.persistentModelID] = mr
            hasSuccessorIDs.insert(mr.persistentModelID)
        }

        let roots = unique
            .filter { !hasSuccessorIDs.contains($0.persistentModelID) }
            .sorted(by: baseSort)

        var result: [MergeRequest] = []
        var visited = Set<PersistentIdentifier>()

        for root in roots {
            appendChain(from: root, predecessorByID: predecessorByID, ids: ids, visited: &visited, result: &result)
        }

        for mr in unique.sorted(by: baseSort) where !visited.contains(mr.persistentModelID) {
            appendChain(from: mr, predecessorByID: predecessorByID, ids: ids, visited: &visited, result: &result)
        }

        return result
    }

    private static func appendChain(
        from root: MergeRequest,
        predecessorByID: [PersistentIdentifier: MergeRequest],
        ids: Set<PersistentIdentifier>,
        visited: inout Set<PersistentIdentifier>,
        result: inout [MergeRequest]
    ) {
        var chain: [MergeRequest] = []
        var current: MergeRequest? = root
        var localVisited = Set<PersistentIdentifier>()

        while let mr = current {
            let id = mr.persistentModelID
            guard ids.contains(id), !visited.contains(id), !localVisited.contains(id) else { break }
            localVisited.insert(id)
            chain.append(mr)
            current = predecessorByID[id]
        }

        for mr in chain {
            visited.insert(mr.persistentModelID)
            result.append(mr)
        }
    }

    private static func baseSort(_ lhs: MergeRequest, _ rhs: MergeRequest) -> Bool {
        let lhsDate = lhs.gitlabUpdatedAt ?? lhs.createdAt
        let rhsDate = rhs.gitlabUpdatedAt ?? rhs.createdAt
        if lhsDate != rhsDate { return lhsDate > rhsDate }
        return lhs.sortOrder > rhs.sortOrder
    }
}
