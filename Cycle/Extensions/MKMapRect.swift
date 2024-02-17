//
//  MKMapRect.swift
//  Cycle
//
//  Created by Jack Finnis on 17/02/2024.
//

import Foundation
import MapKit

extension MKMapRect {
    func padding(_ distance: Double) -> MKMapRect {
        insetBy(dx: -distance, dy: -distance)
    }
}
