import Foundation
import SwiftData

/// Произвольная ссылка, навешенная на MR или на группу.
/// В UI выводится плашкой с поддоменом (см. LinkLabeler).
@Model
final class CustomLink {
    var urlString: String
    var createdAt: Date

    var mergeRequest: MergeRequest?
    var group: TaskGroup?

    init(urlString: String, createdAt: Date = .now) {
        self.urlString = urlString
        self.createdAt = createdAt
    }

    /// «Сырой» поддомен без учёта дедупликации (planka.lala.ru -> planka).
    var baseLabel: String {
        LinkLabeler.baseLabel(for: urlString)
    }
}
