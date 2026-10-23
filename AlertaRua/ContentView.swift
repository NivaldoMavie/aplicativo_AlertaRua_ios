import SwiftUI

// Estrutura principal da interface que gerencia as tres abas de navegacao
struct ContentView: View {
    // Fonte unica da verdade compartilhada para o estado do aplicativo
    @StateObject private var store = DenunciaStore()

    // Controle do indice da aba ativa (0: Ocorrencias, 1: Denunciar, 2: Resumo)
    @State private var abaSelecionada = 0

    var body: some View {
        TabView(selection: $abaSelecionada) {
            // Primeira aba: Listagem, pesquisa, filtros e acoes de ocorrencias
            ListaView()
                .tabItem {
                    Label("Ocorrências", systemImage: "list.bullet.rectangle.portrait.fill")
                }
                .tag(0)

            // Segunda aba: Formulario de criacao de nova denuncia
            NovaDenunciaView(aba: $abaSelecionada)
                .tabItem {
                    Label("Denunciar", systemImage: "plus.circle.fill")
                }
                .tag(1)

            // Terceira aba: Painel estatistico e metricas de resolucao
            ResumoView()
                .tabItem {
                    Label("Resumo", systemImage: "chart.pie.fill")
                }
                .tag(2)
        }
        .environmentObject(store)
    }
}

// MARK: - Ecra de Ocorrencias

// Visualizacao principal com lista de denuncias, filtros e busca por bairro
struct ListaView: View {
    @EnvironmentObject var store: DenunciaStore
    @State private var filtroSelecionado: Filtro = .todas
    @State private var textoPesquisa = ""

