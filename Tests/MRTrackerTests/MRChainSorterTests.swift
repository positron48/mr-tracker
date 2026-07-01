import Foundation
import Testing
@testable import MRTracker

struct MRChainSorterTests {
    @Test func keepsDependentMRsContiguousNewestFirst() {
        let now = Date()

        let oldest = mr(iid: 1, source: "feature/old", target: "main", updatedAt: now.addingTimeInterval(-300), sortOrder: 1)
        let middle = mr(iid: 2, source: "feature/middle", target: "feature/old", updatedAt: now.addingTimeInterval(-200), sortOrder: 2)
        let newest = mr(iid: 3, source: "feature/new", target: "feature/middle", updatedAt: now.addingTimeInterval(-100), sortOrder: 3)
        let unrelated = mr(iid: 4, source: "feature/unrelated", target: "main", updatedAt: now, sortOrder: 4)

        let sorted = MRChainSorter.sorted([oldest, unrelated, middle, newest])

        #expect(sorted.map(\.iid) == [4, 3, 2, 1])
        #expect(MRChainSorter.direction(from: newest, to: middle) == .down)
        #expect(MRChainSorter.direction(from: middle, to: oldest) == .down)
        #expect(!MRChainSorter.isDirectChainLink(upper: unrelated, lower: newest))
    }

    @Test func doesNotBreakChainWhenMiddleMRWasUpdatedLater() {
        let now = Date()

        let oldest = mr(iid: 1, source: "feature/old", target: "main", updatedAt: now.addingTimeInterval(-300), sortOrder: 1)
        let middle = mr(iid: 2, source: "feature/middle", target: "feature/old", updatedAt: now, sortOrder: 2)
        let newest = mr(iid: 3, source: "feature/new", target: "feature/middle", updatedAt: now.addingTimeInterval(-100), sortOrder: 3)
        let unrelated = mr(iid: 4, source: "feature/unrelated", target: "main", updatedAt: now.addingTimeInterval(-50), sortOrder: 4)

        let sorted = MRChainSorter.sorted([oldest, middle, newest, unrelated])

        #expect(sorted.map(\.iid) == [4, 3, 2, 1])
    }

    private func mr(iid: Int, source: String, target: String, updatedAt: Date, sortOrder: Int) -> MergeRequest {
        let mr = MergeRequest(
            urlString: "https://gitlab.example.com/group/project/-/merge_requests/\(iid)",
            projectPath: "group%2Fproject",
            iid: iid,
            sourceBranch: source,
            targetBranch: target,
            sortOrder: sortOrder
        )
        mr.gitlabUpdatedAt = updatedAt
        return mr
    }
}
