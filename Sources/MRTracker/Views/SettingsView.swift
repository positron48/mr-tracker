import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var app

    @State private var baseURL = KeychainStore.baseURL
    @State private var token = KeychainStore.loadToken() ?? ""
    @State private var savedNote: String?

    var body: some View {
        TabView {
            connectionTab
                .tabItem { Label("Подключение", systemImage: "network") }
            profileTab
                .tabItem { Label("Профиль", systemImage: "person.crop.circle") }
        }
        .frame(width: 460, height: 420)
        .padding()
    }

    // MARK: - Подключение

    private var connectionTab: some View {
        Form {
            Section("GitLab") {
                TextField("Base URL (https://gitlab.host)", text: $baseURL)
                    .textContentType(.URL)
                SecureField("Personal Access Token", text: $token)
                Text("Токен хранится в Keychain. Нужны права api / read_api.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section {
                HStack {
                    Button("Сохранить") { save() }
                        .keyboardShortcut(.defaultAction)
                    Button("Проверить") { Task { await test() } }
                    if let note = savedNote {
                        Text(note).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Профиль / активность

    private var profileTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let user = app.currentUser {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading) {
                        Text(user.name ?? "—").font(.headline)
                        if let u = user.username { Text("@\(u)").foregroundStyle(.secondary) }
                    }
                    Spacer()
                }
            } else {
                Text("Профиль не загружен. Проверьте подключение.")
                    .foregroundStyle(.secondary)
            }

            Divider()
            Text("Недавняя активность").font(.headline)
            if app.recentEvents.isEmpty {
                Text("Нет данных").font(.caption).foregroundStyle(.secondary)
            } else {
                List(Array(app.recentEvents.enumerated()), id: \.offset) { _, ev in
                    VStack(alignment: .leading, spacing: 2) {
                        Text([ev.action_name, ev.target_title].compactMap { $0 }.joined(separator: " · "))
                            .font(.callout)
                        if let date = ev.created_at {
                            Text(date).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task { await app.loadProfile() }
    }

    private func save() {
        KeychainStore.baseURL = baseURL.trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let t = token.trimmingCharacters(in: .whitespaces)
        if t.isEmpty { KeychainStore.deleteToken() } else { KeychainStore.saveToken(t) }
        savedNote = "Сохранено"
    }

    private func test() async {
        save()
        app.currentUser = nil
        await app.loadProfile()
        savedNote = app.currentUser != nil ? "Подключение OK" : (app.lastError ?? "Не удалось")
    }
}
