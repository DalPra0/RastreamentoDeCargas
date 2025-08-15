import Foundation
import SwiftUI

enum ProviderMode: String, CaseIterable, Identifiable {
    case mock = "mock"
    case afterShip = "afterShip"
    case t17 = "t17"
    case correiosBackend = "correiosBackend"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .mock:
            return "Mock (Desenvolvimento)"
        case .afterShip:
            return "AfterShip"
        case .t17:
            return "17Track"
        case .correiosBackend:
            return "Correios (Backend)"
        }
    }
    
    var description: String {
        switch self {
        case .mock:
            return "Simula dados para desenvolvimento e testes"
        case .afterShip:
            return "Integração com AfterShip para múltiplas transportadoras"
        case .t17:
            return "Integração com 17Track para rastreamento global"
        case .correiosBackend:
            return "Conecta com seu backend para dados dos Correios"
        }
    }
}

final class SettingsManager: ObservableObject {
    private let userDefaults = UserDefaults(suiteName: "group.com.lucasdalpra.RastreamentoDeCargas") ?? .standard
    
    @Published var providerMode: ProviderMode {
        didSet { save() }
    }
    
    @Published var afterShipAPIKey: String {
        didSet { save() }
    }
    
    @Published var t17APIKey: String {
        didSet { save() }
    }
    
    @Published var correiosBackendURL: String {
        didSet { save() }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet { save() }
    }
    
    @Published var backgroundRefreshEnabled: Bool {
        didSet { save() }
    }
    
    init() {
        self.providerMode = ProviderMode(rawValue: userDefaults.string(forKey: "providerMode") ?? "") ?? .mock
        self.afterShipAPIKey = userDefaults.string(forKey: "afterShipAPIKey") ?? ""
        self.t17APIKey = userDefaults.string(forKey: "t17APIKey") ?? ""
        self.correiosBackendURL = userDefaults.string(forKey: "correiosBackendURL") ?? ""
        self.notificationsEnabled = userDefaults.bool(forKey: "notificationsEnabled")
        self.backgroundRefreshEnabled = userDefaults.bool(forKey: "backgroundRefreshEnabled")
    }
    
    private func save() {
        userDefaults.set(providerMode.rawValue, forKey: "providerMode")
        userDefaults.set(afterShipAPIKey, forKey: "afterShipAPIKey")
        userDefaults.set(t17APIKey, forKey: "t17APIKey")
        userDefaults.set(correiosBackendURL, forKey: "correiosBackendURL")
        userDefaults.set(notificationsEnabled, forKey: "notificationsEnabled")
        userDefaults.set(backgroundRefreshEnabled, forKey: "backgroundRefreshEnabled")
        userDefaults.synchronize()
    }
    
    func makeProvider() -> any TrackingProvider {
        switch providerMode {
        case .mock:
            return MockTrackingProvider()
            
        case .afterShip:
            guard !afterShipAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                print("AfterShip API Key não configurada, usando Mock")
                return MockTrackingProvider()
            }
            return AggregatorProvider(apiKey: afterShipAPIKey, kind: .afterShip)
            
        case .t17:
            guard !t17APIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                print("17Track API Key não configurada, usando Mock")
                return MockTrackingProvider()
            }
            return AggregatorProvider(apiKey: t17APIKey, kind: .t17)
            
        case .correiosBackend:
            let urlString = correiosBackendURL.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !urlString.isEmpty, let url = URL(string: urlString) else {
                print("URL do backend dos Correios não configurada, usando Mock")
                return MockTrackingProvider()
            }
            return CorreiosProvider(baseURL: url)
        }
    }
    
    var isConfigurationValid: Bool {
        switch providerMode {
        case .mock:
            return true
        case .afterShip:
            return !afterShipAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .t17:
            return !t17APIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .correiosBackend:
            let urlString = correiosBackendURL.trimmingCharacters(in: .whitespacesAndNewlines)
            return !urlString.isEmpty && URL(string: urlString) != nil
        }
    }
    
    func resetToDefaults() {
        providerMode = .mock
        afterShipAPIKey = ""
        t17APIKey = ""
        correiosBackendURL = ""
        notificationsEnabled = true
        backgroundRefreshEnabled = true
    }
}
