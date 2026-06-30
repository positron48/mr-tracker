import Foundation
import SwiftData

enum MRChainSorter {
    enum Direction {
        case up
        case down
    }

    static func sorted(_ mergeRequests: [MergeRequest]) -> [MergeRequest] {
        let unique = Array(Dictionary(grouping: mergeRequests, by: \.persistentModelID).compactMap { $0.value.first })
        let adjacency = buildAdjacency(for: unique)

        var visited = Set<PersistentIdentifier>()
        var components: [[MergeRequest]] = []

        for mr in unique.sorted(by: baseSort) where !visited.contains(mr.persistentModelID) {
            var stack = [mr]
            var component: [MergeRequest] = []

            while let current = stack.popLast() {
                let id = current.persistentModelID
                guard !visited.contains(id) else { continue }
                visited.insert(id)
                component.append(current)

                for neighbor in adjacency[id, default: []] where !visited.contains(neighbor.persistentModelID) {
                    stack.append(neighbor)
                }
            }

            components.append(component.sorted(by: baseSort))
        }

        return components
            .sorted { lhs, rhs in
                guard let lhsFirst = lhs.first, let rhsFirst = rhs.first else { return lhs.count > rhs.count }
                return baseSort(lhsFirst, rhsFirst)
            }
            .flatMap { $0 }
    }

    static func direction(from upper: MergeRequest, to lower: MergeRequest) -> Direction? {
        guard !upper.sourceBranch.isEmpty || !upper.targetBranch.isEmpty else { return nil }
        guard !lower.sourceBranch.isEmpty || !lower.targetBranch.isEmpty else { return nil }
        if !lower.targetBranch.isEmpty, lower.targetBranch == upper.sourceBranch {
            return .up
        }
        if !upper.targetBranch.isEmpty, upper.targetBranch == lower.sourceBranch {
            return .down
        }
        return nil
    }

    static func isDirectChainLink(upper: MergeRequest, lower: MergeRequest) -> Bool {
        direction(from: upper, to: lower) != nil
    }

    private static func buildAdjacency(for mergeRequests: [MergeRequest]) -> [PersistentIdentifier: [MergeRequest]] {
        var adjacency: [PersistentIdentifier: [MergeRequest]] = [:]

        for lhs in mergeRequests {
            for rhs in mergeRequests where lhs.persistentModelID != rhs.persistentModelID {
                guard direction(from: lhs, to: rhs) != nil else { continue }
                adjacency[lhs.persistentModelID, default: []].append(rhs)
                adjacency[rhs.persistentModelID, default: []].append(lhs)
            }
        }

        return adjacency
    }

    private static func baseSort(_ lhs: MergeRequest, _ rhs: MergeRequest) -> Bool {
        let lhsDate = lhs.gitlabUpdatedAt ?? lhs.createdAt
        let rhsDate = rhs.gitlabUpdatedAt ?? rhs.createdAt
        if lhsDate != rhsDate { return lhsDate > rhsDate }
        return lhs.sortOrder > rhs.sortOrder
    }
}
