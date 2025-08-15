import Foundation
import SwiftData

enum Carrier: String, Codable, CaseIterable, Identifiable {
    case unknown = "unknown"
    case correios = "correios"
    case amazonLogistics = "amazonLogistics"
    case shopeeExpress = "shopeeExpress"
    case other = "other"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .unknown: return "Desconhecido"
        case .correios: return "Correios"
        case .amazonLogistics: return "Amazon Logistics"
        case .shopeeExpress: return "Shopee Express"
        case .other: return "Outro"
        }
    }
}

enum OrderStatus: String, Codable, CaseIterable {
    case created = "created"
    case inTransit = "inTransit"
    case outForDelivery = "outForDelivery"
    case delivered = "delivered"
    case exception = "exception"
    
    var displayName: String {
        switch self {
        case .created: return "Criado"
        case .inTransit: return "Em Trânsito"
        case .outForDelivery: return "Saiu para Entrega"
        case .delivered: return "Entregue"
        case .exception: return "Exceção"
        }
    }
    
    var color: String {
        switch self {
        case .created: return "gray"
        case .inTransit: return "blue"
        case .outForDelivery: return "orange"
        case .delivered: return "green"
        case .exception: return "red"
        }
    }
}

struct TrackingEvent: Codable, Identifiable, Hashable {
    var id: String { date.iso8601 + (location ?? "") + status.rawValue }
    let date: Date
    let status: OrderStatus
    let description: String
    let location: String?
    
    init(date: Date, status: OrderStatus, description: String, location: String? = nil) {
        self.date = date
        self.status = status
        self.description = description
        self.location = location
    }
}

@Model
final class Order {
    @Attribute(.unique) var id: UUID
    var title: String
    var store: String
    var carrier: Carrier
    var trackingCode: String?
    var orderLink: URL?
    var status: OrderStatus
    var lastUpdated: Date
    var eventsData: Data // [TrackingEvent] codificado
    var createdAt: Date
    
    init(title: String,
         store: String,
         carrier: Carrier = .unknown,
         trackingCode: String? = nil,
         orderLink: URL? = nil,
         status: OrderStatus = .created,
         lastUpdated: Date = .now,
         events: [TrackingEvent] = []) {
        self.id = UUID()
        self.title = title
        self.store = store
        self.carrier = carrier
        self.trackingCode = trackingCode
        self.orderLink = orderLink
        self.status = status
        self.lastUpdated = lastUpdated
        self.createdAt = .now
        self.eventsData = (try? JSONEncoder().encode(events)) ?? Data()
    }
    
    var events: [TrackingEvent] {
        get { 
            (try? JSONDecoder().decode([TrackingEvent].self, from: eventsData)) ?? []
        }
        set { 
            eventsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
    
    var latestEvent: TrackingEvent? {
        events.sorted { $0.date > $1.date }.first
    }
}

extension Date {
    var iso8601: String { 
        ISO8601DateFormatter().string(from: self) 
    }
}
