//
//  SearchAndFilterView.swift
//  food
//
//  Created by Abu Anwar MD Abdullah on 25/1/21.
//

import SwiftUI

struct SearchAndFilterView: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack(spacing: 16) {
                   
            HStack {
                Image(uiImage: #imageLiteral(resourceName: "search"))
                TextField("Search my favorites", text: $searchText)
                
            }
            .padding(8)
            .background(Color.lightGray).opacity(0.7)
            .cornerRadius(8)
        }
    }
}
