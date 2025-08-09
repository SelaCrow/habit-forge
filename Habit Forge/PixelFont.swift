//
//  PixelFont.swift
//  Habit Forge
//
//  Created by Marisela Gomez on 8/5/25.
//


import SwiftUI

struct PixelFont: ViewModifier {
    var size: CGFloat
    
    func body(content: Content) -> some View {
        content
            .font(.custom("ThaleahFat", size: size))
    }
}

extension View {
    func pixelFont(size: CGFloat) -> some View {
        self.modifier(PixelFont(size: size))
    }
}
