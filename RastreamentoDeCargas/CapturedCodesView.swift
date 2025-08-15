import SwiftUI
import SwiftData

struct CapturedCodesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @ObservedObject var viewModel: OrdersViewModel
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.capturedCodes.isEmpty {
                    ContentUnavailableView(
                        "Nenhum código capturado",
                        systemImage: "doc.badge.plus",
                        description: Text("Use o botão \"Compartilhar\" em outros apps para capturar códigos de rastreamento automaticamente.")
                    )
                } else {
                    Section {
                        ForEach(viewModel.capturedCodes, id: \.self) { code in
                            CapturedCodeRow(
                                code: code,
                                onCreateOrder: {
                                    viewModel.createOrderFromCapturedCode(code, context: context)
                                },
                                onIgnore: {
                                    removeCode(code)
                                }
                            )
                        }
                    } header: {
                        Text("Códigos Capturados (\(viewModel.capturedCodes.count))")
                    } footer: {
                        Text("Estes códigos foram encontrados em textos compartilhados com o app.")
                    }
                    
                    Section {
                        Button("Limpar Todos", role: .destructive) {
                            viewModel.clearCapturedCodes()
                        }
                    }
                }
            }
            .navigationTitle("Códigos Capturados")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func removeCode(_ code: String) {
        viewModel.capturedCodes.removeAll { $0 == code }
        SharedSnapshotStore.saveCapturedCodes(viewModel.capturedCodes)
    }
}

struct CapturedCodeRow: View {
    let code: String
    let onCreateOrder: () -> Void
    let onIgnore: () -> Void
    
    @State private var showingDetails = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(code)
                    .font(.body)
                    .fontDesign(.monospaced)
                    .textSelection(.enabled)
                
                Text(carrierInfo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button("Ignorar") {
                    onIgnore()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Criar Pedido") {
                    onCreateOrder()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var carrierInfo: String {
        if code.uppercased().range(of: "^[A-Z]{2}\\d{9}[A-Z]{2}$", options: .regularExpression) != nil {
            return "Correios • Código válido"
        } else if code.uppercased().hasPrefix("TBA") {
            return "Amazon Logistics • Possível código"
        } else if code.uppercased().hasPrefix("SE") {
            return "Shopee Express • Possível código"
        } else {
            return "Transportadora desconhecida • \(code.count) caracteres"
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Order.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let viewModel = OrdersViewModel(provider: MockTrackingProvider())
    viewModel.capturedCodes = ["LB123456789BR", "TBA987654321", "SE555666777"]
    
    return CapturedCodesView(viewModel: viewModel)
        .modelContainer(container)
}
