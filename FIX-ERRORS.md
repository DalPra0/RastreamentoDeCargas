# 🔧 CORREÇÃO DOS ERROS DO XCODE

## ✅ ERRO 1: StateObject no init() - CORRIGIDO!
O código já foi atualizado. Não acessamos mais @StateObject no init().

## ✅ ERRO 2: SharedSnapshotStore no Widget - CORRIGIDO!
Arquivo criado em: `RastreamentoDeCargasWidget/SharedSnapshotStore.swift`

### No Xcode, faça:
1. Selecione o arquivo `SharedSnapshotStore.swift` na pasta do Widget
2. No painel direito, em "Target Membership"
3. Marque ✅ RastreamentoDeCargasWidgetExtension

## ⚠️ ERRO 3: Certificado de Assinatura do Widget

### Passo a Passo para Corrigir:

#### 1. Selecione o Projeto no Xcode
- Clique no projeto (ícone azul no topo)

#### 2. Configure o App Principal
- Selecione o target **"RastreamentoDeCargas"**
- Vá em **"Signing & Capabilities"**
- Certifique-se que:
  - ✅ "Automatically manage signing" está marcado
  - Team: Selecione seu time de desenvolvimento
  - Bundle Identifier: `com.lucasdalpra.RastreamentoDeCargas`

#### 3. Configure o Widget com MESMO Team
- Selecione o target **"RastreamentoDeCargasWidgetExtension"**
- Vá em **"Signing & Capabilities"**
- Configure EXATAMENTE igual:
  - ✅ "Automatically manage signing" está marcado
  - Team: **MESMO TEAM DO APP PRINCIPAL**
  - Bundle Identifier: `com.lucasdalpra.RastreamentoDeCargas.widget`

#### 4. App Groups (IMPORTANTE!)
Em AMBOS os targets (App e Widget):
- Adicione capability "App Groups"
- Use o MESMO grupo: `group.com.lucasdalpra.RastreamentoDeCargas`

#### 5. Clean e Rebuild
- Menu: Product → Clean Build Folder (Shift+Cmd+K)
- Build novamente (Cmd+B)

## 📝 RESUMO DAS CORREÇÕES

### ✅ Corrigido no Código:
1. **RastreamentoDeCargasApp.swift** - Não acessa mais @StateObject no init
2. **SharedSnapshotStore.swift** - Criado para o Widget

### ⚠️ Você precisa fazer no Xcode:
1. **Adicionar SharedSnapshotStore.swift ao target do Widget**
2. **Configurar assinatura:** Mesmo Team em ambos targets
3. **App Groups:** Mesmo grupo em ambos targets
4. **Clean e Build**

## 🎯 ESTRUTURA FINAL DOS TARGETS

```
RastreamentoDeCargas (App Principal)
├── Team: Seu Team
├── Bundle ID: com.lucasdalpra.RastreamentoDeCargas
├── App Group: group.com.lucasdalpra.RastreamentoDeCargas
└── Todos os arquivos do app

RastreamentoDeCargasWidgetExtension
├── Team: MESMO Team do App
├── Bundle ID: com.lucasdalpra.RastreamentoDeCargas.widget
├── App Group: group.com.lucasdalpra.RastreamentoDeCargas
└── Arquivos do Widget + SharedSnapshotStore.swift
```

## 🚀 TESTE FINAL

Após as correções:
1. Build o app (Cmd+B)
2. Run no simulador (Cmd+R)
3. Adicione um pedido teste
4. Vá na Home Screen
5. Adicione o Widget
6. Verifique se mostra os dados

## ⚠️ SE AINDA DER ERRO

Se o erro de certificado persistir:
1. Desmarque "Automatically manage signing" em ambos targets
2. Selecione manualmente o mesmo Provisioning Profile
3. Ou delete os Derived Data:
   - ~/Library/Developer/Xcode/DerivedData/
   - Delete a pasta do projeto
   - Rebuild
