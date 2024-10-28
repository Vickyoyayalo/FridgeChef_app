//
//  GoogleServiceInfo.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/16.
//

import Foundation
import UniformTypeIdentifiers

enum GoogleServiceInfo {
    struct ApiKeyData: Decodable {
        let apiKey: String
    }
    
    static var `default` = {
        guard let fileURL = Bundle.main.url(forResource: "\(Self.self)", withExtension: UTType.propertyList.preferredFilenameExtension) else {
            fatalError("Couldn't find file APIKey.plist")
        }
        guard let data = try? Data(contentsOf: fileURL) else {
            fatalError("Couldn't read data from APIKey.plist")
        }
        guard let apiKey = try? PropertyListDecoder().decode(ApiKeyData.self, from: data).apiKey else {
            fatalError("Couldn't find key apiKey")
        }
        return apiKey
    }()
}
