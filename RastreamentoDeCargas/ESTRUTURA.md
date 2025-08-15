# 📁 Estrutura de Pastas do Projeto

## Organização dos Arquivos

```
RastreamentoDeCargas/
│
├── 📱 App/
│   └── RastreamentoDeCargasApp.swift    # Arquivo principal do app
│
├── 🎯 Core/                             # Núcleo da aplicação (MVVM)
│   ├── Models/
│   │   └── Models.swift                 # Modelos de dados (Order, TrackingEvent, etc)
│   │
│   ├── ViewModels/
│   │   └── OrdersViewModel.swift        # Lógica de negócio das views
│   │
│   └── Views/                           # Todas as telas do app
│       ├── OrdersListView.swift         # Lista principal de pedidos
│       ├── OrderDetailView.swift        # Detalhes de um pedido
│       ├── AddOrderView.swift           # Adicionar novo pedido
│       ├── EditOrderView.swift          # Editar pedido existente
│       ├── SettingsView.swift           # Configurações do app
│       ├── CapturedCodesView.swift      # Códigos capturados via share
│       └── ContentView.swift            # View de conteúdo (se usada)
│
├── 🔧 Services/                         # Serviços e integrações
│   ├── Tracking/                        # Sistema de rastreamento
│   │   ├── TrackingProvider.swift      # Protocolo base
│   │   └── Providers/                  # Implementações específicas
│   │       ├── MockTrackingProvider.swift     # Para testes
│   │       ├── AggregatorProvider.swift       # AfterShip/17Track
│   │       └── CorreiosProvider.swift         # Correios direto
│   │
│   ├── Background/
│   │   └── BackgroundRefresher.swift   # Atualização em background
│   │
│   ├── Network/
│   │   └── HTTPHelper.swift            # Utilitários de rede
│   │
│   └── Storage/
│       ├── SettingsManager.swift       # Gerenciamento de configurações
│       └── SharedSnapshotStore.swift   # Armazenamento compartilhado (Widget)
│
├── 🛠 Utils/
│   └── DeepLinkRouter.swift            # Gerenciamento de deep links
│
├── 🎨 Assets.xcassets/                 # Imagens e cores
│   ├── AppIcon.appiconset/            # Ícone do app
│   └── AccentColor.colorset/          # Cores do tema
│
├── 📄 Info.plist                       # Configurações do app
└── 🔐 RastreamentoDeCargas.entitlements # Permissões e capabilities
```

## 🎯 Descrição das Pastas

### **App/**
Contém o arquivo principal que inicializa o aplicativo e configura o ambiente.

### **Core/**
O coração do aplicativo seguindo arquitetura MVVM:
- **Models**: Estruturas de dados e entidades
- **ViewModels**: Lógica de negócio e estado
- **Views**: Interface do usuário em SwiftUI

### **Services/**
Serviços isolados e reutilizáveis:
- **Tracking**: Todo o sistema de rastreamento modular
- **Background**: Tarefas em segundo plano
- **Network**: Comunicação com APIs
- **Storage**: Persistência e configurações

### **Utils/**
Utilitários e helpers que não se encaixam em outras categorias.

## 🔄 Fluxo de Dados

```
Views ←→ ViewModels ←→ Services ←→ APIs/Storage
                ↓
             Models
```

## 📱 Adicionando ao Xcode

Após mover os arquivos:

1. **No Xcode**, remova as referências antigas (ficaram vermelhas)
2. Clique direito no projeto → "Add Files to..."
3. Navegue até a pasta RastreamentoDeCargas
4. Selecione todas as novas pastas
5. Marque "Create groups" e "Add to targets"
6. Build o projeto para verificar

## ✅ Benefícios desta Estrutura

- **Organização Clara**: Fácil encontrar qualquer arquivo
- **Separação de Responsabilidades**: Cada pasta tem um propósito
- **Escalabilidade**: Fácil adicionar novos recursos
- **Manutenibilidade**: Código mais limpo e organizado
- **Colaboração**: Outros desenvolvedores entendem rapidamente

## 🚀 Próximos Passos

1. Atualizar imports nos arquivos se necessário
2. Rebuild o projeto no Xcode
3. Testar todas as funcionalidades
4. Commit das mudanças no Git
