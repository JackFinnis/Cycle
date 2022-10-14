//
//  MapView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @EnvironmentObject var vm: ViewModel
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = vm
        vm.mapView = mapView
        
        mapView.showsUserLocation = true
        mapView.showsScale = true
        mapView.showsCompass = true
        mapView.isPitchEnabled = true
//        let londonCentre = CLLocationCoordinate2DMake(51.5, -0.15)
//        let londonSpan = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.8)
//        let londonRegion = MKCoordinateRegion(center: londonCentre, span: londonSpan)
//        mapView.cameraBoundary = .init(coordinateRegion: londonRegion)
        
        let delta: Double
        let centre: CLLocationCoordinate2D
        if let coord = vm.manager.location?.coordinate {
            centre = coord
            delta = 0.02
        } else {
            centre = CLLocationCoordinate2DMake(51.5, -0.1)
            delta = 0.4
        }
        let span = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
        mapView.region = MKCoordinateRegion(center: centre, span: span)
        
        let tapRecognizer = UITapGestureRecognizer(target: vm, action: #selector(ViewModel.handleTap))
        mapView.addGestureRecognizer(tapRecognizer)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {}
}
