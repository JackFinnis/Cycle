//
//  RootView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI

struct RootView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject var vm = ViewModel.shared
    
    var background: Material { colorScheme == .light ? .regularMaterial : .thickMaterial }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            MapView()
                .ignoresSafeArea()
            
            VStack {
                CarbonCopy()
                    .id(colorScheme)
                    .blur(radius: 10, opaque: true)
                    .ignoresSafeArea()
                Spacer()
                    .layoutPriority(1)
            }
            
            MapButtons()
        }
        .environmentObject(vm)
        .alert("Access Denied", isPresented: $vm.showAuthAlert) {
            Button("Maybe Later") {}
            Button("Settings", role: .cancel) {
                vm.openSettings()
            }
        } message: {
            Text("\(Constants.name) needs access to your location to show where you are on the map. Please go to Settings > \(Constants.name) > Location and allow access while using the app.")
        }
    }
}
