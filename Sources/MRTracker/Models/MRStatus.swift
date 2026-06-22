import Foundation

/// Локальная статусная модель MR. Хранится в SwiftData как rawValue (String).
enum MRStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case created      // создан
    case inReview     // на ревью
    case approved     // аппрув
    case onProd       // на проде
    case cancelled    // отмена

    var id: String { rawValue }

    var title: String {
        switch self {
        case .created:   return "Создан"
        case .inReview:  return "На ревью"
        case .approved:  return "Аппрув"
        case .onProd:    return "На проде"
        case .cancelled: return "Отмена"
        }
    }

    /// MR в архиве (внизу страницы, под спойлером).
    var isArchived: Bool {
        self == .onProd || self == .cancelled
    }

    /// Порядок для сортировки активных MR (меньше — выше).
    var order: Int {
        switch self {
        case .created:   return 0
        case .inReview:  return 1
        case .approved:  return 2
        case .onProd:    return 3
        case .cancelled: return 4
        }
    }
}

/// Статус CI-пайплайна головного коммита MR.
enum CIStatus: String, Codable, Sendable {
    case success
    case failed
    case running
    case canceled
    case pending
    case skipped
    case manual
    case none

    init(gitlab raw: String?) {
        switch raw {
        case "success":             self = .success
        case "failed":              self = .failed
        case "running":             self = .running
        case "canceled":            self = .canceled
        case "pending", "created", "waiting_for_resource", "preparing", "scheduled":
            self = .pending
        case "skipped":             self = .skipped
        case "manual":              self = .manual
        default:                    self = .none
        }
    }

    var symbol: String {
        switch self {
        case .success:  return "checkmark.circle.fill"
        case .failed:   return "xmark.octagon.fill"
        case .running:  return "arrow.triangle.2.circlepath"
        case .canceled: return "minus.circle.fill"
        case .pending:  return "clock.fill"
        case .skipped:  return "forward.fill"
        case .manual:   return "hand.point.up.left.fill"
        case .none:     return "circle.dashed"
        }
    }

    var label: String {
        switch self {
        case .success:  return "CI ok"
        case .failed:   return "CI fail"
        case .running:  return "CI идёт"
        case .canceled: return "CI отменён"
        case .pending:  return "CI ждёт"
        case .skipped:  return "CI пропущен"
        case .manual:   return "CI manual"
        case .none:     return "нет CI"
        }
    }
}
