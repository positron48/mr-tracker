import SwiftUI
import SwiftData

/// Поле ввода ссылки на MR. По Enter добавляет MR и подтягивает название.
struct AddMRBar: View {
    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var context

    @State private var input = ""
    @State private var busy = false
    @State private var message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Image(systemName: "link.badge.plus")
                    .foregroundStyle(.secondary)
                TextField("Вставьте ссылку на MR и нажмите Enter…", text: $input)
                    .textFieldStyle(.plain)
                    .onSubmit(submit)
                    .disabled(busy)
                if busy { ProgressView().controlSize(.small) }
            }
            .padding(8)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))

            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func submit() {
        let url = input
        guard !url.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        busy = true
        message = nil
        Task {
            let result = await app.addMR(from: url, context: context)
            switch result {
            case .added:      input = ""
            case .duplicate:  message = "Такой MR уже добавлен."
            case .invalidURL: message = "Не похоже на ссылку GitLab MR."
            }
            busy = false
        }
    }
}
