//
//  ContentView.swift
//  AlabamaDictionaryMobile
//
//  Created by Jacob Fernandes on 5/7/24.
//

import SwiftUI

struct DictionaryEntry: Identifiable, Codable {
    var id: String { lemma }
    let lemma: String
    let definition: String
    let wordClass: String?
    let principalPart: String?
    let derivation: String?
    let notes: String?
    let relatedTerms: [String]?

    enum CodingKeys: String, CodingKey {
        case lemma, definition, wordClass = "class", principalPart, derivation, notes, relatedTerms
    }
}

struct DictionaryData: Codable {
    let words: [DictionaryEntry]
}


func loadJSON<T: Decodable>(_ filename: String, as type: T.Type = T.self) -> T {
    let data: Data

    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
    else {
        fatalError("Couldn't find \(filename) in main bundle.")
    }

    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }

    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}
struct ContentView: View {
    @State private var searchText: String = ""
    @State private var searchResults: [DictionaryEntry] = []
    @State private var shown: Int = 0
    @State private var shownMax: Int = 50
    @State private var mode: String = "default"
    @State private var allEntries: [DictionaryEntry] = []

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
            SearchBarView(searchText: $searchText, mode: $mode, dictSort: dictSort, clearInput: clearInput)
            CharacterButtonsView(searchText: $searchText, dictSort: dictSort)
            ResultsNavigationView(shown: $shown, shownMax: $shownMax, updateResults: updateResults)
            ResultsView(searchResults: $searchResults)
            FooterView()
        }
        .padding()
        .onAppear {
            let dictionaryData: DictionaryData = loadJSON("dict.json")
            allEntries = dictionaryData.words
            dictSort()
        }
    }

    func clearInput() {
        searchText = ""
        shown = 0
        searchResults.removeAll()
    }

    func dictSort() {
        let string = mode == "default" ? removeAccents(searchText.lowercased()) : searchText

        var filteredEntries: [DictionaryEntry]
        if mode == "default" {
            filteredEntries = allEntries.filter { entry in
                removeAccents(entry.lemma.lowercased()).contains(string) || entry.definition.lowercased().contains(string)
            }
        } else {
            filteredEntries = allEntries.filter { entry in
                reMatch(string: string, text: entry.lemma)
            }
        }

        filteredEntries.sort { a, b in
            stateMachineSort(string: string, a: a, b: b)
        }

        shownMax = filteredEntries.count
        searchResults = Array(filteredEntries.prefix(50))
    }

    func updateResults(count: Int) {
        if shown + count < 0 {
            shown = 0
        } else if shown + count > shownMax {
            shown = shownMax
        } else {
            shown += count
        }
        dictSort()
    }

    func removeAccents(_ string: String) -> String {
        string.replacingOccurrences(of: "à", with: "a")
            .replacingOccurrences(of: "á", with: "a")
            .replacingOccurrences(of: "ó", with: "o")
            .replacingOccurrences(of: "ò", with: "o")
            .replacingOccurrences(of: "í", with: "i")
            .replacingOccurrences(of: "ì", with: "i")
    }

    func reMatch(string: String, text: String) -> Bool {
        let re = string.replacingOccurrences(of: "C", with: "[bcdfhklɬmnpstwy]")
            .replacingOccurrences(of: "V", with: "[aeoiáóéíàòìè]")
        return text.range(of: re, options: .regularExpression) != nil
    }

    func stateMachineSort(string: String, a: DictionaryEntry, b: DictionaryEntry) -> Bool {
        let aShare = initialShare(string: string, check: removeAccents(a.lemma.lowercased())).lem
        let bShare = initialShare(string: string, check: removeAccents(b.lemma.lowercased())).lem
        if aShare > bShare { return true }
        if bShare > aShare { return false }
        if removeAccents(a.lemma.lowercased()) == string || a.definition.lowercased() == string { return true }
        if removeAccents(b.lemma.lowercased()) == string || b.definition.lowercased() == string { return false }
        return removeAccents(a.lemma.lowercased()).localizedStandardCompare(removeAccents(b.lemma.lowercased())) == .orderedAscending
    }

    func initialShare(string: String, check: String) -> (lem: Int, def: Int) {
        var lemShared = 0
        var defShared = 0
        for i in 0...string.count {
            if check.prefix(string.count - i) == string.prefix(string.count - i) {
                lemShared = string.count - i
            }
            if check.prefix(string.count - i) == string.prefix(string.count - i) {
                defShared = string.count - i
            }
        }
        return (lemShared, defShared)
    }
}


