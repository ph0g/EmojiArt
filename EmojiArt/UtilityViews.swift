//
//  UtilityViews.swift
//  EmojiArt
//
//  Created by Pierre-Hugues Oger on 26/05/2023.
//

import SwiftUI

// syntactic sure to be abale to pass an optional UIImage to Image
// (normally it would only take a non-optional UIImage)

struct OptionalImage: View {
    var uiImage: UIImage?
    
    var body: some View {
        if uiImage != nil {
            Image(uiImage: uiImage!)
        }
    }
}
