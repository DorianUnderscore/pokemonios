import ConfettiSwiftUI
import SwiftUI

struct PokemonDetailView: View {
    let pokemon: Pokemon
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isFavorite: Bool = false
    @State private var isZoomed = false // 🔍 Variable pour gérer le zoom
    @Namespace private var animation

    // 🎮 Mode combat
    @State private var showBattle = false
    @State private var showBattleResult = false // Indicateur pour afficher l'écran de victoire/défaite
    @State private var battleMessage = ""
    @State private var opponent: Pokemon?
    @State private var playerHP: CGFloat = 100
    @State private var opponentHP: CGFloat = 100
    @State private var playerOffset: CGFloat = 0
    @State private var opponentOffset: CGFloat = 0
    @State private var battleInProgress = false
    @State private var triggerConfetti = 0 // 🎉 Déclencheur de confettis

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.largeTitle)
                }
                .padding()
            }

            if showBattle, let opponent = opponent {
                battleView(opponent: opponent)
            } else {
                pokemonInfoView()
            }

            if showBattleResult {
                BattleResultView(message: battleMessage,triggerConfetti: $triggerConfetti) // Affichage du résultat du combat
                // 🎉 Bouton invisible pour déclencher les confettis
                    Button(action: {
                        triggerConfetti += 1
                    }) {
                        Text("")
                            .frame(width: 1, height: 1) // Bouton invisible
                            .opacity(0.01)
                    }
            }
        }
        .padding()
        .onAppear {
            isFavorite = CoreDataManager.shared.isFavorite(pokemon)
        }
    }

    // 🟢 Vue principale avec infos du Pokémon
    private func pokemonInfoView() -> some View {
        VStack {
            Spacer()

            // 🖼️ Image animée avec zoom
            AsyncImage(url: URL(string: pokemon.imageUrl)) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 200, height: 200)
            .matchedGeometryEffect(id: "pokemonImage", in: animation)
            .scaleEffect(isZoomed ? 1.5 : 1)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isZoomed)
            .onTapGesture {
                withAnimation { isZoomed.toggle() }
            }

            // 🔹 Types du Pokémon
            HStack {
                ForEach(pokemon.types, id: \.self) { type in
                    Text(type.capitalized)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(10)
                }
            }

            // 📊 Statistiques du Pokémon
            VStack(alignment: .leading, spacing: 10) {
                ForEach(pokemon.stats.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    HStack {
                        Text("\(key.capitalized):").fontWeight(.bold)
                        Spacer()
                        Text("\(value)")
                    }
                    .padding(.horizontal)
                }
            }
            .padding()

            // ❤️ Bouton Favoris
            Button(action: toggleFavorite) {
                HStack {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? .red : .gray)
                        .animation(.spring(), value: isFavorite)
                    Text(isFavorite ? "Retirer des favoris" : "Ajouter aux favoris")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .background(isFavorite ? Color.red : Color.gray)
                        .cornerRadius(10)
                }
            }
            .padding(.top, 20)

            // ⚔️ Bouton Combat
            Button(action: startBattle) {
                Text("⚔️ Combattre un Pokémon aléatoire")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
        

            Spacer()
        }
    }

    // 🔥 Vue du combat
    private func battleView(opponent: Pokemon) -> some View {
            VStack {
                Spacer()
                pokemonBattleImage(opponent.imageUrl, hp: $opponentHP, offset: $opponentOffset, isOpponent: true)
                healthBar(health: opponentHP, name: opponent.name)

                Spacer()
                healthBar(health: playerHP, name: pokemon.name)
                pokemonBattleImage(pokemon.imageUrl, hp: $playerHP, offset: $playerOffset, isOpponent: false)

                Spacer()

                if battleInProgress {
                    ProgressView().padding()
                } else {
                    Button(action: attack) {
                        Text("⚔️ Attaquer")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(10)
                    }
                    .padding(.top, 20)
                }
            }
            .transition(.opacity)
        }

    // 🖼️ Image animée du combat
    private func pokemonBattleImage(_ url: String, hp: Binding<CGFloat>, offset: Binding<CGFloat>, isOpponent: Bool) -> some View {
        AsyncImage(url: URL(string: url)) { image in
            image.resizable().scaledToFit()
        } placeholder: {
            ProgressView()
        }
        .frame(width: 150, height: 150)
        .offset(x: offset.wrappedValue)
        .opacity(hp.wrappedValue > 0 ? 1 : 0.2)
        .animation(.easeInOut(duration: 0.3), value: offset.wrappedValue)
        .animation(.easeInOut(duration: 0.5), value: hp.wrappedValue)
    }

    // 🟢 Barre de vie des Pokémon
    private func healthBar(health: CGFloat, name: String) -> some View {
        VStack(alignment: .leading) {
            Text(name).font(.headline).padding(.leading)
            GeometryReader { geo in
                Rectangle()
                    .fill(health > 50 ? Color.green : health > 20 ? Color.orange : Color.red)
                    .frame(width: geo.size.width * (health / 100), height: 10)
                    .cornerRadius(5)
                    .animation(.easeInOut, value: health)
            }
            .frame(height: 10)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(5)
            .padding(.horizontal)
        }
    }

    // 🎮 Lancement du combat
    private func startBattle() {
        let allPokemons = CoreDataManager.shared.loadPokemons().filter { $0.id != pokemon.id }
        guard let randomOpponent = allPokemons.randomElement() else { return }

        opponent = randomOpponent
        playerHP = 100
        opponentHP = 100
        showBattle = true
        battleInProgress = false
    }

    // 🎮 Attaque
    private func attack() {
            guard let opponent = opponent else { return }

            battleInProgress = true

            withAnimation { playerOffset = 30 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation { playerOffset = 0 }
                opponentHP -= CGFloat(pokemon.stats["attack"] ?? 10)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if opponentHP <= 0 {
                    endBattle(winner: pokemon.name, hasWon: true)
                    return
                }

                withAnimation { opponentOffset = -30 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation { opponentOffset = 0 }
                    playerHP -= CGFloat(opponent.stats["attack"] ?? 10)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if playerHP <= 0 {
                            endBattle(winner: opponent.name, hasWon: false)
                        } else {
                            battleInProgress = false
                        }
                    }
                }
            }
        }
    // 🎮 Fin du combat
    private func endBattle(winner: String, hasWon: Bool) {
          battleMessage = hasWon ? "\(winner) a gagné 🎉 !" : "\(winner) vous a battu 😔"
          showBattleResult = true

          if hasWon {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                  // Simuler un "clic" sur le bouton invisible
                  triggerConfetti += 1
              }
          }
      }

    // ❤️ Toggle favori
    private func toggleFavorite() {
        if isFavorite {
            CoreDataManager.shared.removeFromFavorites(pokemon, context: viewContext)
        } else {
            CoreDataManager.shared.addToFavorites(pokemon, context: viewContext)
        }
        isFavorite.toggle()
    }
}

// 🏆 Vue de résultat de combat
struct BattleResultView: View {
    let message: String
    @Binding var triggerConfetti: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                Text(message)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(15)
                    .padding()

                Spacer()
            }
        }
        .confettiCannon(trigger: $triggerConfetti, repetitions: 3, repetitionInterval: 0.7)
    }
}
