//
//  AppState.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import Foundation
import MapKit
import SwiftUI

@MainActor
class AppState: NSObject, ObservableObject {
    static let shared = AppState()
    
    // MARK: - Properties
    var routes = [Route]()
    @Published var selectedRouteId: String?
    var selectedRoutes: [Route] {
        routes.filter { $0.id == selectedRouteId }
    }
    
    // Map
    var mapView: MKMapView?
    @Published var trackingMode = MKUserTrackingMode.none
    @Published var mapType = MKMapType.standard
    @Published var is2D = true
    
    // CLLocationManager
    let manager = CLLocationManager()
    var zoomed = false
    var authStatus = CLAuthorizationStatus.notDetermined
    @Published var showAuthAlert = false
    
    // Animations
    @Published var degrees = 180.0
    @Published var scale = 1.0
    
    // MARK: - Initialiser
    override init() {
        super.init()
        manager.delegate = self
        loadRoutes()
    }
    
    // MARK: - Methods
    func loadRoutes() {
        let file = Bundle.main.url(forResource: "CycleRoutes", withExtension: "geojson")!
        let data = try! Data(contentsOf: file)
        let features = try! MKGeoJSONDecoder().decode(data) as! [MKGeoJSONFeature]
        
        for feature in features {
            let geometry = feature.geometry.first!
            let properties = try! JSONDecoder().decode(RouteProperties.self, from: feature.properties!)
            guard properties.Status == .open else { continue }
            
            var polylines = [MKPolyline]()
            if let polyline = geometry as? MKPolyline {
                polylines.append(polyline)
            } else if let multiPolyline = geometry as? MKMultiPolyline {
                polylines.append(contentsOf: multiPolyline.polylines)
            }
            
            polylines.forEach { polyline in
                routes.append(Route(id: properties.Label, polyline: polyline))
            }
        }
    }
    
    func setTrackingMode(_ newMode: MKUserTrackingMode) {
        guard validateAuth(), let mapView else { return }
        mapView.setUserTrackingMode(newMode, animated: true)
        if trackingMode == .followWithHeading || newMode == .followWithHeading {
            withAnimation(.easeInOut(duration: 0.25)) {
                scale = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.trackingMode = newMode
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.scale = 1
                }
            }
        } else {
            trackingMode = newMode
        }
    }
    
    func setMapType(_ newType: MKMapType) {
        guard let mapView else { return }
        mapView.mapType = newType
        refreshOverlays()
        withAnimation(.easeInOut(duration: 0.25)) {
            degrees += 90
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.mapType = newType
            withAnimation(.easeInOut(duration: 0.25)) {
                self.degrees += 90
            }
        }
    }
    
    func updatePitch() {
        guard let mapView else { return }
        let camera = mapView.camera
        let newCamera = MKMapCamera()
        switch mapType {
        case .standard:
            newCamera.pitch = 0
        case .hybrid:
            mapType = .hybridFlyover
            newCamera.pitch = 45
        case .hybridFlyover:
            mapType = .hybrid
            newCamera.pitch = 0
        default: return
        }
        is2D = newCamera.pitch == 0
        mapView.mapType = mapType
        newCamera.centerCoordinateDistance = camera.centerCoordinateDistance
        newCamera.centerCoordinate = camera.centerCoordinate
        newCamera.heading = camera.heading
        mapView.setCamera(newCamera, animated: true)
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    func reverseGeocode(coord: CLLocationCoordinate2D, completion: @escaping (CLPlacemark) -> Void) {
        CLGeocoder().reverseGeocodeLocation(coord.location) { placemarks, error in
            guard let placemark = placemarks?.first else { return }
            completion(placemark)
        }
    }
    
    var tapDelta: Double {
        guard let rect = mapView?.visibleMapRect else { return 0 }
        let left = MKMapPoint(x: rect.minX, y: rect.midY)
        let right = MKMapPoint(x: rect.maxX, y: rect.midY)
        return left.distance(to: right) / 20
    }
    
    func selectClosestRoute(to targetCoord: CLLocationCoordinate2D) {
        let maxDelta = tapDelta
        let targetLocation = targetCoord.location
        var shortestDistance = Double.infinity
        var closestRoute: Route?
        
        for route in routes {
            for coord in route.polyline.coordinates {
                let delta = targetLocation.distance(from: coord.location)
                
                if delta < shortestDistance && delta < maxDelta {
                    shortestDistance = delta
                    closestRoute = route
                }
            }
        }
        selectedRouteId = closestRoute?.id
        refreshOverlays()
    }
    
    func refreshOverlays() {
        mapView?.removeOverlays(routes)
        mapView?.addOverlays(routes, level: .aboveRoads)
    }
    
    func zoomToSelected() {
        let padding = 20.0
        let insets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        mapView?.setVisibleMapRect(selectedRoutes.rect, edgePadding: insets, animated: true)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension AppState: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }
    
    func getCoord(from gesture: UIGestureRecognizer) -> CLLocationCoordinate2D? {
        guard let mapView else { return nil }
        let point = gesture.location(in: mapView)
        return mapView.convert(point, toCoordinateFrom: mapView)
    }
    
    @objc func handleTap(_ tap: UITapGestureRecognizer) {
        guard let coord = getCoord(from: tap) else { return }
        selectClosestRoute(to: coord)
    }
    
    @objc func handlePress(_ press: UILongPressGestureRecognizer) {
        guard press.state == .began, let coord = getCoord(from: press) else { return }
        Haptics.tap()
        reverseGeocode(coord: coord) { placemark in
            let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
            self.mapView?.addAnnotation(mapItem)
            self.mapView?.selectAnnotation(mapItem, animated: true)
        }
    }
    
    @objc
    func tappedCompass() {
        guard trackingMode == .followWithHeading else { return }
        setTrackingMode(.follow)
    }
}

