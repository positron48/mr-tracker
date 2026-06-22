import Foundation

enum GitLabError: LocalizedError {
    case notConfigured
    case badURL
    case http(Int)
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Не задан base URL или токен GitLab (см. Настройки)."
        case .badURL:        return "Некорректный URL запроса."
        case .http(let c):   return "GitLab вернул HTTP \(c)."
        case .decoding(let m): return "Ошибка разбора ответа: \(m)."
        }
    }
}

// MARK: - DTO

struct GitLabMRDetail: Decodable, Sendable {
    let title: String
    let source_branch: String
    let target_branch: String
    let state: String                 // opened / merged / closed / locked
    let user_notes_count: Int?
    let updated_at: String?
    let head_pipeline: Pipeline?

    struct Pipeline: Decodable, Sendable {
        let status: String?
    }
}

struct GitLabApprovals: Decodable, Sendable {
    let approved: Bool?
    let approved_by: [ApprovedBy]?

    struct ApprovedBy: Decodable, Sendable {
        let user: GitLabUser?
    }
}

struct GitLabUser: Decodable, Sendable {
    let username: String?
    let name: String?
    let avatar_url: String?
    let web_url: String?
}

struct GitLabDiscussion: Decodable, Sendable {
    let notes: [Note]?
    struct Note: Decodable, Sendable {
        let resolvable: Bool?
        let resolved: Bool?
    }
}

struct GitLabEvent: Decodable, Sendable {
    let action_name: String?
    let target_title: String?
    let created_at: String?
}

/// Полный снимок данных MR из GitLab (то, что нужно UI/модели).
struct MRSnapshot: Sendable {
    var title: String
    var sourceBranch: String
    var targetBranch: String
    var state: String
    var approved: Bool
    var ciStatus: CIStatus
    var unresolvedCount: Int
    var updatedAt: Date?
}

/// Парсит ISO8601-дату GitLab (с дробными секундами и без).
enum GitLabDate {
    static func parse(_ s: String?) -> Date? {
        guard let s else { return nil }
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = withFraction.date(from: s) { return d }
        return ISO8601DateFormatter().date(from: s)
    }
}

/// Сетевой клиент GitLab REST API v4. actor — сериализует доступ к конфигу.
actor GitLabClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    private var baseURL: String { KeychainStore.baseURL }
    private var token: String? { KeychainStore.loadToken() }

    // MARK: - Public API

    /// Полный снимок MR: detail + approvals + unresolved discussions.
    /// Запросы выполняются последовательно внутри этого метода.
    func fetchSnapshot(encodedProjectPath: String, iid: Int) async throws -> MRSnapshot {
        let detail: GitLabMRDetail = try await get(
            "/projects/\(encodedProjectPath)/merge_requests/\(iid)"
        )
        let approvals: GitLabApprovals = (try? await get(
            "/projects/\(encodedProjectPath)/merge_requests/\(iid)/approvals"
        )) ?? GitLabApprovals(approved: nil, approved_by: nil)
        let unresolved = try await unresolvedDiscussionsCount(
            encodedProjectPath: encodedProjectPath, iid: iid
        )

        let isApproved = approvals.approved ?? !(approvals.approved_by?.isEmpty ?? true)

        return MRSnapshot(
            title: detail.title,
            sourceBranch: detail.source_branch,
            targetBranch: detail.target_branch,
            state: detail.state,
            approved: isApproved,
            ciStatus: CIStatus(gitlab: detail.head_pipeline?.status),
            unresolvedCount: unresolved,
            updatedAt: GitLabDate.parse(detail.updated_at)
        )
    }

    func fetchCurrentUser() async throws -> GitLabUser {
        try await get("/user")
    }

    func fetchRecentEvents(limit: Int = 15) async throws -> [GitLabEvent] {
        try await get("/events?per_page=\(limit)")
    }

    // MARK: - Discussions paging

    private func unresolvedDiscussionsCount(
        encodedProjectPath: String, iid: Int
    ) async throws -> Int {
        var page = 1
        var count = 0
        // Ограничиваем число страниц, чтобы не зациклиться на крупных MR.
        while page <= 20 {
            let discussions: [GitLabDiscussion] = try await get(
                "/projects/\(encodedProjectPath)/merge_requests/\(iid)/discussions?per_page=100&page=\(page)"
            )
            if discussions.isEmpty { break }
            for d in discussions {
                let notes = d.notes ?? []
                // Тред считается нерешённым, если есть resolvable-нота и хоть одна не resolved.
                let resolvable = notes.contains { $0.resolvable == true }
                let unresolved = notes.contains { $0.resolvable == true && $0.resolved == false }
                if resolvable && unresolved { count += 1 }
            }
            if discussions.count < 100 { break }
            page += 1
        }
        return count
    }

    // MARK: - Low level

    private func get<T: Decodable>(_ path: String) async throws -> T {
        guard !baseURL.isEmpty, let token, !token.isEmpty else {
            throw GitLabError.notConfigured
        }
        guard let url = URL(string: baseURL + "/api/v4" + path) else {
            throw GitLabError.badURL
        }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "PRIVATE-TOKEN")
        request.timeoutInterval = 20

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GitLabError.http(-1)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw GitLabError.http(http.statusCode)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw GitLabError.decoding(String(describing: error))
        }
    }
}
