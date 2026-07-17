//
//  Utils.swift
//  AlabamaDictionaryMobile
//
//  Created by Jacob Fernandes on 7/17/26.
//


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
}
