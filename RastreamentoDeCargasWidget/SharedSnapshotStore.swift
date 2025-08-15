// Este arquivo precisa ser adicionado ao target do Widget no Xcode
// Versão compartilhada do SharedSnapshotStore para o Widget

import Foundation

struct SnapshotDTO: Codable {
    let date: Date
    let orderId: UUID
    let title: String
    let status: String
    let subtitle: String
}

struct OrderSummaryDTO: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let lastUpdated: Date
}

enum SharedSnapshotStore {
    private static let appGroup = "group.com.lucasdalpra.RastreamentoDeCargas"
    private static let catalogFile = "orders_catalog.json"
    
    private static func containerURL() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
    }
    
    private static func snapshotURL(for id: UUID) -> URL? {
        containerURL()?.appendingPathComponent("snap_\(id.uuidString).json")
    }
    
    private static var catalogURL: URL? {
        containerURL()?.appendingPathComponent(catalogFile)
    }
    
    // MARK: - Snapshot por pedido
    static func loadSnapshot(orderId: UUID) -> SnapshotDTO? {
        guard let url = snapshotURL(for: orderId) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(SnapshotDTO.self, from: data)
        } catch {
            return nil
        }
    }
    
    // MARK: - Catálogo de pedidos
    static func loadCatalog() -> [OrderSummaryDTO] {
        guard let url = catalogURL else { return [] }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([OrderSummaryDTO].self, from: data)
        } catch {
            return []
        }
    }
}
