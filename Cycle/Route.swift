//
//  Route.swift
//  Cycle
//
//  Created by Jack Finnis on 13/10/2022.
//

import Foundation
import MapKit

class Route: MKPolyline {
    var name = ""
    var status = Status.open
}

struct RouteData: Codable {
    let Label: String
    let Status: String
}

enum Status: String {
    case planned = "Planned"
    case inProgress = "In Progress"
    case open = "Open"
}
