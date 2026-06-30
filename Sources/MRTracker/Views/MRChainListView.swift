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
                    if MRChainSorter.isDirectChainLink(upper: upper, lower: mr) {
                        ChainConnectorView(upper: upper, lower: mr)
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
    let upper: MergeRequest
    let lower: MergeRequest

    var body: some View {
        HStack(spacing: 8) {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.accentColor.opacity(0.55))
                    .frame(width: 2, height: 10)
                Image(systemName: "arrow.up")
                    .font(.caption.bold())
                    .foregroundStyle(Color.accentColor)
                Rectangle()
                    .fill(Color.accentColor.opacity(0.55))
                    .frame(width: 2, height: 10)
            }
            .frame(width: 22)

            HStack(spacing: 6) {
                Text("!\(lower.iid)")
                    .font(.caption.monospaced().bold())
                Image(systemName: "arrow.up")
                    .font(.caption2.bold())
                Text("!\(upper.iid)")
                    .font(.caption.monospaced().bold())
                Text(lower.targetBranch)
                    .font(.caption.monospaced())
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.accentColor.opacity(0.08), in: Capsule())
            .overlay(Capsule().strokeBorder(Color.accentColor.opacity(0.25)))
            .help("MR !\(lower.iid) вливается в MR !\(upper.iid) через ветку \(lower.targetBranch)")

            Spacer(minLength: 0)
        }
        .padding(.leading, 14)
        .padding(.vertical, 2)
    }
}
