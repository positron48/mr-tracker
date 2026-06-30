import SwiftUI
import SwiftData

/// Раскрывающаяся группа-задача со сводкой по входящим MR.
struct GroupSectionView: View {
    @Bindable var group: TaskGroup
    let allGroups: [TaskGroup]
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            if !group.collapsed {
                MRChainListView(mergeRequests: group.activeMRs, groups: allGroups.filter { !$0.isArchived })
            }
        }
        .padding(10)
        .background(Color.accentColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.accentColor.opacity(0.25))
        )
    }

    private var header: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: group.collapsed ? "chevron.right" : "chevron.down")
                    .font(.caption.bold())
                Image(systemName: "square.stack.3d.up")
                    .foregroundStyle(.tint)
                Text(group.name)
                    .font(.headline)
                summary
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .pointerStyle(.link)
            .onTapGesture {
                group.collapsed.toggle()
                try? context.save()
            }

            // Ссылки группы: плюсик первым, слева от добавленных ссылок.
            LinkChipsView(
                links: group.links.sorted { $0.createdAt < $1.createdAt },
                onAdd: addLink,
                onDelete: deleteLink
            )
            .fixedSize()

            Menu {
                Button("Переименовать") { renaming = true }
                Button("Удалить группу", role: .destructive) {
                    context.delete(group)
                    try? context.save()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .alert("Имя группы", isPresented: $renaming) {
            TextField("Название", text: $newName)
            Button("OK") {
                if !newName.isEmpty { group.name = newName; try? context.save() }
            }
            Button("Отмена", role: .cancel) {}
        }
        .onAppear { newName = group.name }
    }

    private var summary: some View {
        HStack(spacing: 6) {
            Text("\(group.activeMRs.count)/\(group.mergeRequests.count) MR")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(group.statusSummary, id: \.status) { item in
                Text("\(item.status.title): \(item.count)")
                    .font(.caption2)
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(.quaternary, in: Capsule())
            }
            if group.aggregateCI != .none {
                Image(systemName: group.aggregateCI.symbol)
                    .font(.caption2)
                    .foregroundStyle(group.aggregateCI == .failed ? .red :
                                     group.aggregateCI == .success ? .green : .orange)
            }
            if group.totalUnresolved > 0 {
                Label("\(group.totalUnresolved)", systemImage: "bubble.left")
                    .font(.caption2).foregroundStyle(.orange)
            }
        }
    }

    @State private var renaming = false
    @State private var newName = ""

    private func addLink(_ urlString: String) {
        let link = CustomLink(urlString: urlString)
        link.group = group
        context.insert(link)
        try? context.save()
    }

    private func deleteLink(_ link: CustomLink) {
        context.delete(link)
        try? context.save()
    }
}
