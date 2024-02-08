//
//  CycleApp.swift
//  Cycle
//
//  Created by Jack Finnis on 08/10/2022.
//

import SwiftUI

// https://cycling.data.tfl.gov.uk/CycleRoutes/CycleRoutes.json

@main
struct CycleApp: App {
    @StateObject var app = AppState.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(app)
        }
    }
}
