//
//  AppSettings.swift
//  AlabamaDictionaryMobile
//
//  Created by Jacob Fernandes on 7/17/26.
//

import Foundation

class AppSettings: ObservableObject {
    @Published var fontSize: CGFloat {
        didSet { UserDefaults.standard.set(fontSize, forKey: "fontSize") }
    }
    @Published var modernOrthography: Bool {
        didSet { UserDefaults.standard.set(modernOrthography, forKey: "modernOrthography") }
    }
    
    init() {
        self.fontSize = UserDefaults.standard.object(forKey: "fontSize") as? CGFloat ?? 16
        self.modernOrthography = UserDefaults.standard.bool(forKey: "modernOrthography")
    }
}
