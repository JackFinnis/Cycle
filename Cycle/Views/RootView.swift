//
//  RootView.swift
//  Cycle
//
//  Created by Jack Finnis on 17/02/2024.
//

import SwiftUI
import MapKit
import StoreKit
import MessageUI

struct RootView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.requestReview) var requestReview
    @State var showEmailSheet = false
    @State var mapStyle = MapStyle.standard(elevation: .realistic, showsTraffic: true)
    @State var mapStandard = true
    @State var mapPosition = MapCameraPosition.userLocation(fallback: .automatic)
    @State var selectedRouteID: String?
    @State var selectedMapItem: MKMapItem?
    @State var mapRect: MKMapRect?
    @State var liveGesture = false
    @Namespace var mapScope
    
    var selectedRoutes: [Route] {
        selectedRouteID == nil ? routes : routes.filter { $0.id == selectedRouteID }
    }

    var body: some View {
        MapReader { map in
            GeometryReader { geo in
                Map(position: $mapPosition, selection: $selectedMapItem.animation(), scope: mapScope) {
                    UserAnnotation()
                        .tag(MKMapItem.forCurrentLocation())
                    ForEach(selectedRoutes, id: \.self) { route in
                        MapPolyline(route.polyline)
                            .stroke(.orange, style: .init(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    }
                    if let selectedMapItem {
                        Marker(item: selectedMapItem)
                            .tag(selectedMapItem)
                    }
                }
                .mapStyle(mapStyle)
                .mapControls {}
                .onMapCameraChange { context in
                    mapRect = context.rect
                }
                .onTapGesture { point in
                    guard selectedMapItem == nil else { return }
                    if selectedRouteID != nil {
                        withAnimation {
                            selectedRouteID = nil
                        }
                    } else {
                        guard let coord = map.convert(point, from: .local) else { return }
                        selectClosestRoute(to: coord)
                    }
                }
                .gesture(
                    LongPressGesture(minimumDuration: 1, maximumDistance: 0)
                        .simultaneously(with: DragGesture(minimumDistance: 0, coordinateSpace: .local))
                        .onEnded { value in
                            liveGesture = false
                        }
                        .onChanged { value in
                            Task {
                                if !liveGesture {
                                    liveGesture = true
                                    Haptics.tap()
                                    guard let drag = value.second,
                                          let coord = map.convert(drag.location, from: .local),
                                          let placemark = try? await CLGeocoder().reverseGeocodeLocation(coord.location).first
                                    else { return }
                                    withAnimation {
                                        selectedMapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                                    }
                                }
                            }
                        }
                )
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
                .overlay(alignment: .topLeading) {
                    MapScaleView(scope: mapScope)
                        .padding(16)
                }
                .overlay(alignment: .topTrailing) {
                    VStack(spacing: 10) {
                        MapUserLocationButton(scope: mapScope)
                            .buttonBorderShape(.roundedRectangle)
                        MapPitchToggle(scope: mapScope)
                            .buttonBorderShape(.roundedRectangle)
                            .mapControlVisibility(.visible)
                        
                        Button {
                            mapStyle = mapStandard ? .hybrid(elevation: .realistic, showsTraffic: true) : .standard(elevation: .realistic, showsTraffic: true)
                            mapStandard.toggle()
                        } label: {
                            Image(systemName: mapStandard ? "globe" : "map")
                                .box()
                                .rotation3DEffect(mapStandard ? .degrees(180) : .zero, axis: (0, 1, 0))
                        }
                        .mapButton()
                        
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
                                .box()
                        }
                        .mapButton()
                        
                        if let selectedMapItem {
                            Button {
                                selectedMapItem.openInMaps()
                            } label: {
                                Image(systemName: "arrow.triangle.turn.up.right.diamond")
                                    .box()
                            }
                            .mapButton()
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        if let selectedRouteID {
                            Button {
                                withAnimation {
                                    mapPosition = .rect(selectedRoutes.rect.padding(10000))
                                }
                            } label: {
                                Text(selectedRouteID)
                                    .font(.system(size: 17))
                                    .box()
                            }
                            .mapButton()
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        MapCompass(scope: mapScope)
                    }
                    .padding(10)
                }
                .mapScope(mapScope)
                .emailSheet(recipient: Constants.email, subject: "\(Constants.name) Feedback", isPresented: $showEmailSheet)
            }
        }
    }
    
    var tapSize: Double {
        guard let mapRect else { return 0 }
        let left = MKMapPoint(x: mapRect.minX, y: mapRect.midY)
        let right = MKMapPoint(x: mapRect.maxX, y: mapRect.midY)
        return left.distance(to: right) / 20
    }
    
    func selectClosestRoute(to targetCoord: CLLocationCoordinate2D) {
        let tapSize = tapSize
        let targetLocation = targetCoord.location
        let targetPoint = MKMapPoint(targetCoord)
        let filteredRoutes = routes.filter { $0.boundingMapRect.padding(tapSize).contains(targetPoint) }
        
        var shortestDistance = Double.infinity
        var closestRoute: Route?
        
        for route in filteredRoutes {
            for coord in route.polyline.coordinates {
                let delta = targetLocation.distance(from: coord.location)
                
                if delta < shortestDistance && delta < tapSize {
                    shortestDistance = delta
                    closestRoute = route
                }
            }
        }
        
        withAnimation {
            selectedRouteID = closestRoute?.id
        }
    }
}

#Preview {
    RootView()
}
