import Foundation

/// Формирует короткие подписи-плашки для произвольных ссылок по их поддомену.
enum LinkLabeler {
    /// Базовая подпись из URL без дедупликации.
    /// planka.lala.ru -> "planka", lala.ru -> "lala", localhost -> "localhost".
    static func baseLabel(for urlString: String) -> String {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        // URL(string:) требует схему, иначе host = nil — подставим временную.
        let candidate = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let host = URL(string: candidate)?.host, !host.isEmpty else {
            return fallbackLabel(trimmed)
        }
        let parts = host.split(separator: ".").map(String.init)
        // Первый лейбл хоста: planka.lala.ru -> planka, lala.ru -> lala.
        return parts.first ?? host
    }

    /// Применяет дедупликацию к набору ссылок одного владельца:
    /// одинаковые подписи получают суффиксы planka, planka2, planka3...
    /// Возвращает массив подписей в том же порядке, что и входные ссылки.
    static func labels(for urlStrings: [String]) -> [String] {
        var counts: [String: Int] = [:]
        return urlStrings.map { url in
            let base = baseLabel(for: url)
            let n = (counts[base] ?? 0) + 1
            counts[base] = n
            return n == 1 ? base : "\(base)\(n)"
        }
    }

    private static func fallbackLabel(_ raw: String) -> String {
        let cleaned = raw
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
        return cleaned.split(separator: "/").first.map(String.init) ?? "link"
    }
}
