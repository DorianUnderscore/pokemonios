import Foundation

class PokemonService {
    static let shared = PokemonService()
    
    func fetchPokemons() async throws -> [Pokemon] {
        let url = URL(string: "https://pokeapi.co/api/v2/pokemon?limit=50")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decodedResponse = try JSONDecoder().decode(PokemonListResponse.self, from: data)
        
        var pokemons: [Pokemon] = []
        
        for result in decodedResponse.results {
            if let pokemon = try await fetchPokemonDetail(from: result.url) {
                pokemons.append(pokemon)
            }
        }
        
        return pokemons
    }
    
    private func fetchPokemonDetail(from url: String) async throws -> Pokemon? {
        let url = URL(string: url)!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decodedPokemon = try JSONDecoder().decode(PokemonDetailResponse.self, from: data)
        
        return Pokemon(
            id: decodedPokemon.id,
            name: decodedPokemon.name,
            imageUrl: decodedPokemon.sprites.other.officialArtwork.front_default,
            types: decodedPokemon.types.map { $0.type.name },
            stats: Dictionary(uniqueKeysWithValues: decodedPokemon.stats.map { ($0.stat.name, $0.base_stat) })
        )
    }
}

// Modèles pour la réponse de l'API
struct PokemonListResponse: Codable {
    let results: [PokemonAPIResult]
}

struct PokemonAPIResult: Codable {
    let name: String
    let url: String
}

struct PokemonDetailResponse: Codable {
    let id: Int
    let name: String
    let sprites: Sprites
    let types: [PokemonType]
    let stats: [PokemonStat]
}

struct Sprites: Codable {
    let other: OtherSprites
}

struct OtherSprites: Codable {
    let officialArtwork: OfficialArtwork
    
    enum CodingKeys: String, CodingKey {
        case officialArtwork = "official-artwork"
    }
}

struct OfficialArtwork: Codable {
    let front_default: String
}

struct PokemonType: Codable {
    let type: TypeName
}

struct TypeName: Codable {
    let name: String
}

struct PokemonStat: Codable {
    let base_stat: Int
    let stat: StatName
}

struct StatName: Codable {
    let name: String
}
