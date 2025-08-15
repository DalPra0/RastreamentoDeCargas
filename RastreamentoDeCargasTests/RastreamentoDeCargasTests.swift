import XCTest
@testable import RastreamentoDeCargas

final class RastreamentoDeCargasTests: XCTestCase {
    
    var mockProvider: MockTrackingProvider!
    
    override func setUpWithError() throws {
        mockProvider = MockTrackingProvider()
    }
    
    override func tearDownWithError() throws {
        mockProvider = nil
    }
    
    // MARK: - TrackingProvider Tests
    
    func testCorreiosCodeValidation() throws {
        // Testa códigos válidos dos Correios
        let validCodes = [
            "LB123456789BR",
            "AB987654321CN",
            "CP555666777US"
        ]
        
        for code in validCodes {
            let normalized = mockProvider.normalizeIfTrackingCode(code)
            XCTAssertNotNil(normalized, "Código \(code) deveria ser válido")
            XCTAssertEqual(normalized, code, "Código normalizado deveria ser igual ao original")
        }
    }
    
    func testInvalidCodesRejection() throws {
        // Testa códigos inválidos
        let invalidCodes = [
            "123456789",      // Muito curto
            "ABCDEFGHIJ",     // Sem números
            "AB12345678BR",   // Números insuficientes
            "LB1234567890BR", // Números em excesso
            "lb123456789br"   // Minúsculas (deve funcionar após normalização)
        ]
        
        for code in invalidCodes {
            let normalized = mockProvider.normalizeIfTrackingCode(code)
            if code == "lb123456789br" {
                XCTAssertEqual(normalized, "LB123456789BR", "Deve normalizar para maiúsculas")
            } else {
                XCTAssertNil(normalized, "Código \(code) deveria ser rejeitado")
            }
        }
    }
    
    func testMockProviderReturnsData() async throws {
        // Testa se o provider mock retorna dados
        let result = try await mockProvider.fetchTracking(code: "LB123456789BR", carrierHint: nil)
        
        XCTAssertEqual(result.carrier, .correios)
        XCTAssertFalse(result.events.isEmpty, "Deve retornar pelo menos um evento")
        XCTAssertNotEqual(result.status, .created, "Status deve ter mudado do inicial")
    }
    
    func testTrackingCodeExtraction() throws {
        // Testa extração de códigos de texto
        let sampleText = """
        Olá! Seu pedido foi enviado.
        Código de rastreamento: LB123456789BR
        Também temos este outro: TBA987654321
        E-mail de confirmação em anexo.
        """
        
        let extractedCodes = mockProvider.extractTrackingCodes(from: sampleText)
        
        XCTAssertTrue(extractedCodes.contains("LB123456789BR"), "Deve extrair código dos Correios")
        XCTAssertTrue(extractedCodes.contains("TBA987654321"), "Deve extrair código genérico")
    }
    
    // MARK: - Model Tests
    
    func testOrderCreation() throws {
        let order = Order(
            title: "Teste",
            store: "Loja Teste",
            carrier: .correios,
            trackingCode: "LB123456789BR",
            status: .created
        )
        
        XCTAssertEqual(order.title, "Teste")
        XCTAssertEqual(order.store, "Loja Teste")
        XCTAssertEqual(order.carrier, .correios)
        XCTAssertEqual(order.trackingCode, "LB123456789BR")
        XCTAssertEqual(order.status, .created)
        XCTAssertTrue(order.events.isEmpty, "Novo pedido deve ter lista de eventos vazia")
    }
    
    func testTrackingEventSerialization() throws {
        let event = TrackingEvent(
            date: Date(),
            status: .inTransit,
            description: "Objeto em trânsito",
            location: "São Paulo, SP"
        )
        
        let events = [event]
        let order = Order(
            title: "Teste",
            store: "Loja",
            events: events
        )
        
        XCTAssertEqual(order.events.count, 1)
        XCTAssertEqual(order.events.first?.description, "Objeto em trânsito")
        XCTAssertEqual(order.events.first?.location, "São Paulo, SP")
    }
    
    // MARK: - Settings Tests
    
    func testSettingsManager() throws {
        let settings = SettingsManager()
        
        // Testa configuração padrão
        XCTAssertEqual(settings.providerMode, .mock)
        XCTAssertTrue(settings.isConfigurationValid, "Configuração mock deve ser sempre válida")
        
        // Testa mudança de provider
        settings.providerMode = .afterShip
        XCTAssertFalse(settings.isConfigurationValid, "AfterShip sem API key deve ser inválido")
        
        settings.afterShipAPIKey = "test-key"
        XCTAssertTrue(settings.isConfigurationValid, "AfterShip com API key deve ser válido")
    }
    
    func testProviderCreation() throws {
        let settings = SettingsManager()
        
        // Mock provider
        settings.providerMode = .mock
        let mockProvider = settings.makeProvider()
        XCTAssertTrue(mockProvider is MockTrackingProvider)
        
        // AfterShip provider
        settings.providerMode = .afterShip
        settings.afterShipAPIKey = "test-key"
        let afterShipProvider = settings.makeProvider()
        XCTAssertTrue(afterShipProvider is AggregatorProvider)
    }
    
    // MARK: - Deep Link Tests
    
    func testDeepLinkURLGeneration() throws {
        let orderId = UUID()
        let orderURL = DeepLinkRouter.orderURL(for: orderId)
        
        XCTAssertEqual(orderURL.scheme, "rastreamento")
        XCTAssertEqual(orderURL.host, "order")
        XCTAssertTrue(orderURL.path.contains(orderId.uuidString))
    }
    
    func testDeepLinkParsing() throws {
        let router = DeepLinkRouter.shared
        let orderId = UUID()
        let url = URL(string: "rastreamento://order/\(orderId.uuidString)")!
        
        router.handleURL(url)
        
        XCTAssertEqual(router.pendingOrderId, orderId)
        
        if case .openOrder(let id) = router.pendingAction {
            XCTAssertEqual(id, orderId)
        } else {
            XCTFail("Ação pendente deveria ser openOrder")
        }
    }
    
    // MARK: - Performance Tests
    
    func testTrackingCodeExtractionPerformance() throws {
        let largeText = String(repeating: "LB123456789BR TBA987654321 ", count: 1000)
        
        measure {
            _ = mockProvider.extractTrackingCodes(from: largeText)
        }
    }
    
    func testMockProviderPerformance() throws {
        measure {
            Task {
                _ = try await mockProvider.fetchTracking(code: "LB123456789BR", carrierHint: nil)
            }
        }
    }
}

// MARK: - Test Extensions

extension XCTestCase {
    func waitForAsync<T>(
        _ asyncExpression: @escaping () async throws -> T,
        timeout: TimeInterval = 5.0
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await asyncExpression()
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}
