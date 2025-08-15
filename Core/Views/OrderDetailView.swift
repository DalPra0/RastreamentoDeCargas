import SwiftUI
import SwiftData

struct OrderDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State var order: Order
    let viewModel: OrdersViewModel
    
    @State private var showingEditOrder = false
    @State private var isRefreshing = false
    
    var body: some View {
        List {
            orderInfoSection
            
            if !order.events.isEmpty {
                trackingTimelineSection
            } else {
                emptyTimelineSection
            }
        }
        .navigationTitle(order.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        Task {
                            await refreshOrder()
                        }
                    } label: {
                        Label("Atualizar", systemImage: "arrow.clockwise")
                    }
                    .disabled(order.trackingCode == nil)
                    
                    Button {
                        showingEditOrder = true
                    } label: {
                        Label("Editar", systemImage: "pencil")
                    }
                    
                    if let url = order.orderLink {
                        Link(destination: url) {
                            Label("Abrir Link do Pedido", systemImage: "safari")
                        }
                    }
                    
                    ShareLink(
                        item: DeepLinkRouter.orderURL(for: order.id),
                        subject: Text("Pedido: \(order.title)"),
                        message: Text("Confira o status do meu pedido")
                    ) {
                        Label("Compartilhar", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .refreshable {
            await refreshOrder()
        }
        .sheet(isPresented: $showingEditOrder) {
            EditOrderView(order: order, viewModel: viewModel)
        }
    }
    
    private var orderInfoSection: some View {
        Section {
            InfoRow(label: "Loja", value: order.store)
            InfoRow(label: "Status", value: order.status.displayName, valueColor: statusColor)
            InfoRow(label: "Transportadora", value: order.carrier.displayName)
            
            if let trackingCode = order.trackingCode {
                InfoRow(label: "Código", value: trackingCode, isMonospaced: true)
            }
            
            InfoRow(label: "Criado", value: formatDate(order.createdAt))
            InfoRow(label: "Atualizado", value: formatRelativeDate(order.lastUpdated))
            
            if let orderLink = order.orderLink {
                Link(destination: orderLink) {
                    HStack {
                        Text("Link do Pedido")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.blue)
                    }
                }
            }
        } header: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Informações")
                    if isRefreshing {
                        Text("Atualizando...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if isRefreshing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
    }
    
    private var trackingTimelineSection: some View {
        Section("Linha do Tempo") {
            ForEach(order.events.sorted { $0.date > $1.date }, id: \.id) { event in
                EventRowView(event: event)
            }
        }
    }
    
    private var emptyTimelineSection: some View {
        Section("Linha do Tempo") {
            ContentUnavailableView(
                "Nenhum evento encontrado",
                systemImage: "clock.badge.questionmark",
                description: Text(order.trackingCode == nil ? 
                    "Adicione um código de rastreamento para ver os eventos" :
                    "Puxe para atualizar ou verifique o código de rastreamento")
            )
        }
    }
    
    private var statusColor: Color {
        switch order.status {
        case .created: return .gray
        case .inTransit: return .blue
        case .outForDelivery: return .orange
        case .delivered: return .green
        case .exception: return .red
        }
    }
    
    private func refreshOrder() async {
        isRefreshing = true
        await viewModel.refreshOrder(order, context: context)
        isRefreshing = false
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: .now)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    var isMonospaced: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .foregroundStyle(valueColor)
                .fontDesign(isMonospaced ? .monospaced : .default)
                .textSelection(.enabled)
        }
    }
}

struct EventRowView: View {
    let event: TrackingEvent
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Circle()
                    .fill(eventColor)
                    .frame(width: 10, height: 10)
                
                Rectangle()
                    .fill(eventColor.opacity(0.3))
                    .frame(width: 2)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(event.description)
                    .font(.body)
                
                HStack {
                    Text(formatEventDate(event.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let location = event.location {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(location)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(event.status.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(eventColor.opacity(0.2))
                        .foregroundStyle(eventColor)
                        .clipShape(Capsule())
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var eventColor: Color {
        switch event.status {
        case .created: return .gray
        case .inTransit: return .blue
        case .outForDelivery: return .orange
        case .delivered: return .green
        case .exception: return .red
        }
    }
    
    private func formatEventDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
    
    return NavigationStack {
        OrderDetailView(order: sampleOrder, viewModel: viewModel)
    }
    .modelContainer(container)
}
