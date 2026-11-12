import SwiftUI

@main
struct LineScrollApp: App {
    @StateObject private var library = LibraryStore()
    @StateObject private var settings = ReaderSettings()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(library)
                .environmentObject(settings)
                .preferredColorScheme(settings.colorSchemePreference.colorScheme)
        }
    }
}
