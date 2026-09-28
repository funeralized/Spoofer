import Foundation
import Combine

class NetworkClient: ObservableObject {
    @Published var isConnected = false
    @Published var serverURL: String = "http://127.0.0.1:5000" // Default Tailscale or Local IP
    
    private var session = URLSession.shared
    
    func updateCoordinates(lat: Double, lng: Double, speed: Double = 1.0) {
        guard let url = URL(string: "\(serverURL)/move") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Double] = [
            "lat": lat,
            "lng": lng,
            "speed": speed
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("Payload serialization failed")
            return
        }
        
        session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Network error: \(error.localizedDescription)")
                    self?.isConnected = false
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    self?.isConnected = true
                } else {
                    self?.isConnected = false
                }
            }
        }.resume()
    }
    
    func checkStatus() {
        guard let url = URL(string: "\(serverURL)/status") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if error == nil, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    self?.isConnected = true
                } else {
                    self?.isConnected = false
                }
            }
        }.resume()
    }
}
