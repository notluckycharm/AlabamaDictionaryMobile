//
//  FlashcardsView.swift
//  AlabamaDictionaryMobile
//
//  Created by Jacob Fernandes on 1/10/25.
//
import SwiftUI
struct FlashcardsView: View {
    @State private var words: [DictionaryEntry] = FavoritesManager.shared.getFavorites() // Example data source
    @State private var shuffledWords: [DictionaryEntry] = []
    @State private var deckID = UUID()
    @State private var swingDir = 0
    @State private var currentWord: DictionaryEntry? // Track the current top card
    @State private var showBack = false

    func getCurr() ->  [DictionaryEntry] {
        return shuffledWords
    }
    
    var body: some View {
        VStack {
            Group {
                if swingDir == 1 {
                    Text("I know this word.")
                        .foregroundColor(.green)
                } else if swingDir == -1 {
                    Text("I don't know this word.")
                        .foregroundColor(.red)
                } else {
                    Text(" ") // Keeps spacing consistent
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
            ZStack {
                if shuffledWords.isEmpty {
                    FlashDeckEndView(restartAction: restartDeck)
                } else {
                    ForEach(getCurr()) { word in
                        FlipCardView(
                            word: word,
                            swingDir: $swingDir,
                            shuffledWords: $shuffledWords,
                            currentWord: $currentWord,
                            showBack: $showBack
                        ).zIndex(word == currentWord ? 1 : 0)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: Constants.cardHeight)
            .id(deckID)
            .onAppear {
                restartDeck()
            }
            .zIndex(1)
            Text(" ")
                .frame(maxWidth: .infinity, alignment: .center)
            HStack {
                Button(action: {
                    // Add the current card back to the deck (marked as unknown)
                    if let word = currentWord {
                        shuffledWords.removeAll { $0.id == word.id }
                        shuffledWords.insert(word, at: 1)
                        showBack = false
                        currentWord = shuffledWords.last
                    }
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .padding()
                }
                .background(.red)
                .cornerRadius(10)
                Button(action: {
                    // Mark the card as known and remove it from the deck
                    if let word = currentWord {
                        shuffledWords.removeAll { $0.id == word.id }
                        showBack = false
                        currentWord = shuffledWords.last
                    }
                }) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .padding()
                }
                .background(.green)
                .cornerRadius(10)
            }
            .zIndex(0)
        }
    }

    func restartDeck() {
        shuffledWords = words.shuffled()
        currentWord = shuffledWords.last
        deckID = UUID()
    }
}

struct FlipCardView: View {
    let word: DictionaryEntry?
    @Binding var swingDir: Int
    @Binding var shuffledWords: [DictionaryEntry]
    @Binding var currentWord: DictionaryEntry?
    @Binding var showBack: Bool
    @State private var offset: CGSize = .zero
    @State private var isRemoved = false
    @State private var rotationAngle: Double = 0

    var body: some View {
        if let word = word {
            if !isRemoved {
                ZStack {
                    FrontCard(word: word)
                        .opacity(showBack ? 0 : 1)
                    BackCard(word: word)
                        .rotation3DEffect(Angle(degrees: 180), axis: (x: 0.0, y: 1.0, z: 0.0))
                        .opacity(showBack ? 1 : 0)
                }
                .offset(x: showBack ? -offset.width : offset.width, y: offset.height)            .rotationEffect(.degrees(Double(offset.width / 20)))
                .rotation3DEffect(
                    showBack ? Angle(degrees: 180) : .zero,
                    axis: (x: 0.0, y: 1.0, z: 0.0)
                )
                .onTapGesture {
                    // Start the flip animation
                    withAnimation(.easeInOut(duration: Constants.flipTime)) {
                        rotationAngle += 180
                        showBack.toggle()  // Now toggle the back after the animation
                    }
                }
                .gesture(DragGesture(minimumDistance: 3.0)
                    .onChanged { gesture in
                        offset = gesture.translation
                        swingDir = offset.width > 0 ? 1 : -1
                    }
                    .onEnded { _ in
                        if abs(offset.width) > 200 {
                            withAnimation{
                                isRemoved = true
                            }
                            // Remove the word and notify the parent
                            shuffledWords.removeAll { $0.id == word.id }
                            if offset.width < -200 {
                                shuffledWords.insert(word, at: 1)
                            }
                            currentWord = shuffledWords.last
                            showBack = false
                            if offset.width < -200 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    // Put your code which should be executed with a delay here
                                    offset = .zero
                                    isRemoved = false
                                }
                            }
                        } else {
                            withAnimation {
                                offset = .zero
                            }
                        }
                        swingDir = 0
                    }
                )
                .frame(maxWidth: 300, maxHeight: 400)
            }
        }
    }
}


struct FrontCard: View {
    let word: DictionaryEntry

    var body: some View {
        VStack {
            Text(word.lemma)
                .foregroundColor(.black)
                .font(.largeTitle)
                .fontWeight(.black)
        }
        .card() // Custom modifier for card appearance
    }
}

struct BackCard: View {
    let word: DictionaryEntry

    var body: some View {
        VStack {
            ForEach(Array(word.definition.enumerated()), id: \.0) { id, key in
                HStack {
                    Text("\(id + 1).") // Convert `id` to a 1-based index and append "."
                    Text(key.definition)
                        .foregroundColor(.black)
                        .font(.title2)
                        .padding()
                }.padding()
            }
        }
        .card() // Custom modifier for card appearance
    }
}

struct FlashDeckEndView: View {
    var restartAction: () -> Void // Closure to restart the deck
    
        var body: some View {
            VStack {
                Text("There are no more cards to display")
                    .foregroundColor(.black)
                Button(action: restartAction) {
                    Text("Restart Deck")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .card() // Assuming you have a card modifier for styling
        }
}
