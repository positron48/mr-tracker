import SwiftUI

/// Простой переносящийся по строкам layout для плашек/тегов.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows = layout(subviews: subviews, maxWidth: maxWidth)
        let height = rows.last.map { $0.yOffset + $0.height } ?? 0
        let width = rows.map(\.width).max() ?? 0
        rows.removeAll()
        return CGSize(width: min(width, maxWidth), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let rows = layout(subviews: subviews, maxWidth: bounds.width)
        for row in rows {
            for item in row.items {
                let pt = CGPoint(x: bounds.minX + item.x, y: bounds.minY + row.yOffset)
                subviews[item.index].place(
                    at: pt, anchor: .topLeading, proposal: ProposedViewSize(item.size)
                )
            }
        }
    }

    private struct Row {
        var items: [(index: Int, x: CGFloat, size: CGSize)] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
        var yOffset: CGFloat = 0
    }

    private func layout(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        var x: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, !current.items.isEmpty {
                rows.append(current)
                current = Row()
                x = 0
            }
            current.items.append((index, x, size))
            current.width = max(current.width, x + size.width)
            current.height = max(current.height, size.height)
            x += size.width + spacing
        }
        if !current.items.isEmpty { rows.append(current) }

        var y: CGFloat = 0
        for i in rows.indices {
            rows[i].yOffset = y
            y += rows[i].height + spacing
        }
        return rows
    }
}
