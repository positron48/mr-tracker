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
                    if let direction = MRChainSorter.direction(from: upper, to: mr) {
                        ChainConnectorView(direction: direction)
                    } else {
                        Spacer()
                            .frame(height: 8)
                    }
                }

                MRRowView(mr: mr, groups: groups)
            }
        }
    }
}

private struct ChainConnectorView: View {
    let direction: MRChainSorter.Direction

    var body: some View {
        Image(systemName: direction == .up ? "arrow.up" : "arrow.down")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity)
            .frame(height: 14)
            .allowsHitTesting(false)
    }
}
