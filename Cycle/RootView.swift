//
//  RootView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI

struct RootView: View {
    @StateObject var vm = ViewModel()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            MapView()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Blur()
                    .ignoresSafeArea()
                Spacer()
                    .layoutPriority(1)
            }
            
            FloatingButtons()
        }
        .environmentObject(vm)
        .onAppear {
            vm.loadData()
        }
        .alert("Grant Access", isPresented: $vm.showAlert) {
            Button("Maybe Later") {}
            Button("Open Settings", role: .cancel) {
                vm.openSettings()
            }
        } message: {
            Text("\(NAME) needs access to your location to show you where you are on the map. Please grant access in Settings.")
        }
    }
}
