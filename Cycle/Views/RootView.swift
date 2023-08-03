//
//  RootView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.colorScheme) var colorScheme
    @StateObject var vm = ViewModel.shared

    var body: some View {
        ZStack(alignment: .topTrailing) {
            MapView()
                .ignoresSafeArea()
            
            VStack {
                CarbonCopy()
                    .id(scenePhase)
                    .blur(radius: 10, opaque: true)
                    .ignoresSafeArea()
                Spacer()
                    .layoutPriority(1)
            }
            
            MapButtons()
        }
        .environmentObject(vm)
    }
}
