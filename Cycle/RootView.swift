//
//  RootView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI

struct RootView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject var vm = ViewModel()
    
    var background: Material { colorScheme == .light ? .regularMaterial : .thickMaterial }

    var body: some View {
        ZStack {
            MapView()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Blur()
                    .ignoresSafeArea()
                Spacer()
                    .layoutPriority(1)
            }
            
            VStack {
                Spacer()
                if let name = vm.selectedRouteName {
                    Text(name)
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(background)
                        .cornerRadius(10)
                        .shadow(color: Color(UIColor.systemFill), radius: 5)
                        .padding(10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onTapGesture(perform: vm.zoomToSelected)
                }
            }
            .animation(.default, value: vm.selectedRouteName)
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingButtons(background: background)
                }
            }
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
