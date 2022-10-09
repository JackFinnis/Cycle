//
//  FloatingButtons.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI
import MapKit

struct FloatingButtons: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var vm: ViewModel
    
    var background: Material { colorScheme == .light ? .regularMaterial : .thickMaterial }
    
    var body: some View {
        VStack(spacing: 20) {
            VStack {
                if !vm.is2D || vm.mapType != .standard {
                    Button {
                        updatePitch()
                    } label: {
                        Image(systemName: vm.is2D ? "view.3d" : "view.2d")
                            .frame(width: SIZE, height: SIZE)
                            .font(.title3)
                    }
                    .background(background)
                    .cornerRadius(10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.default, value: vm.is2D)
            .animation(.default, value: vm.mapType)
            
            VStack(spacing: 0) {
                Button {
                    updateTrackingMode()
                } label: {
                    Image(systemName: trackingModeImage)
                        .frame(width: SIZE, height: SIZE)
                        .scaleEffect(vm.scale)
                }
                
                Divider().frame(width: SIZE)
                
                Button {
                    updateMapType()
                } label: {
                    Image(systemName: mapTypeImage)
                        .frame(width: SIZE, height: SIZE)
                        .rotation3DEffect(.degrees(vm.mapType == .standard ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                        .rotation3DEffect(.degrees(vm.degrees), axis: (x: 0, y: 1, z: 0))
                }
            }
            .background(background)
            .cornerRadius(10)
        }
        .font(.system(size: SIZE/2))
        .compositingGroup()
        .shadow(color: Color(UIColor.systemFill), radius: 5)
        .padding(10)
    }
    
    func updateTrackingMode() {
        let nextTrackingMode: MKUserTrackingMode = {
            switch vm.mapView?.userTrackingMode ?? .none {
            case .none:
                return .follow
            case .follow:
                return .followWithHeading
            default:
                return .none
            }
        }()
        vm.updateTrackingMode(nextTrackingMode)
    }
    
    func updateMapType() {
        let nextMapType: MKMapType = {
            switch vm.mapView?.mapType ?? .standard {
            case .standard:
                if vm.is2D {
                    return .hybrid
                } else {
                    return .hybridFlyover
                }
            default:
                return .standard
            }
        }()
        vm.updateMapType(nextMapType)
    }
    
    func updatePitch() {
        let camera = MKMapCamera()
        switch vm.mapType {
        case .standard:
            camera.pitch = 0
            vm.is2D = true
        case .hybrid:
            vm.mapType = .hybridFlyover
            camera.pitch = 45
        default:
            vm.mapType = .hybrid
            camera.pitch = 0
        }
        vm.mapView?.mapType = vm.mapType
        camera.altitude = vm.mapView?.camera.altitude ?? 0
        camera.centerCoordinate = vm.mapView?.camera.centerCoordinate ?? .init()
        camera.heading = vm.mapView?.camera.heading ?? .init()
        camera.centerCoordinateDistance = vm.mapView?.camera.centerCoordinateDistance ?? 0
        vm.mapView?.setCamera(camera, animated: true)
    }
    
    var trackingModeImage: String {
        switch vm.trackingMode {
        case .none:
            return "location"
        case .follow:
            return "location.fill"
        default:
            return "location.north.line.fill"
        }
    }
    
    var mapTypeImage: String {
        switch vm.mapType {
        case .standard:
            return "globe.europe.africa.fill"
        default:
            return "map"
        }
    }
}

struct FloatingButtons_Previews: PreviewProvider {
    static var previews: some View {
        FloatingButtons()
    }
}
