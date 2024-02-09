//
//  View.swift
//  Geojson
//
//  Created by Jack Finnis on 19/11/2022.
//

import SwiftUI

extension View {
    func squareButton() -> some View {
        self.font(.system(size: Constants.size/2))
            .frame(width: Constants.size, height: Constants.size)
    }
    
    func blurBackground() -> some View {
        self.background(.thickMaterial)
            .clipShape(.rect(cornerRadius: 10))
            .compositingGroup()
            .shadow(color: Color.black.opacity(0.2), radius: 5, y: 5)
    }
}
