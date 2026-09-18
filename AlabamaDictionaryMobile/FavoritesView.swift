//
//  FlashCardsView.swift
//  AlabamaDictionaryMobile
//
//  Created by Jacob Fernandes on 1/6/25.
//

import SwiftUI

struct FavoritesView: View {
    @State private var bookmarkedEntries: [DictionaryEntry] = []
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(bookmarkedEntries) { entry in
                        NavigationLink(destination: EditorView(entry: entry)) {
                            ResultView(entry: entry, simple: true)
                        }
                        .buttonStyle(PlainButtonStyle())
                        Divider()
                    }
                }
            }
            .task {
                let favorites = await Task.detached(priority: .userInitiated) {
                        FavoritesManager.shared.getFavorites()
                    }.value
                    bookmarkedEntries = favorites
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
