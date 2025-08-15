import SwiftUI
import SwiftData

struct EditOrderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State var order: Order
    let viewModel: OrdersViewModel
    
    @State private var title: String
    @State private var store: String
    @State private var trackingCode: String
    @State private var orderLinkText: String
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, store, trackingCode, orderLink
    }
    
    init(order: Order, viewModel: OrdersViewModel) {
        self.order = order
        self.viewModel = viewModel
        self._title = State(initialValue: order.title)
        self._store = State(initialValue: order.store)
        self._trackingCode = State(initialValue: order.trackingCode ?? "")
        self._orderLinkText = State(initialValue: order.orderLink?.absoluteString ?? "")
    }
    
    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !store.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var orderURL: URL? {
        let trimmed = orderLinkText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : URL(string: trimmed)
    }
    
    var hasChanges: Bool {
        title != order.title ||
        store != order.store ||
        trackingCode != (order.trackingCode ?? "") ||
        orderLinkText != (order.orderLink?.absoluteString ?? "")
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
                    TextField("Código de rastreamento", text: $trackingCode)
                        .focused($focusedField, equals: .trackingCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .fontDesign(.monospaced)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .orderLink }
                    
                    if !trackingCode.isEmpty {
                        let normalizedCode = viewModel.normalizeTrackingCode(trackingCode)
                        HStack {
                            Text("Código válido:")
                            Spacer()
                            if normalizedCode != nil {
                                Label("Sim", systemImage: "checkmark.circle")
                                    .foregroundStyle(.green)
                            } else {
                                Label("Não", systemImage: "xmark.circle")
                                    .foregroundStyle(.red)
                            }
                        }
                        .font(.caption)
                    }
                }
                
                Section("Link do Pedido") {
                    TextField("URL do pedido", text: $orderLinkText)
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
                
                Section("Status Atual") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(order.status.displayName)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Transportadora")
                        Spacer()
                        Text(order.carrier.displayName)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Última atualização")
                        Spacer()
                        Text(order.lastUpdated, style: .relative)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section {
                    Button("Atualizar Rastreamento") {
                        Task {
                            await updateTracking()
                        }
                    }
                    .disabled(trackingCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Button("Resetar Eventos", role: .destructive) {
                        resetEvents()
                    }
                }
            }
            .navigationTitle("Editar Pedido")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        saveChanges()
                    }
                    .disabled(!isFormValid || !hasChanges)
                }
            }
        }
    }
    
    private func saveChanges() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedStore = store.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCode = trackingCode.trimmingCharacters(in: .whitespacesAndNewlines)
        
        order.title = trimmedTitle
        order.store = trimmedStore
        order.trackingCode = trimmedCode.isEmpty ? nil : trimmedCode
        order.orderLink = orderURL
        
        if let code = order.trackingCode {
            if viewModel.normalizeTrackingCode(code) != nil {
                if code.uppercased().range(of: "^[A-Z]{2}\\d{9}[A-Z]{2}$", options: .regularExpression) != nil {
                    order.carrier = .correios
                } else if code.uppercased().hasPrefix("TBA") {
                    order.carrier = .amazonLogistics
                } else if code.uppercased().hasPrefix("SE") {
                    order.carrier = .shopeeExpress
                } else {
                    order.carrier = .other
                }
            }
        }
        
        do {
            try context.save()
            dismiss()
        } catch {
            print("Erro ao salvar alterações:", error)
        }
    }
    
    private func updateTracking() async {
        await viewModel.refreshOrder(order, context: context)
    }
    
    private func resetEvents() {
        order.events = []
        order.status = .created
        order.lastUpdated = .now
        
        do {
            try context.save()
        } catch {
            print("Erro ao resetar eventos:", error)
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Order.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let viewModel = OrdersViewModel(provider: MockTrackingProvider())
    
    let sampleOrder = Order(
        title: "Smartphone Galaxy S24",
        store: "Amazon",
        carrier: .amazonLogistics,
        trackingCode: "TBA123456789",
        status: .inTransit
    )
    
    return EditOrderView(order: sampleOrder, viewModel: viewModel)
        .modelContainer(container)
}
