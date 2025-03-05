import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    let context = PersistenceController.shared.container.viewContext
    
    // Vérifie si un Pokémon est dans les favoris
    func isFavorite(_ pokemon: Pokemon) -> Bool {
        let fetchRequest: NSFetchRequest<PokemonEntity> = PokemonEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", pokemon.id)
        
        do {
            let result = try context.fetch(fetchRequest)
            return result.first?.isFavorite ?? false
        } catch {
            print("Erreur lors de la vérification des favoris : \(error)")
            return false
        }
    }
    
    // Ajoute ou met à jour un Pokémon comme favori
    func addToFavorites(_ pokemon: Pokemon, context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<PokemonEntity> = PokemonEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", pokemon.id)
        
        do {
            let result = try context.fetch(fetchRequest)
            
            if let pokemonEntity = result.first {
                pokemonEntity.isFavorite = true
            } else {
                let pokemonEntity = PokemonEntity(context: context)
                pokemonEntity.id = Int64(pokemon.id)
                pokemonEntity.name = pokemon.name
                pokemonEntity.imageUrl = pokemon.imageUrl
                pokemonEntity.types = encodeTypes(pokemon.types)
                pokemonEntity.stats = encodeStats(pokemon.stats)
                pokemonEntity.isFavorite = true
            }
            
            try context.save()
            print("Pokémon ajouté aux favoris.")
        } catch {
            print("Erreur lors de l'ajout aux favoris : \(error)")
        }
    }
    
    // Retirer des favoris (sans supprimer du stockage)
    func removeFromFavorites(_ pokemon: Pokemon, context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<PokemonEntity> = PokemonEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", pokemon.id)
        
        do {
            let result = try context.fetch(fetchRequest)
            if let pokemonEntity = result.first {
                pokemonEntity.isFavorite = false
                try context.save()
                print("Pokémon retiré des favoris.")
            }
        } catch {
            print("Erreur lors du retrait des favoris : \(error)")
        }
    }
    
    // Charger tous les Pokémon stockés
    func loadPokemons(onlyFavorites: Bool = false) -> [Pokemon] {
        let fetchRequest: NSFetchRequest<PokemonEntity> = PokemonEntity.fetchRequest()

        if onlyFavorites {
            fetchRequest.predicate = NSPredicate(format: "isFavorite == %@", NSNumber(value: true))
        }

        do {
            let pokemonEntities = try context.fetch(fetchRequest)
            return pokemonEntities.map { entity in
                guard let name = entity.name,
                      let imageUrl = entity.imageUrl,
                      let typesData = entity.types,
                      let statsData = entity.stats,
                      let typesDecoded = Data(base64Encoded: typesData),
                      let statsDecoded = Data(base64Encoded: statsData),
                      let types = try? JSONDecoder().decode([String].self, from: typesDecoded),
                      let stats = try? JSONDecoder().decode([String: Int].self, from: statsDecoded)
                else {
                    print("⚠️ Erreur: Impossible de charger un Pokémon (données corrompues ou incomplètes), retour d'un Pokémon debug")
                    return Pokemon(id: -1, name: "DebugMon", imageUrl: "https://example.com/debug.png", types: ["Unknown"], stats: ["attack": 0, "defense": 0])
                }

                return Pokemon(id: Int(entity.id), name: name, imageUrl: imageUrl, types: types, stats: stats)
            }
        } catch {
            print("Erreur lors du chargement des Pokémon depuis CoreData : \(error)")
            return [
                Pokemon(id: -1, name: "DebugMon", imageUrl: "https://example.com/debug.png", types: ["Unknown"], stats: ["attack": 0, "defense": 0])
            ]
        }
    }

    
    func savePokemons(_ pokemons: [Pokemon]) {
        for pokemon in pokemons {
            let fetchRequest: NSFetchRequest<PokemonEntity> = PokemonEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %d", pokemon.id)
            
            do {
                let result = try context.fetch(fetchRequest)
                if let pokemonEntity = result.first {
                    // Mise à jour des valeurs si le Pokémon existe déjà
                    pokemonEntity.name = pokemon.name
                    pokemonEntity.imageUrl = pokemon.imageUrl
                    pokemonEntity.types = encodeTypes(pokemon.types)
                    pokemonEntity.stats = encodeStats(pokemon.stats)
                } else {
                    // Création d'un nouveau Pokémon si il n'existe pas encore
                    let pokemonEntity = PokemonEntity(context: context)
                    pokemonEntity.id = Int64(pokemon.id)
                    pokemonEntity.name = pokemon.name
                    pokemonEntity.imageUrl = pokemon.imageUrl
                    pokemonEntity.types = encodeTypes(pokemon.types)
                    pokemonEntity.stats = encodeStats(pokemon.stats)
                    pokemonEntity.isFavorite = false // Par défaut non favori
                }
            } catch {
                print("❌ Erreur lors de l'enregistrement des Pokémon : \(error)")
            }
        }
        
        do {
            try context.save()
            print("✅ Pokémon enregistrés dans CoreData")
        } catch {
            print("❌ Erreur lors de la sauvegarde de CoreData : \(error)")
        }
    }

    
    // Supprime tous les Pokémon stockés (utile pour reset)
    func deleteAllPokemons(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = PokemonEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            print("Tous les Pokémon ont été supprimés de CoreData.")
        } catch {
            print("Erreur lors de la suppression des Pokémon : \(error)")
        }
    }
    
    // Encoder les types
    private func encodeTypes(_ types: [String]) -> String? {
        if let data = try? JSONEncoder().encode(types) {
            return data.base64EncodedString()
        }
        return nil
    }
    
    // Encoder les stats
    private func encodeStats(_ stats: [String: Int]) -> String? {
        if let data = try? JSONEncoder().encode(stats) {
            return data.base64EncodedString()
        }
        return nil
    }
}
