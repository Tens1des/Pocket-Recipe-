//
//  ContentView.swift
//  Pocket Recipe Box
//
//  Created by Рома Котов on 30.09.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = DataStore()
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Pocket Recipe Box")
                    .font(.title)
                Text("Recipes: \(store.db.recipes.count)")
                Text("Categories: \(store.db.categories.count)")
                Button("Add Sample Recipe") { addSample() }
            }
            .padding()
            .navigationTitle("Home")
        }
    }

    private func addSample() {
        let sample = Recipe(
            title: "Creamy Pasta",
            ingredients: [Ingredient(name: "Pasta", quantity: "200g"), Ingredient(name: "Cream", quantity: "100ml")],
            steps: [RecipeStep(order: 1, text: "Boil pasta"), RecipeStep(order: 2, text: "Add cream")],
            difficulty: .easy,
            totalMinutes: 20
        )
        store.addRecipe(sample)
    }
}

#Preview {
    ContentView()
}
