//
//  RecipeDetailView.swift
//  WhatToEat
//
//  Created by Vickyhereiam on 2024/9/27.
 
import SwiftUI
import IQKeyboardManagerSwift
import FirebaseAuth

struct RecipeDetailView: View {
    let recipeId: Int
    @EnvironmentObject var viewModel: RecipeSearchViewModel
    @EnvironmentObject var foodItemStore: FoodItemStore
    @State private var inputServings: String = ""
    @State private var animate = false
    @State private var ratingScore: Int = 5
    @State private var commentUser: String = ""
    @State private var commentText: String = ""
    @State private var isLoading = false
    
    let primaryColor = Color(UIColor(named: "NavigationBarTitle") ?? .orange)
    let secondaryColor = Color.white
    let tagColor = Color(UIColor(named: "SecondaryColor") ?? .black)
    
    @State private var activeAlert: ActiveAlert?
    @State private var showAddedLabel = false
    @State private var isButtonDisabled = false
    
    var body: some View {
        ZStack {
       
            LinearGradient(
                gradient: Gradient(colors: [Color.yellow, Color.orange]),
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(0.3)
            .edgesIgnoringSafeArea(.all)
            
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    IQKeyboardManager.shared.resignFirstResponder()
                }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let recipe = viewModel.selectedRecipe {
                        ZStack(alignment: .topTrailing) {
                            if let imageUrl = recipe.image {
                                AsyncImage(url: URL(string: imageUrl)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 250)
                                        .cornerRadius(15)
                                        .shadow(radius: 10)
                                        .padding([.leading, .trailing, .bottom], 15)
                                        .padding(.top, 30)
                                } placeholder: {
                                    ProgressView()
                                        .frame(height: 250)
                                }
                            } else {
                                Image("RecipeFood")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 250)
                                    .cornerRadius(15)
                                    .shadow(radius: 5)
                                    .foregroundColor(.gray)
                                    .background(Color.white.opacity(0.6))
                                    .padding([.leading, .trailing, .bottom], 15)
                                    .padding(.top, 20)
                            }
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.toggleFavorite(for: recipeId)
                                    animate = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    animate = false
                                }
                            }) {
                                Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                                    .foregroundColor(recipe.isFavorite ? primaryColor : Color.gray)
                                    .padding(10)
                                    .background(Color.white.opacity(0.8))
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                                    .scaleEffect(animate ? 1.5 : 1.0)
                                    .opacity(animate ? 0.5 : 1.0)
                                    .animation(.easeInOut(duration: 0.3), value: animate)
                            }
                            .padding(.top, 40)
                            .padding(.trailing, 25)
                        }
                        .frame(height: 250)
                        
                        Text(recipe.title)
                            .font(.custom("ArialRoundedMTBold", size: 25))
                            .foregroundColor(primaryColor.opacity(0.9))
                            .padding(.horizontal)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack {
                            Label("\(recipe.servings) servings", systemImage: "person.2")
                            Spacer()
                            Label("\(recipe.readyInMinutes) Minutes", systemImage: "clock")
                        }
                        .font(.custom("ArialRoundedMTBold", size: 15))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        
                        SectionView(title: "Decide your serving size") {
                            HStack {
                                TextField(" 🔍 Serving Size", text: $inputServings, onCommit: {
                                    updateServings()
                                })
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.custom("ArialRoundedMTBold", size: 18))
                                
                                Button(action: {
                                    updateServings()
                                }) {
                                    Text("Go")
                                        .bold()
                                        .foregroundColor(.white)
                                        .font(.custom("ArialRoundedMTBold", size: 18))
                                        .padding(5)
                                        .background(primaryColor)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        VStack(alignment: .leading) {
                            if !recipe.cuisines.isEmpty || !recipe.dishTypes.isEmpty || !recipe.diets.isEmpty {
                                SectionView(title: "Category") {
                                    VStack(alignment: .leading, spacing: 10) {
                                        if !recipe.cuisines.isEmpty {
                                            CategoryItemView(title: "Cuisines", items: recipe.cuisines, primaryColor: primaryColor)
                                        }
                                        if !recipe.dishTypes.isEmpty {
                                            CategoryItemView(title: "Dish Types", items: recipe.dishTypes, primaryColor: primaryColor)
                                        }
                                        if !recipe.diets.isEmpty {
                                            CategoryItemView(title: "Diets", items: recipe.diets, primaryColor: primaryColor)
                                        }
                                    }
                                    .padding(.leading, 20)
                                }
                            }
                            
                            let parsedIngredients = recipe.extendedIngredients.map { extIngredient in
                                ParsedIngredient(
                                    name: extIngredient.name.capitalized,
                                    quantity: extIngredient.amount.rounded(toPlaces: 2),
                                    unit: extIngredient.unit.isEmpty ? "unit" : extIngredient.unit,
                                    expirationDate: Calendar.current.date(byAdding: .day, value: 0, to: Date()) ?? Date()
                                )
                            }
                            
                            SectionView(title: "Ingredients") {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(parsedIngredients, id: \.name) { ingredient in
                                        IngredientRow(ingredient: ingredient) { selectedIngredient in
                                          
                                            addIngredientToShoppingList(selectedIngredient)
                                        }
                                        .environmentObject(foodItemStore)
                                    }
                                   
                                    Button(action: {
                                        addAllIngredientsToCart(ingredients: parsedIngredients)
                                        isButtonDisabled = true
                                    }) {
                                        Text("Add All Ingredients to Cart")
                                            .bold()
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(primaryColor)
                                            .cornerRadius(10)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .opacity(isButtonDisabled ? 0.7 : 1.0)
                                    .disabled(isButtonDisabled)
                                    .padding(.top, 10)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 1)
                                .padding(.leading, 5)
                            }
                            
                            SectionView(title: "Instructions") {
                                if let analyzedInstructions = recipe.analyzedInstructions, !analyzedInstructions.isEmpty {
                                    ForEach(analyzedInstructions) { instruction in
                                        VStack(alignment: .leading, spacing: 10) {
                                            if !instruction.name.isEmpty {
                                                Text(instruction.name)
                                                    .font(.custom("ArialRoundedMTBold", size: 18))
                                                    .foregroundColor(primaryColor)
                                            }
                                            
                                            ForEach(instruction.steps, id: \.number) { step in
                                                StepView(step: step)
                                            }
                                        }
                                        .padding(.bottom, 10)
                                        .padding(.horizontal)
                                    }
                                } else if let instructions = recipe.instructions?.htmlDecoded(), !instructions.isEmpty {
                                    Text(instructions)
                                        .font(.custom("ArialRoundedMTBold", size: 18))
                                        .padding(.horizontal)
                                } else {
                                    Text("No Instructions")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal)
                                }
                            }
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.orange.opacity(0.3))
                                    .edgesIgnoringSafeArea(.all)
                            }
                        }
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(30, corners: [.topLeft, .topRight])
                    }
                }
                .onAppear {
                    viewModel.getRecipeDetails(recipeId: recipeId)
                }
                .navigationBarTitle("Recipe Details", displayMode: .inline)
                .alert(item: $activeAlert) { activeAlert in
                    switch activeAlert {
                    case .error(let errorMessage):
                        return Alert(
                            title: Text("Error"),
                            message: Text(errorMessage.message),
                            dismissButton: .default(Text("Sure")) {
                                viewModel.errorMessage = nil
                            }
                        )
                    case .ingredient(let message):
                        return Alert(
                            title: Text("Added to your Grocery List!"),
                            message: Text(message),
                            dismissButton: .default(Text("Sure"))
                        )
                    }
                }
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.4))
                        .edgesIgnoringSafeArea(.all)
                }
            }
            .scrollIndicators(.hidden)
        }
    }
    
    private func toggleFavorite() {
        isLoading = true

        viewModel.toggleFavorite(for: recipeId)
        
        DispatchQueue.main.async {
            isLoading = false
        }
    }
    
    // MARK: - 輔助函數

    private func updateServings() {
        if let newServings = Int(inputServings), newServings > 0 {
            viewModel.adjustServings(newServings: newServings)
        } else {
            activeAlert = .error(ErrorMessage(message: "Please insert a correct number."))
        }
    }
    
    private func addIngredientToShoppingList(_ ingredient: ParsedIngredient) -> Bool {
        let firestoreService = FirestoreService()
        
        guard let userId = Auth.auth().currentUser?.uid else {
            activeAlert = .error(ErrorMessage(message: "User not logged in."))
            return false
        }
        
        let foodItem = FoodItem(
            id: UUID().uuidString,
            name: ingredient.name.capitalized,
            quantity: ingredient.quantity,
            unit: ingredient.unit,
            status: .toBuy,
            daysRemaining: Calendar.current.dateComponents([.day], from: Date(), to: ingredient.expirationDate).day ?? 0,
            expirationDate: ingredient.expirationDate,
            imageURL: nil
        )
        
        firestoreService.addFoodItem(forUser: userId, foodItem: foodItem, image: nil) { result in
            switch result {
            case .success:
                activeAlert = .ingredient("\(ingredient.name) added to your Grocery List!")
            case .failure(let error):
                activeAlert = .error(ErrorMessage(message: "Failed to add \(ingredient.name): \(error.localizedDescription)"))
            }
        }
        
        return true
    }
    
    private func addAllIngredientsToCart(ingredients: [ParsedIngredient]) {
        var alreadyInCart = [String]()
        var addedToCart = [String]()
        
        for ingredient in ingredients {
            let success = addIngredientToShoppingList(ingredient)
            if success {
                addedToCart.append(ingredient.name)
            } else {
                alreadyInCart.append(ingredient.name)
            }
        }
        
        if !addedToCart.isEmpty {
            activeAlert = .ingredient("Added \(addedToCart.joined(separator: ", ")) to your Grocery List!")
        }
        if !alreadyInCart.isEmpty {
            activeAlert = .ingredient("Already in your Grocery List: \(alreadyInCart.joined(separator: ", "))")
        }
    }
}

struct CategoryItemView: View {
    let title: String
    let items: [String]
    let primaryColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.custom("ArialRoundedMTBold", size: 16))
                .foregroundColor(primaryColor)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("\(title):")
                    .font(.custom("ArialRoundedMTBold", size: 16))
                    .foregroundColor(.gray)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(items, id: \.self) { item in
                            TagView(text: item)
                        }
                    }
                }
            }
        }
    }
}

struct TagView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.custom("ArialRoundedMTBold", size: 15))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange).opacity(0.6))
            .foregroundColor(.white)
            .fontWeight(.medium)
            .cornerRadius(8)
    }
}

