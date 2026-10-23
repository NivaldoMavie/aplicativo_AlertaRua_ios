import SwiftUI

// Estrutura principal da aplicacao AlertaRua
// Integra os ecras do Cidadao, o Portal Operacional do Municipio da Beira e o Painel Estatistico
struct ContentView: View {
    // Fonte unica da verdade gerenciada pelo DenunciaStore
    @StateObject private var store = DenunciaStore()

    // Controle da aba ativa na barra de navegacao inferior
    @State private var abaSelecionada = 0

    var body: some View {
        TabView(selection: $abaSelecionada) {
            // Aba 1: Feed de Alertas Urbanos para os cidadaos da Beira
            ListaAlertasView()
                .tabItem {
                    Label("Alertas", systemImage: "list.bullet.rectangle.portrait.fill")
                }
                .tag(0)

            // Aba 2: Formulario de reporte de nova ocorrencia
            NovoAlertaView(aba: $abaSelecionada)
                .tabItem {
                    Label("Reportar", systemImage: "plus.circle.fill")
                }
                .tag(1)

            // Aba 3: Painel de Gestao e Triagem do Conselho Municipal da Beira (CMB)
            PainelMunicipioView()
                .tabItem {
                    Label("Município", systemImage: "building.columns.fill")
                }
                .tag(2)

            // Aba 4: Indicadores gerais e relatorios de resolucao
            ResumoEstatisticasView()
                .tabItem {
                    Label("Resumo", systemImage: "chart.pie.fill")
                }
                .tag(3)
        }
        .environmentObject(store)
    }
}

// MARK: - Ecra de Alertas (Visao do Municipe)

// Listagem publica de ocorrencias com busca, filtros por estado e navegacao para detalhes
struct ListaAlertasView: View {
    @EnvironmentObject var store: DenunciaStore
    @State private var filtroSelecionado: Filtro = .todas
    @State private var textoPesquisa = ""

    // Filtra ocorrencias de acordo com o estado e termo de pesquisa de bairro
    private var alertasFiltrados: [Alerta] {
        store.alertas.filter { item in
            let correspondeFiltro = filtroSelecionado.aceita(item.estado)
            let termoLimpo = textoPesquisa.trimmingCharacters(in: .whitespacesAndNewlines)
            let correspondeBairro = termoLimpo.isEmpty || item.bairro.localizedCaseInsensitiveContains(termoLimpo)
            return correspondeFiltro && correspondeBairro
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // Filtros em barra segmentada
                Section {
                    Picker("Filtro de Estado", selection: $filtroSelecionado) {
                        ForEach(Filtro.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Lista de ocorrencias cadastradas
                Section {
                    if alertasFiltrados.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass.circle")
                                .font(.system(size: 44))
                                .foregroundStyle(.secondary)
                            Text("Nenhum alerta encontrado")
                                .font(.headline)
                            Text("Tente alterar o filtro ou pesquisar por outro bairro da Beira.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        ForEach(alertasFiltrados) { item in
                            NavigationLink(destination: DetalheAlertaView(alertaId: item.id)) {
                                LinhaAlerta(alerta: item)
                            }
                            // Deslizar para a direita para avancar o ciclo de vida
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                if item.estado != .resolvido {
                                    Button {
                                        withAnimation {
                                            store.avancarEstado(item)
                                        }
                                    } label: {
                                        Label(item.estado == .pendente ? "Aceitar" : "Avançar", systemImage: "arrow.right.circle.fill")
                                    }
                                    .tint(item.estado == .pendente ? .purple : .green)
                                }
                            }
                            // Deslizar para a esquerda para apagar o registro
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        store.remover(id: item.id)
                                    }
                                } label: {
                                    Label("Apagar", systemImage: "trash.fill")
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Ocorrências na Beira")
                        Spacer()
                        Text("Total: \(alertasFiltrados.count)")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .textCase(.none)
                    }
                }
            }
            .navigationTitle("AlertaRua")
            .searchable(text: $textoPesquisa, prompt: "Pesquisar pelo nome do bairro")
        }
    }
}

// Linha de apresentacao resumida de cada alerta
struct LinhaAlerta: View {
    @EnvironmentObject var store: DenunciaStore
    let alerta: Alerta

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cabecalho com icone da categoria, bairro, data relativa e estado
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: alerta.categoria.icone)
                    .foregroundStyle(.white)
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 38, height: 38)
                    .background(alerta.categoria.cor, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(alerta.categoria.rawValue)
                        .font(.headline)

                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption2)
                        Text(alerta.bairro)
                        Text("·")
                        Text(alerta.data.formatted(.relative(presentation: .named)))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Tag do estado atual
                Text(alerta.estado.rawValue)
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(alerta.estado.cor.opacity(0.16), in: Capsule())
                    .foregroundStyle(alerta.estado.cor)
            }

            // Descricao em texto
            Text(alerta.descricao)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(2)

            // Linha inferior com brigada e botao Eu tambem vi
            HStack {
                if let equipa = alerta.equipaAtribuida {
                    Label(equipa, systemImage: "person.2.badge.gearshape")
                        .font(.caption2)
                        .foregroundStyle(Color.accentColor)
                }

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        store.apoiar(alerta)
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "hand.thumbsup.fill")
                        Text("Eu também vi")
                        Text("(\(alerta.apoios))")
                            .fontWeight(.semibold)
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Ecra de Reportar (Novo Alerta)

// Formulario de envio de problemas com validacao de 10 caracteres e prioridades
struct NovoAlertaView: View {
    @EnvironmentObject var store: DenunciaStore
    @Binding var aba: Int

