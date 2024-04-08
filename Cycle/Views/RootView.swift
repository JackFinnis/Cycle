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
    @Environment(\.colorScheme) var colorScheme
    
    @State var mapStyle = MapStyle.standard
    @State var mapStandard = true
    @State var mapPosition = MapCameraPosition.userLocation(fallback: .automatic)
    @State var mapRect: MKMapRect?
    @State var liveGesture = false
    @Namespace var mapScope
    
    @State var selectedRoute: Route?
    @State var selectedMapItem: MKMapItem?
    @State var showEmailSheet = false

    var body: some View {
        let routeColor = colorScheme == .light ? Color.blue : .cyan
        
        MapReader { map in
            GeometryReader { geo in
                Map(position: $mapPosition, selection: $selectedMapItem.animation(), scope: mapScope) {
                    UserAnnotation()
                        .tag(MKMapItem.forCurrentLocation())
                    ForEach(routes, id: \.self) { route in
                        let selected = route == selectedRoute
                        ForEach(route.multiPolyline.polylines, id: \.self) { polyline in
                            MapPolyline(polyline)
                                .mapOverlayLevel(level: selected ? .aboveLabels : .aboveRoads)
                                .stroke(selected ? .orange : routeColor, style: .init(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        }
                    }
                    if let selectedMapItem {
                        Marker(item: selectedMapItem)
                            .tag(selectedMapItem)
                    }
                }
                .contentMargins(20)
                .mapStyle(mapStyle)
                .mapControls {}
                .onMapCameraChange { context in
                    mapRect = context.rect
                }
                .onTapGesture { point in
                    guard let coord = map.convert(point, from: .local) else { return }
                    selectClosestRoute(to: coord)
                }
                .gesture(
                    LongPressGesture(minimumDuration: 1, maximumDistance: 0)
                        .simultaneously(with: DragGesture(minimumDistance: 0, coordinateSpace: .local))
                        .onEnded { value in
                            liveGesture = false
                        }
                        .onChanged { value in
                            guard let drag = value.second,
                                  let coord = map.convert(drag.location, from: .local),
                                  !liveGesture
                            else { return }
                            liveGesture = true
                            Haptics.tap()
                            Task {
                                await dropPin(at: coord)
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
                        Button {
                            mapStyle = mapStandard ? .hybrid : .standard
                            mapStandard.toggle()
                        } label: {
                            Image(systemName: mapStandard ? "globe.americas.fill" : "map")
                                .contentTransition(.symbolEffect(.replace))
                                .box()
                        }
                        .mapButton()
                        
                        MapUserLocationButton(scope: mapScope)
                            .buttonBorderShape(.roundedRectangle)
                        
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
                            if let url = Emails.url(subject: "\(Constants.name) Feedback"), UIApplication.shared.canOpenURL(url) {
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
                        
                        if let selectedRoute {
                            Button {
                                withAnimation {
                                    mapPosition = .rect(selectedRoute.multiPolyline.boundingMapRect)
                                }
                            } label: {
                                Text(selectedRoute.id)
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
            }
        }
        .confirmationDialog("", isPresented: Binding(get: {
            selectedMapItem != nil
        }, set: { isPresented in
            withAnimation {
                if !isPresented {
                    selectedMapItem = nil
                }
            }
        })) {
            if let selectedMapItem {
                Button("Directions") {
                    selectedMapItem.openInMaps()
                }
            }
        }
    }
    
    func dropPin(at coord: CLLocationCoordinate2D) async {
        guard let placemark = try? await CLGeocoder().reverseGeocodeLocation(coord.location).first else { return }
        selectedMapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
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
        
        var shortestDistance = Double.infinity
        var closestRoute: Route?
        
        for route in routes where route.boundingMapRect.padding(tapSize).contains(targetPoint) {
            for polyline in route.multiPolyline.polylines where polyline.boundingMapRect.padding(tapSize).contains(targetPoint) {
                for coord in polyline.coordinates {
                    let delta = targetLocation.distance(from: coord.location)
                    
                    if delta < shortestDistance && delta < tapSize {
                        shortestDistance = delta
                        closestRoute = route
                    }
                }
            }
        }
        
        withAnimation {
            selectedRoute = closestRoute
        }
    }
}

#Preview {
    RootView()
}
