//
//  Route.swift
//  Cycle
//
//  Created by Jack Finnis on 13/10/2022.
//

import Foundation
import MapKit

class Route: NSObject {
    let id: String
    let polyline: MKPolyline
    
    init(id: String, polyline: MKPolyline) {
        self.id = id
        self.polyline = polyline
    }
}

extension Route: MKOverlay {
    var coordinate: CLLocationCoordinate2D { polyline.coordinate }
    var boundingMapRect: MKMapRect { polyline.boundingMapRect }
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
