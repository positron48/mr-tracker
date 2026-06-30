import SwiftUI
import SwiftData

struct FolderManagerView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TaskGroup.sortOrder) private var groups: [TaskGroup]

    @State private var pendingArchiveGroup: TaskGroup?
    @State private var showArchiveWarning = false

    private var activeGroups: [TaskGroup] {
        groups.filter { !$0.isArchived }
    }

    private var archivedGroups: [TaskGroup] {
        groups.filter { $0.isArchived }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Папки")
                .font(.title2.bold())

            if groups.isEmpty {
                ContentUnavailableView("Папок нет", systemImage: "folder")
            } else {
                List {
                    Section("Активные") {
                        ForEach(activeGroups) { group in
                            folderRow(group, archived: false)
                        }
                    }
                    Section("Архив") {
                        if archivedGroups.isEmpty {
                            Text("Архив пуст")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(archivedGroups) { group in
                                folderRow(group, archived: true)
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .padding(16)
        .alert("Архивировать папку?", isPresented: $showArchiveWarning) {
            Button("Архивировать", role: .destructive) {
                if let group = pendingArchiveGroup {
                    archive(group)
                }
                pendingArchiveGroup = nil
            }
            Button("Отмена", role: .cancel) {
                pendingArchiveGroup = nil
            }
        } message: {
            Text("В папке есть неархивные MR. Если продолжить, папка и все эти MR будут скрыты.")
        }
    }

    private func folderRow(_ group: TaskGroup, archived: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: archived ? "archivebox" : "folder")
                .foregroundStyle(archived ? Color.secondary : Color.accentColor)
            TextField("Название папки", text: Bindable(group).name)
                .textFieldStyle(.plain)
                .onSubmit { try? context.save() }
            Spacer()
            Text("\(group.activeMRs.count)/\(group.mergeRequests.count) MR")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(minWidth: 64, alignment: .trailing)
            if archived {
                Button("Вернуть") {
                    restore(group)
                }
                .controlSize(.small)
            } else {
                Button("В архив") {
                    requestArchive(group)
                }
                .controlSize(.small)
            }
        }
        .padding(.vertical, 2)
    }

    private func requestArchive(_ group: TaskGroup) {
        if group.activeMRs.isEmpty {
            archive(group)
        } else {
            pendingArchiveGroup = group
            showArchiveWarning = true
        }
    }

    private func archive(_ group: TaskGroup) {
        group.isArchived = true
        for mr in group.mergeRequests where !mr.status.isArchived {
            mr.isManuallyArchived = true
        }
        try? context.save()
    }

    private func restore(_ group: TaskGroup) {
        group.isArchived = false
        for mr in group.mergeRequests {
            mr.isManuallyArchived = false
        }
        try? context.save()
    }
}