    @State private var categoriaSelecionada: Categoria = .buraco
    @State private var bairroSelecionado = bairros[0]
    @State private var pontoReferencia = ""
    @State private var prioridadeSelecionada: Prioridade = .media
    @State private var descricaoTexto = ""

    // Validacao que remove espacos em branco nas pontas
    private var descricaoLimpa: String {
        descricaoTexto.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var formularioValido: Bool {
        descricaoLimpa.count >= 10
    }

    var body: some View {
        NavigationStack {
            Form {
                // Selecao da categoria
                Section("Tipo de Problema") {
                    Picker("Categoria", selection: $categoriaSelecionada) {
                        ForEach(Categoria.allCases) { item in
                            Label(item.rawValue, systemImage: item.icone)
                                .tag(item)
                        }
                    }
                }

                // Selecao do bairro e ponto de referencia
                Section("Localização na Beira") {
                    Picker("Bairro", selection: $bairroSelecionado) {
                        ForEach(bairros, id: \.self) { nome in
                            Text(nome).tag(nome)
                        }
                    }

                    TextField("Ponto de referência (opcional)", text: $pontoReferencia)
                }

                // Gravidade da ocorrencia
                Section("Nível de Urgência") {
                    Picker("Prioridade", selection: $prioridadeSelecionada) {
                        ForEach(Prioridade.allCases) { nivel in
                            Label(nivel.rawValue, systemImage: nivel.icone)
                                .tag(nivel)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Descricao com contador de caracteres
                Section {
                    TextField(
                        "Descreva o problema em detalhe (mínimo 10 caracteres)...",
                        text: $descricaoTexto,
                        axis: .vertical
                    )
                    .lineLimit(3...6)

                    HStack {
                        Spacer()
                        Text("\(descricaoLimpa.count)/10 caracteres (mínimo 10)")
                            .font(.caption)
                            .foregroundStyle(
                                formularioValido ? Color.green : (descricaoLimpa.isEmpty ? Color.secondary : Color.orange)
                            )
                    }
                } header: {
                    Text("Descrição Detalhada")
                } footer: {
                    Text("Forneça informações claras para ajudar a brigada técnica do município.")
                }

                // Botao de envio
                Section {
                    Button {
                        submeterAlerta()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Enviar Alerta", systemImage: "paperplane.fill")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!formularioValido)
                }
            }
            .navigationTitle("Novo Alerta")
        }
    }

    private func submeterAlerta() {
        guard formularioValido else { return }

        let novo = Alerta(
            categoria: categoriaSelecionada,
            descricao: descricaoLimpa,
            bairro: bairroSelecionado,
            pontoReferencia: pontoReferencia.trimmingCharacters(in: .whitespacesAndNewlines),
            prioridade: prioridadeSelecionada,
            data: Date(),
            estado: .pendente,
            apoios: 0
        )

        withAnimation {
            store.adicionar(novo)
        }

        // Limpeza dos campos e retorno ao feed
        descricaoTexto = ""
        pontoReferencia = ""
        categoriaSelecionada = .buraco
        prioridadeSelecionada = .media
        bairroSelecionado = bairros[0]
        aba = 0
    }
}

// MARK: - Ecra de Resumo e Estatisticas

// Painel com indicadores operacionais da cidade e taxas de conclusao
struct ResumoEstatisticasView: View {
    @EnvironmentObject var store: DenunciaStore

    private var totalAlertas: Int {
        store.alertas.count
    }

    private func contarPorEstado(_ estado: Estado) -> Int {
        store.alertas.filter { $0.estado == estado }.count
    }

    private func contarPorCategoria(_ categoria: Categoria) -> Int {
        store.alertas.filter { $0.categoria == categoria }.count
    }

    private var taxaResolucao: Double {
        guard totalAlertas > 0 else { return 0.0 }
        return Double(contarPorEstado(.resolvido)) / Double(totalAlertas)
    }

    var body: some View {
        NavigationStack {
            List {
                // Cartao principal com total de alertas
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total de Alertas Registados")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(totalAlertas)")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                        }
                        Spacer()
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.accentColor)
                    }
                    .padding(.vertical, 6)
                }

                // Indicador de taxa de resolucao
                Section("Taxa de Resolução Municipal") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("\(Int(taxaResolucao * 100))%")
                                .font(.title2.bold())
                                .foregroundStyle(.green)
                            Spacer()
                            Text("\(contarPorEstado(.resolvido)) de \(totalAlertas) resolvidos")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(value: taxaResolucao)
                            .tint(.green)
                    }
                    .padding(.vertical, 4)
                }

                // Estatisticas divididas por estado
                Section("Distribuição por Estado") {
                    ForEach(Estado.allCases, id: \.self) { itemEstado in
                        HStack {
                            Circle()
                                .fill(itemEstado.cor)
                                .frame(width: 10, height: 10)
                            Text(itemEstado.rawValue)
                            Spacer()
                            Text("\(contarPorEstado(itemEstado))")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }

                // Estatisticas divididas por categoria
                Section("Ocorrências por Categoria") {
                    ForEach(Categoria.allCases) { itemCategoria in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label(itemCategoria.rawValue, systemImage: itemCategoria.icone)
                                Spacer()
                                Text("\(contarPorCategoria(itemCategoria))")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }

                            let proporcao = totalAlertas == 0 ? 0.0 : Double(contarPorCategoria(itemCategoria)) / Double(totalAlertas)
                            ProgressView(value: proporcao)
                                .tint(itemCategoria.cor)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Estatísticas")
        }
    }
}
