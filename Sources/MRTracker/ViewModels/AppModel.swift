import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class AppModel {
    let client = GitLabClient()

    // Состояние обновления (для тулбара).
    var isRefreshing = false
    var refreshProgress: (done: Int, total: Int) = (0, 0)
    private(set) var refreshingMRIDs: Set<PersistentIdentifier> = []
    var lastError: String?

    // Профиль/активность для экрана настроек.
    var currentUser: GitLabUser?
    var recentEvents: [GitLabEvent] = []

    // Кратковременное уведомление («Скопировано» и т.п.).
    var toast: String?
    private var toastTask: Task<Void, Never>?

    func showToast(_ message: String) {
        toast = message
        toastTask?.cancel()
        toastTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            if !Task.isCancelled { toast = nil }
        }
    }

    /// Пауза между последовательными MR-запросами — чтобы не «ддосить» GitLab.
    private let throttleNanos: UInt64 = 350_000_000

    // MARK: - Добавление MR

    enum AddResult { case added, duplicate, invalidURL }

    func addMR(from urlString: String, context: ModelContext) async -> AddResult {
        guard let parsed = MRURLParser.parse(urlString) else { return .invalidURL }

        // Дубликат по projectPath + iid.
        let existing = (try? context.fetch(FetchDescriptor<MergeRequest>()))?.first {
            $0.projectPath == parsed.projectPath && $0.iid == parsed.iid
        }
        if existing != nil { return .duplicate }

        let maxOrder = (try? context.fetch(FetchDescriptor<MergeRequest>()))?
            .map(\.sortOrder).max() ?? 0

        let mr = MergeRequest(
            urlString: urlString.trimmingCharacters(in: .whitespacesAndNewlines),
            projectPath: parsed.encodedProjectPath,
            iid: parsed.iid,
            sortOrder: maxOrder + 1
        )
        context.insert(mr)
        try? context.save()

        // Подтягиваем название/ветки в фоне.
        await syncOne(mr)
        try? context.save()
        return .added
    }

    // MARK: - Обновление

    /// Обновляет все активные MR строго последовательно с троттлингом.
    func refreshAll(context: ModelContext) async {
        guard !isRefreshing else { return }
        guard KeychainStore.hasCredentials else {
            lastError = GitLabError.notConfigured.errorDescription
            return
        }
        let active = (try? context.fetch(FetchDescriptor<MergeRequest>()))?
            .filter { !$0.isArchived } ?? []

        isRefreshing = true
        lastError = nil
        refreshProgress = (0, active.count)
        defer {
            isRefreshing = false
            refreshingMRIDs.removeAll()
        }

        for (idx, mr) in active.enumerated() {
            refreshingMRIDs.insert(mr.persistentModelID)
            await syncOne(mr)
            refreshingMRIDs.remove(mr.persistentModelID)
            refreshProgress = (idx + 1, active.count)
            try? context.save()
            if idx < active.count - 1 {
                try? await Task.sleep(nanoseconds: throttleNanos)
            }
        }
    }

    func refresh(_ mr: MergeRequest, context: ModelContext) async {
        guard !refreshingMRIDs.contains(mr.persistentModelID) else { return }
        guard KeychainStore.hasCredentials else {
            lastError = GitLabError.notConfigured.errorDescription
            return
        }

        lastError = nil
        refreshingMRIDs.insert(mr.persistentModelID)
        defer { refreshingMRIDs.remove(mr.persistentModelID) }

        await syncOne(mr)
        try? context.save()
    }

    func refresh(_ group: TaskGroup, context: ModelContext) async {
        guard !isRefreshing else { return }
        let active = group.activeMRs
        guard !active.isEmpty else { return }
        guard KeychainStore.hasCredentials else {
            lastError = GitLabError.notConfigured.errorDescription
            return
        }

        isRefreshing = true
        lastError = nil
        refreshProgress = (0, active.count)
        defer {
            isRefreshing = false
            refreshingMRIDs.removeAll()
        }

        for (idx, mr) in active.enumerated() {
            refreshingMRIDs.insert(mr.persistentModelID)
            await syncOne(mr)
            refreshingMRIDs.remove(mr.persistentModelID)
            refreshProgress = (idx + 1, active.count)
            try? context.save()
            if idx < active.count - 1 {
                try? await Task.sleep(nanoseconds: throttleNanos)
            }
        }
    }

    func isRefreshing(_ mr: MergeRequest) -> Bool {
        refreshingMRIDs.contains(mr.persistentModelID)
    }

    /// Тянет снимок одного MR и применяет к модели с учётом «залипания» отмены.
    private func syncOne(_ mr: MergeRequest) async {
        do {
            let snap = try await client.fetchSnapshot(
                encodedProjectPath: mr.projectPath, iid: mr.iid
            )
            apply(snapshot: snap, to: mr)
            mr.lastSyncedAt = .now
        } catch {
            lastError = (error as? LocalizedError)?.errorDescription
                ?? error.localizedDescription
        }
    }

    /// Применение снимка с авто-переходами статуса.
    private func apply(snapshot snap: MRSnapshot, to mr: MergeRequest) {
        mr.title = snap.title
        mr.sourceBranch = snap.sourceBranch
        mr.targetBranch = snap.targetBranch
        mr.gitlabState = snap.state
        mr.approved = snap.approved
        mr.ciStatus = snap.ciStatus
        mr.unresolvedCount = snap.unresolvedCount
        mr.gitlabUpdatedAt = snap.updatedAt

        // Залипание ручной отмены: статус не трогаем.
        guard !(mr.manuallyOverridden && mr.status == .cancelled) else { return }

        // Авто-переходы по состоянию GitLab.
        if snap.state == "merged" {
            mr.status = .onProd
        } else if snap.approved, mr.status == .created || mr.status == .inReview {
            mr.status = .approved
        }
    }

    /// Ручная установка статуса. Отмена помечается «залипшей».
    func setStatus(_ status: MRStatus, for mr: MergeRequest, context: ModelContext) {
        mr.status = status
        mr.manuallyOverridden = (status == .cancelled)
        try? context.save()
    }

    // MARK: - Профиль / активность

    func loadProfile() async {
        guard KeychainStore.hasCredentials else { return }
        do {
            currentUser = try await client.fetchCurrentUser()
            try? await Task.sleep(nanoseconds: throttleNanos)
            recentEvents = try await client.fetchRecentEvents()
        } catch {
            lastError = (error as? LocalizedError)?.errorDescription
                ?? error.localizedDescription
        }
    }
}
