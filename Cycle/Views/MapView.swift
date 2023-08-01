//
//  MapView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI
import MapKit

class _MKMapView: MKMapView {
    var compass: UIView? {
        subviews.first(where: { type(of: $0).id == "MKCompassView" })
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let compass {
            compass.center = compass.center.applying(.init(translationX: -(15 + Constants.size), y: 5))
            if (compass.gestureRecognizers?.count ?? 0) < 2 {
                let tap = UITapGestureRecognizer(target: ViewModel.shared, action: #selector(ViewModel.tappedCompass))
                tap.delegate = ViewModel.shared
                compass.addGestureRecognizer(tap)
            }
        }
    }
}

struct MapView: UIViewRepresentable {
    @EnvironmentObject var vm: ViewModel
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = _MKMapView()
        mapView.delegate = vm
        vm.mapView = mapView
        mapView.addOverlays(vm.routes, level: .aboveRoads)
        
        mapView.showsUserLocation = true
        mapView.showsScale = true
        mapView.showsCompass = true
        mapView.isPitchEnabled = true
        if #available(iOS 16, *) {
            mapView.selectableMapFeatures = [.physicalFeatures, .pointsOfInterest, .territories]
        }
        
        let tapRecognizer = UITapGestureRecognizer(target: vm, action: #selector(ViewModel.handleTap))
        mapView.addGestureRecognizer(tapRecognizer)
        let longPressRecognizer = UILongPressGestureRecognizer(target: vm, action: #selector(ViewModel.handleLongPress))
        mapView.addGestureRecognizer(longPressRecognizer)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {}
}
