import SwiftUI
import SwiftData

struct OrdersListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Order.lastUpdated, order: .reverse) private var orders: [Order]
    
    @StateObject private var viewModel: OrdersViewModel
    @StateObject private var router = DeepLinkRouter.shared
    
    @State private var showingAddOrder = false
    @State private var showingCapturedCodes = false
    @State private var selectedOrder: Order?
    @State private var searchText = ""
    
    init(viewModel: OrdersViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var filteredOrders: [Order] {
        if searchText.isEmpty {
            return orders
        }
        
        var filtered: [Order] = []
        let lowercaseSearch = searchText.lowercased()
        
        for order in orders {
            let titleContains = order.title.lowercased().contains(lowercaseSearch)
            let storeContains = order.store.lowercased().contains(lowercaseSearch)
            
            var codeContains = false
            if let code = order.trackingCode {
                codeContains = code.lowercased().contains(lowercaseSearch)
            }
            
            if titleContains || storeContains || codeContains {
                filtered.append(order)
            }
        }
        return filtered
    }
    
    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Rastreamento")
                .searchable(text: $searchText, prompt: "Buscar pedidos...")
                .toolbar {
                    leadingToolbar
                    trailingToolbar
                }
                .refreshable {
                    await refreshAction()
                }
                .sheet(isPresented: $showingAddOrder) {
                    AddOrderView(viewModel: viewModel)
                }
                .sheet(isPresented: $showingCapturedCodes) {
                    CapturedCodesView(viewModel: viewModel)
                }
                .navigationDestination(item: $selectedOrder) { order in
                    OrderDetailView(order: order, viewModel: viewModel)
                }
                .onAppear {
                    viewModel.loadCapturedCodes()
                }
                .onChange(of: router.pendingOrderId) { _, newValue in
                    handlePendingOrderId(newValue)
                }
                .onChange(of: router.pendingAction) { _, action in
                    handlePendingAction(action)
                }
        }
        .alert("Erro", isPresented: errorBinding) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private var contentView: some View {
        Group {
            if orders.isEmpty {
                emptyStateView
            } else {
                ordersList
            }
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "Nenhum pedido ainda",
            systemImage: "shippingbox",
            description: Text("Toque em + para adicionar seu primeiro pedido para rastreamento.")
        )
    }
    
    private var ordersList: some View {
        List {
            ForEach(filteredOrders) { order in
                OrderRowView(order: order, viewModel: viewModel)
                    .onTapGesture {
                        selectedOrder = order
                    }
            }
            .onDelete(perform: deleteOrders)
        }
    }
    
    @ToolbarContentBuilder
    private var leadingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !viewModel.capturedCodes.isEmpty {
                Button {
                    showingCapturedCodes = true
                } label: {
                    Label("\(viewModel.capturedCodes.count)", systemImage: "doc.badge.plus")
                }
            }
        }
    }
    
    @ToolbarContentBuilder
    private var trailingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showingAddOrder = true
            } label: {
                Image(systemName: "plus.circle.fill")
            }
        }
    }
    
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in }
        )
    }
    
    private func refreshAction() async {
        await viewModel.refreshAllOrders(filteredOrders, context: context)
    }
    
    private func handlePendingOrderId(_ orderId: UUID?) {
        guard let orderId = orderId else { return }
        
        for order in orders {
            if order.id == orderId {
                selectedOrder = order
                router.clearPendingAction()
                break
            }
        }
    }
    
    private func handlePendingAction(_ action: DeepLinkRouter.DeepLinkAction?) {
        guard let action = action else { return }
        
        switch action {
        case .addOrder:
            showingAddOrder = true
            router.clearPendingAction()
        case .openOrder:
            break // Já tratado pelo pendingOrderId
        case .settings:
            router.clearPendingAction()
        }
    }
    
    private func deleteOrders(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                viewModel.deleteOrder(filteredOrders[index], context: context)
            }
        }
    }
}

struct OrderRowView: View {
    let order: Order
    let viewModel: OrdersViewModel
    @Environment(\.modelContext) private var context
    
    var body: some View {
        HStack(spacing: 12) {
            statusIndicator
            
            orderInfo
            
            Spacer()
            
            trailingInfo
        }
        .padding(.vertical, 4)
    }
    
    private var statusIndicator: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            
            Text(order.carrier.displayName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: 50)
    }
    
    private var orderInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(order.title)
                .font(.headline)
                .lineLimit(1)
            
            Text(order.store)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if let trackingCode = order.trackingCode {
                Text(trackingCode)
                    .font(.caption)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.secondary)
            }
            
            if let latestEvent = order.latestEvent {
                Text(latestEvent.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
    
    private var trailingInfo: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(order.lastUpdated, style: .relative)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            refreshButton
        }
    }
    
    private var refreshButton: some View {
        Group {
            if viewModel.isRefreshing {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Button {
                    Task {
                        await viewModel.refreshOrder(order, context: context)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
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
}

#Preview {
    let container = try! ModelContainer(for: Order.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let viewModel = OrdersViewModel(provider: MockTrackingProvider())
    
    return OrdersListView(viewModel: viewModel)
        .modelContainer(container)
}
