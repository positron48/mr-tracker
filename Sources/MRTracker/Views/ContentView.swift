import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var context
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow

    @Query(sort: \MergeRequest.sortOrder) private var allMRs: [MergeRequest]
    @Query(sort: \TaskGroup.sortOrder) private var groups: [TaskGroup]

    @State private var showNewGroup = false
    @State private var newGroupName = ""

    /// Активные MR без группы.
    private var ungroupedActive: [MergeRequest] {
        MRChainSorter.sorted(allMRs.filter { !$0.isArchived && $0.group == nil })
    }

    /// Группы, в которых есть активные MR.
    private var activeGroups: [TaskGroup] {
        groups.filter { !$0.isArchived && !$0.activeMRs.isEmpty }
    }

    private var archived: [MergeRequest] {
        allMRs.filter { $0.isArchived && $0.group?.isArchived != true }
            .sorted { ($0.gitlabUpdatedAt ?? $0.createdAt) > ($1.gitlabUpdatedAt ?? $1.createdAt) }
    }

    private var archivedGroups: [TaskGroup] {
        groups.filter(\.isArchived)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                AddMRBar()
                    .padding(.horizontal, 14)
                RefreshProgressBar(progress: app.refreshProgress)
                    .opacity(app.isRefreshing ? 1 : 0)
                    .frame(height: app.isRefreshing ? 14 : 0)
            }
            .padding(.top, 14)
            .padding(.bottom, 8)
            .background(.background)
            .zIndex(1)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let err = app.lastError {
                        Label(err, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(8)
                            .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    }

                    if allMRs.isEmpty {
                        emptyState
                    } else {
                        ForEach(activeGroups) { group in
                            GroupSectionView(group: group, allGroups: groups)
                        }
                        MRChainListView(mergeRequests: ungroupedActive, groups: groups.filter { !$0.isArchived })
                        if !archived.isEmpty || !archivedGroups.isEmpty {
                            ArchiveSection(archived: archived, archivedGroups: archivedGroups, allGroups: groups.filter { !$0.isArchived })
                                .padding(.top, 4)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .navigationTitle("MR Tracker")
        .overlay(alignment: .bottom) {
            if let toast = app.toast {
                Label(toast, systemImage: "checkmark.circle.fill")
                    .font(.callout)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
                    .overlay(Capsule().strokeBorder(.green.opacity(0.4)))
                    .shadow(radius: 6, y: 2)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.25), value: app.toast)
        .toolbar { toolbarContent }
        .alert("Новая группа", isPresented: $showNewGroup) {
            TextField("Название задачи", text: $newGroupName)
            Button("Создать") { createGroup() }
            Button("Отмена", role: .cancel) {}
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                showNewGroup = true
                newGroupName = ""
            } label: {
                Label("Группа", systemImage: "plus.rectangle.on.rectangle")
            }
            Button {
                openWindow(id: "folders")
            } label: {
                Label("Папки", systemImage: "folder")
            }
            Button {
                Task { await app.refreshAll(context: context) }
            } label: {
                Label("Обновить", systemImage: "arrow.clockwise")
            }
            .disabled(app.isRefreshing)
            Button {
                openSettings()
            } label: {
                Label("Настройки", systemImage: "gearshape")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Пока нет MR")
                .font(.headline)
            Text("Вставьте ссылку на merge request выше и нажмите Enter.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func createGroup() {
        let name = newGroupName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let maxOrder = groups.map(\.sortOrder).max() ?? 0
        let g = TaskGroup(name: name, sortOrder: maxOrder + 1)
        context.insert(g)
        try? context.save()
    }
}

private struct RefreshProgressBar: View {
    let progress: (done: Int, total: Int)

    private var fraction: Double {
        guard progress.total > 0 else { return 0 }
        return min(max(Double(progress.done) / Double(progress.total), 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            let total = max(progress.total, 1)
            let width = proxy.size.width

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                    .frame(height: 5)
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: width * fraction, height: 5)
                    .animation(.easeInOut(duration: 0.22), value: fraction)
                ForEach(0...total, id: \.self) { tick in
                    Rectangle()
                        .fill(tick <= progress.done ? Color.white.opacity(0.8) : Color.secondary.opacity(0.35))
                        .frame(width: 1, height: tick == 0 || tick == total ? 9 : 7)
                        .offset(x: tickOffset(tick: tick, total: total, width: width))
                }
            }
            .frame(maxHeight: .infinity)
        }
        .accessibilityLabel("Прогресс обновления")
        .accessibilityValue("\(progress.done) из \(progress.total)")
    }

    private func tickOffset(tick: Int, total: Int, width: CGFloat) -> CGFloat {
        guard total > 0 else { return 0 }
        return (width * CGFloat(tick) / CGFloat(total)) - 0.5
    }
}
