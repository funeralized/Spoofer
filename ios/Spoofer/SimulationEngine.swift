import Foundation
import AVFoundation
import CoreLocation

class SimulationEngine: ObservableObject {
    @Published var currentLatitude: Double = 37.7749
    @Published var currentLongitude: Double = -122.4194
    @Published var isSimulating: Bool = false
    
    private var audioPlayer: AVAudioPlayer?
    private var simulationTimer: Timer?
    private let networkClient: NetworkClient
    
    // Joystick state
    var joystickAngle: Double = 0
    var joystickMagnitude: Double = 0
    var walkSpeed: Double = 2.0 // m/s
    
    // Anti-detection drift
    private var lastDriftTime: Date = Date()
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
        setupSilentAudio()
    }
    
    // MARK: - Background Persistence
    
    private func setupSilentAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Generate 1 second of silent audio data dynamically
            let sampleRate = 44100.0
            let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
            let frameCount = AVAudioFrameCount(sampleRate)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
            buffer.frameLength = frameCount
            
            // Fill with silence
            let channels = buffer.floatChannelData!
            for i in 0..<Int(frameCount) {
                channels[0][i] = 0.0
            }
            
            // Write to a temporary file to play it
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("silence.wav")
            let file = try AVAudioFile(forWriting: tempURL, settings: format.settings)
            try file.write(from: buffer)
            
            audioPlayer = try AVAudioPlayer(contentsOf: tempURL)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.volume = 0.01 // Barely audible just in case
            
        } catch {
            print("Failed to initialize background audio session: \(error.localizedDescription)")
        }
    }
    
    func startEngine() {
        isSimulating = true
        audioPlayer?.play()
        
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.simulationLoop()
        }
        RunLoop.current.add(simulationTimer!, forMode: .common)
    }
    
    func stopEngine() {
        isSimulating = false
        audioPlayer?.pause()
        simulationTimer?.invalidate()
        simulationTimer = nil
    }
    
    // MARK: - Simulation Loop
    
    private func simulationLoop() {
        guard isSimulating else { return }
        
        let now = Date()
        var lat = currentLatitude
        var lng = currentLongitude
        
        // 1. Calculate Joystick Movement
        if joystickMagnitude > 0.05 {
            let speed = walkSpeed * joystickMagnitude
            let dt = 0.1 // 100ms interval
            
            let metersPerDegLat = 111320.0
            let metersPerDegLng = 111320.0 * cos(lat * .pi / 180.0)
            
            let dLng = cos(joystickAngle) * speed * dt / metersPerDegLng
            let dLat = sin(joystickAngle) * speed * dt / metersPerDegLat
            
            lat += dLat
            lng += dLng
        }
        
        // 2. Anti-Detection Drift (every 3 seconds)
        if now.timeIntervalSince(lastDriftTime) >= 3.0 {
            // Apply a microscopic float drift between +/- 0.00001 and 0.00003
            let driftMag = Double.random(in: 0.00001...0.00003)
            let driftAngle = Double.random(in: 0...(2 * .pi))
            
            lat += cos(driftAngle) * driftMag
            lng += sin(driftAngle) * driftMag
            
            lastDriftTime = now
        }
        
        // Only update if changed to save network calls
        if lat != currentLatitude || lng != currentLongitude {
            currentLatitude = lat
            currentLongitude = lng
            networkClient.updateCoordinates(lat: lat, lng: lng, speed: walkSpeed)
        }
    }
    
    func teleport(to coordinate: CLLocationCoordinate2D) {
        currentLatitude = coordinate.latitude
        currentLongitude = coordinate.longitude
        networkClient.updateCoordinates(lat: currentLatitude, lng: currentLongitude, speed: walkSpeed)
    }
}
