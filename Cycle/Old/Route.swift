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
