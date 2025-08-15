import SwiftUI
import SwiftData
import BackgroundTasks
import UserNotifications

@main
struct RastreamentoDeCargasApp: App {
    @StateObject private var settings = SettingsManager()
    @StateObject private var router = DeepLinkRouter.shared
    @State private var provider: any TrackingProvider = MockTrackingProvider()
    
    init() {
        // Configuração inicial do background refresh
        setupBackgroundRefresh()
        
        // Solicitar permissões de notificação (movido para onAppear)
        // Não podemos acessar @StateObject no init
        Task {
            await BackgroundRefresher.requestNotificationPermission()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            TabView {
                OrdersListView(viewModel: OrdersViewModel(provider: provider))
                    .tabItem {
                        Label("Pedidos", systemImage: "shippingbox")
                    }
                
                SettingsView(settings: settings) {
                    updateProvider()
                }
                .tabItem {
                    Label("Configurações", systemImage: "gearshape")
                }
            }
            .onAppear {
                updateProvider()
                scheduleBackgroundRefresh()
                loadCapturedCodes()
                requestNotificationPermissions()
            }
            .onOpenURL { url in
                router.handleURL(url)
            }
            .environmentObject(router)
        }
        .modelContainer(for: Order.self)
    }
    
    private func updateProvider() {
        provider = settings.makeProvider()
        BackgroundRefresher.register(provider: provider)
    }
    
    private func setupBackgroundRefresh() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundRefresher.taskIdentifier,
            using: nil
        ) { task in
            Task {
                await BackgroundRefresher.handleBackgroundRefresh(
                    task: task as! BGAppRefreshTask,
                    provider: self.provider
                )
            }
        }
    }
    
    private func scheduleBackgroundRefresh() {
        if settings.backgroundRefreshEnabled {
            BackgroundRefresher.schedule()
        }
    }
    
    private func requestNotificationPermissions() {
        if settings.notificationsEnabled {
            Task {
                await BackgroundRefresher.requestNotificationPermission()
            }
        }
    }
    
    private func loadCapturedCodes() {
        // Processa códigos capturados via Share Extension
        let capturedCodes = SharedSnapshotStore.loadCapturedCodes()
        if !capturedCodes.isEmpty {
            print("Códigos capturados encontrados: \(capturedCodes.count)")
            
            // Notifica o usuário sobre códigos capturados
            if settings.notificationsEnabled {
                Task {
                    await sendCapturedCodesNotification(count: capturedCodes.count)
                }
            }
        }
    }
    
    private func sendCapturedCodesNotification(count: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "Códigos de Rastreamento Capturados"
        content.body = count == 1 ? 
            "1 código de rastreamento foi capturado" :
            "\(count) códigos de rastreamento foram capturados"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "captured_codes",
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Erro ao enviar notificação de códigos capturados:", error)
        }
    }
}
