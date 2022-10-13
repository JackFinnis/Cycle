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
    var filteredRoutes = [Route]()
    @Published var selectedRouteName: String?
    var selectedRoutes: [Route] {
        filteredRoutes.filter { $0.name == selectedRouteName }
    }
    
    // Map
    @Published var trackingMode = MKUserTrackingMode.none
    @Published var mapType = MKMapType.standard
    @Published var is2D = true
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
        
        var routes = [Route]()
        for feature in features {
            let geometry = feature.geometry.first!
            let routeData = try! JSONDecoder().decode(RouteData.self, from: feature.properties!)
            
            if let polyline = geometry as? MKPolyline {
                let route = Route(coordinates: polyline.coordinates, count: polyline.pointCount)
                route.name = routeData.Label
                route.status = Status(rawValue: routeData.Status)!
                routes.append(route)
            } else if let multiPolyline = geometry as? MKMultiPolyline {
                for polyline in multiPolyline.polylines {
                    let route = Route(coordinates: polyline.coordinates, count: polyline.pointCount)
                    route.name = routeData.Label
                    route.status = Status(rawValue: routeData.Status)!
                    routes.append(route)
                }
            }
        }
        
        filteredRoutes = routes.filter { $0.status == .open }
        mapView?.addOverlays(filteredRoutes, level: .aboveRoads)
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
    
    func selectClosestRoute(to targetCoord: CLLocationCoordinate2D) {
        let routes = selectedRoutes
        selectedRouteName = nil
        resetRoutes(routes)
        
        var shortestDistance = Double.infinity
        var closestRoute: Route?
        
        guard let mapView = mapView else { return }
        let rect = mapView.visibleMapRect
        let topLeft = MKMapPoint(x: rect.minX, y: rect.minY)
        let bottomRight = MKMapPoint(x: rect.maxX, y: rect.maxY)
        let maxDelta = topLeft.distance(to: bottomRight) / 50
        
        for route in filteredRoutes {
            for coord in route.coordinates {
                let delta = targetCoord.distance(to: coord)
                
                if delta < shortestDistance && delta < maxDelta {
                    shortestDistance = delta
                    closestRoute = route
                }
            }
        }
        
        selectedRouteName = closestRoute?.name
        resetRoutes(selectedRoutes)
    }
    
    func resetRoutes(_ routes: [Route]) {
        for route in routes {
            mapView?.removeOverlay(route)
            mapView?.addOverlay(route)
        }
    }
    
    func zoomToSelected() {
        guard let selectedRouteName = selectedRouteName else { return }
        let selectedRoutes = filteredRoutes.filter { $0.name == selectedRouteName }
        let rect = MKMultiPolyline(selectedRoutes).boundingMapRect
        let padding = UIEdgeInsets(top: 20, left: 20, bottom: 80, right: 20)
        mapView?.setVisibleMapRect(rect, edgePadding: padding, animated: true)
    }
}

// MARK: - Gesture Recogniser
extension ViewModel {
    @objc func handleTap(_ tap: UITapGestureRecognizer) {
        guard let mapView = mapView else { return }
        let tapPoint = tap.location(in: mapView)
        let tapCoord = mapView.convert(tapPoint, toCoordinateFrom: mapView)
        selectClosestRoute(to: tapCoord)
    }
}

// MARK: - MKMapViewDelegate
extension ViewModel: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let route = overlay as? Route {
            let renderer = MKPolylineRenderer(polyline: route)
            renderer.lineWidth = 2
            renderer.strokeColor = UIColor(route.name == selectedRouteName ? .yellow : .blue)
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        if !animated {
            updateTrackingMode(.none)
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        DispatchQueue.main.async {
            self.is2D = mapView.camera.pitch == 0 && self.mapType != .hybridFlyover
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension ViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        zoomedIn = false
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
