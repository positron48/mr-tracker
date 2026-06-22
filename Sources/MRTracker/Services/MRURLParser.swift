import Foundation

/// Разбирает ссылку на GitLab merge request.
/// Пример: https://gitlab.host/group/sub/project/-/merge_requests/123
enum MRURLParser {
    struct Parsed: Equatable {
        /// Полный путь проекта, не закодированный: "group/sub/project".
        let projectPath: String
        /// URL-encoded путь для подстановки в :id API ("group%2Fsub%2Fproject").
        let encodedProjectPath: String
        /// Номер MR (iid).
        let iid: Int
        /// Схема+хост, например "https://gitlab.host".
        let baseURL: String
    }

    static func parse(_ raw: String) -> Parsed? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme,
              let host = url.host else { return nil }

        // path вида /group/sub/project/-/merge_requests/123(/diffs|/commits|...)
        let components = url.path.split(separator: "/").map(String.init)
        guard let dashIndex = components.firstIndex(of: "-"),
              dashIndex + 2 < components.count,
              components[dashIndex + 1] == "merge_requests",
              let iid = Int(components[dashIndex + 2]) else {
            return nil
        }

        let projectParts = components[0..<dashIndex]
        guard !projectParts.isEmpty else { return nil }
        let projectPath = projectParts.joined(separator: "/")

        // Кодируем путь так, чтобы '/' стал %2F, но валидные в namespace
        // символы (-, _, .) сохранялись.
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._")
        let encoded = projectPath.addingPercentEncoding(withAllowedCharacters: allowed)
            ?? projectPath.replacingOccurrences(of: "/", with: "%2F")

        var base = "\(scheme)://\(host)"
        if let port = url.port { base += ":\(port)" }

        return Parsed(
            projectPath: projectPath,
            encodedProjectPath: encoded,
            iid: iid,
            baseURL: base
        )
    }
}
