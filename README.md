# Rastreamento de Cargas

Um aplicativo iOS completo para rastreamento de pedidos e encomendas, desenvolvido em SwiftUI.

## Funcionalidades

### Core
- ✅ Gerenciamento completo de pedidos (CRUD)
- ✅ Múltiplos providers de rastreamento (Mock, AfterShip, 17Track, Correios)
- ✅ Interface SwiftUI moderna e responsiva
- ✅ Persistência com SwiftData
- ✅ Busca e filtros

### Rastreamento
- ✅ Detecção automática de transportadoras
- ✅ Timeline de eventos de rastreamento
- ✅ Atualização manual e automática
- ✅ Suporte a códigos dos Correios, Amazon, Shopee

### Automação
- ✅ Background refresh automático
- ✅ Notificações de mudança de status
- ✅ Share Extension para captura de códigos
- ✅ Widget para tela inicial

### Configuração
- ✅ Sistema modular de providers
- ✅ Configurações de API keys
- ✅ Testes integrados
- ✅ Deep links

## Estrutura do Projeto

```
RastreamentoDeCargas/
├── Models/
│   ├── Models.swift              # Order, TrackingEvent, Enums
│   └── SharedSnapshotStore.swift # Armazenamento compartilhado
├── Providers/
│   ├── TrackingProvider.swift    # Protocol base
│   ├── MockTrackingProvider.swift
│   ├── AggregatorProvider.swift  # AfterShip, 17Track
│   └── CorreiosProvider.swift
├── ViewModels/
│   ├── OrdersViewModel.swift     # Lógica principal
│   └── SettingsManager.swift     # Configurações
├── Views/
│   ├── OrdersListView.swift      # Lista de pedidos
│   ├── OrderDetailView.swift     # Detalhes do pedido
│   ├── AddOrderView.swift        # Adicionar pedido
│   ├── EditOrderView.swift       # Editar pedido
│   ├── CapturedCodesView.swift   # Códigos capturados
│   └── SettingsView.swift        # Configurações
├── Services/
│   ├── BackgroundRefresher.swift # Background tasks
│   ├── DeepLinkRouter.swift      # Deep links
│   └── HTTPHelper.swift          # Requisições HTTP
└── Widget/
    └── RastreamentoDeCargasWidget.swift
```

## Configuração

### 1. Providers de Rastreamento

#### Mock (Desenvolvimento)
- Simula dados para testes
- Não requer configuração

#### AfterShip
1. Crie uma conta em [aftership.com](https://aftership.com)
2. Obtenha sua API key
3. Configure nas Configurações do app

#### 17Track
1. Crie uma conta em [17track.net](https://17track.net)
2. Obtenha sua API key
3. Configure nas Configurações do app

#### Correios (Backend)
1. Implemente um backend que conecte com a API dos Correios
2. Configure a URL do backend nas Configurações

### 2. App Groups
Certifique-se de que o App Group `group.com.lucasdalpra.RastreamentoDeCargas` esteja configurado:
1. No Xcode, vá em Signing & Capabilities
2. Adicione "App Groups"
3. Marque o grupo correto para App e Widget

### 3. Background Refresh
1. Ative "Background Fetch" em Capabilities
2. Configure o identificador `com.lucasdalpra.RastreamentoDeCargas.refresh` no Info.plist

### 4. Notificações
1. Ative "Push Notifications" em Capabilities
2. O app solicitará permissão automaticamente

### 5. Deep Links
URLs suportadas:
- `rastreamento://order/{uuid}` - Abre pedido específico
- `rastreamento://add?code={codigo}` - Adiciona pedido com código
- `rastreamento://settings` - Abre configurações

## Como Usar

### Adicionando Pedidos
1. Toque no botão "+" na tela principal
2. Preencha as informações do pedido
3. Adicione o código de rastreamento (opcional)
4. Salve o pedido

### Captura Automática
1. Em outros apps (Email, WhatsApp, etc.), selecione texto com códigos
2. Toque em "Compartilhar" > "Rastreamento de Cargas"
3. Os códigos aparecerão na tela principal para criar pedidos

### Widget
1. Adicione o widget à tela inicial
2. Mostra o status do pedido mais recente
3. Toque para abrir o app diretamente no pedido

### Background Refresh
- O app atualiza pedidos automaticamente a cada hora
- Receba notificações quando o status mudar
- Configure nas Configurações

## Desenvolvimento

### Requisitos
- Xcode 15+
- iOS 17+
- Swift 5.9+

### Testando
1. Use o provider Mock para desenvolvimento
2. Teste códigos: `LB123456789BR` (Correios), `TBA987654321` (Amazon)
3. Use a seção "Testes" nas Configurações

### Expandindo Providers
Para adicionar novos providers:
1. Implemente o protocol `TrackingProvider`
2. Adicione à enum `ProviderMode`
3. Configure no `SettingsManager.makeProvider()`

## Arquitetura

### MVVM + SwiftData
- **Models**: Entidades de dados com SwiftData
- **ViewModels**: Lógica de negócio e estado
- **Views**: Interface SwiftUI reativa
- **Providers**: Abstração para diferentes APIs

### Modularidade
- Providers intercambiáveis
- Configuração dinâmica
- Testes isolados
- Expansão facilitada

### Performance
- Background refresh otimizado
- Cache via App Groups
- Lazy loading de dados
- Compressão de eventos

## Próximos Passos

- [ ] Share Extension target
- [ ] Suporte a Universal Links
- [ ] Filtros avançados (status, transportadora)
- [ ] Exportação de dados
- [ ] Integração com Siri Shortcuts
- [ ] Modo escuro personalizado
- [ ] Análise de tendências de entrega

## Licença

MIT License - veja LICENSE para detalhes.