struct HeaderView: View {
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image("Alabama-Coushata")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
            Text("Alabama to English Dictionary Online")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.primary)
                .padding(.vertical)
        }
        .padding(.top, 0)
    }
}

struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var mode: String
    var dictSort: () -> Void
    var clearInput: () -> Void

    var body: some View {
        HStack(spacing: -10) {
            TextField("Search for an Alabama or English word", text: $searchText, onEditingChanged: { _ in dictSort() })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button(action: clearInput) {
                Image(systemName: "xmark.circle")
                    .padding()
            }
            Button(action: { useRE() }) {
                Text("[.*]")
                    .padding()
                    .background(mode == "default" ? Color.white : Color.blue)
                    .cornerRadius(10)
            }
        }
    }

    func useRE() {
        if mode == "default" {
            mode = "re"
        } else {
            mode = "default"
        }
    }
}


struct CharacterButtonsView: View {
    @Binding var searchText: String
    var dictSort: () -> Void

    let characters = ["ɬ", "á", "à", "ó", "ò", "í", "ì", "◌ⁿ"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(characters, id: \.self) { character in
                ZStack {
                    Button(action: {
                        searchText.append(character)
                        dictSort()
                    }) {
                        Text(character)
                            .frame(minWidth: 44, maxHeight: 44)  // Adjust the width and height as needed
                            .background(Color.blue.opacity(0.2))  // Optional: Add background color for better visibility
                            .cornerRadius(0)  // Optional: Set corner radius to 0 to avoid rounded corners
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)  // Ensure buttons take up available width
    }
}



struct ResultsNavigationView: View {
    @Binding var shown: Int
    @Binding var shownMax: Int
    var updateResults: (Int) -> Void

    var body: some View {
        HStack {
            Button(action: { updateResults(-50) }) {
                Text("<")
                    .font(.system(size: 30))
                    
            }
            .frame(height: 10.0)
            Spacer()
            Text("\(shown) - \(shown + min(50, shownMax - shown)) Results Shown out of \(shownMax)")
            Spacer()
            Button(action: { updateResults(50) }) {
                Text(">").font(.system(size: 30))
            }
        }
    }
}

struct ResultsView: View {
    @Binding var searchResults: [DictionaryEntry]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(searchResults) { entry in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(entry.lemma)
                                .font(.headline)
                            Spacer()
                            if let wordClass = entry.wordClass, wordClass != "nan" {
                                                        Text("[\(wordClass)]")
                                                    }
                        }
                        if let derivation = entry.derivation, derivation != "nan" {
                            Text(derivation)
                                .italic()
                        }
                        Text(entry.definition)
                            .font(.system(size: 16))
                        if let principalPart = entry.principalPart, principalPart != "nan" {
                            let parts = principalPart.split(separator: ", ").map { String($0) }
                            let labels = ["first person plural", "second person plural", "second person plural"]

                            ForEach(parts.indices, id: \.self) { index in
                                if index < labels.count {
                                    HStack {
                                        Text(parts[index])
                                        Spacer()
                                        Text(labels[index]).italic()
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    Divider()
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
}


struct FooterView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Divider()
            Text("Data sourced from the Dictionary of the Alabama Language by Cora Sylvestine, Heather K. Hardy, and Thomas Montler.")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


#Preview {
    ContentView()
}
