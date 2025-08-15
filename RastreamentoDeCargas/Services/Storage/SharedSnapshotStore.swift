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
    static func saveSnapshot(_ snapshot: SnapshotDTO) {
        guard let url = snapshotURL(for: snapshot.orderId) else { return }
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: url, options: [.atomic])
            print("Snapshot salvo: \(snapshot.title)")
        } catch {
            print("Erro ao salvar snapshot:", error)
        }
    }
    
    static func loadSnapshot(orderId: UUID) -> SnapshotDTO? {
        guard let url = snapshotURL(for: orderId) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(SnapshotDTO.self, from: data)
        } catch {
            print("Erro ao carregar snapshot:", error)
            return nil
        }
    }
    
    // MARK: - Catálogo de pedidos
    static func saveCatalog(_ list: [OrderSummaryDTO]) {
        guard let url = catalogURL else { return }
        do {
            let data = try JSONEncoder().encode(list)
            try data.write(to: url, options: [.atomic])
            print("Catálogo salvo com \(list.count) pedidos")
        } catch {
            print("Erro ao salvar catálogo:", error)
        }
    }
    
    static func loadCatalog() -> [OrderSummaryDTO] {
        guard let url = catalogURL else { return [] }
        do {
            let data = try Data(contentsOf: url)
            let catalog = try JSONDecoder().decode([OrderSummaryDTO].self, from: data)
            print("Catálogo carregado com \(catalog.count) pedidos")
            return catalog
        } catch {
            print("Erro ao carregar catálogo:", error)
            return []
        }
    }
    
    // MARK: - Gerenciamento de códigos capturados
    private static let capturedCodesKey = "captured_codes"
    
    static func saveCapturedCodes(_ codes: [String]) {
        guard let userDefaults = UserDefaults(suiteName: appGroup) else { return }
        userDefaults.set(codes, forKey: capturedCodesKey)
        userDefaults.synchronize()
    }
    
    static func loadCapturedCodes() -> [String] {
        guard let userDefaults = UserDefaults(suiteName: appGroup) else { return [] }
        return userDefaults.array(forKey: capturedCodesKey) as? [String] ?? []
    }
    
    static func clearCapturedCodes() {
        guard let userDefaults = UserDefaults(suiteName: appGroup) else { return }
        userDefaults.removeObject(forKey: capturedCodesKey)
        userDefaults.synchronize()
    }
}
