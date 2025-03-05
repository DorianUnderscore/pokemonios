import SwiftUI

@main
struct PokedexSwiftUIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate // ✅ Lien vers AppDelegate
    @State private var isDarkMode = false
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            PokemonListView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
