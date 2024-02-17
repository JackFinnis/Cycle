//
//  CycleApp.swift
//  Cycle
//
//  Created by Jack Finnis on 08/10/2022.
//

import SwiftUI
import MapKit

@main
struct CycleApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// https://cycling.data.tfl.gov.uk/CycleRoutes/CycleRoutes.json
let routes: [Route] = {
    let file = Bundle.main.url(forResource: "CycleRoutes", withExtension: "geojson")!
    let data = try! Data(contentsOf: file)
    let features = try! MKGeoJSONDecoder().decode(data) as! [MKGeoJSONFeature]
    
    return features.flatMap { feature -> [Route] in
        let geometry = feature.geometry.first!
        let properties = try! JSONDecoder().decode(RouteProperties.self, from: feature.properties!)
        guard properties.Status == .open else { return [] }
        
        if let polyline = geometry as? MKPolyline {
            return [Route(id: properties.Label, polyline: polyline)]
        } else if let multiPolyline = geometry as? MKMultiPolyline {
            return multiPolyline.polylines.map { Route(id: properties.Label, polyline: $0) }
        }
        return []
    }
}()