// MARK: - MKMapViewDelegate
extension AppState: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let darkMode = UITraitCollection.current.userInterfaceStyle == .dark || mapView.mapType == .hybrid
        if let route = overlay as? Route {
            let selected = route.id == selectedRouteId
            let renderer = MKPolylineRenderer(polyline: route.polyline)
            renderer.lineWidth = selected ? 3 : 2
            renderer.strokeColor = UIColor(selected ? .orange : (darkMode ? .cyan : .accentColor))
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func getButton(systemName: String) -> UIButton {
        let config = UIImage.SymbolConfiguration(font: .systemFont(ofSize: Constants.size/2))
        let image = UIImage(systemName: systemName, withConfiguration: config)
        let button = UIButton()
        button.setImage(image, for: .normal)
        button.frame.size = CGSize(width: Constants.size, height: Constants.size)
        return button
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if #available(iOS 16, *), let feature = annotation as? MKMapFeatureAnnotation {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: MKMarkerAnnotationView.id, for: feature) as? MKMarkerAnnotationView
            view?.canShowCallout = true
            view?.markerTintColor = feature.iconStyle?.backgroundColor
            view?.rightCalloutAccessoryView = getButton(systemName: "arrow.triangle.turn.up.right.circle")
            if let icon = feature.iconStyle {
                let imageView = UIImageView(image: icon.image.withTintColor(icon.backgroundColor, renderingMode: .alwaysOriginal))
                imageView.frame.size = CGSize(width: Constants.size, height: Constants.size)
                view?.leftCalloutAccessoryView = imageView
            }
            return view
        } else if let mapItem = annotation as? MKMapItem {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: MKMarkerAnnotationView.id, for: mapItem) as? MKMarkerAnnotationView
            view?.canShowCallout = true
            view?.animatesWhenAdded = true
            view?.rightCalloutAccessoryView = getButton(systemName: "arrow.triangle.turn.up.right.circle")
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        if let user = mapView.view(for: mapView.userLocation) {
            user.rightCalloutAccessoryView = getButton(systemName: "map")
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if #available(iOS 16, *), let feature = view.annotation as? MKMapFeatureAnnotation {
            let request = MKMapItemRequest(mapFeatureAnnotation: feature)
            request.getMapItem { mapItem, error in
                mapItem?.openInMaps()
            }
        } else if let mapItem = view.annotation as? MKMapItem {
            mapItem.openInMaps()
        } else if let _ = view.annotation as? MKUserLocation {
            MKMapItem.forCurrentLocation().openInMaps()
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if let mapItem = view.annotation as? MKMapItem {
            mapView.removeAnnotation(mapItem)
        }
    }
    
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        if !animated {
            setTrackingMode(.none)
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if !zoomed {
            zoomed = true
            mapView.setUserTrackingMode(.follow, animated: false)
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        DispatchQueue.main.async {
            self.is2D = mapView.camera.pitch == 0 && mapView.mapType != .hybridFlyover
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension AppState: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authStatus = manager.authorizationStatus
        if authStatus == .denied {
            showAuthAlert.toggle()
        } else if authStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }
    
    func validateAuth() -> Bool {
        showAuthAlert = authStatus == .denied
        return !showAuthAlert
    }
}
