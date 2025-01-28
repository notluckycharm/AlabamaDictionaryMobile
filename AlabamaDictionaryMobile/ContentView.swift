//
//  ContentView.swift
//  AlabamaDictionaryMobile
//
//  Created by Jacob Fernandes on 5/7/24.
//

import SwiftUI

struct Sentence: Codable, Identifiable, Equatable {
    let id = UUID()
    let akz: String?
    let en: String?

    enum CodingKeys: String, CodingKey {
        case akz = "alabama-example"
        case en = "english-translation"
    }
    
    static func == (lhs: Sentence, rhs: Sentence) -> Bool {
            lhs.id == rhs.id &&
            lhs.akz == rhs.akz &&
            lhs.en == rhs.en
        }
}

struct Definition: Codable, Identifiable, Equatable {
    let id = UUID()
    let wordClass: String
    let definition: String

    enum CodingKeys: String, CodingKey {
        case wordClass = "class"
        case definition = "def"
    }
    
    static func == (lhs: Definition, rhs: Definition) -> Bool {
            lhs.id == rhs.id &&
            lhs.wordClass == rhs.wordClass &&
            lhs.definition == rhs.definition
        }
}

struct DictionaryEntry: Identifiable, Codable, Equatable {
    var id: String { lemma }
    let lemma: String
    let definition: [Definition]
    let wordClass: String?
    let principalPart: String?
    let derivation: String?
    let notes: String?
    let relatedTerms: [String]
    let audio: [String]
    let sentences: [Sentence]

    enum CodingKeys: String, CodingKey {
        case lemma, definition, wordClass = "class", principalPart, derivation, notes, relatedTerms, audio, sentences
    }
    
