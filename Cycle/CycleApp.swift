//
//  CycleApp.swift
//  Cycle
//
//  Created by Jack Finnis on 08/10/2022.
//

import SwiftUI

let SIZE = 48.0
let NAME = "CycleLane"

// Cycle data from https://cycling.data.tfl.gov.uk/CycleRoutes/CycleRoutes.json

@main
struct CycleApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
