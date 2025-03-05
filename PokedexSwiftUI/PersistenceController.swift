import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "PokemonDataModel") // Vérifie que le nom correspond à ton modèle
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Erreur de chargement de CoreData: \(error)")
            }
        }
    }
}
