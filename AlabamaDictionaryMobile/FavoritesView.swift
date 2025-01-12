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
        NavigationStack{
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(bookmarkedEntries) { entry in
                        NavigationLink(destination: EditorView(entry: entry)) {
                            ResultView(entry: entry, simple: false)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        Divider()
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .navigationTitle("Favorites")
            .toolbar{
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: FlashcardsView()) {
                            Image(systemName: "rectangle.on.rectangle.angled")
                                .foregroundColor(.gray)
                        }
                        .help("Flashcard Mode")
                    }
                }
        }.padding()
            .refreshable{
                bookmarkedEntries = FavoritesManager.shared.getFavorites()
            }
            .onAppear {
                bookmarkedEntries = FavoritesManager.shared.getFavorites()
            }
    }
}


#Preview {
    FavoritesView()
}
