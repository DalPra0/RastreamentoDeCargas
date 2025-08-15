import WidgetKit
import SwiftUI
import AppIntents

struct OrderEntry: TimelineEntry {
    let date: Date
    let orderId: UUID?
    let title: String
    let status: String
    let subtitle: String
    let hasData: Bool
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> OrderEntry {
        OrderEntry(
            date: .now,
            orderId: nil,
            title: "Smartphone Galaxy S24",
            status: "inTransit",
            subtitle: "Objeto em trânsito · Curitiba, PR · 14:30",
            hasData: false
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (OrderEntry) -> Void) {
        let entry = loadLatestOrder() ?? placeholder(in: context)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<OrderEntry>) -> Void) {
        let entry = loadLatestOrder() ?? placeholder(in: context)
        
        // Atualiza a cada 30 minutos
        let nextUpdate = Date().addingTimeInterval(30 * 60)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func loadLatestOrder() -> OrderEntry? {
        let catalog = SharedSnapshotStore.loadCatalog()
        
        guard let latestOrder = catalog.sorted(by: { $0.lastUpdated > $1.lastUpdated }).first else {
            return nil
        }
        
        if let snapshot = SharedSnapshotStore.loadSnapshot(orderId: latestOrder.id) {
            return OrderEntry(
                date: snapshot.date,
                orderId: snapshot.orderId,
                title: snapshot.title,
                status: snapshot.status,
                subtitle: snapshot.subtitle,
                hasData: true
            )
        } else {
            return OrderEntry(
                date: .now,
                orderId: latestOrder.id,
                title: latestOrder.title,
                status: "created",
                subtitle: "Sem eventos ainda",
                hasData: true
            )
        }
    }
}

struct RastreamentoDeCargasWidgetEntryView: View {
    var entry: Provider.Entry
    
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "created": return .gray
        case "intransit": return .blue
        case "outfordelivery": return .orange
        case "delivered": return .green
        case "exception": return .red
        default: return .blue
        }
    }
    
    private func statusDisplayName(_ status: String) -> String {
        switch status.lowercased() {
        case "created": return "Criado"
        case "intransit": return "Em Trânsito"
        case "outfordelivery": return "Saiu para Entrega"
        case "delivered": return "Entregue"
        case "exception": return "Exceção"
        default: return "Desconhecido"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if entry.hasData {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Text(entry.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Circle()
                            .fill(statusColor(entry.status))
                            .frame(width: 12, height: 12)
                        
                        Text(statusDisplayName(entry.status))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                HStack {
                    Text("Toque para abrir")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(entry.date, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "shippingbox")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    
                    Text("Nenhum pedido")
                        .font(.headline)
                    
                    Text("Adicione um pedido no app")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .widgetURL(widgetURL)
    }
    
    private var widgetURL: URL? {
        if let orderId = entry.orderId {
            return URL(string: "rastreamento://order/\(orderId.uuidString)")
        } else {
            return URL(string: "rastreamento://add")
        }
    }
}

struct RastreamentoDeCargasWidget: Widget {
    let kind: String = "RastreamentoDeCargasWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            RastreamentoDeCargasWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Rastreamento de Cargas")
        .description("Acompanhe o status do seu pedido mais recente.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    RastreamentoDeCargasWidget()
} timeline: {
    OrderEntry(
        date: .now,
        orderId: UUID(),
        title: "Smartphone Galaxy S24",
        status: "inTransit",
        subtitle: "Objeto em trânsito · Curitiba, PR · 14:30",
        hasData: true
    )
    OrderEntry(
        date: .now,
        orderId: UUID(),
        title: "Fone Bluetooth",
        status: "delivered",
        subtitle: "Entregue ao destinatário · 12:45",
        hasData: true
    )
}
