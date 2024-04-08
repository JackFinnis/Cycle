//
//  Route.swift
//  Cycle
//
//  Created by Jack Finnis on 17/02/2024.
//

import Foundation
import MapKit

class Route: NSObject {
    let id: String
    let multiPolyline: MKMultiPolyline
    
    init(id: String, multiPolyline: MKMultiPolyline) {
        self.id = id
        self.multiPolyline = multiPolyline
    }
}

extension Route: MKOverlay {
    var coordinate: CLLocationCoordinate2D { multiPolyline.coordinate }
    var boundingMapRect: MKMapRect { multiPolyline.boundingMapRect }
}

struct RouteProperties: Codable {
    let Label: String
    let Status: RouteStatus
}

enum RouteStatus: String, Codable {
    case planned = "Planned"
    case inProgress = "In Progress"
    case open = "Open"
}
