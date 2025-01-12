//
//  FlashCardsView.swift
//  AlabamaDictionaryMobile
//
//  Created by Jacob Fernandes on 1/6/25.
//

import SwiftUI

struct FavoritesView: View {
    @State private var bookmarkedEntries: [DictionaryEntry] = FavoritesManager.shared.getFavorites()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(bookmarkedEntries) { entry in
                        let def = entry.definition.map { $0.definition }.joined(separator: ";")
                        
                        NavigationLink(destination: EditorView(entry: entry)) {
                            VStack {
                                HStack {
                                    Text(entry.lemma).bold()
                                    Spacer()
                                }
                                HStack {
                                    Text(def)
                                    Spacer()
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        Divider()
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .navigationTitle("Favorites")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: FlashcardsView()) {
                        Image(systemName: "rectangle.on.rectangle.angled")
                            .foregroundColor(.gray)
                    }
                    .help("Flashcard Mode")
                }
            }
        }
        .onAppear() {
            if FavoritesManager.shared.getModify() == true {
                bookmarkedEntries = FavoritesManager.shared.getFavorites()
            }
        }
        .padding()
        .refreshable {
            bookmarkedEntries = FavoritesManager.shared.getFavorites()
        }
    }

}


#Preview {
    FavoritesView()
}
