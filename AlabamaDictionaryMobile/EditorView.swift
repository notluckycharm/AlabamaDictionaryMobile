//
//  EditorView.swift
//  AlabamaDictionaryMobile
//
//  Created by Jacob Fernandes on 12/28/24.
//

import SwiftUI
import AVFoundation

struct EditorView: View {
    let entry: DictionaryEntry
    private var relatedTerms: [DictionaryEntry]
    @State private var audioPlayer: AVPlayer? = nil
    @State private var fontSize: CGFloat = 18
    @State private var showOverlay = false
    @State private var isFavorited: Bool
    
    
    init(entry: DictionaryEntry) {
            self.entry = entry
            _isFavorited = State(initialValue: FavoritesManager.shared.getFavorites().contains(where: { $0.lemma == entry.lemma }))
            self.relatedTerms = Self.loadRelatedTerms(for: entry)
        }
    
    var body: some View {
        ScrollView{
            VStack{
                HStack{
                    Text(entry.lemma)
                        .font(.system(size: fontSize + 8))
                        .bold()
                    if (entry.audio.count > 0) {
                        Button(action: { playAudio(at: entry.audio[0]) }) {
                            Image(systemName: "speaker.wave.3")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25, height: 25) // Adjust size as needed
                                .foregroundColor(.gray) // Change color as desired
                        }
                    }
                }
                VStack{
                    NegativeView(entry: entry)
                    DefinitionView(entry: entry)
                    ForEach(entry.sentences) { sentence in
                        VStack(spacing:0){
                            if let alabama = sentence.akz {
                                HStack{
                                    Text(alabama).bold()
                                    Spacer()
                                }
                            }
                            if let english = sentence.en {
                                HStack{
                                    Text(english)
                                    Spacer()
                                }
                            }
                        }.padding(.leading, 15)
                    }
                    if let notes = entry.notes, notes != "nan" {
                        HStack{
                            Text("Notes:").italic()
                            Spacer()
                        }.padding(.top, 8)
                        HStack{
                            Text("\(notes)").italic().foregroundColor(.gray)
                            Spacer()
                        }
                    }
                    InflectionView(entry: entry)
                    if !relatedTerms.isEmpty {
                        DividerWithText(text: "Related Terms").padding(.top, 10)
                        RelatedTermsView(relatedTerms: relatedTerms)
                    }
                    Spacer()
                }.environment(\.font, .system(size: fontSize))
            }
        }.toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation {
                        showOverlay.toggle()
                    }
                }) {
                    Image(systemName: "textformat.size")
                        .foregroundColor(.gray)
                }.popover(isPresented: $showOverlay, arrowEdge: .top) {
                    if #available(iOS 16.4, *) {
                        TextModifyView(fontSize: $fontSize)
                            .frame(maxWidth: 600, maxHeight: 300)
                            .presentationCompactAdaptation(.none)
                    } else {
                        // Fallback on earlier versions
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button (action: {
                    if isFavorited {
                        FavoritesManager.shared.removeFavorite(word: entry)
                    } else {
                        FavoritesManager.shared.addFavorite(word: entry)
                    }
                    isFavorited.toggle()
                }) {
                    Image(systemName: isFavorited ? "bookmark.fill" : "bookmark").foregroundColor(.gray)
                }
            }
        }
    }
    private static func loadRelatedTerms(for entry: DictionaryEntry) -> [DictionaryEntry] {
        let dictionaryData: DictionaryData = loadJSON("dict.json", as: DictionaryData.self)
        let filteredWords = dictionaryData.words.filter { word in
            word.relatedTerms.contains(entry.lemma) == true && word.lemma != entry.lemma
        }
        
        // Return only the first 5 entries
        return Array(filteredWords.prefix(5))
    }
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

}

struct DefinitionView: View {
    let entry: DictionaryEntry
    
    var body: some View {
        VStack {
            ForEach(Array(entry.definition.enumerated()), id: \.offset) { index, def in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if def.definition.prefix(3) != "to " &&
                            !entry.lemma.contains("-") &&
                            !def.definition.contains("Var") &&
                            !def.definition.contains("Negative form") {
                            Text("(Noun)").italic().foregroundColor(.cyan)
                        } else {
                            if def.wordClass != "nan" {
                                Text("[\(def.wordClass)]").italic().foregroundColor(.cyan)
                            } else if def.definition.prefix(3) == "to " {
                                Text("(Verb)").italic().foregroundColor(.cyan)
                            }
                        }
                        Spacer()
                    }
                    HStack {
                        Text("\(index + 1).") // Display the counter
                            .bold()
                        Text(def.definition) // Display the definition
                        Spacer()
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}


struct NegativeView: View {
    let entry: DictionaryEntry

    var mappedDefs: [Bool] {
        entry.definition.map { def in
            def.definition.prefix(3) == "to"
        }.filter { $0 }
    }

    var negatives: [DictionaryEntry] {
        let dictionaryData: DictionaryData = loadJSON("dict.json")
        return dictionaryData.words.filter { word in
            word.definition.contains(where: { $0.definition == "Negative form of \(entry.lemma)" })
        }
    }

    var body: some View {
        if !mappedDefs.isEmpty {
            HStack {
                Text("Negative: ").italic()
                if !negatives.isEmpty {
                    ForEach(negatives) { negative in
                        Text("\(negative.lemma)").bold()
                        if negative != negatives.last {
                            Text(", ")
                        }
                    }
                } else {
                    Text("-")
                }
            }
        }
    }
}

struct DividerWithText: View {
    let text: String
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray) // Solid gray background
                .frame(height: 40) // Adjust height as needed
            
            HStack {
                Text(text)
                    .foregroundColor(.white) // Text color
                    .font(.headline) // Font style
                    .padding()
                Spacer()
            }
        }
    }
}

