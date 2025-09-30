import Foundation

// MARK: - Enums

enum RecipeDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy
    case medium
    case hard
    var id: String { rawValue }
}

enum CookTimeCategory: String, Codable, CaseIterable, Identifiable {
    case under30
    case min30to60
    case over60
    var id: String { rawValue }
}

// MARK: - Core Models

struct Ingredient: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var quantity: String?

    init(id: UUID = UUID(), name: String, quantity: String? = nil) {
        self.id = id
        self.name = name
        self.quantity = quantity
    }
}

struct RecipeStep: Identifiable, Codable, Hashable {
    let id: UUID
    var order: Int
    var text: String

    init(id: UUID = UUID(), order: Int, text: String) {
        self.id = id
        self.order = order
        self.text = text
    }
}

struct Category: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var emoji: String?

    init(id: UUID = UUID(), name: String, emoji: String? = nil) {
        self.id = id
        self.name = name
        self.emoji = emoji
    }
}

struct Recipe: Identifiable, Codable {
    let id: UUID
    var title: String
    var categoryId: UUID?
    var imageFilename: String? // Stored locally; file managed separately
    var ingredients: [Ingredient]
    var steps: [RecipeStep]
    var notes: String?
    var difficulty: RecipeDifficulty
    var totalMinutes: Int?
    var favorite: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        categoryId: UUID? = nil,
        imageFilename: String? = nil,
        ingredients: [Ingredient] = [],
        steps: [RecipeStep] = [],
        notes: String? = nil,
        difficulty: RecipeDifficulty = .medium,
        totalMinutes: Int? = nil,
        favorite: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.categoryId = categoryId
        self.imageFilename = imageFilename
        self.ingredients = ingredients
        self.steps = steps
        self.notes = notes
        self.difficulty = difficulty
        self.totalMinutes = totalMinutes
        self.favorite = favorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct ShoppingItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var quantity: String?
    var price: Double?
    var checked: Bool
    var recipeId: UUID?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        quantity: String? = nil,
        price: Double? = nil,
        checked: Bool = false,
        recipeId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.price = price
        self.checked = checked
        self.recipeId = recipeId
        self.createdAt = createdAt
    }
}

// MARK: - Settings & Profile

struct UserProfile: Codable {
    var nickname: String
    var avatarIndex: Int
    var joinDate: Date
    
    init(nickname: String = "User", avatarIndex: Int = 0, joinDate: Date = Date()) {
        self.nickname = nickname
        self.avatarIndex = avatarIndex
        self.joinDate = joinDate
    }
}

enum AppTheme: String, Codable, CaseIterable, Identifiable { case system, light, dark; var id: String { rawValue } }

enum AppLanguage: String, Codable, CaseIterable, Identifiable { case en, ru; var id: String { rawValue } }

struct AppSettings: Codable {
    var theme: AppTheme
    var language: AppLanguage
    var defaultSort: RecipeSort
}

enum RecipeSort: String, Codable, CaseIterable, Identifiable {
    case byDateDesc
    case byTitleAsc
    case byCategory
    var id: String { rawValue }
}

// MARK: - Achievements

enum AchievementKey: String, Codable, CaseIterable, Identifiable {
    case firstCard
    case tenRecipes
    case twentyFiveRecipes
    case fiveCategories
    case fiveFavorites
    case tenNotes
    case under30Chef
    case hardChef
    case shoppingFive
    case fiftyRecipes
    case tenPhotos
    case trueChef
    var id: String { rawValue }
}

struct AchievementProgress: Codable {
    var unlocked: Set<AchievementKey>
    var counters: [String: Int]

    init(unlocked: Set<AchievementKey> = [], counters: [String: Int] = [:]) {
        self.unlocked = unlocked
        self.counters = counters
    }
}


