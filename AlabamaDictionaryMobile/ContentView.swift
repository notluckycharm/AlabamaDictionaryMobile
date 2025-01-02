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
    @State private var reMode: Bool = false
    @State private var allEntries: [DictionaryEntry] = []
    @State var presentSideMenu: Bool = false
    @State private var limitAudio: Bool = false
    
    var body: some View {
        ZStack{
            TabView{
                VStack{
                    HeaderView()
                    NavigationStack{
                        VStack(spacing: 0) {
                            SearchBarView(searchText: $searchText, reMode: $reMode, dictSort: dictSort, clearInput: clearInput, presentSideMenu: $presentSideMenu)
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
            SettingsView(isShowing: $presentSideMenu, reMode: $reMode, limitAudio: $limitAudio)
                .zIndex(1)
        }
    }
    
    func clearInput() {
        searchText = ""
        shown = 0
        searchResults.removeAll()
    }
    
    func stripped(string: String) -> String {
        return string.replacingOccurrences(of: "#english", with: "")
                     .replacingOccurrences(of: "#en", with: "")
                     .replacingOccurrences(of: " ", with: "")
                     .replacingOccurrences(of: "#akz", with: "")
                     .replacingOccurrences(of: "#alabama", with: "")
    }
    
    func dictSort() {
        let string = !reMode ? removeAccents(searchText.lowercased()) : searchText
        
        var filteredEntries: [DictionaryEntry]
        if !reMode {
            filteredEntries = allEntries.filter { entry in
                removeAccents(stripped(string: entry.lemma.lowercased())).contains(stripped(string: string)) || stripped(string: entry.definition.lowercased()).contains(stripped(string: string))
            }
        } else {
            filteredEntries = allEntries.filter { entry in
                reMatch(string: string, text: entry.lemma)
            }
        }
        
        if limitAudio {
            filteredEntries = filteredEntries.filter { entry in
                entry.audio.count > 0
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
    
    func longestPrefixofTwoStrs(search: String, a: String, b: String) -> Bool {
        let aPrefixLength = longestCommonPrefixLength(search, a)
        let bPrefixLength = longestCommonPrefixLength(search, b)

        if aPrefixLength > bPrefixLength { return true }
        if bPrefixLength > aPrefixLength { return false }
        
        let aContains = isValidSubstringMatch(a, search)
        let bContains = isValidSubstringMatch(b, search)

        if aContains && !bContains { return true }
        if bContains && !aContains { return false }
        
        else {
            return a.localizedStandardCompare(b) == .orderedAscending
        }
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
        
        if search.contains("#en") {
            return longestPrefixofTwoStrs(search: search.replacingOccurrences(of: "#english", with: "").replacingOccurrences(of: "#en", with: ""), a: aDefinition, b: bDefinition)
        }
        else if search.contains("#akz") || search.contains("#alabama") {
            return longestPrefixofTwoStrs(search: search.replacingOccurrences(of: "#alabama", with: "").replacingOccurrences(of: "#akz", with: ""), a: aLemma, b: bLemma)
        }
        
        if aLemma.contains(search) || bLemma.contains(search) {
            // If both have prefix matches, compare by prefix length
            return longestPrefixofTwoStrs(search: search, a: aLemma, b: bLemma)
        }
        else {
            // If both have prefix matches, compare by prefix length
            return longestPrefixofTwoStrs(search: search, a: aDefinition, b: bDefinition)
        }
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
    @Binding var reMode: Bool
    var dictSort: () -> Void
    var clearInput: () -> Void
    @Binding var presentSideMenu: Bool
    let characters = ["ɬ", "á", "à", "ó", "ò", "í", "ì", "ⁿ"]
    var body: some View {
        VStack(spacing: 0){
            HStack(spacing: -10) {
                ZStack {
                    TextField("Search in Alabama or English", text: $searchText)
                        .onSubmit {
                            dictSort() // Run dictSort() when the user presses Return
                        }
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
                Button(action: { presentSideMenu.toggle() }) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.gray)
                        .imageScale(.large)
                        .padding(.trailing, 25)
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
        reMode.toggle()
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
