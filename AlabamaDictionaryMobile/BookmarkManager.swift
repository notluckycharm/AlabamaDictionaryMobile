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

    private var modified = false
    
    func modify() {
        modified = true
    }
    
    func getModify() -> Bool {
        return modified
    }
    
    // Save a word to favorites
    func addFavorite(word: DictionaryEntry) {
        var favorites = getFavorites()
        if !favorites.contains(where: { $0.lemma == word.lemma }) {
            favorites.append(word)
            saveFavorites(favorites)
        }
        modify()
    }

    // Remove a word from favorites
    func removeFavorite(word: DictionaryEntry) {
        var favorites = getFavorites()
        favorites.removeAll(where: { $0.lemma == word.lemma })
        saveFavorites(favorites)
        modify()
    }

    // Get all favorited words
    func getFavorites() -> [DictionaryEntry] {
        modified = false
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
