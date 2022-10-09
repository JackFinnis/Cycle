//
//  ViewModel.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import Foundation
import MapKit
import SwiftUI

class ViewModel: NSObject, ObservableObject {
    @Published var trackingMode = MKUserTrackingMode.none
    @Published var mapType = MKMapType.standard
    var mapView: MKMapView?
    var zoomedIn = false
    
    // Auth
    @Published var showAlert = false
    var status = CLAuthorizationStatus.notDetermined
    let manager = CLLocationManager()
    
    // Animations
    @Published var degrees = 0.0
    @Published var scale = 1.0
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    func loadData() {
        let file = Bundle.main.url(forResource: "CycleRoutes", withExtension: "geojson")!
        let data = try! Data(contentsOf: file)
        let features = try! MKGeoJSONDecoder().decode(data) as! [MKGeoJSONFeature]
        
        var polylines = [MKPolyline]()
        for feature in features {
            let geometry = feature.geometry.first!
            if let polyline = geometry as? MKPolyline {
                polylines.append(polyline)
            } else if let multiPolyline = geometry as? MKMultiPolyline {
                polylines.append(contentsOf: multiPolyline.polylines)
            }
        }
        
        mapView?.addOverlays(polylines, level: .aboveRoads)
    }
    
    func updateTrackingMode(_ newTrackingMode: MKUserTrackingMode) {
        if status == .denied {
            showAlert = true
        } else {
            mapView?.setUserTrackingMode(newTrackingMode, animated: true)
            if trackingMode == .followWithHeading || newTrackingMode == .followWithHeading {
                withAnimation(.easeInOut(duration: 0.25)) {
                    scale = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.trackingMode = newTrackingMode
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.scale = 1
                    }
                }
            } else {
                trackingMode = newTrackingMode
            }
        }
    }
    
    func updateMapType(_ newMapType: MKMapType) {
        mapView?.mapType = newMapType
        withAnimation(.easeInOut(duration: 0.25)) {
            degrees += 90
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.mapType = newMapType
            withAnimation(.easeInOut(duration: 0.3)) {
                self.degrees += 90
            }
        }
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - MKMapViewDelegate
extension ViewModel: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.lineWidth = 2
            renderer.strokeColor = UIColor(.accentColor)
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        if !animated {
            updateTrackingMode(.none)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension ViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            manager.startUpdatingLocation()
        default:
            showAlert = true
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !zoomedIn {
            zoomedIn = true
            let centre = locations.first?.coordinate ?? CLLocationCoordinate2D()
            let delta = 0.02
            let span = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
            let region = MKCoordinateRegion(center: centre, span: span)
            mapView?.region = region
        }
    }
}
