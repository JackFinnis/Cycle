//
//  MapButtons.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI
import MapKit
import MessageUI

struct MapButtons: View {
    @EnvironmentObject var vm: ViewModel
    @State var showEmailSheet = false
    @State var showShareSheet = false
    
    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 0) {
                Menu {
                    Button {
                        showShareSheet.toggle()
                    } label: {
                        Label("Share \(Constants.name)", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        Store.requestRating()
                    } label: {
                        Label("Rate \(Constants.name)", systemImage: "star")
                    }
                    Button {
                        Store.writeReview()
                    } label: {
                        Label("Write a Review", systemImage: "quote.bubble")
                    }
                    if MFMailComposeViewController.canSendMail() {
                        Button {
                            showEmailSheet.toggle()
                        } label: {
                            Label("Send us Feedback", systemImage: "envelope")
                        }
                    } else if let url = Emails.mailtoUrl(subject: "\(Constants.name) Feedback"), UIApplication.shared.canOpenURL(url) {
                        Button {
                            UIApplication.shared.open(url)
                        } label: {
                            Label("Send us Feedback", systemImage: "envelope")
                        }
                    }
                } label: {
                    Image(systemName: "info.circle")
                        .squareButton()
                }
                .sharePopover(items: [Constants.appUrl], showsSharedAlert: true, isPresented: $showShareSheet)
                
                Divider().frame(width: Constants.size)
                Button {
                    updateMapType()
                } label: {
                    Image(systemName: mapTypeImage)
                        .squareButton()
                        .rotation3DEffect(.degrees(vm.mapType == .standard ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                        .rotation3DEffect(.degrees(vm.degrees), axis: (x: 0, y: 1, z: 0))
                }
                
                Divider().frame(width: Constants.size)
                Button {
                    updateTrackingMode()
                } label: {
                    Image(systemName: trackingModeImage)
                        .scaleEffect(vm.scale)
                        .squareButton()
                }
                
                if !vm.is2D || vm.mapType != .standard {
                    Divider().frame(width: Constants.size)
                    Button {
                        vm.updatePitch()
                    } label: {
                        Image(systemName: vm.is2D ? "view.3d" : "view.2d")
                            .squareButton()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .blurBackground()
            
            if let name = vm.selectedRouteId {
                Button {
                    vm.zoomToSelected()
                } label: {
                    Text(name)
                        .font(.system(size: 17).weight(.medium))
                        .squareButton()
                        .animation(.none, value: vm.selectedRouteId)
                }
                .blurBackground()
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(10)
        .animation(.default, value: vm.selectedRouteId)
        .animation(.default, value: vm.is2D)
        .animation(.default, value: vm.mapType)
        .emailSheet(recipient: Constants.email, subject: "\(Constants.name) Feedback", isPresented: $showEmailSheet)
        .alert("Access Denied", isPresented: $vm.showAuthAlert) {
            Button("Maybe Later") {}
            Button("Settings", role: .cancel) {
                vm.openSettings()
            }
        } message: {
            Text("\(Constants.name) needs access to your location to show where you are on the map. Please go to Settings > \(Constants.name) > Location and select \"While Using the App\".")
        }
    }
    
    func updateTrackingMode() {
        let mode: MKUserTrackingMode
        switch vm.trackingMode {
        case .none:
            mode = .follow
        case .follow:
            mode = .followWithHeading
        default:
            mode = .none
        }
        vm.setTrackingMode(mode)
    }
    
    func updateMapType() {
        let type: MKMapType
        switch vm.mapType {
        case .standard:
            type = .hybrid
        default:
            type = .standard
        }
        vm.setMapType(type)
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
