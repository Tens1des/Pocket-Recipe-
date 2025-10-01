import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        TabView {
            RecipesListView()
                .tabItem { Label("Recipes", systemImage: "book") }

            ShoppingListView()
                .tabItem { Label("Shopping", systemImage: "cart") }

            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "star") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .preferredColorScheme(store.db.settings.theme == .dark ? .dark : 
                            store.db.settings.theme == .light ? .light : nil)
    }
}

struct RecipesListView: View {
    @EnvironmentObject var store: DataStore
    @State private var query: String = ""
    @State private var selectedCategory: String = "All"
    @State private var showingEditor = false

    var filtered: [Recipe] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let byQuery = q.isEmpty ? store.db.recipes : store.db.recipes.filter { r in
            if r.title.lowercased().contains(q) { return true }
            if r.ingredients.contains(where: { $0.name.lowercased().contains(q) }) { return true }
            return false
        }
        guard selectedCategory != "All" else { return byQuery }
        return byQuery.filter { r in
            guard let cid = r.categoryId, let cat = store.db.categories.first(where: { $0.id == cid }) else { return false }
            return cat.name == selectedCategory
        }
    }

    var categories: [String] { ["All"] + store.db.categories.map { $0.name } }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 12) {
                        header
                        searchBar
                        categoryTabs
                        // Compact rows instead of big cards
                        LazyVStack(spacing: 10) {
                            ForEach(filtered) { recipe in
                                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                    CompactRecipeRow(recipe: recipe, categoryName: store.db.categories.first(where: { $0.id == recipe.categoryId })?.name)
                                }.buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        NavigationLink(destination: CategoriesView()) { Image(systemName: "square.grid.2x2") }
                    }
                }
                floatingAddButton
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("My Recipes").font(.largeTitle.bold())
                Spacer()
                Image(systemName: avatarSymbol(for: store.db.profile.avatarIndex))
                    .font(.title2)
                    .foregroundColor(.purple)
            }
            Text("\(store.db.recipes.count) delicious meals").foregroundColor(.secondary)
        }
    }

    private func avatarSymbol(for index: Int) -> String {
        let icons = ["person.circle.fill","fork.knife.circle.fill","flame.circle.fill","leaf.circle.fill","cup.and.saucer.fill","camera.circle.fill","cart.circle.fill","book.circle.fill","star.circle.fill"]
        return icons.indices.contains(index) ? icons[index] : icons[0]
    }

    private var searchBar: some View {
        HStack { Image(systemName: "magnifyingglass").foregroundColor(.secondary); TextField("Search recipes or ingredients...", text: $query) }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Color.gray.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    Button(action: { selectedCategory = cat }) {
                        HStack(spacing: 4) {
                            if cat == "Favorites" { Image(systemName: "star.fill").foregroundColor(.yellow) }
                            Text(cat)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(cat == selectedCategory ? Color.purple : Color.white)
                        .foregroundColor(cat == selectedCategory ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 1)
                    }
                }
            }
            .padding(.horizontal, 1)
        }
    }

    private var floatingAddButton: some View {
        Button(action: { showingEditor = true }) {
            Image(systemName: "plus").font(.title2.bold()).foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(Circle())
                .shadow(radius: 4)
        }
        .padding(.trailing).padding(.bottom, 8)
        .sheet(isPresented: $showingEditor) { RecipeEditorView() }
    }
}

struct CompactRecipeRow: View {
    let recipe: Recipe
    let categoryName: String?

    private func difficultyColor(_ d: RecipeDifficulty) -> Color {
        switch d { case .easy: return .green; case .medium: return .orange; case .hard: return .red }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let fn = recipe.imageFilename, let img = ImageManager.shared.loadImage(named: fn) {
                Image(uiImage: img).resizable().scaledToFill().frame(width: 56, height: 56).clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                ZStack { RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2)); Image(systemName: "photo") }.frame(width: 56, height: 56)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title).font(.headline).lineLimit(1)
                Text(recipe.notes ?? "").font(.caption).foregroundColor(.secondary).lineLimit(1)
                HStack(spacing: 14) {
                    if let m = recipe.totalMinutes {
                        HStack(spacing: 4) { Image(systemName: "clock").foregroundColor(.blue); Text("\(m)"); Text("min").foregroundColor(.secondary) }.font(.caption)
                    }
                    HStack(spacing: 4) { Image(systemName: "flame.fill").foregroundColor(difficultyColor(recipe.difficulty)); Text(recipe.difficulty.rawValue.capitalized) }.font(.caption)
                    if let categoryName { HStack(spacing: 4) { Image(systemName: "tag.fill").foregroundColor(.purple); Text(categoryName) }.font(.caption) }
                }
            }
            Spacer()
            if recipe.favorite { Image(systemName: "star.fill").foregroundColor(.yellow) }
        }
        .padding(10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct RecipeCardView: View {
    let recipe: Recipe
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let fn = recipe.imageFilename, let ui = ImageManager.shared.loadImage(named: fn) {
                        Image(uiImage: ui).resizable().scaledToFill()
                    } else {
                        ZStack { RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.2)); Image(systemName: "photo") }
                    }
                }
                .frame(height: 160).frame(maxWidth: .infinity).clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                if recipe.favorite { Image(systemName: "star.fill").foregroundColor(.yellow).padding(8) }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title).font(.headline).lineLimit(1)
                Text(recipe.notes ?? "Delicious recipe").font(.subheadline).foregroundColor(.secondary).lineLimit(1)
                HStack(spacing: 12) {
                    if let m = recipe.totalMinutes { Label("\(m)m", systemImage: "clock").font(.caption) }
                    Label(recipe.difficulty.rawValue.capitalized, systemImage: "flame").font(.caption)
                    if let cid = recipe.categoryId, let cat = DataStore().db.categories.first(where: { $0.id == cid }) {
                        Label(cat.name, systemImage: "folder").font(.caption)
                    }
                }
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }
}

