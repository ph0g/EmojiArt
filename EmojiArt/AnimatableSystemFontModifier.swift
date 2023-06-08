//
//  AnimatableSystemFontModifier.swift
//  EmojiArt
//
//  Created by Pierre-Hugues Oger on 08/06/2023.
//

import SwiftUI

struct AnimatableSystemFontModifier: ViewModifier, Animatable {
    var size: Double

    var animatableData: Double {
        get { size }
        set { size = newValue }
    }

    func body(content: Content) -> some View {
        content
            .font(.system(size: size))
    }
}

extension View {
    func animatableSystemFont(size: Double) -> some View {
        self.modifier(AnimatableSystemFontModifier(size: size))
    }
}

