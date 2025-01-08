//
//  BookmarkManager.swift
//  AlabamaDictionaryMobile
//
//  Created by Jacob Fernandes on 1/7/25.
//

import Foundation

class FavoritesManager {
    static let shared = FavoritesManager()

    private let favoritesKey = "FavoritedWords"

    private init() {}

    // Save a word to favorites
    func addFavorite(word: DictionaryEntry) {
        var favorites = getFavorites()
        if !favorites.contains(where: { $0.lemma == word.lemma }) {
            favorites.append(word)
            saveFavorites(favorites)
        }
    }

    // Remove a word from favorites
    func removeFavorite(word: DictionaryEntry) {
        var favorites = getFavorites()
        favorites.removeAll(where: { $0.lemma == word.lemma })
        saveFavorites(favorites)
    }

    // Get all favorited words
    func getFavorites() -> [DictionaryEntry] {
        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let favorites = try? JSONDecoder().decode([DictionaryEntry].self, from: data) {
            return favorites
        }
        return []
    }

    // Save favorites to UserDefaults
    private func saveFavorites(_ favorites: [DictionaryEntry]) {
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: favoritesKey)
        }
    }
}
