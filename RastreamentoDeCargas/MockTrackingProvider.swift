import Foundation

struct MockTrackingProvider: TrackingProvider {
    func normalizeIfTrackingCode(_ text: String) -> String? {
        let trimmed = text.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Aceita códigos dos Correios ou códigos genéricos para teste
        if looksLikeCorreios(trimmed) {
            return trimmed
        }
        
        // Para desenvolvimento, aceita qualquer código com 8+ caracteres
        if trimmed.count >= 8 && trimmed.count <= 30 {
            return trimmed
        }
        
        return nil
    }
    
    func fetchTracking(code: String, carrierHint: Carrier?) async throws -> TrackingResult {
        // Simula delay da rede
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 segundo
        
        // Simula timeline de eventos baseada no código
        let baseTime = Date().addingTimeInterval(-Double.random(in: 24*3600...7*24*3600)) // Entre 1-7 dias atrás
        
        var events: [TrackingEvent] = []
        
        // Evento inicial
        events.append(TrackingEvent(
            date: baseTime,
            status: .created,
            description: "Objeto postado",
            location: "São Paulo, SP"
        ))
        
        // Eventos intermediários baseados no hash do código
        let hash = abs(code.hashValue)
        let numEvents = 2 + (hash % 4) // 2-5 eventos
        
        for i in 1...numEvents {
            let eventTime = baseTime.addingTimeInterval(Double(i) * 24 * 3600)
            
            let status: OrderStatus
            let description: String
            let location: String
            
            switch i {
            case 1:
                status = .inTransit
                description = "Objeto em trânsito - origem"
                location = "São Paulo, SP"
            case 2:
                status = .inTransit
                description = "Objeto em trânsito - destino"
                location = "Curitiba, PR"
            case 3:
                status = .outForDelivery
                description = "Objeto saiu para entrega"
                location = "Curitiba, PR"
            default:
                status = .delivered
                description = "Objeto entregue ao destinatário"
                location = "Curitiba, PR"
            }
            
            // Para alguns códigos, simula entrega
            if eventTime < Date() {
                events.append(TrackingEvent(
                    date: eventTime,
                    status: status,
                    description: description,
                    location: location
                ))
            }
        }
        
        // Determina status final
        let finalStatus = events.last?.status ?? .created
        
        // Determina transportadora baseada no código
        let carrier: Carrier
        if looksLikeCorreios(code) {
            carrier = .correios
        } else if code.uppercased().hasPrefix("TBA") {
            carrier = .amazonLogistics
        } else if code.uppercased().hasPrefix("SE") {
            carrier = .shopeeExpress
        } else {
            carrier = .other
        }
        
        return TrackingResult(
            status: finalStatus,
            events: events.sorted { $0.date > $1.date },
            carrier: carrier
        )
    }
}
