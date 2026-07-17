//
//  AlabamaDictionaryMobileApp.swift
//  AlabamaDictionaryMobile
//
//  Created by Jacob Fernandes on 5/7/24.
//

import SwiftUI

@main
struct AlabamaDictionaryMobileApp: App {
    @StateObject private var settings = AppSettings()
    
    var body: some Scene {
        WindowGroup(id:"home") {
            ContentView().environmentObject(settings)
        }
    }
}
