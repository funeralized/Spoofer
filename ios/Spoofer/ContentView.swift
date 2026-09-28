import SwiftUI

struct ContentView: View {
    @StateObject private var networkClient = NetworkClient()
    @StateObject private var engine: SimulationEngine
    
    init() {
        let client = NetworkClient()
        _networkClient = StateObject(wrappedValue: client)
        _engine = StateObject(wrappedValue: SimulationEngine(networkClient: client))
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("SPOOFER")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Circle()
                        .fill(networkClient.isConnected ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                }
                .padding()
                .background(Color.black.opacity(0.8))
                
                // Map
                MapView(engine: engine)
                    .frame(maxHeight: .infinity)
                
                // Controls
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(String(format: "LAT: %.6f", engine.currentLatitude))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.white)
                            Text(String(format: "LNG: %.6f", engine.currentLongitude))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Toggle("Active", isOn: $engine.isSimulating)
                            .labelsHidden()
                            .onChange(of: engine.isSimulating) { active in
                                if active {
                                    engine.startEngine()
                                } else {
                                    engine.stopEngine()
                                }
                            }
                    }
                    
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading) {
                            Text("SPEED")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Slider(value: $engine.walkSpeed, in: 0.5...25.0)
                            Text(String(format: "%.1f m/s", engine.walkSpeed))
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .frame(width: 150)
                        
                        Spacer()
                        
                        JoystickView(engine: engine)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.9))
            }
        }
        .onAppear {
            networkClient.checkStatus()
        }
    }
}
