import SwiftUI
import SwiftData

@main
struct MRTrackerApp: App {
    @State private var appModel = AppModel()

    let container: ModelContainer = {
        let schema = Schema([MergeRequest.self, TaskGroup.self, CustomLink.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Не удалось создать ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
                .frame(minWidth: 720, minHeight: 480)
        }
        .modelContainer(container)

        Settings {
            SettingsView()
                .environment(appModel)
                .modelContainer(container)
        }
    }
}
