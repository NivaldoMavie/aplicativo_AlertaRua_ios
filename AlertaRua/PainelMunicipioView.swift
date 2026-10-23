import SwiftUI

// Painel exclusivo para os operadores e tecnicos do Conselho Municipal da Beira (CMB)
// Permite triagem de alertas, despacho de brigadas e atualizacao de estados em tempo real
struct PainelMunicipioView: View {
    @EnvironmentObject var store: DenunciaStore

    @State private var filtroOperacional: FiltroOperacional = .pendentes
    @State private var termoBusca = ""
    @State private var alertaParaAcao: Alerta? = nil
    @State private var acaoSelecionada: TipoAcao = .aceitar

    // Estados para o formulario de despacho rapido
    @State private var equipaSelecionada = equipasMunicipais[0]
    @State private var prazoDigitado = "Até 48 horas"
    @State private var notaDespacho = ""

    enum FiltroOperacional: String, CaseIterable, Identifiable {
        case pendentes = "Para Triar"
        case emCurso = "Em Intervenção"
        case resolvidos = "Concluídos"
        case todos = "Todos"

        var id: String { rawValue }

        func filtrar(_ alerta: Alerta) -> Bool {
            switch self {
            case .pendentes: return alerta.estado == .pendente
            case .emCurso: return alerta.estado == .aceite || alerta.estado == .emResolucao
            case .resolvidos: return alerta.estado == .resolvido
            case .todos: return true
            }
        }
    }

    enum TipoAcao {
        case aceitar
        case iniciar
        case concluir
        case rejeitar
    }

