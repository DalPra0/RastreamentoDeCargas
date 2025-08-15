import Foundation
import SwiftUI

final class DeepLinkRouter: ObservableObject {
    static let shared = DeepLinkRouter()
    
    @Published var pendingOrderId: UUID?
    @Published var pendingAction: DeepLinkAction?
    
    enum DeepLinkAction: Equatable {
        case openOrder(UUID)
        case addOrder(String?)
        case settings
    }
    
    private init() {}
    
    func openOrder(id: UUID) {
        pendingOrderId = id
        pendingAction = .openOrder(id)
    }
    
    func addOrder(trackingCode: String? = nil) {
        pendingAction = .addOrder(trackingCode)
    }
    
    func openSettings() {
        pendingAction = .settings
    }
    
    func handleURL(_ url: URL) {
        guard url.scheme == "rastreamento" else { return }
        
        switch url.host {
        case "order":
            handleOrderURL(url)
        case "add":
            handleAddURL(url)
        case "settings":
            openSettings()
        default:
            print("URL não reconhecida: \(url)")
        }
    }
    
    private func handleOrderURL(_ url: URL) {
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        guard let idString = pathComponents.first,
              let uuid = UUID(uuidString: idString) else {
            print("ID do pedido inválido na URL: \(url)")
            return
        }
        
        openOrder(id: uuid)
    }
    
    private func handleAddURL(_ url: URL) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let trackingCode = components?.queryItems?.first(where: { $0.name == "code" })?.value
        
        addOrder(trackingCode: trackingCode)
    }
    
    func clearPendingAction() {
        pendingAction = nil
        pendingOrderId = nil
    }
}
    
extension DeepLinkRouter {
    static func orderURL(for orderId: UUID) -> URL {
        URL(string: "rastreamento://order/\(orderId.uuidString)")!
    }
    
    static func addOrderURL(trackingCode: String? = nil) -> URL {
        var components = URLComponents()
        components.scheme = "rastreamento"
        components.host = "add"
        
        if let code = trackingCode {
            components.queryItems = [URLQueryItem(name: "code", value: code)]
        }
        
        return components.url!
    }
    
    static let settingsURL = URL(string: "rastreamento://settings")!
}