    static func == (lhs: DictionaryEntry, rhs: DictionaryEntry) -> Bool {
            lhs.id == rhs.id &&
            lhs.lemma == rhs.lemma &&
            lhs.definition == rhs.definition &&
            lhs.wordClass == rhs.wordClass &&
            lhs.principalPart == rhs.principalPart &&
            lhs.derivation == rhs.derivation &&
            lhs.notes == rhs.notes &&
            lhs.relatedTerms == rhs.relatedTerms &&
            lhs.audio == rhs.audio &&
            lhs.sentences == rhs.sentences
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
    @State private var loadedResults: [DictionaryEntry] = []
    @State private var isLoading: Bool = false

    var body: some View {
        ZStack{
            TabView{
                VStack{
                    HeaderView()
                    NavigationStack{
                        VStack(spacing: 0) {
                            SearchBarView(searchText: $searchText, reMode: $reMode, dictSort: dictSort, clearInput: clearInput, presentSideMenu: $presentSideMenu)
                            ResultsNavigationView(shown: $shown, shownMax: $shownMax, updateResults: updateResults)
                            ResultsView(searchResults: $loadedResults, shown: $shown, shownMax: $shownMax)
                        }
                    }
                    .padding()
                    .onAppear {
                        DispatchQueue.global(qos: .background).async {
                            let dictionaryData: DictionaryData = loadJSON("dict.json")
                            DispatchQueue.main.async {
                                allEntries = dictionaryData.words
                            }
                        }
                    }
                    
                    
                }.tabItem {
                    Label("Dictionary", systemImage: "text.book.closed.fill")
                }
                AboutView()
                    .tabItem {
                        Label("About", systemImage: "info.circle.fill")
                    }
                FavoritesView().tabItem {
                    Label("Favorites", systemImage: "bookmark.fill")
                }
            }.environment(\.horizontalSizeClass, .compact)
            if isLoading {
                        Color.black.opacity(0.5) // Semi-transparent overlay
                            .edgesIgnoringSafeArea(.all)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(2)
                            .padding()
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
                     .replacingOccurrences(of: "#akz", with: "")
                     .replacingOccurrences(of: "#alabama", with: "")
                     .replacingOccurrences(of: "#noun", with: "")
                     .replacingOccurrences(of: "#verb", with: "")
                     .replacingOccurrences(of: "#am-p", with: "")
                     .replacingOccurrences(of: "#LI", with: "")
                     .replacingOccurrences(of: "#CHA", with: "")
                     .replacingOccurrences(of: "#AM", with: "")
                     .replacingOccurrences(of: "#transitive", with: "")
                     .replacingOccurrences(of: "#affix", with: "")
                     .trimmingCharacters(in: .whitespaces)
    }
    
    func dictSort() {
        let string = !reMode ? removeAccents(searchText.lowercased()) : searchText
        let strippedSearchText = stripped(string: string)
        DispatchQueue.global(qos: .userInitiated).async {
            isLoading = true
            var filteredEntries: [DictionaryEntry]
            if !reMode {
                let regexPattern = """
                ^\(NSRegularExpression.escapedPattern(for: strippedSearchText))|\\b\(NSRegularExpression.escapedPattern(for: strippedSearchText))(\\b|$)
                """
                // Pre-compile the regex pattern
                guard let regex = try? NSRegularExpression(pattern: regexPattern, options: .caseInsensitive) else {
                    return // Handle the case where regex can't be created
                }
                
                filteredEntries = allEntries.filter { entry in
                    // Match the lemma or the definition using regex
                    removeAccents(stripped(string: entry.lemma.lowercased())).contains(strippedSearchText) || entry.definition.contains { def in
                        // Use the precompiled regex for matching the definition
                        let lowercasedDef = def.definition.lowercased()
                        return regex.firstMatch(in: lowercasedDef, options: [], range: NSRange(lowercasedDef.startIndex..., in: lowercasedDef)) != nil
                    }
                }
            }
            else {
                filteredEntries = allEntries.filter { entry in
                    reMatch(string: strippedSearchText, text: stripped(string: entry.lemma))
                }
            }
            if limitAudio {
                filteredEntries = filteredEntries.filter { entry in
                    entry.audio.count > 0
                }
            }
            if string.contains("#") {
                if string.contains("#en") {
                    filteredEntries = filteredEntries.filter {
                        entry in entry.definition.contains { def in
                            def.definition.contains(strippedSearchText)
                        }
                    }
                }
                else if string.contains("#akz") || string.contains("#alabama") {
                    filteredEntries = filteredEntries.filter {
                        entry in removeAccents( entry.lemma.lowercased()).contains(strippedSearchText)
                    }
                }
                if string.contains("#noun") {
                    filteredEntries = filteredEntries.filter { entry in
                        entry.definition.map { def in
                            !def.definition.hasPrefix("to ")
                        }.filter { el in
                            el == true
                        }.count > 0
                        && !entry.lemma.contains(where: { ["-", "<", ">"].contains($0) })
                    }
                }
                if string.contains("#verb") {
                    filteredEntries = filteredEntries.filter { entry in
                        entry.definition.map { def in
                            def.definition.hasPrefix("to ")
                        }.filter { el in
                            el == true
                        }.count > 0
                        && !entry.lemma.contains(where: { ["-", "<", ">"].contains($0) })
                    }
                }
                if string.contains("#transitive") {
                    filteredEntries = filteredEntries.filter { entry in
                        entry.definition.map { def in
                            def.wordClass.contains("-LI/CHA-") || def.wordClass.contains("-LI/AM-") || def.wordClass.contains("CHA-/AM-")
                        }.filter { $0 }.count > 0
                    }
                }
                if string.contains("#LI") {
                    filteredEntries = filteredEntries.filter { entry in
                        entry.definition.map { def in
                            def.wordClass.contains("-LI")
                        }.filter { $0 }.count > 0
                    }
                }
                if string.contains("#CHA") {
                    filteredEntries = filteredEntries.filter { entry in
                        entry.definition.map { def in
                            def.wordClass == ("CHA-") || def.wordClass.prefix(7) == ("CHA- or") || def.wordClass == "CHA-/3"
                        }.filter { $0 }.count > 0
                    }
                }
                if string.contains("#am-p") {
                    filteredEntries = filteredEntries.filter { entry in
                        entry.definition.map { def in
                            def.wordClass == ("AM-p")
                        }.filter { $0 }.count > 0
                    }
                }
                if string.contains("#AM") {
                    filteredEntries = filteredEntries.filter { entry in
                        entry.definition.map { def in
                            def.wordClass == ("AM-") || def.wordClass.contains("or AM-") || def.wordClass.contains("AM- or") || def.wordClass == "AM-/3"
                        }.filter { $0 }.count > 0
                    }
                }
            }
            let searchString = string.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: "^", with: "").replacingOccurrences(of: ".", with: "").replacingOccurrences(of: "*", with: "").replacingOccurrences(of: "+", with: "")
            filteredEntries.sort { a, b in
                return stateMachineSort(string: searchString, a: a, b: b)
            }
            DispatchQueue.main.async {
                shownMax = filteredEntries.count
                loadedResults = filteredEntries
                isLoading = false
            }
        }
    }
    
    func updateResults(count: Int) {
        if shown + count < 0 {
            shown = 0
        } else if shown + count > shownMax {
            shown = shownMax
        } else {
            shown += count
        }
        searchResults = Array(loadedResults[shown..<shown + min(50, shownMax - shown)])
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
        var aPrefix = a.hasPrefix(search)
        var bPrefix = b.hasPrefix(search)
        if aPrefix != bPrefix {
            return aPrefix == true
        }
        
        aPrefix = longestCommonPrefixLength(search, a)
        bPrefix  = longestCommonPrefixLength(search, b)
        if aPrefix != bPrefix {
            return aPrefix == true
        }
        
        return a.localizedStandardCompare(b) == .orderedAscending
    }

    
    func isValidSubstringMatch(_ lemma: String, _ search: String) -> Bool {
            let regex = "\\b\(NSRegularExpression.escapedPattern(for: search))\\b"
            let matches = lemma.range(of: regex, options: .regularExpression)
            return matches != nil
        }
    
    func longestCommonPrefixLength(_ search: String, _ b: String) -> Bool {
        let bs = b.split(separator: ";")
        let prefixLengths = bs.map { substring in
            let substring = String(substring)
            if substring.hasPrefix(search) {
                return true
            } else {
                return false // A large number for non-matching cases
            }
        }
        return prefixLengths.contains(true)
    }

    
    func stateMachineSort(string: String, a: DictionaryEntry, b: DictionaryEntry) -> Bool {
        let search = removeAccents(string.lowercased())
        let strippedSearch = (stripped(string: search))
        let aLemma = removeAccents(a.lemma.lowercased())
        let bLemma = removeAccents(b.lemma.lowercased())
        if aLemma == search { return true }
        if bLemma == search { return false }
        let aDefinition = (a.definition).map { def in
            removeAccents(def.definition.lowercased())
        }.joined(separator: ";")
        let bDefinition = b.definition.map{ def in
            removeAccents(def.definition.lowercased())
        }.joined(separator: ";")
        // Prioritize exact matches (full word or definition)
        if aDefinition == search { return true }
        if bDefinition == search { return false }
        
        if reMode || strippedSearch == "" {
            return a.lemma.localizedStandardCompare(b.lemma) == .orderedAscending
        }
        else{
            if aLemma.contains(strippedSearch) || bLemma.contains(strippedSearch) {
                // If both have prefix matches, compare by prefix length
                return longestPrefixofTwoStrs(search: search, a: aLemma, b: bLemma)
            }
            else {
                // If both have prefix matches, compare by prefix length
                return longestPrefixofTwoStrs(search: search, a: aDefinition, b: bDefinition)
            }
        }
    }
    
    func nearPrefix(_ string: String, _ b: String) -> Bool {
        return String(string.prefix(b.count + 1)) == "\(b),"
    }
}

struct HeaderView: View {
    var body: some View {
        VStack(){
            HStack(alignment: .center, spacing: 16) {
                Image("Alabama-Coushata")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 75, height: 75)
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
    @Binding var shown: Int
    @Binding var shownMax: Int
    
    var body: some View {
        ScrollView {
        if !searchResults.isEmpty {
                LazyVStack(alignment: .leading) {
                    ForEach(searchResults[shown..<shown + min(50, shownMax - shown)]) { entry in
                        NavigationLink(destination: EditorView(entry: entry)) {
                            ResultView(entry: entry, simple: false)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        Divider()
                    }
                }
            }
        }.frame(maxHeight: .infinity)
    }
}


struct ResultView: View {
    let entry: DictionaryEntry
    @State var simple = false
    
    init(entry: DictionaryEntry, simple: Bool = false) {
        self.entry = entry
        self.simple = simple
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                // Use NavigationLink to make the lemma clickable
                    Text(entry.lemma)
                            .bold()
                            .textSelection(.enabled)
                Spacer()
                if let wordClass = entry.wordClass, wordClass != "nan" {
                    Text("[\(wordClass)]")
                }
            }
            if !simple {
                if let derivation = entry.derivation, derivation != "nan" {
                    Text(derivation)
                        .italic()
                }
            }
            let def = entry.definition.map{ def in
                (def.definition)
            }.joined(separator: ";")
            Text(def)
        }
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
