//
//  FlashcardsView.swift
//  AlabamaDictionaryMobile
//
//  Created by Jacob Fernandes on 1/10/25.
//
import SwiftUI
import AVFoundation


struct FlashcardsView: View {
    @State private var words: [DictionaryEntry] = FavoritesManager.shared.getFavorites() // Example data source
    @State private var shuffledWords: [DictionaryEntry] = []
    @State private var deckID = UUID()
    @State private var swingDir = 0
    @State private var currentWord: DictionaryEntry? // Track the current top card
    @State private var showBack = false
    @State private var front: String = "Alabama"
    @State private var back: String = "English"
    @State private var start: Bool = false

    func getCurr() ->  [DictionaryEntry] {
        return shuffledWords
    }
    
    var body: some View {
        ZStack{
            ModeView(front: $front, back: $back, start: $start)
            if start {
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
                                    showBack: $showBack,
                                    front: front
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
                                shuffledWords.insert(word, at: 0)
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
    let front: String
    @State private var offset: CGSize = .zero
    @State private var isRemoved = false
    @State private var rotationAngle: Double = 0

    var body: some View {
        if let word = word {
            if !isRemoved {
                ZStack {
//                    if !word.audio.isEmpty {
//                        Card(word: word, type: "audio", swingDir: $swingDir, shuffledWords: $shuffledWords, currentWord: $currentWord)
//                    }
//                    else{
                    Card(word: word, type: "meaning", swingDir: $swingDir, shuffledWords: $shuffledWords, currentWord: $currentWord, front: front)
//                    }
                }
            }
        }
    }
}

struct Card: View {
    let word: DictionaryEntry?
    var type: String
    @Binding var swingDir: Int
    @Binding var shuffledWords: [DictionaryEntry]
    @Binding var currentWord: DictionaryEntry?
    let front: String
    
    @State private var showBack = false
    @State private var offset: CGSize = .zero
    @State private var isRemoved = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        if let word = word {
            Group {
                if front == "Audio" {
                    if !word.audio.isEmpty{
                        AudioCard(path: word.audio[0])
                            .opacity(showBack ? 0 : 1)
                    }
                    else {
                        FrontCard(word: word)
                            .opacity(showBack ? 0 : 1)
                    }
                    FrontCard(word: word)
                        .opacity(showBack ? 1 : 0)
                        .rotation3DEffect(Angle(degrees: 180), axis: (x: 0.0, y: 1.0, z: 0.0))
                }
                else if front == "Alabama" {
                    FrontCard(word: word)
                        .opacity(showBack ? 0 : 1)
                    BackCard(word: word)
                        .opacity(showBack ? 1 : 0)
                        .rotation3DEffect(Angle(degrees: 180), axis: (x: 0.0, y: 1.0, z: 0.0))
                }
                else {
                    BackCard(word: word)
                        .opacity(showBack ? 0 : 1)
                    FrontCard(word: word)
                        .opacity(showBack ? 1 : 0)
                        .rotation3DEffect(Angle(degrees: 180), axis: (x: 0.0, y: 1.0, z: 0.0))
                }
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
                    if abs(offset.width) > Constants.flipThreshold {
                        withAnimation{
                            isRemoved = true
                        }
                        // Remove the word and notify the parent
                        shuffledWords.removeAll { $0.id == word.id }
                        if offset.width < -1 * Constants.flipThreshold {
                            shuffledWords.insert(word, at: 0)
                        }
                        currentWord = shuffledWords.last
                        showBack = false
                        if offset.width < -Constants.flipThreshold {
                                // Put your code which should be executed with a delay here
                            offset = .zero
                            withAnimation{
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

struct AudioCard: View {
    let path: String
    @State private var audioPlayer: AVPlayer? = nil

    func playAudio(at path: String) {
        // Configure the audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
            return
        }
        
        // Find the file URL in the app bundle
        guard let filePath = Bundle.main.url(forResource: path, withExtension: "wav") else {
            print("Invalid URL for file: \(path)")
            return
        }
        
        // Create and play the AVPlayer
        audioPlayer = AVPlayer(url: filePath)
        audioPlayer?.volume = 1.0
        audioPlayer?.play()
    }
    
    var body: some View {
        VStack {
            Text("Listen:")
            Button(action: { playAudio(at: path) }) {
                Image(systemName: "speaker.wave.3.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 45, height: 45) // Adjust size as needed
                    .foregroundColor(.black) // Change color as desired
            }
        }
        .card()
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
                Text("There are no cards to display")
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

struct ModeView: View {
    @Binding var front: String
    @Binding var back: String
    @Binding var start: Bool
    @State private var frontOpts: [String] = ["Alabama", "Audio", "English"]
    @State private var backOpts: [String] = ["Alabama", "English"]
    @State private var opacity: Double = 1
    
    var body: some View {
        VStack{
            Text("Customize Flashcards")
            Group
            {
                VStack{
                    Text("Card Front")
                    HStack{
                        if front == "Alabama" {
                            ZStack{
                                Text("Alabama")
                                    .zIndex(1)
                                    .foregroundColor(Color.white)
                                RoundedRectangle(cornerRadius: 15)
                                    .frame(width: 100, height: 50)
                                    .foregroundColor(Color.blue)
                            }
                        }
                        else {
                            Button(action: {
                                withAnimation{
                                    back = "English"
                                    front = "Alabama"
                                }
                            }){
                                Text("Alabama")
                                    .padding()
                            }.buttonStyle(PlainButtonStyle())
                        }
                        if front == "Audio" {
                            ZStack{
                                Text("Audio")
                                    .zIndex(1)
                                    .foregroundColor(Color.white)
                                RoundedRectangle(cornerRadius: 15)
                                    .frame(width: 100, height: 50)
                                    .foregroundColor(Color.blue)
                            }
                        }
                        else {
                            Button(action: {
                                withAnimation{
                                    front = "Audio"
                                }
                            }){
                                Text("Audio")
                                    .padding()
                            }.buttonStyle(PlainButtonStyle())
                        }
                        if front == "English" {
                            ZStack{
                                Text("English")
                                    .zIndex(1)
                                    .foregroundColor(Color.white)
                                RoundedRectangle(cornerRadius: 15)
                                    .frame(width: 100, height: 50)
                                    .foregroundColor(Color.blue)
                            }
                        }
                        else {
                            Button(action: {
                                withAnimation{
                                    back = "Alabama"
                                    front = "English"
                                }
                            }){
                                Text("English")
                                    .padding()
                            }.buttonStyle(PlainButtonStyle())
                        }
                        
                    }.background(Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                VStack{
                    Text("Card Back")
                    HStack{
                        if back == "Alabama" {
                            ZStack{
                                Text("Alabama")
                                    .zIndex(1)
                                    .foregroundColor(Color.white)
                                RoundedRectangle(cornerRadius: 15)
                                    .frame(width: 100, height: 50)
                                    .foregroundColor(Color.blue)
                            }
                        }
                        else {
                            Button(action: {
                                withAnimation{
                                    back = "Alabama"
                                    front = "English"
                                }
                            }){
                                Text("Alabama")
                                    .padding()
                            }.buttonStyle(PlainButtonStyle())
                        }
                        if back == "English" {
                            ZStack{
                                Text("English")
                                    .zIndex(1)
                                    .foregroundColor(Color.white)
                                RoundedRectangle(cornerRadius: 15)
                                    .frame(width: 100, height: 50)
                                    .foregroundColor(Color.blue)
                            }
                        }
                        else {
                            Button(action: {
                                withAnimation{
                                    back = "English"
                                    front = "Alabama"
                                }
                            }){
                                Text("English")
                                    .padding()
                            }.buttonStyle(PlainButtonStyle())
                        }
                        
                    }.background(Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                ZStack{
                    Button(action: {
                        opacity = 0
                        start = true
                    }) {
                        Text("Start")
                    }
                    .buttonStyle(PlainButtonStyle())
                        .zIndex(1)
                        .foregroundColor(Color.white)
                    RoundedRectangle(cornerRadius: 15)
                        .frame(width: 100, height: 50)
                        .foregroundColor(Color.blue)
                }
                
            }.padding()
        }.frame(width: Constants.cardWidth+50, height: Constants.cardHeight+100)
            .background(RoundedRectangle(cornerRadius: 15).fill(.white))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 1)
            .opacity(opacity)
    }
}

//struct OptView: View {
//    let opts: [String]
//    let condition: String
//    
//    var body: some View {
//        HStack{
//                if condition.contains(opt) {
//                    ZStack{
//                        Text(opt)
//                            .foregroundColor(Color.white)
//                        RoundedRectangle(cornerRadius: 15)
//                            .frame(width: 100, height: 50)
//                            .foregroundColor(Color.blue)
//                    }
//                }
//                else {
//                    Text(opt)
//                }
//            }
//        }
//    }
//}

