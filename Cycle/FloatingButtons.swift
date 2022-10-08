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
    
    var body: some View {
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
                    .rotation3DEffect(.degrees(vm.mapType == .hybrid ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                    .rotation3DEffect(.degrees(vm.degrees), axis: (x: 0, y: 1, z: 0))
            }
        }
        .background(colorScheme == .light ? .regularMaterial : .thickMaterial)
        .cornerRadius(10)
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
                return .hybrid
            default:
                return .standard
            }
        }()
        vm.updateMapType(nextMapType)
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