struct RecipeDetailView: View {
    @EnvironmentObject var store: DataStore
    let recipe: Recipe

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroImage
                content
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { store.toggleFavorite(recipe.id) }) {
                    Image(systemName: recipe.favorite ? "star.fill" : "star")
                        .foregroundColor(recipe.favorite ? .yellow : .primary)
                }
            }
        }
    }
    
    private var heroImage: some View {
        ZStack(alignment: .bottomLeading) {
            if let fn = recipe.imageFilename, let ui = ImageManager.shared.loadImage(named: fn) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 280)
                    .clipped()
            } else {
                ZStack {
                    Color.gray.opacity(0.2)
                    Image(systemName: "photo")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                }
                .frame(height: 280)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(recipe.title)
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                
                HStack(spacing: 16) {
                    if let minutes = recipe.totalMinutes {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text("\(minutes)m")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .shadow(radius: 1)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame")
                        Text(recipe.difficulty.rawValue.capitalized)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .shadow(radius: 1)
                    
                    if let categoryId = recipe.categoryId,
                       let category = store.db.categories.first(where: { $0.id == categoryId }) {
                        HStack(spacing: 4) {
                            Text(category.emoji ?? "📁")
                            Text(category.name)
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .shadow(radius: 1)
                    }
                }
            }
            .padding()
        }
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 24) {
            aboutSection
            ingredientsSection
            instructionsSection
            if let notes = recipe.notes, !notes.isEmpty {
                notesSection(notes)
            }
        }
        .padding()
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About this recipe")
                .font(.title2.bold())
            
            Text(recipe.notes ?? "A delicious recipe to try!")
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
            
            HStack {
                Text("Serves")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("4 people")
                    .font(.subheadline.bold())
            }
        }
    }
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Ingredients")
                    .font(.title2.bold())
                Spacer()
                Button(action: addToShopping) {
                    Text("Add to cart")
                        .font(.subheadline)
                        .foregroundColor(.purple)
                }
            }
            
            VStack(spacing: 12) {
                ForEach(recipe.ingredients) { ingredient in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ingredient.name)
                                .font(.body)
                            if let quantity = ingredient.quantity {
                                Text(quantity)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Instructions")
                .font(.title2.bold())
            
            VStack(spacing: 16) {
                ForEach(recipe.steps.sorted(by: { $0.order < $1.order })) { step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(step.order)")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.purple)
                            .clipShape(Circle())
                        
                        Text(step.text)
                            .font(.body)
                            .lineSpacing(4)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
    
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Notes")
                .font(.title2.bold())
            
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb")
                    .foregroundColor(.yellow)
                    .font(.title3)
                
                Text(notes)
                    .font(.body)
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    

    private func addToShopping() {
        let items = recipe.ingredients.map { 
            ShoppingItem(name: $0.name, quantity: $0.quantity, recipeId: recipe.id) 
        }
        store.addShoppingItems(items)
        store.trackAfterUsingShopping(items.count)
    }
}

struct CookingModeView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    @State private var currentStepIndex = 0
    @State private var completedSteps: Set<Int> = []
    
    var currentStep: RecipeStep? {
        let sortedSteps = recipe.steps.sorted(by: { $0.order < $1.order })
        guard currentStepIndex < sortedSteps.count else { return nil }
        return sortedSteps[currentStepIndex]
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                progressSection
                stepContent
                navigationButtons
            }
            .padding()
            .navigationTitle("Cooking Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Step \(currentStepIndex + 1) of \(recipe.steps.count)")
                    .font(.headline)
                Spacer()
                Text("\(Int(Double(completedSteps.count) / Double(recipe.steps.count) * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: Double(completedSteps.count), total: Double(recipe.steps.count))
                .progressViewStyle(LinearProgressViewStyle(tint: .purple))
        }
    }
    
    private var stepContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let step = currentStep {
                Text(step.text)
                    .font(.title3)
                    .lineSpacing(6)
                
                Button(action: { toggleStepCompletion(step.order) }) {
                    HStack {
                        Image(systemName: completedSteps.contains(step.order) ? "checkmark.circle.fill" : "circle")
                        Text(completedSteps.contains(step.order) ? "Completed" : "Mark as Complete")
                    }
                    .foregroundColor(completedSteps.contains(step.order) ? .green : .purple)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            Button("Previous") {
                if currentStepIndex > 0 {
                    currentStepIndex -= 1
                }
            }
            .disabled(currentStepIndex == 0)
            .foregroundColor(.purple)
            
            Spacer()
            
            Button("Next") {
                if currentStepIndex < recipe.steps.count - 1 {
                    currentStepIndex += 1
                }
            }
            .disabled(currentStepIndex >= recipe.steps.count - 1)
            .foregroundColor(.purple)
        }
    }
    
    private func toggleStepCompletion(_ stepOrder: Int) {
        if completedSteps.contains(stepOrder) {
            completedSteps.remove(stepOrder)
        } else {
            completedSteps.insert(stepOrder)
        }
    }
}

struct CategoriesView: View {
    @EnvironmentObject var store: DataStore
    @State private var newName: String = ""
    @State private var showingAddCategory = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                myCategoriesSection
                moreCategoriesSection
                statisticsSection
                createCategoryButton
            }
            .padding(.horizontal)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddCategory) { AddCategoryView() }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Categories").font(.largeTitle.bold())
                Spacer()
                Button("Edit") { /* TODO: Edit mode */ }
                    .foregroundColor(.purple)
            }
            Text("Organize your recipes").foregroundColor(.secondary)
        }
    }
    
    private var myCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Categories").font(.headline.bold())
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(store.db.categories.prefix(4)) { category in
                    CategoryCardView(category: category, recipeCount: recipeCount(for: category))
                }
            }
        }
    }
    
    private var moreCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("More Categories").font(.headline.bold())
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(store.db.categories.dropFirst(4)) { category in
                    CategoryCardView(category: category, recipeCount: recipeCount(for: category))
                }
            }
        }
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recipe Statistics").font(.headline.bold())
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCardView(number: "\(store.db.recipes.count)", label: "Total Recipes", color: .purple)
                StatCardView(number: "\(store.db.categories.count)", label: "Categories", color: .green)
                StatCardView(number: "\(store.db.recipes.filter { $0.favorite }.count)", label: "Favorites", color: .orange)
                StatCardView(number: "\(recipesThisMonth)", label: "This Month", color: .yellow)
            }
        }
    }
    
    private var createCategoryButton: some View {
        Button(action: { showingAddCategory = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Create New Category")
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .foregroundColor(.primary)
    }
    
    private func recipeCount(for category: Category) -> Int {
        store.db.recipes.filter { $0.categoryId == category.id }.count
    }
    
    private var recipesThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        return store.db.recipes.filter { recipe in
            calendar.isDate(recipe.createdAt, equalTo: now, toGranularity: .month)
        }.count
    }
}

