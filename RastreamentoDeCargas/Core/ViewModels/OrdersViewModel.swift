import Foundation
import SwiftData

@MainActor
final class OrdersViewModel: ObservableObject {
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var capturedCodes: [String] = []
    
    private let provider: any TrackingProvider
    
    init(provider: any TrackingProvider) {
        self.provider = provider
        loadCapturedCodes()
    }
    
 
    func addOrder(
        title: String,
        store: String,
        trackingCode: String?,
        orderLink: URL?,
        context: ModelContext
    ) {
        var carrier: Carrier = .unknown
        
         if let code = trackingCode?.trimmingCharacters(in: .whitespacesAndNewlines), !code.isEmpty {
            if provider.looksLikeCorreios(code) {
                carrier = .correios
            } else if code.uppercased().hasPrefix("TBA") {
                carrier = .amazonLogistics
            } else if code.uppercased().hasPrefix("SE") {
                carrier = .shopeeExpress
            } else {
                carrier = .other
            }
        }
        
        let order = Order(
            title: title,
            store: store,
            carrier: carrier,
            trackingCode: trackingCode?.isEmpty == true ? nil : trackingCode,
            orderLink: orderLink
        )
        
        context.insert(order)
        
        do {
            try context.save()
            updateCatalog(context: context)
            print("Pedido criado: \(title)")
        } catch {
            errorMessage = "Erro ao salvar pedido: \(error.localizedDescription)"
        }
    }
    
    func deleteOrder(_ order: Order, context: ModelContext) {
        context.delete(order)
        
        do {
            try context.save()
            updateCatalog(context: context)
            print("Pedido removido: \(order.title)")
        } catch {
            errorMessage = "Erro ao remover pedido: \(error.localizedDescription)"
        }
    }
    
 
    func refreshOrder(_ order: Order, context: ModelContext) async {
        guard let trackingCode = order.trackingCode else {
            print("Pedido sem código de rastreamento: \(order.title)")
            return
        }
        
        isRefreshing = true
        errorMessage = nil
        
        do {
            let result = try await provider.fetchTracking(code: trackingCode, carrierHint: order.carrier)
            
            order.status = result.status
            order.carrier = result.carrier
            order.events = result.events
            order.lastUpdated = .now
            
            try context.save()
            
             saveOrderSnapshot(order)
            updateCatalog(context: context)
            
            print("Pedido atualizado: \(order.title) - \(result.status.displayName)")
            
        } catch {
            errorMessage = "Erro ao atualizar \(order.title): \(error.localizedDescription)"
            print("Erro ao atualizar pedido:", error)
        }
        
        isRefreshing = false
    }
    
    func refreshAllOrders(_ orders: [Order], context: ModelContext) async {
        isRefreshing = true
        errorMessage = nil
        
        await withTaskGroup(of: Void.self) { group in
            for order in orders.filter({ $0.trackingCode != nil }) {
                group.addTask { [weak self] in
                    await self?.refreshOrder(order, context: context)
                }
            }
        }
        
        isRefreshing = false
    }
    
 
    func loadCapturedCodes() {
        capturedCodes = SharedSnapshotStore.loadCapturedCodes()
    }
    
    func clearCapturedCodes() {
        capturedCodes.removeAll()
        SharedSnapshotStore.clearCapturedCodes()
    }
    
    func createOrderFromCapturedCode(_ code: String, context: ModelContext) {
         capturedCodes.removeAll { $0 == code }
        SharedSnapshotStore.saveCapturedCodes(capturedCodes)
        
         var store = "Loja"
        if provider.looksLikeCorreios(code) {
            store = "Correios"
        } else if code.uppercased().hasPrefix("TBA") {
            store = "Amazon"
        } else if code.uppercased().hasPrefix("SE") {
            store = "Shopee"
        }
        
        addOrder(
            title: "Rastreamento \(code.suffix(6))",
            store: store,
            trackingCode: code,
            orderLink: nil,
            context: context
        )
    }
    
 
    private func saveOrderSnapshot(_ order: Order) {
        let subtitle: String = {
            if let event = order.latestEvent {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                let dateStr = formatter.string(from: event.date)
                let location = event.location.map { " · \($0)" } ?? ""
                return "\(event.description)\(location) · \(dateStr)"
            } else {
                return "Sem eventos"
            }
        }()
        
        let snapshot = SnapshotDTO(
            date: .now,
            orderId: order.id,
            title: order.title,
            status: order.status.rawValue,
            subtitle: subtitle
        )
        
        SharedSnapshotStore.saveSnapshot(snapshot)
    }
    
    private func updateCatalog(context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<Order>(
                sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
            )
            let orders = try context.fetch(descriptor)
            
            let catalog = orders.map { order in
                OrderSummaryDTO(
                    id: order.id,
                    title: order.title,
                    lastUpdated: order.lastUpdated
                )
            }
            
            SharedSnapshotStore.saveCatalog(catalog)
        } catch {
            print("Erro ao atualizar catálogo:", error)
        }
    }
    
 
    func extractTrackingCodes(from text: String) -> [String] {
        return provider.extractTrackingCodes(from: text)
    }
    
    func normalizeTrackingCode(_ text: String) -> String? {
        return provider.normalizeIfTrackingCode(text)
    }
}
