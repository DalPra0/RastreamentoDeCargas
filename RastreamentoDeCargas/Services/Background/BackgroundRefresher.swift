import Foundation
import BackgroundTasks
import SwiftData
import UserNotifications

enum BackgroundRefresher {
    static let taskIdentifier = "com.lucasdalpra.RastreamentoDeCargas.refresh"
    
    static func register(provider: any TrackingProvider) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            Task {
                await handleBackgroundRefresh(task: task as! BGAppRefreshTask, provider: provider)
            }
        }
    }
    
    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60) // 1 hora
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background refresh agendado")
        } catch {
            print("Erro ao agendar background refresh:", error)
        }
    }
    
    @MainActor
    static func handleBackgroundRefresh(task: BGAppRefreshTask, provider: any TrackingProvider) async {
        print("Executando background refresh")
        
        // Agenda a próxima execução
        schedule()
        
        // Configura expiração
        task.expirationHandler = {
            print("Background refresh expirado")
            task.setTaskCompleted(success: false)
        }
        
        do {
            let container = try ModelContainer(for: Order.self)
            let context = ModelContext(container)
            
            let descriptor = FetchDescriptor<Order>()
            let orders = try context.fetch(descriptor)
            
            var updatedCount = 0
            
            // Atualiza apenas pedidos que não estão entregues
            let activeOrders = orders.filter { $0.status != .delivered }
            
            for order in activeOrders.prefix(5) { // Limita a 5 para não consumir muito tempo
                let oldStatus = order.status
                
                if let trackingCode = order.trackingCode {
                    do {
                        let result = try await provider.fetchTracking(code: trackingCode, carrierHint: order.carrier)
                        
                        order.status = result.status
                        order.carrier = result.carrier
                        order.events = result.events
                        order.lastUpdated = .now
                        
                        // Salva snapshot para o widget
                        saveOrderSnapshot(order)
                        
                        if order.status != oldStatus {
                            await sendNotification(for: order, oldStatus: oldStatus)
                            updatedCount += 1
                        }
                    } catch {
                        print("Erro ao atualizar pedido \(order.title):", error)
                    }
                }
            }
            
            try context.save()
            updateCatalog(orders: orders)
            
            print("Background refresh concluído: \(updatedCount) pedidos atualizados")
            task.setTaskCompleted(success: true)
            
        } catch {
            print("Erro no background refresh:", error)
            task.setTaskCompleted(success: false)
        }
    }
    
    static func sendNotification(for order: Order, oldStatus: OrderStatus) async {
        await requestNotificationPermission()
        
        let content = UNMutableNotificationContent()
        content.title = order.title
        content.body = "Status mudou de \(oldStatus.displayName) para \(order.status.displayName)"
        content.sound = .default
        
        // Adiciona ação para abrir o pedido
        let openAction = UNNotificationAction(
            identifier: "OPEN_ORDER",
            title: "Ver Detalhes",
            options: [.foreground]
        )
        
        let category = UNNotificationCategory(
            identifier: "ORDER_UPDATE",
            actions: [openAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "ORDER_UPDATE"
        content.userInfo = ["orderId": order.id.uuidString]
        
        let request = UNNotificationRequest(
            identifier: "order_\(order.id.uuidString)",
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Notificação enviada para \(order.title)")
        } catch {
            print("Erro ao enviar notificação:", error)
        }
    }
    
    static func requestNotificationPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            print("Permissão de notificação: \(granted)")
        } catch {
            print("Erro ao solicitar permissão de notificação:", error)
        }
    }
    
    static func saveOrderSnapshot(_ order: Order) {
        let subtitle = order.latestEvent?.description ?? "Sem eventos"
        let snapshot = SnapshotDTO(
            date: .now,
            orderId: order.id,
            title: order.title,
            status: order.status.rawValue,
            subtitle: subtitle
        )
        
        SharedSnapshotStore.saveSnapshot(snapshot)
    }
    
    static func updateCatalog(orders: [Order]) {
        let catalog = orders.map { order in
            OrderSummaryDTO(
                id: order.id,
                title: order.title,
                lastUpdated: order.lastUpdated
            )
        }
        
        SharedSnapshotStore.saveCatalog(catalog)
    }
}
