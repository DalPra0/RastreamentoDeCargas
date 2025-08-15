import SwiftUI
import SwiftData

struct AddOrderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    let viewModel: OrdersViewModel
    
    @State private var title = ""
    @State private var store = ""
    @State private var trackingCode = ""
    @State private var orderLinkText = ""
    @State private var selectedCarrier = Carrier.unknown
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, store, trackingCode, orderLink
    }
    
    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !store.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var orderURL: URL? {
        let trimmed = orderLinkText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : URL(string: trimmed)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Informações do Pedido") {
                    TextField("Título do produto", text: $title)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .store }
                    
                    TextField("Nome da loja", text: $store)
                        .focused($focusedField, equals: .store)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .trackingCode }
                }
                
                Section("Rastreamento") {
                    TextField("Código de rastreamento (opcional)", text: $trackingCode)
                        .focused($focusedField, equals: .trackingCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .fontDesign(.monospaced)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .orderLink }
                        .onChange(of: trackingCode) { _, newValue in
                            updateCarrierFromCode(newValue)
                        }
                    
                    if !trackingCode.isEmpty {
                        HStack {
                            Text("Transportadora detectada:")
                            Spacer()
                            Text(selectedCarrier.displayName)
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }
                }
                
                Section("Link do Pedido") {
                    TextField("URL do pedido (opcional)", text: $orderLinkText)
                        .focused($focusedField, equals: .orderLink)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                    
                    if !orderLinkText.isEmpty && orderURL == nil {
                        Label("URL inválida", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                
                Section {
                    suggestedInputsView
                }
            }
            .navigationTitle("Novo Pedido")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        saveOrder()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var suggestedInputsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if title.isEmpty {
                Text("Sugestões de título:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 4) {
                    ForEach(titleSuggestions, id: \.self) { suggestion in
                        Button(suggestion) {
                            title = suggestion
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                }
            }
            
            if store.isEmpty {
                Text("Lojas populares:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 4) {
                    ForEach(storeSuggestions, id: \.self) { suggestion in
                        Button(suggestion) {
                            store = suggestion
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                }
            }
        }
    }
    
    private let titleSuggestions = [
        "Smartphone", "Fone de Ouvido", "Carregador", "Cabo USB",
        "Mouse", "Teclado", "Notebook", "Tablet", "Smartwatch", "Livro"
    ]
    
    private let storeSuggestions = [
        "Amazon", "Shopee", "Mercado Livre", "Casas Bahia",
        "Magazine Luiza", "Americanas", "Submarino", "Kabum",
        "Ponto Frio", "Extra"
    ]
    
    private func updateCarrierFromCode(_ code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if viewModel.normalizeTrackingCode(trimmed) != nil {
            if trimmed.uppercased().range(of: "^[A-Z]{2}\\d{9}[A-Z]{2}$", options: .regularExpression) != nil {
                selectedCarrier = .correios
            } else if trimmed.uppercased().hasPrefix("TBA") {
                selectedCarrier = .amazonLogistics
            } else if trimmed.uppercased().hasPrefix("SE") {
                selectedCarrier = .shopeeExpress
            } else {
                selectedCarrier = .other
            }
        } else {
            selectedCarrier = .unknown
        }
    }
    
    private func saveOrder() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedStore = store.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCode = trackingCode.trimmingCharacters(in: .whitespacesAndNewlines)
        
        viewModel.addOrder(
            title: trimmedTitle,
            store: trimmedStore,
            trackingCode: trimmedCode.isEmpty ? nil : trimmedCode,
            orderLink: orderURL,
            context: context
        )
        
        dismiss()
    }
}

#Preview {
    let container = try! ModelContainer(for: Order.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let viewModel = OrdersViewModel(provider: MockTrackingProvider())
    
    return AddOrderView(viewModel: viewModel)
        .modelContainer(container)
}
