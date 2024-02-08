//
//  RootView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                MapView(geo: geo)
                    .ignoresSafeArea()
                
                VStack {
                    CarbonCopy()
                        .id(scenePhase)
                        .blur(radius: 10)
                        .ignoresSafeArea()
                    Spacer()
                        .layoutPriority(1)
                }
                
                MapButtons()
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
}
