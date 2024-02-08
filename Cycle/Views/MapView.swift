//
//  MapView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @EnvironmentObject var app: AppState
    
    let geo: GeometryProxy
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = app
        app.mapView = mapView
        mapView.addOverlays(app.routes, level: .aboveRoads)
        
        let compass = MKCompassButton(mapView: mapView)
        mapView.showsCompass = false
        mapView.addSubview(compass)
        
        compass.translatesAutoresizingMaskIntoConstraints = false
        compass.trailingAnchor.constraint(
            equalTo: mapView.trailingAnchor,
            constant: -(geo.safeAreaInsets.trailing + Constants.size + 20)
        ).isActive = true
        compass.topAnchor.constraint(
            equalTo: mapView.topAnchor,
            constant: geo.safeAreaInsets.top + 10
        ).isActive = true
        let tap = UITapGestureRecognizer(target: AppState.shared, action: #selector(AppState.tappedCompass))
        tap.delegate = AppState.shared
        compass.addGestureRecognizer(tap)
        
        mapView.showsUserLocation = true
        mapView.showsScale = true
        mapView.isPitchEnabled = true
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMarkerAnnotationView.id)
        mapView.selectableMapFeatures = [.physicalFeatures, .pointsOfInterest, .territories]
        
        let tapRecognizer = UITapGestureRecognizer(target: app, action: #selector(AppState.handleTap))
        mapView.addGestureRecognizer(tapRecognizer)
        let longPressRecognizer = UILongPressGestureRecognizer(target: app, action: #selector(AppState.handlePress))
        mapView.addGestureRecognizer(longPressRecognizer)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {}
}
