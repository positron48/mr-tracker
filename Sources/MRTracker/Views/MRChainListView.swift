import SwiftUI

struct MRChainListView: View {
    let mergeRequests: [MergeRequest]
    let groups: [TaskGroup]

    private var sortedMRs: [MergeRequest] {
        MRChainSorter.sorted(mergeRequests)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(sortedMRs.enumerated()), id: \.element.persistentModelID) { index, mr in
                if index > 0 {
                    let upper = sortedMRs[index - 1]
                    if MRChainSorter.direction(from: upper, to: mr) == nil {
                        Spacer()
                            .frame(height: 8)
                    }
                }

                MRRowView(
                    mr: mr,
                    groups: groups,
                    chainFromPrevious: directionFromPrevious(index),
                    chainToNext: directionToNext(index)
                )
            }
        }
    }

    private func directionFromPrevious(_ index: Int) -> MRChainSorter.Direction? {
        guard index > 0 else { return nil }
        return MRChainSorter.direction(from: sortedMRs[index - 1], to: sortedMRs[index])
    }

    private func directionToNext(_ index: Int) -> MRChainSorter.Direction? {
        guard index < sortedMRs.count - 1 else { return nil }
        return MRChainSorter.direction(from: sortedMRs[index], to: sortedMRs[index + 1])
    }
}
