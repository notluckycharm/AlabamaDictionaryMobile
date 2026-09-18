//
//  Utils.swift
//  AlabamaDictionaryMobile
//
//  Created by Jacob Fernandes on 7/17/26.
//

import Foundation
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

enum DictUtils {

    static func removeAccents(_ string: String) -> String {
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
    static func convertNasals(_ string: String) -> String {
        removeAccents(string).replacingOccurrences(of: "iⁿ", with: "ĩ").replacingOccurrences(of: "aⁿ", with: "ã").replacingOccurrences(of: "oⁿ", with: "õ")
    }
    
    static func reMatch(string: String, text: String) -> Bool {
        let re = string.replacingOccurrences(of: "C", with: "[bcdfhklɬmnpstwy]")
            .replacingOccurrences(of: "V", with: "[aeoiáóéíàòìè]")
        return text.range(of: re, options: .regularExpression) != nil
    }
    final class WordOfTheDayProvider {
        private let allowedEntries: [DictionaryEntry]

        init(entries: [DictionaryEntry], banList: Set<String>) {
                self.allowedEntries = entries.filter { entry in
                    let combinedText = entry.definition // [Definition]
                        .map { $0.definition }
                        .joined(separator: " ")

                    return !banList.contains { combinedText.contains($0) }
                }
            }

        func entry(for date: Date = Date()) -> DictionaryEntry? {
            guard !allowedEntries.isEmpty else { return nil }

            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            guard let normalizedDate = calendar.date(from: components) else { return nil }
            let daysSinceEpoch = Int(normalizedDate.timeIntervalSince1970 / 86400)

            var generator = SeededGenerator(seed: UInt64(daysSinceEpoch))
            let index = Int.random(in: 0..<allowedEntries.count, using: &generator)
            return allowedEntries[index]
        }
    }
    
}
