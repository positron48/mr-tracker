import SwiftUI
import SwiftData

/// Спойлер с готовыми (на проде) и отменёнными MR + пагинация.
struct ArchiveSection: View {
    let archived: [MergeRequest]
    let archivedGroups: [TaskGroup]
    let allGroups: [TaskGroup]
    @Environment(\.modelContext) private var context

    @State private var expanded = false
    @State private var page = 0
    private let pageSize = 20

    private var pageCount: Int {
        max(1, Int(ceil(Double(archived.count) / Double(pageSize))))
    }

    private var pageItems: [MergeRequest] {
        let start = page * pageSize
        guard start < archived.count else { return [] }
        return Array(archived[start..<min(start + pageSize, archived.count)])
    }

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            VStack(spacing: 8) {
                ForEach(archivedGroups) { group in
                    archivedGroupRow(group)
                }
                ForEach(pageItems) { mr in
                    MRRowView(mr: mr, groups: allGroups)
                }
                if pageCount > 1 {
                    pager
                }
            }
            .padding(.top, 6)
        } label: {
            HStack {
                Image(systemName: "archivebox")
                Text("Архив")
                    .font(.headline)
                Text("\(archived.count + archivedGroups.count)")
                    .font(.caption)
                    .padding(.horizontal, 6).padding(.vertical, 1)
                    .background(.quaternary, in: Capsule())
            }
        }
        .padding(10)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
        .onChange(of: archived.count) { _, _ in
            if page >= pageCount { page = max(0, pageCount - 1) }
        }
    }

    private func archivedGroupRow(_ group: TaskGroup) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "folder")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.headline)
                Text("\(group.mergeRequests.count) MR")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Вернуть") {
                group.isArchived = false
                for mr in group.mergeRequests {
                    mr.isManuallyArchived = false
                }
                try? context.save()
            }
            .controlSize(.small)
        }
        .padding(10)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }

    private var pager: some View {
        HStack {
            Button {
                if page > 0 { page -= 1 }
            } label: { Image(systemName: "chevron.left") }
                .disabled(page == 0)

            Text("Стр. \(page + 1) из \(pageCount)")
                .font(.caption)
                .frame(minWidth: 110)

            Button {
                if page < pageCount - 1 { page += 1 }
            } label: { Image(systemName: "chevron.right") }
                .disabled(page >= pageCount - 1)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}
