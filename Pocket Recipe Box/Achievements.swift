import Foundation

enum AchievementCounterKey {
    static let recipesAdded = "recipesAdded"
    static let categoriesCreated = "categoriesCreated"
    static let favoritesMarked = "favoritesMarked"
    static let notesAdded = "notesAdded"
    static let shoppingUsed = "shoppingUsed"
    static let photosAdded = "photosAdded"
}

extension DataStore {
    func trackAfterAddingRecipe(_ recipe: Recipe) {
        increment(AchievementCounterKey.recipesAdded)
        if let m = recipe.totalMinutes, m < 30 { unlock(.under30Chef) }
        if recipe.difficulty == .hard { unlock(.hardChef) }
        if recipe.imageFilename != nil { increment(AchievementCounterKey.photosAdded) }
        evaluateRecipeMilestones()
    }

    func trackAfterToggleFavorite(to value: Bool) {
        if value { increment(AchievementCounterKey.favoritesMarked) }
    }

    func trackAfterAddingCategory() { increment(AchievementCounterKey.categoriesCreated); evaluateCategoryMilestones() }
    func trackAfterAddingNotes(_ count: Int) { if count > 0 { increment(AchievementCounterKey.notesAdded, by: count) } }
    func trackAfterUsingShopping(_ count: Int) { if count > 0 { increment(AchievementCounterKey.shoppingUsed, by: count) } }

    private func increment(_ key: String, by: Int = 1) {
        var cnt = db.achievements.counters[key] ?? 0
        cnt += by
        db.achievements.counters[key] = cnt
        save()
        evaluateAll()
    }

    private func unlock(_ key: AchievementKey) {
        if !db.achievements.unlocked.contains(key) {
            db.achievements.unlocked.insert(key)
            save()
        }
    }

    private func evaluateRecipeMilestones() {
        let total = db.recipes.count
        if total >= 1 { unlock(.firstCard) }
        if total >= 10 { unlock(.tenRecipes) }
        if total >= 25 { unlock(.twentyFiveRecipes) }
        if total >= 50 { unlock(.fiftyRecipes) }
        evaluateTrueChef()
    }

    private func evaluateCategoryMilestones() {
        let total = db.categories.count
        if total >= 5 { unlock(.fiveCategories) }
        evaluateTrueChef()
    }

    private func evaluateAll() {
        if (db.achievements.counters[AchievementCounterKey.favoritesMarked] ?? 0) >= 5 { unlock(.fiveFavorites) }
        if (db.achievements.counters[AchievementCounterKey.notesAdded] ?? 0) >= 10 { unlock(.tenNotes) }
        if (db.achievements.counters[AchievementCounterKey.shoppingUsed] ?? 0) >= 5 { unlock(.shoppingFive) }
        if (db.achievements.counters[AchievementCounterKey.photosAdded] ?? 0) >= 10 { unlock(.tenPhotos) }
        evaluateTrueChef()
    }

    private func evaluateTrueChef() {
        let required: Set<AchievementKey> = Set(AchievementKey.allCases.filter { $0 != .trueChef })
        if db.achievements.unlocked.isSuperset(of: required) { unlock(.trueChef) }
    }
}