struct CategoryCardView: View {
    let category: Category
    let recipeCount: Int
    
    private let colors: [Color] = [.purple, .green, .orange, .red, .teal, .yellow, .indigo, .blue]
    private var cardColor: Color { 
        let index = abs(category.name.hash) % colors.count
        return colors[index]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.emoji ?? "📁").font(.title2)
                Spacer()
                Circle().fill(Color.white).frame(width: 6, height: 6)
            }
            Text(category.name).font(.headline).foregroundColor(.white)
            Text("\(recipeCount) recipes").font(.caption).foregroundColor(.white.opacity(0.8))
            if let lastRecipe = lastRecipe {
                Text("Last: \(lastRecipe)").font(.caption).foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }
    
    private var lastRecipe: String? {
        // TODO: Get last recipe for this category
        return "Sample"
    }
}

struct StatCardView: View {
    let number: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(number).font(.title.bold()).foregroundColor(color)
            Text(label).font(.caption).foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 1)
    }
}

struct AddCategoryView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var emoji: String = "📁"
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category Details") {
                    TextField("Category name", text: $name)
                    TextField("Emoji", text: $emoji)
                }
            }
            .navigationTitle("Add Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func save() {
        store.addCategory(Category(name: name, emoji: emoji.isEmpty ? nil : emoji))
        store.trackAfterAddingCategory()
        dismiss()
    }
}

struct CategoryRecipesView: View {
    @EnvironmentObject var store: DataStore
    let category: Category
    var body: some View {
        List(store.db.recipes.filter { $0.categoryId == category.id }) { r in
            Text(r.title)
        }
        .navigationTitle(category.name)
    }
}

