import SwiftUI
import SwiftData

/// Общая высота «таблеток» (плашки, плюсик, бейдж статуса) — чтобы выровнять их в строке.
enum ChipStyle {
    static let height: CGFloat = 22
}

/// Ряд плашек-ссылок с подписью по поддомену + кнопка добавления.
struct LinkChipsView: View {
    private let chipHeight = ChipStyle.height

    let links: [CustomLink]
    var onAdd: (String) -> Void
    var onDelete: (CustomLink) -> Void

    @State private var adding = false
    @State private var newURL = ""

    private var labels: [String] {
        LinkLabeler.labels(for: links.map(\.urlString))
    }

    var body: some View {
        FlowLayout(spacing: 6) {
            addControl
            ForEach(Array(links.enumerated()), id: \.element.persistentModelID) { idx, link in
                chip(label: labels[safe: idx] ?? link.baseLabel, link: link)
            }
        }
    }

    private func chip(label: String, link: CustomLink) -> some View {
        Button {
            if let url = URL(string: link.urlString) { openURL(url) }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "link")
                    .font(.system(size: 9))
                Text(label)
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(height: chipHeight)
            .padding(.horizontal, 9)
            .background(Color.accentColor.opacity(0.15), in: Capsule())
        }
        .buttonStyle(.plain)
        .pointerStyle(.link)
        .help(link.urlString)
        .contextMenu {
            Button("Открыть") {
                if let url = URL(string: link.urlString) { openURL(url) }
            }
            Button("Копировать ссылку") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(link.urlString, forType: .string)
            }
            Divider()
            Button("Удалить", role: .destructive) { onDelete(link) }
        }
    }

    @ViewBuilder
    private var addControl: some View {
        if adding {
            HStack(spacing: 4) {
                TextField("https://…", text: $newURL)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 180)
                    .onSubmit(commit)
                Button("OK", action: commit)
                Button("✕") { adding = false; newURL = "" }
                    .buttonStyle(.plain)
            }
        } else {
            Button {
                adding = true
            } label: {
                Image(systemName: "plus")
                    .font(.caption)
                    .frame(height: chipHeight)
                    .padding(.horizontal, 9)
                    .background(Color.secondary.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.plain)
            .pointerStyle(.link)
            .help("Добавить ссылку")
        }
    }

    private func commit() {
        let trimmed = newURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onAdd(trimmed)
        newURL = ""
        adding = false
    }

    @Environment(\.openURL) private var openURL
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
