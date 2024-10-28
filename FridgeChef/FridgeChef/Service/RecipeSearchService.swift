//
//  RecipeSearchService.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/28.
//

import Foundation

// MARK: - APIErrorResponse
struct APIErrorResponse: Codable {
    let code: Int?
    let message: String?
    let status: String?
}

// MARK: - RecipeSearchService
class RecipeSearchService {
    private let apiKey = ""
    private let baseURL = "https://api.spoonacular.com/recipes"
    
    func fetchData<T: Codable>(url: URL, completion: @escaping (Result<T, Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Data Task Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            guard let data = data else {
                let noDataError = NSError(domain: "No Data", code: 0, userInfo: nil)
                print("Data Task Error: No Data")
                completion(.failure(noDataError))
                return
            }
            
            if let rawString = String(data: data, encoding: .utf8) {
                print("Raw Response Data: \(rawString)")
            }
            
            do {
                let decoder = JSONDecoder()
                let decodedResponse = try decoder.decode(T.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                print("Decoding Error: \(error)")
                do {
                    let decoder = JSONDecoder()
                    let apiError = try decoder.decode(APIErrorResponse.self, from: data)
                    if let message = apiError.message {
                        print("API Error: \(message)")
                        let apiErrorMsg = NSError(domain: "API Error", code: apiError.code ?? 0, userInfo: [NSLocalizedDescriptionKey: message])
                        completion(.failure(apiErrorMsg))
                    } else {
                        completion(.failure(error))
                    }
                } catch {
                    print("Decoding or API Error: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }


    func searchRecipes(query: String, maxFat: Int?, completion: @escaping (Result<RecipeSearchResponse, Error>) -> Void) {
        var components = URLComponents(string: "\(baseURL)/complexSearch")!
        
        var queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "number", value: "10"),
            URLQueryItem(name: "addRecipeInformation", value: "true")
        ]
        
        if let maxFat = maxFat {
            queryItems.append(URLQueryItem(name: "maxFat", value: "\(maxFat)"))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        print("Fetching URL: \(url.absoluteString)")
        fetchData(url: url, completion: completion)
    }
    
    func getRecipeInformation(recipeId: Int, completion: @escaping (Result<RecipeDetails, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/\(recipeId)/information?apiKey=\(apiKey)&includeNutrition=false")!
        
        print("Fetching URL: \(url.absoluteString)") 
        
        fetchData(url: url, completion: completion)
    }
}
