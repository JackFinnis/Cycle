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
    
    @State var routes = [Route]()
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
                        
                        if routes.isEmpty {
                            ProgressView()
                                .box()
                                .mapButton()
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
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
        .confirmationDialog(selectedFeature?.title ?? "", isPresented: Binding(get: {
            selectedFeature != nil
        }, set: { isPresented in
            withAnimation {
                if !isPresented {
                    selectedFeature = nil
                }
            }
        }), titleVisibility: .visible) {
            if let selectedFeature {
                Button("Directions") {
                    MKMapItemRequest(feature: selectedFeature).getMapItem { mapItem, error in
                        mapItem?.openInMaps()
                    }
                }
            }
        }
        .animation(.default, value: routes)
        .task {
            await fetchRoutes()
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
    
    func fetchRoutes() async {
        let data: Data
        do {
            let url = URL(string: "https://cycling.data.tfl.gov.uk/CycleRoutes/CycleRoutes.json")!
            (data, _) = try await URLSession.shared.data(from: url)
        } catch {
            let file = Bundle.main.url(forResource: "CycleRoutes", withExtension: "geojson")!
            data = try! Data(contentsOf: file)
        }
        
        let features = try! MKGeoJSONDecoder().decode(data) as! [MKGeoJSONFeature]
        let routes = features.compactMap { feature -> Route? in
            let geometry = feature.geometry.first!
            guard let properties = try? JSONDecoder().decode(RouteProperties.self, from: feature.properties!),
                  properties.Status == .open
            else { return nil }
            
            if let polyline = geometry as? MKPolyline {
                return Route(id: properties.Label, multiPolyline: MKMultiPolyline([polyline]))
            } else if let multiPolyline = geometry as? MKMultiPolyline {
                return Route(id: properties.Label, multiPolyline: multiPolyline)
            }
            return nil
        }
        
        let dict = Dictionary(grouping: routes, by: \.id)
        self.routes = dict.values.map { routes in
            let route = routes.first!
            let multiPolyline = MKMultiPolyline(routes.map(\.multiPolyline).flatMap(\.polylines))
            return Route(id: route.id, multiPolyline: multiPolyline)
        }
    }
}

#Preview {
    RootView()
}
