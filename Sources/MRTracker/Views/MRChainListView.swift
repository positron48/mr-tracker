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

                MRRowView(
                    mr: mr,
                    groups: groups,
                    chainToPrevious: hasLinkToPrevious(index),
                    chainToNext: hasLinkToNext(index)
                )
            }
        }
    }

    private func hasLinkToPrevious(_ index: Int) -> Bool {
        guard index > 0 else { return false }
        return MRChainSorter.direction(from: sortedMRs[index - 1], to: sortedMRs[index]) != nil
    }

    private func hasLinkToNext(_ index: Int) -> Bool {
        guard index < sortedMRs.count - 1 else { return false }
        return MRChainSorter.direction(from: sortedMRs[index], to: sortedMRs[index + 1]) != nil
    }
}

private struct ChainConnectorView: View {
    let direction: MRChainSorter.Direction

    var body: some View {
        HStack {
            Spacer(minLength: 0)
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.accentColor.opacity(0.62))
                    .frame(width: 2, height: 7)
                Image(systemName: direction == .up ? "arrow.up" : "arrow.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.accentColor)
                Rectangle()
                    .fill(Color.accentColor.opacity(0.62))
                    .frame(width: 2, height: 7)
            }
            .frame(width: 18)
            .padding(.trailing, 3)
        }
        .frame(height: 24)
        .allowsHitTesting(false)
    }
}
