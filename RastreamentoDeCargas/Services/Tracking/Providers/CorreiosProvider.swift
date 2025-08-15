import Foundation

struct CorreiosProvider: TrackingProvider {
    let baseURL: URL
    
    init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    func normalizeIfTrackingCode(_ text: String) -> String? {
        let trimmed = text.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return looksLikeCorreios(trimmed) ? trimmed : nil
    }
    
    func fetchTracking(code: String, carrierHint: Carrier?) async throws -> TrackingResult {
        // Se o baseURL contém "mock" ou está vazio, usa o provider mock
        if baseURL.absoluteString.contains("mock") || baseURL.absoluteString.isEmpty {
            return try await MockTrackingProvider().fetchTracking(code: code, carrierHint: .correios)
        }
        
        let url = baseURL.appendingPathComponent(code)
        let (data, response) = try await HTTP.get(url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw HTTPError.serverError(httpResponse.statusCode)
        }
        
        struct CorreiosResponse: Decodable {
            struct Event: Decodable {
                let date: String
                let status: String
                let description: String
                let location: String?
            }
            let carrier: String
            let status: String
            let events: [Event]
        }
        
        let decoder = JSONDecoder()
        let responseData = try decoder.decode(CorreiosResponse.self, from: data)
        
        let status = OrderStatus(rawValue: responseData.status) ?? .inTransit
        
        let dateFormatter = ISO8601DateFormatter()
        let events: [TrackingEvent] = responseData.events.compactMap { event in
            guard let date = dateFormatter.date(from: event.date) else { return nil }
            return TrackingEvent(
                date: date,
                status: OrderStatus(rawValue: event.status) ?? .inTransit,
                description: event.description,
                location: event.location
            )
        }.sorted { $0.date > $1.date }
        
        return TrackingResult(status: status, events: events, carrier: .correios)
    }
}
