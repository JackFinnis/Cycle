//
//  MapButtons.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI
import MapKit
import MessageUI
import StoreKit

struct MapButtons: View {
    @Environment(\.requestReview) var requestReview
    @EnvironmentObject var app: AppState
    @State var showEmailSheet = false
    @State var showShareSheet = false
    
    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 0) {
                Menu {
                    Button {
                        requestReview()
                    } label: {
                        Label("Rate \(Constants.name)", systemImage: "star")
                    }
                    Button {
                        AppStore.writeReview()
                    } label: {
                        Label("Write a Review", systemImage: "quote.bubble")
                    }
                    if MFMailComposeViewController.canSendMail() {
                        Button {
                            showEmailSheet.toggle()
                        } label: {
                            Label("Send us Feedback", systemImage: "envelope")
                        }
                    } else if let url = Emails.url(subject: "\(Constants.name) Feedback"), UIApplication.shared.canOpenURL(url) {
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
                
                Divider().frame(width: Constants.size)
                Button {
                    updateTrackingMode()
                } label: {
                    Image(systemName: trackingModeImage)
                        .scaleEffect(app.scale)
                        .squareButton()
                }
                
                Divider().frame(width: Constants.size)
                Button {
                    updateMapType()
                } label: {
                    Image(systemName: mapTypeImage)
                        .squareButton()
                        .rotation3DEffect(.degrees(app.degrees), axis: (x: 0, y: 1, z: 0))
                }
                
                if !app.is2D || app.mapType != .standard {
                    Divider().frame(width: Constants.size)
                    Button {
                        app.updatePitch()
                    } label: {
                        Image(systemName: app.is2D ? "view.3d" : "view.2d")
                            .squareButton()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .blurBackground()
            
            if let name = app.selectedRouteId {
                Button {
                    app.zoomToSelected()
                } label: {
                    Text(name)
                        .font(.system(size: 17).weight(.medium))
                        .squareButton()
                        .animation(.none, value: app.selectedRouteId)
                }
                .blurBackground()
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(10)
        .animation(.default, value: app.selectedRouteId)
        .animation(.default, value: app.is2D)
        .animation(.default, value: app.mapType)
        .emailSheet(recipient: Constants.email, subject: "\(Constants.name) Feedback", isPresented: $showEmailSheet)
        .alert("Access Denied", isPresented: $app.showAuthAlert) {
            Button("Maybe Later") {}
            Button("Settings", role: .cancel) {
                app.openSettings()
            }
        } message: {
            Text("\(Constants.name) needs access to your location to show where you are on the map. Please go to Settings > \(Constants.name) > Location and select \"While Using the App\".")
        }
    }
    
    func updateTrackingMode() {
        let mode: MKUserTrackingMode
        switch app.trackingMode {
        case .none:
            mode = .follow
        case .follow:
            mode = .followWithHeading
        default:
            mode = .none
        }
        app.setTrackingMode(mode)
    }
    
    func updateMapType() {
        let type: MKMapType
        switch app.mapType {
        case .standard:
            type = .hybrid
        default:
            type = .standard
        }
        app.setMapType(type)
    }
    
    var trackingModeImage: String {
        switch app.trackingMode {
        case .none:
            return "location"
        case .follow:
            return "location.fill"
        default:
            return "location.north.line.fill"
        }
    }
    
    var mapTypeImage: String {
        switch app.mapType {
        case .standard:
            return "globe"
        default:
            return "map"
        }
    }
}
