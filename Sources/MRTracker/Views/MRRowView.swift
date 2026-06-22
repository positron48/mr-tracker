import SwiftUI
import SwiftData

struct MRRowView: View {
    @Bindable var mr: MergeRequest
    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL

    /// Доступные группы для перемещения MR.
    let groups: [TaskGroup]

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Верхняя строка: заголовок … [+ ссылки] [статус + ссылка на MR].
            HStack(alignment: .top, spacing: 8) {
                Text(mr.displayTitle)
                    .font(.headline)
                    .lineLimit(2)
                Spacer(minLength: 8)
                // Плашки-ссылки: плюсик первым, слева от добавленных ссылок.
                LinkChipsView(
                    links: mr.links.sorted { $0.createdAt < $1.createdAt },
                    onAdd: addLink,
                    onDelete: deleteLink
                )
                .fixedSize()
                VStack(alignment: .trailing, spacing: 4) {
                    statusBadge
                    Button {
                        if let url = URL(string: mr.urlString) { openURL(url) }
                    } label: {
                        Text("!\(mr.iid)")
                            .font(.caption.monospaced())
                            .foregroundStyle(Color.accentColor)
                            .underline()
                    }
                    .buttonStyle(.plain)
                    .pointerStyle(.link)
                    .help("Открыть MR в GitLab")
                    .padding(.trailing, 12)
                }
            }

            // Ветки + CI + комменты.
            HStack(spacing: 10) {
                branchView
                ciView
                if mr.unresolvedCount > 0 {
                    Label("\(mr.unresolvedCount)", systemImage: "bubble.left.and.bubble.right")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .help("Нерешённых комментариев: \(mr.unresolvedCount)")
                }
                if let updated = mr.gitlabUpdatedAt {
                    Text(updated, format: .relative(presentation: .numeric))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .help("Изменён в GitLab")
                }
            }
        }
        .padding(10)
        .background(statusColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(statusColor)
                .frame(width: 4)
                .padding(.vertical, 6)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(statusColor.opacity(0.35))
        )
        .contextMenu { contextMenu }
    }

    // MARK: - Subviews

    private var statusBadge: some View {
        Menu {
            ForEach(MRStatus.allCases) { st in
                Button {
                    app.setStatus(st, for: mr, context: context)
                } label: {
                    Label {
                        Text(st.title)
                    } icon: {
                        if mr.status == st {
                            Image(systemName: "checkmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, Self.color(for: st))
                        } else {
                            Image(systemName: "circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Self.color(for: st))
                        }
                    }
                }
            }
        } label: {
            Text(mr.status.title)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(height: ChipStyle.height)
                .padding(.horizontal, 9)
                .background(statusColor, in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(0.25)))
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
        .pointerStyle(.link)
    }

    @ViewBuilder
    private var branchView: some View {
        HStack(spacing: 3) {
            Image(systemName: "arrow.branch")
                .font(.caption2)
            if !mr.sourceBranch.isEmpty {
                branchChip(mr.sourceBranch, hint: "Ветка MR — скопировать")
            } else {
                Text("—").font(.caption.monospaced())
            }
            if let target = mr.displayTargetBranch {
                Image(systemName: "arrowtriangle.right.fill").font(.system(size: 7))
                    .foregroundStyle(.tertiary)
                branchChip(target, hint: "Целевая ветка (куда мержится) — скопировать")
                    .foregroundStyle(.primary)
            }
        }
        .foregroundStyle(.secondary)
    }

    /// Имя ветки. По клику копируется в буфер обмена с уведомлением.
    private func branchChip(_ branch: String, hint: String = "Скопировать ветку") -> some View {
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(branch, forType: .string)
            app.showToast("Скопировано: \(branch)")
        } label: {
            Text(branch)
                .font(.caption.monospaced())
        }
        .buttonStyle(.plain)
        .pointerStyle(.link)
        .help(hint)
    }

    private var ciView: some View {
        Label(mr.ciStatus.label, systemImage: mr.ciStatus.symbol)
            .font(.caption)
            .foregroundStyle(ciColor)
    }

    @ViewBuilder
    private var contextMenu: some View {
        Button("Открыть MR") {
            if let url = URL(string: mr.urlString) { openURL(url) }
        }
        Divider()
        Menu("Группа") {
            Button("Без группы") { mr.group = nil; try? context.save() }
            Divider()
            ForEach(groups) { g in
                Button(g.name) { mr.group = g; try? context.save() }
            }
        }
        Divider()
        Button("Удалить MR", role: .destructive) {
            context.delete(mr)
            try? context.save()
        }
    }

    // MARK: - Actions

    private func addLink(_ urlString: String) {
        let link = CustomLink(urlString: urlString)
        link.mergeRequest = mr
        context.insert(link)
        try? context.save()
    }

    private func deleteLink(_ link: CustomLink) {
        context.delete(link)
        try? context.save()
    }

    private var statusColor: Color { Self.color(for: mr.status) }

    static func color(for status: MRStatus) -> Color {
        switch status {
        case .created:   return .gray
        case .inReview:  return .blue
        case .approved:  return .green
        case .onProd:    return .purple
        case .cancelled: return .red
        }
    }

    private var ciColor: Color {
        switch mr.ciStatus {
        case .success:  return .green
        case .failed:   return .red
        case .running, .pending: return .orange
        default:        return .secondary
        }
    }
}
