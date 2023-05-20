//
//  Array.swift
//  Cycle
//
//  Created by Jack Finnis on 20/05/2023.
//

import Foundation
import MapKit

extension Array where Element: MKOverlay {
    var rect: MKMapRect {
        reduce(.null) { $0.union($1.boundingMapRect) }
    }
}