    // Filtra as ocorrencias pelo estado selecionado e pelo termo de busca de bairro
    private var ocorrenciasFiltradas: [Denuncia] {
        store.denuncias.filter { denuncia in
            let correspondeFiltro = filtroSelecionado.aceita(denuncia.estado)
            let termoLimpo = textoPesquisa.trimmingCharacters(in: .whitespacesAndNewlines)
            let correspondeBairro = termoLimpo.isEmpty || denuncia.bairro.localizedCaseInsensitiveContains(termoLimpo)
            return correspondeFiltro && correspondeBairro
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // Secao de selecao de filtro rapido por estado
                Section {
                    Picker("Filtrar ocorrências", selection: $filtroSelecionado) {
                        ForEach(Filtro.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Secao principal com total de resultados e lista de registros
                Section {
                    if ocorrenciasFiltradas.isEmpty {
                        // Mensagem amigavel exibida quando nenhum registro corresponde aos criterios
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass.circle")
                                .font(.system(size: 44))
                                .foregroundStyle(.secondary)
                            Text("Nenhuma ocorrência encontrada")
                                .font(.headline)
                            Text("Tente alterar o filtro ou o termo de pesquisa por bairro.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        ForEach(ocorrenciasFiltradas) { item in
                            LinhaDenuncia(denuncia: item)
                                // Deslizar para a direita (leading) para avancar o estado da ocorrencia
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    if item.estado != .resolvido {
                                        Button {
                                            withAnimation {
                                                store.avancarEstado(item)
                                            }
                                        } label: {
                                            if item.estado == .pendente {
                                                Label("Em resolução", systemImage: "clock.arrow.2.circlepath")
                                            } else {
                                                Label("Resolver", systemImage: "checkmark.circle.fill")
                                            }
                                        }
                                        .tint(item.estado == .pendente ? .orange : .green)
                                    }
                                }
                                // Deslizar para a esquerda (trailing) para apagar a ocorrencia
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
                    // Exibicao clara do total de resultados filtrados
                    HStack {
                        Text("Ocorrências")
                        Spacer()
                        Text("Total: \(ocorrenciasFiltradas.count)")
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

// Componente responsavel pela apresentacao visual de cada linha de ocorrencia
struct LinhaDenuncia: View {
    @EnvironmentObject var store: DenunciaStore
    let denuncia: Denuncia

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Cabecalho da linha: icone de categoria, bairro, data relativa e estado
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: denuncia.categoria.icone)
                    .foregroundStyle(.white)
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 38, height: 38)
                    .background(denuncia.categoria.cor, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(denuncia.categoria.rawValue)
                        .font(.headline)

                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption2)
                        Text(denuncia.bairro)
                        Text("·")
                        Text(denuncia.data.formatted(.relative(presentation: .named)))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Tag visual do estado atual da ocorrencia
                Text(denuncia.estado.rawValue)
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(denuncia.estado.cor.opacity(0.15), in: Capsule())
                    .foregroundStyle(denuncia.estado.cor)
            }

            // Descricao em texto fornecida pelo cidadao
            Text(denuncia.descricao)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            // Botao interativo para apoiar a denuncia com contagem
            HStack {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        store.apoiar(denuncia)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.thumbsup.fill")
                        Text("Eu também vi")
                        Text("(\(denuncia.apoios))")
                            .fontWeight(.semibold)
                    }
                    .font(.footnote)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.borderless)

                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Ecra de Denunciar

// Formulario para submissao de novas ocorrencias urbanas
struct NovaDenunciaView: View {
    @EnvironmentObject var store: DenunciaStore
    @Binding var aba: Int

    @State private var categoriaSelecionada: Categoria = .buraco
    @State private var bairroSelecionado = bairros[0]
    @State private var descricaoTexto = ""

    // Validacao: ignora espacos em branco nas extremidades e exige no minimo 10 caracteres
    private var descricaoLimpa: String {
        descricaoTexto.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var formularioValido: Bool {
        descricaoLimpa.count >= 10
    }

    var body: some View {
        NavigationStack {
            Form {
                // Selecao de uma das quatro categorias
                Section("Tipo de problema") {
                    Picker("Categoria", selection: $categoriaSelecionada) {
                        ForEach(Categoria.allCases) { item in
                            Label(item.rawValue, systemImage: item.icone)
                                .tag(item)
                        }
                    }
                }

                // Selecao de um dos oito bairros da Beira
                Section("Localização") {
                    Picker("Bairro", selection: $bairroSelecionado) {
                        ForEach(bairros, id: \.self) { nomeBairro in
                            Text(nomeBairro).tag(nomeBairro)
                        }
                    }
                }

                // Campo multilinhas de descricao com validacao e contador
                Section {
                    TextField(
                        "Descreva a ocorrência com detalhes (rua, ponto de referência...)",
                        text: $descricaoTexto,
                        axis: .vertical
                    )
                    .lineLimit(3...6)

                    // Contador visual de caracteres com informacao de validade
                    HStack {
                        Spacer()
                        Text("\(descricaoLimpa.count)/10 caracteres (mínimo 10)")
                            .font(.caption)
                            .foregroundStyle(
                                formularioValido ? Color.green : (descricaoLimpa.isEmpty ? Color.secondary : Color.orange)
                            )
                    }
                } header: {
                    Text("Descrição do problema")
                } footer: {
                    Text("A descrição deve conter no mínimo 10 caracteres válidos para ser enviada.")
                }

                // Botao de envio desativado enquanto o texto for invalido
                Section {
                    Button {
                        submeterDenuncia()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Enviar Denúncia", systemImage: "paperplane.fill")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!formularioValido)
                }
            }
            .navigationTitle("Nova Denúncia")
        }
    }

    // Cria a nova denuncia, insere no topo, limpa os campos e retorna a primeira aba
    private func submeterDenuncia() {
        guard formularioValido else { return }

        let nova = Denuncia(
            categoria: categoriaSelecionada,
            descricao: descricaoLimpa,
            bairro: bairroSelecionado,
            data: Date(),
            estado: .pendente,
            apoios: 0
        )

        // Adiciona no topo da lista com animacao
        withAnimation {
            store.adicionar(nova)
        }

        // Limpa os campos do formulario apos o envio bem-sucedido
        descricaoTexto = ""
        categoriaSelecionada = .buraco
        bairroSelecionado = bairros[0]

        // Redireciona o usuario imediatamente de volta para a aba de Ocorrencias
        aba = 0
    }
}

// MARK: - Ecra de Resumo

// Painel de indicadores com estatisticas em tempo real das denuncias
struct ResumoView: View {
    @EnvironmentObject var store: DenunciaStore

    // Contadores gerais calculados a partir dos dados atuais da loja
    private var totalOcorrencias: Int {
        store.denuncias.count
    }

    private func contarPorEstado(_ estado: Estado) -> Int {
        store.denuncias.filter { $0.estado == estado }.count
    }

    private func contarPorCategoria(_ categoria: Categoria) -> Int {
        store.denuncias.filter { $0.categoria == categoria }.count
    }

    // Taxa de resolucao em formato percentual (0.0 a 1.0)
    private var taxaResolucao: Double {
        guard totalOcorrencias > 0 else { return 0.0 }
        return Double(contarPorEstado(.resolvido)) / Double(totalOcorrencias)
    }

    var body: some View {
        NavigationStack {
            List {
                // Cartao de destaque com total geral de denuncias cadastradas
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total de Ocorrências")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(totalOcorrencias)")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                        }
                        Spacer()
                        Image(systemName: "exclamationmark.bubble.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.accentColor)
                    }
                    .padding(.vertical, 6)
                }

                // Metricas de progresso e porcentagem de resolucao
                Section("Taxa de Resolução") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("\(Int(taxaResolucao * 100))%")
                                .font(.title2.bold())
                                .foregroundStyle(.green)
                            Spacer()
                            Text("\(contarPorEstado(.resolvido)) de \(totalOcorrencias) resolvidas")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(value: taxaResolucao)
                            .tint(.green)
                    }
                    .padding(.vertical, 4)
                }

                // Distribuicao de contagem por cada estado de resolucao
                Section("Por Estado") {
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

                // Distribuicao das ocorrencias pelas quatro categorias de problemas
                Section("Por Categoria") {
                    ForEach(Categoria.allCases) { itemCategoria in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label(itemCategoria.rawValue, systemImage: itemCategoria.icone)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text("\(contarPorCategoria(itemCategoria))")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }

                            // Barra de proporcao de cada categoria em relacao ao total
                            let proporcao = totalOcorrencias == 0 ? 0.0 : Double(contarPorCategoria(itemCategoria)) / Double(totalOcorrencias)
                            ProgressView(value: proporcao)
                                .tint(itemCategoria.cor)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Resumo")
        }
    }
}
