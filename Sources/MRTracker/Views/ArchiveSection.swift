import SwiftUI
import SwiftData

/// Спойлер с готовыми (на проде) и отменёнными MR + пагинация.
struct ArchiveSection: View {
    let archived: [MergeRequest]
    let allGroups: [TaskGroup]

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
                Text("Готовые и отменённые")
                    .font(.headline)
                Text("\(archived.count)")
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
