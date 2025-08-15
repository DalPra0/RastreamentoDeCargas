import Foundation

struct AggregatorProvider: TrackingProvider {
    enum Kind {
        case afterShip
        case t17
    }
    
    let apiKey: String
    let kind: Kind
    
    func normalizeIfTrackingCode(_ text: String) -> String? {
        let trimmed = text.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Aceita códigos dos Correios e outros padrões genéricos
        if looksLikeCorreios(trimmed) || (trimmed.count >= 8 && trimmed.count <= 30) {
            return trimmed
        }
        
        return nil
    }
    
    func fetchTracking(code: String, carrierHint: Carrier?) async throws -> TrackingResult {
        switch kind {
        case .afterShip:
            return try await fetchAfterShip(code: code)
        case .t17:
            return try await fetch17Track(code: code)
        }
    }
    
    // MARK: - AfterShip
    private func fetchAfterShip(code: String) async throws -> TrackingResult {
        let baseURL = URL(string: "https://api.aftership.com/v4")!
        let url = baseURL.appendingPathComponent("trackings/\(code)")
        let headers = [
            "aftership-api-key": apiKey,
            "Content-Type": "application/json"
        ]
        
        let (data, response) = try await HTTP.get(url, headers: headers)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw HTTPError.serverError(httpResponse.statusCode)
        }
        
        struct AfterShipResponse: Decodable {
            struct DataContainer: Decodable {
                struct Tracking: Decodable {
                    struct Checkpoint: Decodable {
                        let created_at: String
                        let tag: String
                        let message: String
                        let location: String?
                    }
                    let slug: String?
                    let tag: String
                    let checkpoints: [Checkpoint]
                }
                let tracking: Tracking
            }
            let data: DataContainer
        }
        
        let decoder = JSONDecoder()
        let afterShipResponse = try decoder.decode(AfterShipResponse.self, from: data)
        
        let tracking = afterShipResponse.data.tracking
        let status = mapAfterShipStatus(tracking.tag)
        
        let dateFormatter = ISO8601DateFormatter()
        let events = tracking.checkpoints.compactMap { checkpoint -> TrackingEvent? in
            guard let date = dateFormatter.date(from: checkpoint.created_at) else { return nil }
            return TrackingEvent(
                date: date,
                status: mapAfterShipStatus(checkpoint.tag),
                description: checkpoint.message,
                location: checkpoint.location
            )
        }.sorted { $0.date > $1.date }
        
        let carrier: Carrier = {
            if let slug = tracking.slug?.lowercased() {
                if slug.contains("correios") { return .correios }
                if slug.contains("amazon") { return .amazonLogistics }
                if slug.contains("shopee") { return .shopeeExpress }
            }
            return .other
        }()
        
        return TrackingResult(status: status, events: events, carrier: carrier)
    }
    
    // MARK: - 17Track
    private func fetch17Track(code: String) async throws -> TrackingResult {
        // Por enquanto, usa o mock provider para 17Track até ter acesso real à API
        print("17Track não implementado ainda, usando dados simulados")
        return try await MockTrackingProvider().fetchTracking(code: code, carrierHint: nil)
    }
    
    // MARK: - Status Mapping
    private func mapAfterShipStatus(_ tag: String) -> OrderStatus {
        switch tag.lowercased() {
        case "delivered":
            return .delivered
        case "out_for_delivery", "outfordelivery":
            return .outForDelivery
        case "exception", "expired", "undelivered", "failed_attempt":
            return .exception
        case "in_transit", "intransit", "info_received", "pickup", "available_for_pickup":
            return .inTransit
        case "pending", "not_found", "notfound":
            return .created
        default:
            return .inTransit
        }
    }
}
