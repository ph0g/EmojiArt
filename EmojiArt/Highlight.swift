//
//  Selection.swift
//  EmojiArt
//
//  Created by Pierre-Hugues Oger on 02/06/2023.
//

import SwiftUI

struct Highlight: ViewModifier {
    let isOn: Bool
    
    func body(content: Content) -> some View {
        Group {
            if isOn {
                content
                    .colorMultiply(Color.red)
            } else {
                content
            }
        }
    }
}

extension View {
    func highlight(if isOn: Bool) -> some View {
        modifier(Highlight(isOn: isOn))
    }
}
