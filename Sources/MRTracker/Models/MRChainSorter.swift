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

            components.append(orderedComponent(component, adjacency: adjacency))
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

        for lhsIndex in mergeRequests.indices {
            for rhsIndex in mergeRequests.indices where rhsIndex > lhsIndex {
                let lhs = mergeRequests[lhsIndex]
                let rhs = mergeRequests[rhsIndex]
                guard direction(from: lhs, to: rhs) != nil else { continue }
                adjacency[lhs.persistentModelID, default: []].append(rhs)
                adjacency[rhs.persistentModelID, default: []].append(lhs)
            }
        }

        return adjacency
    }

    private static func orderedComponent(
        _ component: [MergeRequest],
        adjacency: [PersistentIdentifier: [MergeRequest]]
    ) -> [MergeRequest] {
        guard component.count > 1 else { return component }

        let componentIDs = Set(component.map(\.persistentModelID))
        let endpoints = component.filter { mr in
            adjacency[mr.persistentModelID, default: []]
                .filter { componentIDs.contains($0.persistentModelID) }
                .count <= 1
        }
        let start = (endpoints.isEmpty ? component : endpoints).sorted(by: baseSort).first ?? component[0]

        var result: [MergeRequest] = []
        var visited = Set<PersistentIdentifier>()
        appendContinuousChain(
            from: start,
            componentIDs: componentIDs,
            adjacency: adjacency,
            visited: &visited,
            result: &result
        )

        for mr in component.sorted(by: baseSort) where !visited.contains(mr.persistentModelID) {
            appendContinuousChain(
                from: mr,
                componentIDs: componentIDs,
                adjacency: adjacency,
                visited: &visited,
                result: &result
            )
        }

        return result
    }

    private static func appendContinuousChain(
        from start: MergeRequest,
        componentIDs: Set<PersistentIdentifier>,
        adjacency: [PersistentIdentifier: [MergeRequest]],
        visited: inout Set<PersistentIdentifier>,
        result: inout [MergeRequest]
    ) {
        var current: MergeRequest? = start

        while let mr = current {
            let id = mr.persistentModelID
            guard componentIDs.contains(id), !visited.contains(id) else { break }
            visited.insert(id)
            result.append(mr)

            current = adjacency[id, default: []]
                .filter { componentIDs.contains($0.persistentModelID) && !visited.contains($0.persistentModelID) }
                .sorted(by: baseSort)
                .first
        }
    }

    private static func baseSort(_ lhs: MergeRequest, _ rhs: MergeRequest) -> Bool {
        let lhsDate = lhs.gitlabUpdatedAt ?? lhs.createdAt
        let rhsDate = rhs.gitlabUpdatedAt ?? rhs.createdAt
        if lhsDate != rhsDate { return lhsDate > rhsDate }
        return lhs.sortOrder > rhs.sortOrder
    }
}
