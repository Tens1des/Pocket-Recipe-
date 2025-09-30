import Foundation
import SwiftUI

// MARK: - File paths helpers

enum AppFile {
    static func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static func fileURL(_ name: String) -> URL {
        documentsDirectory().appendingPathComponent(name)
    }
}

// MARK: - Image Manager (stores images as JPEG/PNG in Documents)

final class ImageManager {
    static let shared = ImageManager()
    private init() {}

    func saveImage(_ image: UIImage, filename: String? = nil) throws -> String {
        let name = filename ?? UUID().uuidString + ".jpg"
        let url = AppFile.fileURL(name)
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw NSError(domain: "image.encode", code: -1)
        }
        try data.write(to: url, options: [.atomic])
        return name
    }

    func loadImage(named: String) -> UIImage? {
        let url = AppFile.fileURL(named)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func deleteImage(named: String) {
        let url = AppFile.fileURL(named)
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - JSON Store

struct AppDatabase: Codable {
    var recipes: [Recipe]
    var categories: [Category]
    var shopping: [ShoppingItem]
    var settings: AppSettings
    var profile: UserProfile
    var achievements: AchievementProgress

    static func empty() -> AppDatabase {
        AppDatabase(
            recipes: [],
            categories: defaultCategories,
            shopping: [],
            settings: AppSettings(theme: .system, language: .en, defaultSort: .byDateDesc),
            profile: UserProfile(nickname: "Chef", avatarIndex: 0, joinDate: Date()),
            achievements: AchievementProgress()
        )
    }
}

let defaultCategories: [Category] = [
    Category(name: "Breakfast", emoji: "🥞"),
    Category(name: "Lunch", emoji: "🍲"),
    Category(name: "Dinner", emoji: "🍝"),
    Category(name: "Desserts", emoji: "🍰"),
    Category(name: "Family", emoji: "👨‍👩‍👧"),
]

@MainActor
final class DataStore: ObservableObject {
    @Published var db: AppDatabase

    private let userDefaults = UserDefaults.standard
    private let databaseKey = "PocketRecipeBox_Database"

    init() {
        if let data = UserDefaults.standard.data(forKey: "PocketRecipeBox_Database"),
           let loaded = try? JSONDecoder().decode(AppDatabase.self, from: data) {
            db = loaded
        } else {
            db = .empty()
            save()
        }
    }

    // MARK: - CRUD Helpers

    func addRecipe(_ recipe: Recipe) { db.recipes.append(recipe); save() }

    func updateRecipe(_ recipe: Recipe) {
        if let idx = db.recipes.firstIndex(where: { $0.id == recipe.id }) {
            db.recipes[idx] = recipe
            db.recipes[idx].updatedAt = Date()
            save()
        }
    }

    func deleteRecipe(_ id: UUID) {
        if let r = db.recipes.first(where: { $0.id == id }), let img = r.imageFilename { ImageManager.shared.deleteImage(named: img) }
        db.recipes.removeAll { $0.id == id }
        save()
    }

    func toggleFavorite(_ id: UUID) {
        guard let idx = db.recipes.firstIndex(where: { $0.id == id }) else { return }
        db.recipes[idx].favorite.toggle()
        trackAfterToggleFavorite(to: db.recipes[idx].favorite)
        save()
    }

    func addShoppingItems(_ items: [ShoppingItem]) { db.shopping.append(contentsOf: items); save() }
    func toggleShoppingItem(_ id: UUID) { if let i = db.shopping.firstIndex(where: { $0.id == id }) { db.shopping[i].checked.toggle(); save() } }
    func clearShopping() { db.shopping.removeAll(); save() }

    func addCategory(_ c: Category) { db.categories.append(c); save() }
    func deleteCategory(_ id: UUID) { db.categories.removeAll { $0.id == id }; save() }

    // MARK: - Persistence

    func save() {
        do {
            let data = try JSONEncoder().encode(db)
            userDefaults.set(data, forKey: databaseKey)
        } catch {
            print("Save error: \(error)")
        }
    }

}


