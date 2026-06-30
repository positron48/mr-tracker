import Foundation
import SwiftData

@Model
final class MergeRequest {
    /// Исходная ссылка на MR.
    var urlString: String
    /// URL-encoded путь проекта для `:id` в API (например `group%2Fsub%2Fproject`).
    var projectPath: String
    /// Номер MR внутри проекта (iid).
    var iid: Int

    var title: String
    var sourceBranch: String
    var targetBranch: String

    /// Состояние MR в GitLab: opened / merged / closed / locked.
    var gitlabState: String
    var approved: Bool
    var ciStatusRaw: String
    var unresolvedCount: Int

    /// Локальный статус (rawValue MRStatus).
    var statusRaw: String
    /// true, если пользователь вручную выставил статус (отмену) — sync его не перетирает.
    var manuallyOverridden: Bool
    /// true, если MR скрыт вместе с архивной папкой без изменения рабочего статуса.
    var isManuallyArchived: Bool = false

    var createdAt: Date
    var sortOrder: Int
    /// Дата последней успешной синхронизации с GitLab.
    var lastSyncedAt: Date?
    /// Дата последнего изменения MR в GitLab (updated_at).
    var gitlabUpdatedAt: Date?

    @Relationship(deleteRule: .nullify, inverse: \TaskGroup.mergeRequests)
    var group: TaskGroup?

    @Relationship(deleteRule: .cascade, inverse: \CustomLink.mergeRequest)
    var links: [CustomLink]

    init(
        urlString: String,
        projectPath: String,
        iid: Int,
        title: String = "",
        sourceBranch: String = "",
        targetBranch: String = "",
        gitlabState: String = "opened",
        approved: Bool = false,
        ciStatusRaw: String = CIStatus.none.rawValue,
        unresolvedCount: Int = 0,
        statusRaw: String = MRStatus.created.rawValue,
        manuallyOverridden: Bool = false,
        isManuallyArchived: Bool = false,
        createdAt: Date = .now,
        sortOrder: Int = 0
    ) {
        self.urlString = urlString
        self.projectPath = projectPath
        self.iid = iid
        self.title = title
        self.sourceBranch = sourceBranch
        self.targetBranch = targetBranch
        self.gitlabState = gitlabState
        self.approved = approved
        self.ciStatusRaw = ciStatusRaw
        self.unresolvedCount = unresolvedCount
        self.statusRaw = statusRaw
        self.manuallyOverridden = manuallyOverridden
        self.isManuallyArchived = isManuallyArchived
        self.createdAt = createdAt
        self.sortOrder = sortOrder
        self.links = []
    }

    var status: MRStatus {
        get { MRStatus(rawValue: statusRaw) ?? .created }
        set { statusRaw = newValue.rawValue }
    }

    var ciStatus: CIStatus {
        get { CIStatus(rawValue: ciStatusRaw) ?? .none }
        set { ciStatusRaw = newValue.rawValue }
    }

    var isArchived: Bool { status.isArchived || isManuallyArchived || group?.isArchived == true }

    /// Показывать ли target-ветку (скрываем main/master).
    var displayTargetBranch: String? {
        let lowered = targetBranch.lowercased()
        guard !targetBranch.isEmpty, lowered != "master", lowered != "main" else { return nil }
        return targetBranch
    }

    var displayTitle: String {
        title.isEmpty ? "MR !\(iid)" : title
    }
}
