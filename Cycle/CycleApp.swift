//
//  CycleApp.swift
//  Cycle
//
//  Created by Jack Finnis on 08/10/2022.
//

import SwiftUI
import MapKit
import StoreKit
import MessageUI

// https://cycling.data.tfl.gov.uk/CycleRoutes/CycleRoutes.json

@main
struct CycleApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.requestReview) var requestReview
    @State var showEmailSheet = false
    @Namespace var mapScope

    var body: some View {
        GeometryReader { geo in
            Map(initialPosition: .userLocation(fallback: .automatic), scope: mapScope) {
                UserAnnotation()
                ForEach(polylines, id: \.self) { polyline in
                    MapPolyline(polyline)
                        .stroke(.orange, style: .init(lineWidth: 3, lineCap: .round, lineJoin: .round))
                }
            }
            .contentMargins(5)
            .mapControlVisibility(.visible)
            .mapControls {
                MapUserLocationButton()
                MapPitchToggle()
            }
            .overlay(alignment: .top) {
                CarbonCopy()
                    .id(scenePhase)
                    .blur(radius: 5, opaque: true)
                    .frame(height: geo.safeAreaInsets.top)
                    .mask {
                        LinearGradient(colors: [.white, .white, .clear], startPoint: .top, endPoint: .bottom)
                    }
                    .ignoresSafeArea()
            }
            .overlay(alignment: .topTrailing) {
                VStack(spacing: 10) {
                    Menu {
                        ShareLink("Share \(Constants.name)", item: Constants.appURL)
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
                            .font(.system(size: 20))
                            .frame(width: Constants.size, height: Constants.size)
                    }
                    .background(.ultraThickMaterial)
                    .clipShape(.rect(cornerRadius: 8))
                    
                    MapCompass(scope: mapScope)
                }
                .padding(.trailing, 10)
                .padding(.top, Constants.size*2 + 30)
            }
        }
        .mapScope(mapScope)
        .emailSheet(recipient: Constants.email, subject: "\(Constants.name) Feedback", isPresented: $showEmailSheet)
    }
}

#Preview {
    RootView()
}

let polylines: [MKPolyline] = {
    let file = Bundle.main.url(forResource: "CycleRoutes", withExtension: "geojson")!
    let data = try! Data(contentsOf: file)
    let features = try! MKGeoJSONDecoder().decode(data) as! [MKGeoJSONFeature]
    
    return features.flatMap { feature -> [MKPolyline] in
        let geometry = feature.geometry.first!
        let properties = try! JSONDecoder().decode(RouteProperties.self, from: feature.properties!)
        guard properties.Status == .open else { return [] }
        
        if let polyline = geometry as? MKPolyline {
            return [polyline]
        } else if let multiPolyline = geometry as? MKMultiPolyline {
            return multiPolyline.polylines
        }
        return []
    }
}()

struct RouteProperties: Codable {
    let Label: String
    let Status: RouteStatus
}

enum RouteStatus: String, Codable {
    case planned = "Planned"
    case inProgress = "In Progress"
    case open = "Open"
}

struct CarbonCopy: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView()
    }
    
    func updateUIView(_ view: UIVisualEffectView, context: Context) {
        view.effect = nil
        let effect = UIBlurEffect(style: .regular)
        let animator = UIViewPropertyAnimator()
        animator.addAnimations { view.effect = effect }
        animator.startAnimation()
        animator.stopAnimation(true)
    }
}
