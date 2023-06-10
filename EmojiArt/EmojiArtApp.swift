//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Pierre-Hugues Oger on 14/05/2023.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    let document = EmojiArtDocument()
    let paletteStore = PaletteStore(named: "Default")
    
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: document)
        }
    }
}