struct RecipeEditorView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var minutes: String = "30"
    @State private var difficulty: RecipeDifficulty = .medium
    @State private var ingredients: [Ingredient] = []
    @State private var steps: [RecipeStep] = []
    @State private var notes: String = ""
    @State private var description: String = ""
    @State private var selectedCategory: Category?
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCategoryPicker = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    photoSection
                    recipeNameSection
                    categoryAndTimeSection
                    difficultySection
                    descriptionSection
                    ingredientsSection
                    instructionsSection
                    notesSection
                }
                .padding()
            }
            .navigationTitle("Add Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .foregroundColor(.purple)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerView(selectedCategory: $selectedCategory)
            }
        }
    }
    
    private var photoSection: some View {
        Button(action: { showingImagePicker = true }) {
            VStack(spacing: 8) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "camera")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Add a photo")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Tap to choose from gallery")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                            .foregroundColor(.gray.opacity(0.3))
                    )
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var recipeNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recipe Name").font(.headline)
            TextField("Enter recipe name...", text: $title)
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var categoryAndTimeSection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Category").font(.headline)
                Button(action: { showingCategoryPicker = true }) {
                    HStack {
                        Text(selectedCategory?.name ?? "Select category")
                            .foregroundColor(selectedCategory == nil ? .secondary : .primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Cook Time").font(.headline)
                VStack(alignment: .leading, spacing: 2) {
                    TextField("30", text: $minutes)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Text("minutes").font(.caption).foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Difficulty Level").font(.headline)
            HStack(spacing: 0) {
                ForEach(RecipeDifficulty.allCases, id: \.self) { diff in
                    Button(action: { difficulty = diff }) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .foregroundColor(difficulty == diff ? .white : .orange)
                            Text(diff.rawValue.capitalized)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .background(difficulty == diff ? LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing) : LinearGradient(colors: [.gray.opacity(0.1)], startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(difficulty == diff ? .white : .primary)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description").font(.headline)
            TextField("Tell us about this recipe...", text: $description, axis: .vertical)
                .lineLimit(3...6)
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ingredients").font(.headline)
                Spacer()
                Button("+ Add") { addIngredient() }
                    .foregroundColor(.purple)
            }
            
            ForEach(Array(ingredients.enumerated()), id: \.element.id) { index, ingredient in
                HStack(spacing: 8) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.purple)
                        .clipShape(Circle())
                    
                    TextField("e.g., 400g spaghetti", text: ingredientNameBinding(for: ingredient))
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Button(action: { removeIngredient(ingredient) }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Instructions").font(.headline)
                Spacer()
                Button("+ Add Step") { addStep() }
                    .foregroundColor(.purple)
            }
            
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                HStack(spacing: 8) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.blue)
                        .clipShape(Circle())
                    
                    TextField("Describe the first step...", text: stepTextBinding(for: step), axis: .vertical)
                        .lineLimit(2...4)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Button(action: { removeStep(step) }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Personal Notes (Optional)").font(.headline)
            TextField("Any tips, modifications, or secrets...", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private func addIngredient() {
        ingredients.append(Ingredient(name: "", quantity: nil))
    }
    
    private func removeIngredient(_ ingredient: Ingredient) {
        ingredients.removeAll { $0.id == ingredient.id }
    }
    
    private func addStep() {
        steps.append(RecipeStep(order: steps.count + 1, text: ""))
    }
    
    private func removeStep(_ step: RecipeStep) {
        steps.removeAll { $0.id == step.id }
    }
    
    private func ingredientNameBinding(for ingredient: Ingredient) -> Binding<String> {
        guard let idx = ingredients.firstIndex(of: ingredient) else { return .constant(ingredient.name) }
        return Binding(
            get: { ingredients[idx].name },
            set: { ingredients[idx].name = $0 }
        )
    }
    
    private func stepTextBinding(for step: RecipeStep) -> Binding<String> {
        guard let idx = steps.firstIndex(of: step) else { return .constant(step.text) }
        return Binding(
            get: { steps[idx].text },
            set: { steps[idx].text = $0 }
        )
    }

    private func save() {
        let minutesInt = Int(minutes)
        var imageFilename: String?
        
        if let image = selectedImage {
            do {
                imageFilename = try ImageManager.shared.saveImage(image)
            } catch {
                print("Failed to save image: \(error)")
            }
        }
        
        let new = Recipe(
            title: title,
            categoryId: selectedCategory?.id,
            imageFilename: imageFilename,
            ingredients: ingredients,
            steps: steps,
            notes: notes.isEmpty ? nil : notes,
            difficulty: difficulty,
            totalMinutes: minutesInt
        )
        store.addRecipe(new)
        store.trackAfterAddingRecipe(new)
        if !notes.isEmpty { store.trackAfterAddingNotes(1) }
        dismiss()
    }
}

struct CategoryPickerView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: Category?
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: { selectedCategory = nil; dismiss() }) {
                        HStack {
                            Text("No Category")
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedCategory == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                }
                
                Section("Available Categories") {
                    ForEach(store.db.categories) { category in
                        Button(action: { selectedCategory = category; dismiss() }) {
                            HStack {
                                Text(category.emoji ?? "📁")
                                Text(category.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedCategory?.id == category.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.purple)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct ShoppingListView: View {
    @EnvironmentObject var store: DataStore
    @State private var showingAddItem = false
    
    var groupedItems: [String: [ShoppingItem]] {
        Dictionary(grouping: store.db.shopping) { item in
            // Simple category detection based on item name
            let name = item.name.lowercased()
            if name.contains("tomato") || name.contains("basil") || name.contains("lemon") || name.contains("greens") {
                return "Produce"
            } else if name.contains("meat") || name.contains("cheese") || name.contains("egg") || name.contains("cream") || name.contains("pancetta") {
                return "Meat & Dairy"
            } else {
                return "Pantry"
            }
        }
    }
    
    var totalItems: Int { store.db.shopping.count }
    var completedItems: Int { store.db.shopping.filter { $0.checked }.count }
    var progressPercentage: Double {
        totalItems > 0 ? Double(completedItems) / Double(totalItems) : 0
    }
    
    var estimatedTotal: Double {
        store.db.shopping.reduce(0) { total, item in
            if let price = item.price {
                return total + price
            } else {
                // Fallback to mock price if no price set
                let basePrice = Double(item.name.hash % 100) / 10 + 1.0
                return total + basePrice
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 16) {
                        header
                        progressSection
                        shoppingSections
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100) // Space for total card
                }
                
                totalCard
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddItem) { AddShoppingItemView() }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Shopping List").font(.largeTitle.bold())
                Spacer()
                Button("Clear") { store.clearShopping() }
                    .foregroundColor(.purple)
            }
            Text("\(totalItems) items • \(completedItems) completed")
                .foregroundColor(.secondary)
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(Int(progressPercentage * 100))% complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(totalItems - completedItems) items left")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            ProgressView(value: progressPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: .purple))
        }
    }
    
    private var shoppingSections: some View {
        VStack(spacing: 12) {
            ForEach(Array(groupedItems.keys.sorted()), id: \.self) { category in
                ShoppingSectionView(
                    title: category,
                    items: groupedItems[category] ?? [],
                    onToggle: { item in store.toggleShoppingItem(item.id) }
                )
            }
        }
    }
    
    private var totalCard: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Estimated Total").font(.headline).foregroundColor(.white)
                    Text("\(totalItems) items").font(.caption).foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("$\(String(format: "%.2f", estimatedTotal))").font(.title.bold()).foregroundColor(.white)
                    Button(action: { showingAddItem = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding()
        .background(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

struct ShoppingSectionView: View {
    let title: String
    let items: [ShoppingItem]
    let onToggle: (ShoppingItem) -> Void
    
    private var completedCount: Int { items.filter { $0.checked }.count }
    private var totalCount: Int { items.count }
    
    private var categoryIcon: String {
        switch title {
        case "Produce": return "leaf.fill"
        case "Meat & Dairy": return "fork.knife"
        case "Pantry": return "archivebox.fill"
        default: return "folder.fill"
        }
    }
    
    private var categoryColor: Color {
        switch title {
        case "Produce": return .green
        case "Meat & Dairy": return .red
        case "Pantry": return .orange
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: categoryIcon)
                        .foregroundColor(categoryColor)
                    Text(title).font(.headline)
                }
                Spacer()
                Text("\(completedCount)/\(totalCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                ForEach(items) { item in
                    ShoppingItemRow(item: item, onToggle: { onToggle(item) })
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }
}

struct ShoppingItemRow: View {
    let item: ShoppingItem
    let onToggle: () -> Void
    
    private var displayPrice: String {
        if let price = item.price {
            return String(format: "$%.2f", price)
        } else {
            // Fallback to mock price if no price set
            let basePrice = Double(item.name.hash % 100) / 10 + 1.0
            return String(format: "$%.2f", basePrice)
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.checked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.checked ? .green : .gray)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                    .strikethrough(item.checked)
                    .foregroundColor(item.checked ? .secondary : .primary)
                
                if let quantity = item.quantity {
                    Text(quantity)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(displayPrice)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AddShoppingItemView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var quantity: Int = 1
    @State private var unit: String = "pcs"
    @State private var category: String = ""
    @State private var priority: String = "Medium"
    @State private var notes: String = ""
    
    private let units = ["pcs", "kg", "g", "L", "ml", "cup", "tbsp", "tsp"]
    private let priorities = ["High", "Medium", "Low"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    itemNameSection
                    quantitySection
                    unitSection
                    categorySection
                    prioritySection
                    notesSection
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
            }
            Spacer()
            Text("Add to Shopping List")
                .font(.headline.bold())
                .foregroundColor(.white)
            Spacer()
            // Invisible spacer to center title
            Color.clear.frame(width: 24, height: 24)
        }
        .padding()
        .background(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
    }
    
    private var itemNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Item Name").font(.headline)
            HStack {
                TextField("Enter item name...", text: $name)
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var quantitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quantity").font(.headline)
            HStack {
                Button(action: { if quantity > 1 { quantity -= 1 } }) {
                    Image(systemName: "minus")
                        .foregroundColor(.purple)
                }
                .frame(width: 40, height: 40)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Text("\(quantity)")
                    .font(.headline)
                    .frame(minWidth: 40)
                
                Button(action: { quantity += 1 }) {
                    Image(systemName: "plus")
                        .foregroundColor(.purple)
                }
                .frame(width: 40, height: 40)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    private var unitSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Unit").font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                ForEach(units, id: \.self) { unitOption in
                    Button(action: { unit = unitOption }) {
                        Text(unitOption)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(unit == unitOption ? Color.purple : Color.gray.opacity(0.1))
                            .foregroundColor(unit == unitOption ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
    }
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category").font(.headline)
            HStack {
                TextField("Enter category (e.g., Dairy, Meat, Ve)", text: $category)
                Text("🛒")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Priority").font(.headline)
            HStack(spacing: 12) {
                ForEach(priorities, id: \.self) { priorityOption in
                    Button(action: { priority = priorityOption }) {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(priorityColor(for: priorityOption))
                                .frame(width: 12, height: 12)
                            Text(priorityOption)
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(priority == priorityOption ? priorityColor(for: priorityOption).opacity(0.1) : Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes (Optional)").font(.headline)
            TextField("Add any notes or specifications...", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: addItem) {
                Text("Add to Shopping List")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            Button(action: addAnotherItem) {
                Text("Add Another Item")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    private func priorityColor(for priority: String) -> Color {
        switch priority {
        case "High": return .red
        case "Medium": return .yellow
        case "Low": return .green
        default: return .gray
        }
    }
    
    private func addItem() {
        let newItem = ShoppingItem(
            name: name,
            quantity: "\(quantity) \(unit)"
        )
        store.addShoppingItems([newItem])
        dismiss()
    }
    
    private func addAnotherItem() {
        addItem()
        // Reset form for another item
        name = ""
        quantity = 1
        unit = "pcs"
        category = ""
        priority = "Medium"
        notes = ""
    }
}

struct FavoritesView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedFilter: String = "All"
    
    var favoriteRecipes: [Recipe] { store.db.recipes.filter { $0.favorite } }
    
    var filteredRecipes: [Recipe] {
        switch selectedFilter {
        case "Recent":
            return favoriteRecipes.sorted { $0.createdAt > $1.createdAt }
        case "Most Cooked":
            // Mock data for "cooked" count - in real app this would be tracked
            return favoriteRecipes.sorted { $0.title < $1.title }
        default:
            return favoriteRecipes
        }
    }
    
    var filters = ["All", "Recent", "Most Cooked"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    filterTabs
                    recipeCards
                    statsSection
                    achievementsSection
                }
                .padding(.horizontal)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("My Favorites")
                    .font(.largeTitle.bold())
                Spacer()
                HStack(spacing: 16) {
                    Button(action: { /* TODO: Filter action */ }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.purple)
                    }
                    Button(action: { /* TODO: Layout action */ }) {
                        Image(systemName: "square.grid.2x2")
                            .foregroundColor(.purple)
                    }
                }
            }
            Text("\(favoriteRecipes.count) beloved recipes")
                .foregroundColor(.secondary)
        }
    }
    
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.self) { filter in
                    Button(action: { selectedFilter = filter }) {
                        Text(filter == "All" ? "All (\(favoriteRecipes.count))" : filter)
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedFilter == filter ? Color.purple : Color.white)
                            .foregroundColor(selectedFilter == filter ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(radius: 1)
                    }
                }
            }
            .padding(.horizontal, 1)
        }
    }
    
    private var recipeCards: some View {
        LazyVStack(spacing: 16) {
            ForEach(Array(filteredRecipes.enumerated()), id: \.element.id) { index, recipe in
                FavoriteRecipeCard(recipe: recipe, isFirst: index == 0)
            }
        }
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Favorite Stats")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            HStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(favoriteRecipes.count * 4)x")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    Text("Times Cooked")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("4.8")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    Text("Avg Rating")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            
            Text("Most popular: \(favoriteRecipes.first?.title ?? "No favorites yet")")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("My Favorite Achievements")
                .font(.title2.bold())
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(achievementData, id: \.key) { achievement in
                    AchievementCard(achievement: achievement)
                }
            }
        }
    }
    
    private var achievementData: [AchievementData] {
        [
            AchievementData(
                key: .firstCard,
                title: "First Card",
                description: "Add your first recipe to the app.",
                icon: "plus.circle.fill",
                color: .green,
                isUnlocked: store.db.achievements.unlocked.contains(.firstCard)
            ),
            AchievementData(
                key: .tenRecipes,
                title: "Collector",
                description: "Add 10 recipes to the app.",
                icon: "book.fill",
                color: .blue,
                isUnlocked: store.db.achievements.unlocked.contains(.tenRecipes)
            ),
            AchievementData(
                key: .twentyFiveRecipes,
                title: "Gastronomic Expert",
                description: "Add 25 recipes.",
                icon: "star.fill",
                color: .purple,
                isUnlocked: store.db.achievements.unlocked.contains(.twentyFiveRecipes)
            ),
            AchievementData(
                key: .fiveCategories,
                title: "Category Master",
                description: "Create 5 different recipe categories.",
                icon: "folder.fill",
                color: .orange,
                isUnlocked: store.db.achievements.unlocked.contains(.fiveCategories)
            ),
            AchievementData(
                key: .fiveFavorites,
                title: "Favorite Dish",
                description: "Mark 5 recipes as favorites.",
                icon: "heart.fill",
                color: .red,
                isUnlocked: store.db.achievements.unlocked.contains(.fiveFavorites)
            ),
            AchievementData(
                key: .tenNotes,
                title: "Advisor",
                description: "Add 10 mini-notes to different recipes.",
                icon: "lightbulb.fill",
                color: .yellow,
                isUnlocked: store.db.achievements.unlocked.contains(.tenNotes)
            ),
            AchievementData(
                key: .under30Chef,
                title: "Quick Chef",
                description: "Add a recipe with cooking time less than 30 minutes.",
                icon: "bolt.fill",
                color: .cyan,
                isUnlocked: store.db.achievements.unlocked.contains(.under30Chef)
            ),
            AchievementData(
                key: .hardChef,
                title: "Hard Chef",
                description: "Add a recipe with high difficulty level.",
                icon: "crown.fill",
                color: .indigo,
                isUnlocked: store.db.achievements.unlocked.contains(.hardChef)
            ),
            AchievementData(
                key: .shoppingFive,
                title: "Shopping List Ready",
                description: "Use shopping list for 5 recipes.",
                icon: "cart.fill",
                color: .mint,
                isUnlocked: store.db.achievements.unlocked.contains(.shoppingFive)
            ),
            AchievementData(
                key: .fiftyRecipes,
                title: "Complete Collection",
                description: "Add 50 recipes to the app.",
                icon: "archivebox.fill",
                color: .brown,
                isUnlocked: store.db.achievements.unlocked.contains(.fiftyRecipes)
            ),
            AchievementData(
                key: .tenPhotos,
                title: "Photo Master",
                description: "Add photos to 10 recipes.",
                icon: "camera.fill",
                color: .pink,
                isUnlocked: store.db.achievements.unlocked.contains(.tenPhotos)
            ),
            AchievementData(
                key: .trueChef,
                title: "True Chef",
                description: "Use all app features: categories, notes, shopping list, ratings and photos.",
                icon: "crown.fill",
                color: .purple,
                isUnlocked: store.db.achievements.unlocked.contains(.trueChef)
            )
        ]
    }
}

struct AchievementData {
    let key: AchievementKey
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isUnlocked: Bool
}

struct AchievementCard: View {
    let achievement: AchievementData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: achievement.icon)
                    .foregroundColor(achievement.isUnlocked ? achievement.color : .gray)
                    .font(.title2)
                
                Spacer()
                
                if achievement.isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            
            Text(achievement.title)
                .font(.headline)
                .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
            
            Text(achievement.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding()
        .background(achievement.isUnlocked ? achievement.color.opacity(0.1) : Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(achievement.isUnlocked ? achievement.color : Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct FavoriteRecipeCard: View {
    let recipe: Recipe
    let isFirst: Bool
    
    private var mockCookedCount: Int {
        // Mock data - in real app this would be tracked
        Int.random(in: 5...20)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let fn = recipe.imageFilename, let ui = ImageManager.shared.loadImage(named: fn) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(height: isFirst ? 200 : 120)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Heart icon
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                    .padding(8)
                
                // Badges
                VStack(alignment: .leading, spacing: 4) {
                    if isFirst {
                        HStack {
                            Image(systemName: "star.fill")
                            Text("Top Favorite")
                        }
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    
                    Spacer()
                    
                    HStack {
                        Text("Cooked \(mockCookedCount)x")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        
                        Spacer()
                    }
                }
                .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(recipe.title)
                        .font(isFirst ? .title2.bold() : .headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if !isFirst {
                        Text("Cooked \(mockCookedCount)x")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(recipe.notes ?? "Delicious recipe")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    if let minutes = recipe.totalMinutes {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text("\(minutes) min")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame")
                        Text(recipe.difficulty.rawValue.capitalized)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    if let categoryId = recipe.categoryId,
                       let category = DataStore().db.categories.first(where: { $0.id == categoryId }) {
                        HStack(spacing: 4) {
                            Text(category.emoji ?? "📁")
                            Text(category.name)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5) { _ in
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }
}

struct SettingsView: View {
    @EnvironmentObject var store: DataStore
    @State private var showingProfileEdit = false
    @State private var showingLanguagePicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    profileSection
                    appPreferencesSection
                    dangerZoneSection
                }
                .padding(.horizontal)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingProfileEdit) { ProfileEditView() }
            .sheet(isPresented: $showingLanguagePicker) { LanguagePickerView() }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Settings")
                .font(.largeTitle.bold())
            Text("Customize your experience")
                .foregroundColor(.secondary)
        }
    }
    
    private var profileSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 60, height: 60)
                    Image(systemName: avatarSymbol(for: store.db.profile.avatarIndex))
                        .foregroundColor(.purple)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.db.profile.nickname)
                        .font(.headline.bold())
                    Text("Recipe enthusiast since \(Calendar.current.component(.year, from: store.db.profile.joinDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(store.db.recipes.count) recipes • \(store.db.recipes.filter { $0.favorite }.count) favorites")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
                
                Spacer()
                
                Button("Edit") { showingProfileEdit = true }
                    .foregroundColor(.purple)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }

    private func avatarSymbol(for index: Int) -> String {
        let icons = ["person.circle.fill","fork.knife.circle.fill","flame.circle.fill","leaf.circle.fill","cup.and.saucer.fill","camera.circle.fill","cart.circle.fill","book.circle.fill","star.circle.fill"]
        return icons.indices.contains(index) ? icons[index] : icons[0]
    }
    
    private var appPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("App Preferences")
                .font(.headline.bold())
            
            VStack(spacing: 0) {
                SettingRow(
                    icon: "moon.fill",
                    iconColor: .purple,
                    title: "Dark Mode",
                    subtitle: "Switch to dark theme",
                    type: .toggle(Binding(
                        get: { store.db.settings.theme == .dark },
                        set: { isOn in
                            store.db.settings.theme = isOn ? .dark : .light
                            store.save()
                        }
                    ))
                )
                
                SettingRow(
                    icon: "globe",
                    iconColor: .blue,
                    title: "Language",
                    subtitle: store.db.settings.language == .en ? "English" : "Русский",
                    type: .navigation { showingLanguagePicker = true }
                )
            }
        }
    }
    
    
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Danger Zone")
                .font(.headline.bold())
                .foregroundColor(.red)
            
            VStack(spacing: 0) {
                SettingRow(
                    icon: "trash.fill",
                    iconColor: .red,
                    title: "Clear All Data",
                    subtitle: "This cannot be undone",
                    type: .navigation { /* TODO: Clear data */ }
                )
            }
            .padding()
            .background(Color.red.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

enum SettingRowType {
    case toggle(Binding<Bool>)
    case navigation(() -> Void)
}

struct SettingRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let type: SettingRowType
    
    var body: some View {
        Button(action: {
            if case .navigation(let action) = type {
                action()
            }
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.title3)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                switch type {
                case .toggle(let binding):
                    Toggle("", isOn: binding)
                        .labelsHidden()
                case .navigation:
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProfileEditView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var nickname: String = ""
    @State private var selectedAvatar: Int = 0

    private let avatarIcons = ["person.circle.fill","fork.knife.circle.fill","flame.circle.fill","leaf.circle.fill","cup.and.saucer.fill","camera.circle.fill","cart.circle.fill","book.circle.fill","star.circle.fill"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar grid
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose Avatar").font(.headline)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                            ForEach(avatarIcons.indices, id: \.self) { idx in
                                Button(action: { selectedAvatar = idx }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedAvatar == idx ? Color.purple.opacity(0.15) : Color.gray.opacity(0.08))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(selectedAvatar == idx ? Color.purple : Color.clear, lineWidth: 2)
                                            )
                                        Image(systemName: avatarIcons[idx]).font(.title).foregroundColor(.purple)
                                    }
                                    .frame(height: 64)
                                }
                            }
                        }
                    }

                    // Nickname section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nickname").font(.headline)
                        TextField("Enter your nickname", text: $nickname)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding()
                .onAppear {
                    nickname = store.db.profile.nickname
                    selectedAvatar = store.db.profile.avatarIndex
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        store.db.profile.nickname = nickname
                        store.db.profile.avatarIndex = selectedAvatar
                        store.save()
                        dismiss()
                    }.disabled(nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct LanguagePickerView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    store.db.settings.language = .en
                    store.save()
                    dismiss()
                }) {
                    HStack {
                        Text("English")
                        Spacer()
                        if store.db.settings.language == .en {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Button(action: {
                    store.db.settings.language = .ru
                    store.save()
                    dismiss()
                }) {
                    HStack {
                        Text("Русский")
                        Spacer()
                        if store.db.settings.language == .ru {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}



