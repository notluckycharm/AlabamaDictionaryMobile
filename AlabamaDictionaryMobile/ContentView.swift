//
//  ContentView.swift
//  AlabamaDictionaryMobile
//
//  Created by Jacob Fernandes on 5/7/24.
//

import SwiftUI

struct Sentence: Codable, Identifiable {
    let id = UUID()
    let akz: String?
    let en: String?

    enum CodingKeys: String, CodingKey {
        case akz = "alabama-example"
        case en = "english-translation"
    }
}

struct DictionaryEntry: Identifiable, Codable {
    var id: String { lemma }
    let lemma: String
    let definition: String
    let wordClass: String?
    let principalPart: String?
    let derivation: String?
    let notes: String?
    let relatedTerms: [String]?
    let audio: [String]
    let sentences: [Sentence]

    enum CodingKeys: String, CodingKey {
        case lemma, definition, wordClass = "class", principalPart, derivation, notes, relatedTerms, audio, sentences
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
        TabView{
            VStack{
                HeaderView()
                NavigationStack{
                    VStack(spacing: 0) {
                        SearchBarView(searchText: $searchText, mode: $mode, dictSort: dictSort, clearInput: clearInput)
                        ResultsNavigationView(shown: $shown, shownMax: $shownMax, updateResults: updateResults)
                        ResultsView(searchResults: $searchResults)
                    }
                }
                .padding()
                .onAppear {
                    let dictionaryData: DictionaryData = loadJSON("dict.json")
                    allEntries = dictionaryData.words
                    dictSort()
                }
            }.tabItem {
                Label("Home", systemImage: "house.fill")
            }
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle.fill")
                }
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
            return stateMachineSort(string: string, a: a, b: b)
        }
        
        shownMax = filteredEntries.count
        searchResults = Array(filteredEntries[shown..<shown+min(50,shownMax-shown)])
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
            .replacingOccurrences(of: "\u{2081}", with: "")
            .replacingOccurrences(of: "\u{2082}", with: "")
            .replacingOccurrences(of: "\u{2083}", with: "")
    }
    
    func reMatch(string: String, text: String) -> Bool {
        let re = string.replacingOccurrences(of: "C", with: "[bcdfhklɬmnpstwy]")
            .replacingOccurrences(of: "V", with: "[aeoiáóéíàòìè]")
        return text.range(of: re, options: .regularExpression) != nil
    }
    
    func stateMachineSort(string: String, a: DictionaryEntry, b: DictionaryEntry) -> Bool {
        let search = removeAccents(string.lowercased())
        let aLemma = removeAccents(a.lemma.lowercased())
        let bLemma = removeAccents(b.lemma.lowercased())
        let aDefinition = removeAccents(a.definition.lowercased())
        let bDefinition = removeAccents(b.definition.lowercased())
        
        // Prioritize exact matches (full word or definition)
        if aLemma == search || aDefinition == search { return true }
        if bLemma == search || bDefinition == search { return false }
        
        if aLemma.contains(search) || bLemma.contains(search) {
            // If both have prefix matches, compare by prefix length
            let aPrefixLength = longestCommonPrefixLength(search, aLemma)
            let bPrefixLength = longestCommonPrefixLength(search, bLemma)

            if aPrefixLength > bPrefixLength { return true }
            if bPrefixLength > aPrefixLength { return false }
            
            let aContains = isValidSubstringMatch(aLemma, search)
                let bContains = isValidSubstringMatch(bLemma, search)

                if aContains && !bContains { return true }
                if bContains && !aContains { return false }
        }
        else {
            // If both have prefix matches, compare by prefix length
            let aPrefixLength = longestCommonPrefixLength(search, aDefinition)
            let bPrefixLength = longestCommonPrefixLength(search, bDefinition)

            if aPrefixLength > bPrefixLength { return true }
            if bPrefixLength > aPrefixLength { return false }
            
            let aContains = isValidSubstringMatch(aDefinition, search)
                let bContains = isValidSubstringMatch(bDefinition, search)

                if aContains && !bContains { return true }
                if bContains && !aContains { return false }
        }

    // Substring matches: Only apply if no prefixes are found

        // Final fallback: lexicographical order
        return aLemma.localizedStandardCompare(bLemma) == .orderedAscending
    }

    func isValidSubstringMatch(_ lemma: String, _ search: String) -> Bool {
        let regex = "\\b\(NSRegularExpression.escapedPattern(for: search))\\b"
        let matches = lemma.range(of: regex, options: .regularExpression)
        return matches != nil
    }
    
    // Helper function to compute the length of the longest common prefix
    func longestCommonPrefixLength(_ s1: String, _ s2: String) -> Int {
        let minLength = min(s1.count, s2.count)
        for i in 0..<minLength {
            if s1[s1.index(s1.startIndex, offsetBy: i)] != s2[s2.index(s2.startIndex, offsetBy: i)] {
                return i
            }
        }
        return minLength
    }
}

struct HeaderView: View {
    var body: some View {
        VStack(){
            HStack(alignment: .center, spacing: 16) {
                Image("Alabama-Coushata")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                Text("Alabama Dictionary")
                    .font(.system(size: 25, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.vertical)
            }
        }
        .padding(.top, 0)
    }
}

struct LimitView: View{
    var body: some View {
        HStack(){
            Spacer()
            Text("Limit results to: ")
            Spacer()
        }.padding()
    }
}

struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var mode: String
    var dictSort: () -> Void
    var clearInput: () -> Void
    let characters = ["ɬ", "á", "à", "ó", "ò", "í", "ì", "ⁿ"]
    var body: some View {
        VStack(spacing: 0){
            HStack(spacing: -10) {
                ZStack {
                    TextField("Search in Alabama or English", text: $searchText, onEditingChanged: { _ in dictSort() })
                        .frame(height: 48)
                        .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
                                        .cornerRadius(5)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(lineWidth: 1.0)
                                        )
                        .padding()
                        .font(Font.system(size:20))
                        .overlay(
                            HStack {
                                Spacer()
                                if !searchText.isEmpty {
                                    Button(action: clearInput) {
                                        Image(systemName: "xmark.circle")
                                            .foregroundColor(.gray)
                                            .padding(.trailing, 25)
                                    }
                                }
                            }
                        )
                }
                Button(action: { useRE() }) {
                    Text("[.*]")
                        .padding()
                        .background(mode == "default" ? Color.white : Color.blue)
                        .foregroundStyle(mode == "default" ? Color.blue : Color.white)
                        .cornerRadius(10)
                }
            }
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

    func useRE() {
        if mode == "default" {
            mode = "re"
        } else {
            mode = "default"
        }
        if searchText != "" {
            dictSort()
        }
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
            Text("\(shown) - \(shown + min(50, shownMax - shown)) Results Shown out of \(shownMax)")
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
                                // Use NavigationLink to make the lemma clickable
                                NavigationLink(destination: EditorView(entry: entry)) {
                                    Text(entry.lemma)
                                            .font(.headline)
                                            .textSelection(.enabled)
                                }
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
                                let labels = ["second person singular", "first person plural", "second person plural"]

                                ForEach(parts.indices, id: \.self) { index in
                                    if index < labels.count {
                                        HStack {
                                            Text(parts[index]).textSelection(.enabled)
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


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


#Preview {
    ContentView()
}
