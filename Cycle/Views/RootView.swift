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
    @Environment(\.colorScheme) var colorScheme
    
    @State var mapStyle = MapStyle.standard
    @State var mapStandard = true
    @State var mapPosition = MapCameraPosition.userLocation(fallback: .automatic)
    @State var mapRect: MKMapRect?
    @Namespace var mapScope
    
    @State var selectedRoute: Route?
    @State var selectedFeature: MapFeature?

    var body: some View {
        let routeColor = colorScheme == .light && mapStandard ? Color.blue : .cyan
        
        MapReader { map in
            GeometryReader { geo in
                Map(position: $mapPosition, interactionModes: [.pan, .rotate, .zoom], selection: $selectedFeature.animation(), scope: mapScope) {
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
            selectedFeature != nil
        }, set: { isPresented in
            withAnimation {
                if !isPresented {
                    selectedFeature = nil
                }
            }
        })) {
            if let selectedFeature {
                Button("Directions") {
                    MKMapItemRequest(feature: selectedFeature).getMapItem { mapItem, error in
                        mapItem?.openInMaps()
                    }
                }
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
