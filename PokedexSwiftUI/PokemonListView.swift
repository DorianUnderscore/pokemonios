import SwiftUI

struct PokemonListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var pokemons: [Pokemon] = []
    @State private var selectedPokemon: Pokemon? // Pokémon sélectionné
    @State private var searchQuery: String = "" // Texte de recherche
    @State private var selectedType: String = "All" // Type de Pokémon sélectionné
    @State private var sortOption: SortOption = .name // Critère de tri sélectionné
    @State private var isDarkMode: Bool = false // Etat du mode sombre
    @Namespace private var animation // Animation pour effet visuel

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    // Barre de recherche
                    TextField("Rechercher un Pokémon", text: $searchQuery)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: searchQuery) { _ in applyFilters() }
                        .animation(.easeInOut, value: searchQuery)

                    // Picker pour filtrer par type
                    Picker("Filtrer par Type", selection: $selectedType) {
                        Text("Tous").tag("All")
                        Text("Eau").tag("Water")
                        Text("Feu").tag("Fire")
                        Text("Plante").tag("Grass")
                        Text("Électrique").tag("Electric")
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .onChange(of: selectedType) { _ in applyFilters() }
                    .animation(.spring(), value: selectedType)

                    // Picker pour trier par nom ou statistique
                    Picker("Trier par", selection: $sortOption) {
                        Text("Nom").tag(SortOption.name)
                        Text("Force").tag(SortOption.strength)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .onChange(of: sortOption) { _ in applyFilters() }
                    .animation(.spring(), value: sortOption)

                    // Liste animée des Pokémon
                    List(pokemons) { pokemon in
                        HStack {
                            AsyncImage(url: URL(string: pokemon.imageUrl)) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 50, height: 50)
                            .matchedGeometryEffect(id: pokemon.id, in: animation)

                            Text(pokemon.name.capitalized)
                                .font(.headline)

                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring()) {
                                selectedPokemon = pokemon
                            }
                        }
                    }
                    .task { loadPokemons() }
                }

                // Bouton pour changer le mode sombre
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: toggleDarkMode) {
                            Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                                .foregroundColor(isDarkMode ? .yellow : .orange)
                                .font(.system(size: 30))
                                .padding(15)
                                .background(isDarkMode ? Color.black : Color.white) // Fond coloré
                                .clipShape(Circle())
                                .shadow(radius: 10)
                        }
                        .padding(.bottom, 20) // Positionné en bas à droite
                    }
                }
            }
            .navigationTitle("") // Enlever le titre de la barre de navigation
            .preferredColorScheme(isDarkMode ? .dark : .light) // Application du mode sombre ou clair
            .toolbar {
                // Bouton Reset
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") { resetCollection() }
                }
            }
            .sheet(item: $selectedPokemon) { pokemon in
                PokemonDetailView(pokemon: pokemon)
            }
        }
    }

    // 🚀 Charge les Pokémon depuis CoreData ou API
    private func loadPokemons() {
        let cachedPokemons = CoreDataManager.shared.loadPokemons()
        pokemons = cachedPokemons
        applyFilters()
    }

    // 🔄 Filtrage + Tri dynamique
    private func applyFilters() {
        let cachedPokemons = CoreDataManager.shared.loadPokemons()

        let filteredPokemons = cachedPokemons.filter { pokemon in
            (searchQuery.isEmpty || pokemon.name.lowercased().contains(searchQuery.lowercased())) &&
            (selectedType == "All" || pokemon.types.contains { $0.lowercased() == selectedType.lowercased() })
        }

        // Applique le tri
        withAnimation {
            switch sortOption {
            case .name:
                pokemons = filteredPokemons.sorted { $0.name.lowercased() < $1.name.lowercased() }
            case .strength:
                pokemons = filteredPokemons.sorted { $0.stats["attack"] ?? 0 > $1.stats["attack"] ?? 0 }
            }
        }
    }

    // 🔥 Reset la collection Pokémon
    private func resetCollection() {
        CoreDataManager.shared.deleteAllPokemons(context: viewContext)
        Task {
            do {
                let fetchedPokemons = try await PokemonService.shared.fetchPokemons()
                pokemons = fetchedPokemons
                CoreDataManager.shared.savePokemons(fetchedPokemons)
            } catch {
                print("Erreur lors de la réinitialisation : \(error)")
            }
        }
    }

    // 🎮 Fonction pour changer le mode sombre/claire
    private func toggleDarkMode() {
        isDarkMode.toggle()
    }
}

// Enum pour le tri
enum SortOption {
    case name, strength
}
