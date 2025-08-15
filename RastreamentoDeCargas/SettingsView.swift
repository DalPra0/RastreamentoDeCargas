import SwiftUI
import SwiftData

struct SettingsView: View {
    @ObservedObject var settings: SettingsManager
    @Environment(\.modelContext) private var context
    @Query(sort: \Order.lastUpdated, order: .reverse) private var orders: [Order]
    
    let onProviderChange: () -> Void
    
    @State private var testTrackingCode = ""
    @State private var showingTestResult = false
    @State private var testResult: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                providerSection
                
                if settings.providerMode != .mock {
                    configurationSection
                }
                
                featuresSection
                testingSection
                aboutSection
            }
            .navigationTitle("Configurações")
        }
        .alert("Resultado do Teste", isPresented: $showingTestResult) {
            Button("OK") { }
        } message: {
            Text(testResult)
        }
    }
    
    private var providerSection: some View {
        Section {
            Picker("Provider de Rastreamento", selection: $settings.providerMode) {
                ForEach(ProviderMode.allCases) { mode in
                    VStack(alignment: .leading) {
                        Text(mode.displayName)
                        Text(mode.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .tag(mode)
                }
            }
            .pickerStyle(.navigationLink)
            .onChange(of: settings.providerMode) { _, _ in
                onProviderChange()
            }
            
            HStack {
                Text("Status da Configuração")
                Spacer()
                if settings.isConfigurationValid {
                    Label("Válida", systemImage: "checkmark.circle")
                        .foregroundStyle(.green)
                } else {
                    Label("Incompleta", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }
            .font(.caption)
        } header: {
            Text("Provider de Rastreamento")
        } footer: {
            Text("Escolha como o app deve buscar informações de rastreamento.")
        }
    }
    
    private var configurationSection: some View {
        Section {
            switch settings.providerMode {
            case .afterShip:
                SecureField("API Key do AfterShip", text: $settings.afterShipAPIKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .fontDesign(.monospaced)
                
            case .t17:
                SecureField("API Key do 17Track", text: $settings.t17APIKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .fontDesign(.monospaced)
                
            case .correiosBackend:
                TextField("URL do Backend", text: $settings.correiosBackendURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .placeholder(when: settings.correiosBackendURL.isEmpty) {
                        Text("https://seu-backend.com/api/correios/")
                            .foregroundColor(.secondary)
                    }
                
            case .mock:
                EmptyView()
            }
        } header: {
            Text("Configuração do Provider")
        } footer: {
            switch settings.providerMode {
            case .afterShip:
                Text("Obtenha sua API key em aftership.com")
            case .t17:
                Text("Obtenha sua API key em 17track.net")
            case .correiosBackend:
                Text("URL do seu backend que conecta com a API dos Correios")
            case .mock:
                EmptyView()
            }
        }
    }
    
    private var featuresSection: some View {
        Section("Recursos") {
            Toggle("Notificações de Atualização", isOn: $settings.notificationsEnabled)
            Toggle("Atualização em Background", isOn: $settings.backgroundRefreshEnabled)
                .onChange(of: settings.backgroundRefreshEnabled) { _, enabled in
                    if enabled {
                        BackgroundRefresher.schedule()
                    }
                }
            
            NavigationLink("Códigos Capturados") {
                CapturedCodesManagementView()
            }
        }
    }
    
    private var testingSection: some View {
        Section("Testes") {
            HStack {
                TextField("Código de teste", text: $testTrackingCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .fontDesign(.monospaced)
                
                Button("Testar") {
                    testProvider()
                }
                .disabled(testTrackingCode.isEmpty)
            }
            
            Button("Criar Pedido de Teste") {
                createTestOrder()
            }
            
            if !orders.isEmpty {
                Button("Atualizar Primeiro Pedido") {
                    refreshFirstOrder()
                }
            }
            
            Button("Agendar Background Refresh") {
                BackgroundRefresher.schedule()
                testResult = "Background refresh agendado"
                showingTestResult = true
            }
        }
    }
    
    private var aboutSection: some View {
        Section("Sobre") {
            HStack {
                Text("Versão do App")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Text("Build")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                    .foregroundStyle(.secondary)
            }
            
            Button("Resetar Configurações") {
                settings.resetToDefaults()
                onProviderChange()
            }
            .foregroundStyle(.red)
        }
    }
    
    private func testProvider() {
        Task {
            let provider = settings.makeProvider()
            
            do {
                let result = try await provider.fetchTracking(code: testTrackingCode, carrierHint: nil)
                testResult = """
                Status: \(result.status.displayName)
                Transportadora: \(result.carrier.displayName)
                Eventos: \(result.events.count)
                
                Últimos eventos:
                \(result.events.prefix(3).map { "• \($0.description)" }.joined(separator: "\n"))
                """
            } catch {
                testResult = "Erro: \(error.localizedDescription)"
            }
            
            showingTestResult = true
        }
    }
    
    private func createTestOrder() {
        let testOrder = Order(
            title: "Pedido de Teste",
            store: "Loja Teste",
            trackingCode: testTrackingCode.isEmpty ? "LB123456789BR" : testTrackingCode,
            status: .created
        )
        
        context.insert(testOrder)
        
        do {
            try context.save()
            testResult = "Pedido de teste criado com sucesso!"
        } catch {
            testResult = "Erro ao criar pedido: \(error.localizedDescription)"
        }
        
        showingTestResult = true
    }
    
    private func refreshFirstOrder() {
        guard let firstOrder = orders.first else { return }
        
        Task {
            let provider = settings.makeProvider()
            let viewModel = OrdersViewModel(provider: provider)
            await viewModel.refreshOrder(firstOrder, context: context)
            
            await MainActor.run {
                testResult = "Primeiro pedido atualizado: \(firstOrder.title)"
                showingTestResult = true
            }
        }
    }
}

struct CapturedCodesManagementView: View {
    @State private var capturedCodes = SharedSnapshotStore.loadCapturedCodes()
    
    var body: some View {
        List {
            if capturedCodes.isEmpty {
                ContentUnavailableView(
                    "Nenhum código capturado",
                    systemImage: "doc.badge.plus",
                    description: Text("Códigos de rastreamento capturados via Share Extension aparecerão aqui.")
                )
            } else {
                ForEach(capturedCodes, id: \.self) { code in
                    Text(code)
                        .fontDesign(.monospaced)
                        .textSelection(.enabled)
                }
                .onDelete(perform: deleteCodes)
                
                Section {
                    Button("Limpar Todos", role: .destructive) {
                        capturedCodes.removeAll()
                        SharedSnapshotStore.clearCapturedCodes()
                    }
                }
            }
        }
        .navigationTitle("Códigos Capturados")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            capturedCodes = SharedSnapshotStore.loadCapturedCodes()
        }
    }
    
    private func deleteCodes(offsets: IndexSet) {
        capturedCodes.remove(atOffsets: offsets)
        SharedSnapshotStore.saveCapturedCodes(capturedCodes)
    }
}

// MARK: - View Extensions

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
    
    func placeholder(
        _ text: String,
        when shouldShow: Bool,
        alignment: Alignment = .leading
    ) -> some View {
        placeholder(when: shouldShow, alignment: alignment) {
            Text(text).foregroundColor(.secondary)
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Order.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let settings = SettingsManager()
    
    return SettingsView(settings: settings, onProviderChange: {})
        .modelContainer(container)
}
