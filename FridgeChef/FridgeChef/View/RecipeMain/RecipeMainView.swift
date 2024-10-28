//
//  RecipeMainView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/06.

import SwiftUI

struct RecipeMainView: View {
    @EnvironmentObject var viewModel: RecipeSearchViewModel
    @State private var showingAddGroceryForm = false
    @State private var searchQuery: String = ""
    @State private var isShowingDefaultPage = true
    @State private var selectedRecipe: Recipe? = nil
    var showEditAndAddButtons: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
              
                LinearGradient(
                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.4)
                .edgesIgnoringSafeArea(.all)

                VStack {
                    if isShowingDefaultPage {
                        DefaultRecipeView(recipeManager: RecipeManager())
                    } else {
                        if viewModel.isLoading {
                            Spacer()
                            ProgressView()
                                .scaleEffect(1.5)
                            Spacer()
                        } else if !viewModel.recipes.isEmpty {
                           
                            List(viewModel.recipes, id: \.id) { recipe in
                                RecipeRowView(recipe: recipe, toggleFavorite: {
                                    viewModel.toggleFavorite(for: recipe.id)
                                }, viewModel: RecipeSearchViewModel())
                                .onTapGesture {
                                    selectedRecipe = recipe
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                            .listStyle(PlainListStyle())
                        } else if let errorMessage = viewModel.errorMessage {
                            
                            Spacer()
                            Text("wrong：\(errorMessage.message)")
                                .foregroundColor(.red)
                                .padding()
                            Spacer()
                        } else {
                         
                            Spacer()
                            Text("Opps...Let's try again.. \nSearch by keywords🕵🏻‍♂️")
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                }
                .navigationTitle("Recipe 👩🏻‍🍳")
                .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search recipes")
                .onSubmit(of: .search) {
                    if !searchQuery.isEmpty {
                        isShowingDefaultPage = false
                        viewModel.searchRecipes(query: searchQuery)
                    } else {
                        isShowingDefaultPage = true
                    }
                }
                .alert(item: $viewModel.errorMessage) { errorMessage in
                    Alert(
                        title: Text("Error"),
                        message: Text(errorMessage.message),
                        dismissButton: .default(Text("Sure")) {
                            viewModel.errorMessage = nil
                        }
                    )
                }
                .sheet(isPresented: $showingAddGroceryForm) {
                    AddGroceryForm(viewModel: AddGroceryFormViewModel())
                }
            }
            .navigationBarItems(
                leading: showEditAndAddButtons ? EditButton().bold() : nil,
                trailing: showEditAndAddButtons ? addButton : nil
            )
            .background(
                NavigationLink(
                    destination: selectedRecipe.map { RecipeDetailView(recipeId: $0.id) },
                    isActive: Binding(
                        get: { selectedRecipe != nil },
                        set: { if !$0 { selectedRecipe = nil } }
                    ),
                    label: { EmptyView() } 
                )
            )
        }
    }

    var addButton: some View {
        Button(action: {
            showingAddGroceryForm = true
        }) {
            Image(systemName: "plus")
                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                .bold()
        }
    }
}

struct RecipeMainView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeMainView()
            .environmentObject(RecipeSearchViewModel())
    }
}