    // Alertas filtrados pela fase operacional e termo de pesquisa
    private var alertasOperacionais: [Alerta] {
        store.alertas.filter { item in
            let correspondeFase = filtroOperacional.filtrar(item)
            let termoLimpo = termoBusca.trimmingCharacters(in: .whitespacesAndNewlines)
            let correspondeBusca = termoLimpo.isEmpty ||
                item.bairro.localizedCaseInsensitiveContains(termoLimpo) ||
                item.descricao.localizedCaseInsensitiveContains(termoLimpo) ||
                (item.equipaAtribuida?.localizedCaseInsensitiveContains(termoLimpo) ?? false)

            return correspondeFase && correspondeBusca
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // Banner oficial do Conselho Municipal da Beira
                Section {
                    cartaoMunicipioBoasVindas
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                // Filtro de fase operacional
                Section {
                    Picker("Fase Operacional", selection: $filtroOperacional) {
                        ForEach(FiltroOperacional.allCases) { fase in
                            Text(fase.rawValue).tag(fase)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Lista de ocorrencias na fila operacional
                Section {
                    if alertasOperacionais.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text("Nenhum alerta nesta fase")
                                .font(.headline)
                            Text("Todos os casos desta secção foram processados pelo Conselho Municipal.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                    } else {
                        ForEach(alertasOperacionais) { item in
                            NavigationLink(destination: DetalheAlertaView(alertaId: item.id)) {
                                linhaOperacional(item)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Fila de Trabalho")
                        Spacer()
                        Text("\(alertasOperacionais.count) alertas")
                            .font(.caption.bold())
                            .textCase(.none)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Gestão Municipal")
            .searchable(text: $termoBusca, prompt: "Pesquisar por bairro, equipa ou termo")
            .sheet(item: $alertaParaAcao) { item in
                sheetDespachoMunicipal(item: item)
            }
        }
    }

    // MARK: - Componentes de Interface

    // Banner de identificacao do Conselho Municipal da Beira
    private var cartaoMunicipioBoasVindas: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "building.columns.circle.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Conselho Municipal da Beira")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Central de Atendimento e Triagem de Alertas")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
            }

            // Metricas rapidas no topo do painel
            HStack(spacing: 12) {
                cartaoMetrica(
                    titulo: "Para Triar",
                    valor: "\(store.alertas.filter { $0.estado == .pendente }.count)",
                    cor: .red
                )
                cartaoMetrica(
                    titulo: "Em Intervenção",
                    valor: "\(store.alertas.filter { $0.estado == .aceite || $0.estado == .emResolucao }.count)",
                    cor: .orange
                )
                cartaoMetrica(
                    titulo: "Resolvidos",
                    valor: "\(store.alertas.filter { $0.estado == .resolvido }.count)",
                    cor: .green
                )
            }
            .padding(.top, 4)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.95), Color.indigo.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // Mini cartao com contador de alertas
    private func cartaoMetrica(titulo: String, valor: String, cor: Color) -> some View {
        VStack(spacing: 2) {
            Text(valor)
                .font(.title3.bold())
                .foregroundStyle(cor)
            Text(titulo)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
    }

    // Linha de cada alerta no quadro de triagem
    private func linhaOperacional(_ item: Alerta) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Badge de prioridade
                Text(item.prioridade.rawValue)
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(item.prioridade.cor.opacity(0.15), in: Capsule())
                    .foregroundStyle(item.prioridade.cor)

                Text(item.categoria.rawValue)
                    .font(.subheadline.bold())

                Spacer()

                // Tag do estado atual
                Text(item.estado.rawValue)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(item.estado.cor.opacity(0.18), in: Capsule())
                    .foregroundStyle(item.estado.cor)
            }

            Text(item.descricao)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Label(item.bairro, systemImage: "mappin")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                if let equipa = item.equipaAtribuida {
                    Label(equipa, systemImage: "person.2.fill")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.accentColor)
                } else {
                    Text("Sem brigada")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Acoes rapidas de triagem direta no cartao
            HStack(spacing: 8) {
                if item.estado == .pendente {
                    Button {
                        acaoSelecionada = .aceitar
                        alertaParaAcao = item
                    } label: {
                        Text("Aceitar & Atribuir")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.purple.opacity(0.15), in: Capsule())
                            .foregroundStyle(.purple)
                    }
                    .buttonStyle(.borderless)
                } else if item.estado == .aceite {
                    Button {
                        acaoSelecionada = .iniciar
                        alertaParaAcao = item
                    } label: {
                        Text("Iniciar Obras")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.orange.opacity(0.15), in: Capsule())
                            .foregroundStyle(.orange)
                    }
                    .buttonStyle(.borderless)
                } else if item.estado == .emResolucao {
                    Button {
                        acaoSelecionada = .concluir
                        alertaParaAcao = item
                    } label: {
                        Text("Concluir Alerta")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.green.opacity(0.15), in: Capsule())
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.borderless)
                }

                Spacer()

                Text("Apoios: \(item.apoios)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 4)
    }

    // Modal de confirmacao e despacho de brigadas
    private func sheetDespachoMunicipal(item: Alerta) -> some View {
        NavigationStack {
            Form {
                Section("Detalhes da Ocorrência") {
                    Text(item.categoria.rawValue)
                        .font(.headline)
                    Text("\(item.bairro) · Prioridade \(item.prioridade.rawValue)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(item.descricao)
                        .font(.caption)
                }

                if acaoSelecionada == .aceitar {
                    Section("Atribuição da Brigada") {
                        Picker("Equipa Municipal", selection: $equipaSelecionada) {
                            ForEach(equipasMunicipais, id: \.self) { nome in
                                Text(nome).tag(nome)
                            }
                        }

                        TextField("Prazo previsto (ex: 24h, 3 dias)", text: $prazoDigitado)
                    }

                    Section("Nota para o Munícipe") {
                        TextField("Instruções e despacho oficial...", text: $notaDespacho, axis: .vertical)
                            .lineLimit(3...4)
                    }
                } else if acaoSelecionada == .iniciar {
                    Section("Confirmação Operacional") {
                        Text("A brigada técnica iniciará os trabalhos no terreno.")
                            .font(.subheadline)
                        TextField("Nota sobre a operação em curso...", text: $notaDespacho, axis: .vertical)
                            .lineLimit(3...4)
                    }
                } else if acaoSelecionada == .concluir {
                    Section("Registo de Conclusão") {
                        Text("Finalizar esta ocorrência e notificar o cidadão.")
                            .font(.subheadline)
                        TextField("Descreva o trabalho realizado com sucesso...", text: $notaDespacho, axis: .vertical)
                            .lineLimit(3...4)
                    }
                }
            }
            .navigationTitle("Despacho Operacional")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        alertaParaAcao = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirmar") {
                        executarDespacho(item: item)
                        alertaParaAcao = nil
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func executarDespacho(item: Alerta) {
        withAnimation {
            switch acaoSelecionada {
            case .aceitar:
                store.aceitarAlerta(
                    id: item.id,
                    equipa: equipaSelecionada,
                    nota: notaDespacho,
                    prazo: prazoDigitado
                )
            case .iniciar:
                store.iniciarIntervencao(id: item.id, nota: notaDespacho)
            case .concluir:
                store.concluirAlerta(id: item.id, nota: notaDespacho)
            case .rejeitar:
                store.rejeitarAlerta(id: item.id, motivo: notaDespacho.isEmpty ? "Não especificado" : notaDespacho)
            }
        }
        notaDespacho = ""
    }
}
