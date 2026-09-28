import SwiftUI
import MapKit

struct MapView: View {
    @ObservedObject var engine: SimulationEngine
    
    @State private var region: MKCoordinateRegion
    
    init(engine: SimulationEngine) {
        self.engine = engine
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: engine.currentLatitude, longitude: engine.currentLongitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: false)
                .ignoresSafeArea()
                .onTapGesture { location in
                    // In a real app, coordinate conversion from screen tap requires GeometryReader and MKMapView overlay.
                    // For SwiftUI simplicity without UIKit wrappers, we use a center-screen crosshair.
                }
            
            // Center Crosshair
            Image(systemName: "plus")
                .font(.title)
                .foregroundColor(.blue)
            
            VStack {
                Spacer()
                
                // Teleport button to center
                Button(action: {
                    engine.teleport(to: region.center)
                }) {
                    Text("TELEPORT HERE")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding()
                }
            }
        }
        .onChange(of: engine.currentLatitude) { _ in
            updateRegionIfNeeded()
        }
    }
    
    private func updateRegionIfNeeded() {
        let current = CLLocationCoordinate2D(latitude: engine.currentLatitude, longitude: engine.currentLongitude)
        // Only update region if the simulated location moves significantly off-screen
        let latDelta = abs(region.center.latitude - current.latitude)
        let lngDelta = abs(region.center.longitude - current.longitude)
        
        if latDelta > 0.005 || lngDelta > 0.005 {
            region.center = current
        }
    }
}

// Simple Virtual Joystick implementation
struct JoystickView: View {
    @ObservedObject var engine: SimulationEngine
    @State private var thumbPosition = CGSize.zero
    
    let radius: CGFloat = 60
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: radius * 2, height: radius * 2)
            
            Circle()
                .fill(Color.blue)
                .frame(width: 40, height: 40)
                .offset(x: thumbPosition.width, y: thumbPosition.height)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let translation = value.translation
                            let distance = sqrt(translation.width * translation.width + translation.height * translation.height)
                            
                            let angle = atan2(translation.height, translation.width)
                            let clampedDistance = min(distance, radius)
                            
                            thumbPosition = CGSize(
                                width: cos(angle) * clampedDistance,
                                height: sin(angle) * clampedDistance
                            )
                            
                            // Map SwiftUI coordinate system (Y down) to standard math (Y up)
                            engine.joystickAngle = Double(-angle)
                            engine.joystickMagnitude = Double(clampedDistance / radius)
                        }
                        .onEnded { _ in
                            thumbPosition = .zero
                            engine.joystickMagnitude = 0
                            engine.joystickAngle = 0
                        }
                )
        }
    }
}
