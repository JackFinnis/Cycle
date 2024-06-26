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
    @Namespace var mapScope
    
    @State var routes = [Route]()
    @State var selectedRoute: Route?

    var body: some View {
        let routeColor = colorScheme == .light && mapStandard ? Color.blue : .cyan
        
        MapReader { map in
            GeometryReader { geo in
                Map(position: $mapPosition, interactionModes: [.pan, .rotate, .zoom], scope: mapScope) {
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
                .onTapGesture { point in
                    guard let coord = map.convert(point, from: .local) else { return }
                    if selectedRoute == nil {
                        selectClosestRoute(to: coord)
                    } else {
                        selectedRoute = nil
                    }
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
                                .mapBox()
                        }
                        .mapButton()
                        
                        MapUserLocationButton(scope: mapScope)
                            .buttonBorderShape(.roundedRectangle)
                        
                        if routes.isEmpty {
                            ProgressView()
                                .mapBox()
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
                                    .mapBox()
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
        .animation(.default, value: routes)
        .animation(.default, value: selectedRoute)
        .task {
            await fetchRoutes()
        }
    }
    
    func selectClosestRoute(to targetCoord: CLLocationCoordinate2D) {
        let targetLocation = targetCoord.location
        var shortestDistance = Double.infinity
        var closestRoute: Route?
        
        for route in routes {
            for polyline in route.multiPolyline.polylines {
                for coord in polyline.coordinates {
                    let delta = targetLocation.distance(from: coord.location)
                    if delta < shortestDistance {
                        shortestDistance = delta
                        closestRoute = route
                    }
                }
            }
        }
        
        selectedRoute = closestRoute
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
            guard let geometry = feature.geometry.first,
                  let properties = try? JSONDecoder().decode(RouteProperties.self, from: feature.properties!),
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
