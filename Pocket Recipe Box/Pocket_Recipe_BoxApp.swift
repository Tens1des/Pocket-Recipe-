//
//  Pocket_Recipe_BoxApp.swift
//  Pocket Recipe Box
//
//  Created by Рома Котов on 30.09.2025.
//

import SwiftUI

@main
struct Pocket_Recipe_BoxApp: App {
    @StateObject private var store = DataStore()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