struct InflectionView: View {
    let entry: DictionaryEntry
    
    private var stem: String {
            let lemma = entry.lemma
            if entry.derivation?.contains("im-") ?? false {
                // Proper string slicing using String.Index
                let startIndex = lemma.index(lemma.startIndex, offsetBy: 2)
                let endIndex = lemma.index(lemma.endIndex, offsetBy: -1)
                return String(lemma[startIndex..<endIndex])
            }
            return lemma
        }
    
    private var appl: String {
        var appl = "m"
        if let first = stem.first, ["m", "n", "l", "y", "w"].contains(first) {
                appl = String(first)
            }
        else if let first = stem.first, ["h", "s", "ɬ"].contains(first) {
            appl = "ⁿ"
        }
        return appl
        }
    private var nounForms: [String] {
        if let first = entry.lemma.first {
            if first == "i" || first == "o" {
                let stem = String(entry.lemma.dropFirst())
                return ["cha\(stem)", "chi\(stem)", entry.lemma, "ko\(stem)", "hachi\(stem)"]
            }
            else if first == "a" {
                let stem = String(entry.lemma.dropFirst())
                return ["acha\(stem)", "achi\(stem)", entry.lemma, "ako\(stem)", "ahachi\(stem)"]
            }
        }
        return ["cha\(entry.lemma)", "chi\(entry.lemma)", entry.lemma, "ko\(entry.lemma)", "hachi\(entry.lemma)"]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if entry.principalPart != "nan" {
                DividerWithText(text: "Inflectional Stems")
                let pPs = entry.principalPart?.split(separator: ", ").map(String.init) ?? []
                let ho = ["a", "i", "o", "á", "í", "ì", "ó", "ò", "à"].contains(entry.lemma.prefix(1)) ? "oh" : "ho"
                VStack(spacing: 0) {
                    HStack {
                        Text("\(entry.lemma)li")
                        Spacer()
                        Text("First person singular").italic()
                    }
                    HStack {
                        Text(pPs.first ?? "-")
                        Spacer()
                        Text("Second person singular").italic()
                    }
                    HStack {
                        Text(entry.lemma)
                        Spacer()
                        Text("Third person singular").italic()
                    }
                    HStack {
                        Text(pPs.indices.contains(1) ? pPs[1] : "-")
                        Spacer()
                        Text("First person plural").italic()
                    }
                    HStack {
                        Text(pPs.last ?? "-")
                        Spacer()
                        Text("Second person plural").italic()
                    }
                    HStack {
                        Text("\(ho)\(entry.lemma)")
                        Spacer()
                        Text("Third person plural").italic()
                    }
                }
            } //else if entry.wordClass == "AM-p" {
//                ZStack {
//                    Rectangle()
//                        .fill(Color.gray) // Solid gray background
//                        .frame(height: 40) // Adjust height as needed
//                    
//                    HStack {
//                        Text("Possessive Forms")
//                            .foregroundColor(.white) // Text color
//                            .font(.headline) // Font style
//                    }
//                }
//                
//                VStack(spacing: 0) {
//                    let defCut = entry.definition.first?.definition
//                                    .split(separator: ",")
//                                    .map(String.init) ?? []
//                    let prefixes = ["My", "Your", "Her/his/their", "Our", "Y'all's"]
//                    let akzPrefixes = ["a", "chi", "i", "ko", "hachi"]
//                    
//                    ForEach(Array(zip(prefixes, akzPrefixes)), id: \.0) { (prefix, akzPrefix) in
//                        HStack {
//                            Text("\(akzPrefix)\(appl)\(stem)")
//                            Spacer()
//                            Text("\(prefix) \(defCut.first ?? "unknown definition")")
//                        }
//                    }
//                }
//            }
//            } else if entry.wordClass == "CHA-" && entry.definition.prefix(3) != "to " {
//                ZStack {
//                    Rectangle()
//                        .fill(Color.gray) // Solid gray background
//                        .frame(height: 40) // Adjust height as needed
//                    
//                    HStack {
//                        Text("Possessive Forms")
//                            .foregroundColor(.white) // Text color
//                            .font(.headline) // Font style
//                    }
//                }
//                
//                VStack(spacing: 0) {
//                    let defCut = entry.definition
//                        .split(separator: ",")          // Split by commas
//                        .flatMap { $0.split(separator: ";") }  // Split each resulting string by semicolons
//                        .map(String.init)
//
//                    let prefixes = ["My", "Your", "Her/his/their", "Our", "Y'all's"]
//                    ForEach(Array(zip(prefixes, nounForms)), id: \.0) { (prefix, nounForm) in
//                        HStack {
//                            Text("\(nounForm)")
//                            Spacer()
//                            Text("\(prefix) \(defCut.first ?? "unknown definition")")
//                        }
//                    }
//                }
//            }
        }
    }

}


struct TextModifyView: View {
    @Binding var fontSize: CGFloat
    
    var body: some View {
        VStack(spacing:0){
            HStack(alignment: .lastTextBaseline){
                Text("Small text")
                    .font(.system(size: 12))
                    .padding(.leading, 5 )
                Spacer()
                Text("Large text")
                    .font(.system(size: 30))
                    .padding(.trailing, 5)
            }
            Slider(value: $fontSize, in: 12...30) {
                Text("Font Size")
            }.padding(10)
        }
    }
}

struct RelatedTermsView: View {
    let relatedTerms: [DictionaryEntry]
    
    var body: some View {
        LazyVStack{
            ForEach(relatedTerms) { entry in
                NavigationLink(destination: EditorView(entry: entry)) {
                    ResultView(entry: entry, simple: true)
                .contentShape(Rectangle())
                }.buttonStyle(PlainButtonStyle())
                Divider()
            }
        }
    }
}
