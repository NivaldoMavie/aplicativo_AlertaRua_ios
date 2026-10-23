import SwiftUI

// Visualizacao detalhada de uma ocorrencia com timeline de eventos e acoes operacionais
struct DetalheAlertaView: View {
    @EnvironmentObject var store: DenunciaStore
    let alertaId: UUID

    // Recupera a versao mais atualizada do alerta a partir da loja observavel
    private var alerta: Alerta? {
        store.alertas.first(where: { $0.id == alertaId })
    }

    // Estados para controle do dialogo de despacho municipal
    @State private var exibindoDespacho = false
    @State private var equipaSelecionada = equipasMunicipais[0]
    @State private var prazoDigitado = "Até 48 horas"
    @State private var notaDigitada = ""
    @State private var acaoMunicipal: AcaoMunicipal? = nil

    enum AcaoMunicipal {
        case aceitar
        case iniciar
        case concluir
        case rejeitar
    }

    var body: some View {
        Group {
            if let item = alerta {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Cartao principal com categoria, bairro, prioridade e estado
                        cartaoCabecalho(item)

                        // Descricao completa fornecida pelo cidadao
                        secaoDescricao(item)

                        // Painel de acompanhamento e despacho oficial do Conselho Municipal
                        secaoInformacoesMunicipais(item)

                        // Botoes de acao operacional para a gestao municipal
                        secaoAcoesMunicipais(item)

                        // Linha do tempo com historico cronologico das atualizacoes
                        secaoLinhaDoTempo(item)
                    }
                    .padding()
                }
                .navigationTitle("Alerta #\(item.id.uuidString.prefix(6))")
                .navigationBarTitleDisplayMode(.inline)
                .sheet(item: $acaoMunicipal) { acao in
                    sheetAcaoMunicipal(item: item, acao: acao)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Ocorrência não encontrada.")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Componentes Visuais

    // Cabecalho visual com icones, badges de prioridade e estado
    private func cartaoCabecalho(_ item: Alerta) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                Image(systemName: item.categoria.icone)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(item.categoria.cor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.categoria.rawValue)
                        .font(.title3.bold())

                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption)
                        Text(item.bairro)
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()
            }

            if !item.pontoReferencia.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "signpost.right.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(item.pontoReferencia)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            }

            Divider()

            HStack {
                // Badge visual de prioridade
                HStack(spacing: 5) {
                    Image(systemName: item.prioridade.icone)
                    Text("Prioridade \(item.prioridade.rawValue)")
                }
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(item.prioridade.cor.opacity(0.15), in: Capsule())
                .foregroundStyle(item.prioridade.cor)

                Spacer()

                // Badge visual do estado atual
                HStack(spacing: 5) {
                    Image(systemName: item.estado.icone)
                    Text(item.estado.rawValue)
                }
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(item.estado.cor.opacity(0.18), in: Capsule())
                .foregroundStyle(item.estado.cor)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // Secao com o relato fornecido pelo cidadao e botao de apoio
    private func secaoDescricao(_ item: Alerta) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Relato do Munícipe")
                .font(.headline)

            Text(item.descricao)
                .font(.body)
                .foregroundStyle(.primary)

            HStack {
                Text("Registado em: \(item.data.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        store.apoiar(item)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.thumbsup.fill")
                        Text("Eu também vi")
                        Text("(\(item.apoios))")
                            .bold()
                    }
                    .font(.footnote)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.15), in: Capsule())
                }
                .buttonStyle(.borderless)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }

    // Painel informativo sobre brigada atribuida, prazos e despachos
    private func secaoInformacoesMunicipais(_ item: Alerta) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Conselho Municipal da Beira", systemImage: "building.columns.fill")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
                Spacer()
                Text("Gabinete Operacional")
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.1), in: Capsule())
            }

            VStack(spacing: 10) {
                linhaInfo(
                    titulo: "Brigada Responsável",
                    valor: item.equipaAtribuida ?? "Pendente de atribuição técnica",
                    icone: "person.3.sequence.fill",
                    cor: item.equipaAtribuida != nil ? .primary : .secondary
                )

                linhaInfo(
                    titulo: "Previsão de Conclusão",
                    valor: item.prazoEstimado ?? "Aguardando triagem de campo",
                    icone: "calendar.badge.clock",
                    cor: item.prazoEstimado != nil ? .primary : .secondary
                )

                if let nota = item.notaMunicipio, !nota.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "quote.opening")
                                .font(.caption)
                                .foregroundStyle(Color.accentColor)
                            Text("Nota Oficial do Município:")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                        Text(nota)
                            .font(.subheadline)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding()
        .background(Color.accentColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
        )
    }

    // Linha auxiliar de dados municipais
    private func linhaInfo(titulo: String, valor: String, icone: String, cor: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icone)
                .font(.body)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(titulo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(valor)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(cor)
            }
            Spacer()
        }
    }

    // Botoes interativos para despachos do Conselho Municipal
    private func secaoAcoesMunicipais(_ item: Alerta) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Gestão Operacional do Alerta")
                .font(.headline)

            HStack(spacing: 10) {
                if item.estado == .pendente {
                    Button {
                        acaoMunicipal = .aceitar
                    } label: {
                        Label("Aceitar Alerta", systemImage: "checkmark.seal.fill")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)

                    Button {
                        acaoMunicipal = .rejeitar
                    } label: {
                        Label("Arquivar", systemImage: "xmark.circle")
                            .font(.subheadline.bold())
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                } else if item.estado == .aceite {
                    Button {
                        acaoMunicipal = .iniciar
                    } label: {
                        Label("Iniciar Obras / Limpeza", systemImage: "wrench.and.screwdriver.fill")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                } else if item.estado == .emResolucao {
                    Button {
                        acaoMunicipal = .concluir
                    } label: {
                        Label("Concluir e Resolver", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Ocorrência concluída com sucesso.")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    // Linha do tempo vertical com registro de auditoria
    private func secaoLinhaDoTempo(_ item: Alerta) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Linha do Tempo Oficial", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                Spacer()
                Text("\(item.historico.count) eventos")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(item.historico.enumerated()), id: \.element.id) { index, evento in
                    HStack(alignment: .top, spacing: 14) {
                        // Linha vertical conectora com no circular
                        VStack(spacing: 0) {
                            Circle()
                                .fill(index == item.historico.count - 1 ? Color.accentColor : Color.secondary.opacity(0.4))
                                .frame(width: 12, height: 12)

                            if index < item.historico.count - 1 {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(width: 2, height: 44)
                            }
                        }
                        .frame(width: 20)

                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(evento.titulo)
                                    .font(.subheadline.weight(.semibold))

                                Spacer()

                                Text(evento.data.formatted(date: .numeric, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Text(evento.descricao)
                                .font(.caption)
                                .foregroundStyle(.primary)

                            Text("Responsável: \(evento.autor)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.bottom, index < item.historico.count - 1 ? 14 : 0)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }

    // Modal interativo para submissao de acoes de gestao municipal
    private func sheetAcaoMunicipal(item: Alerta, acao: AcaoMunicipal) -> some View {
        NavigationStack {
            Form {
                switch acao {
                case .aceitar:
                    Section("Atribuição Técnica") {
                        Picker("Brigada Municipal", selection: $equipaSelecionada) {
                            ForEach(equipasMunicipais, id: \.self) { nome in
                                Text(nome).tag(nome)
                            }
                        }

                        TextField("Previsão de conclusão (ex: 24h, 3 dias)", text: $prazoDigitado)
                    }

                    Section("Despacho Oficial") {
                        TextField("Instruções para a equipa técnica...", text: $notaDigitada, axis: .vertical)
                            .lineLimit(3...5)
                    }

                case .iniciar:
                    Section("Confirmação de Início") {
                        Text("Confirma que a brigada já está no local para realizar a intervenção?")
                            .font(.subheadline)
                        TextField("Detalhes da operação em curso...", text: $notaDigitada, axis: .vertical)
                            .lineLimit(3...4)
                    }

                case .concluir:
                    Section("Conclusão do Trabalho") {
                        Text("Registe a conclusão da ocorrência para notificar o munícipe.")
                            .font(.subheadline)
                        TextField("Descreva a intervenção realizada...", text: $notaDigitada, axis: .vertical)
                            .lineLimit(3...4)
                    }

                case .rejeitar:
                    Section("Motivo do Arquivamento") {
                        TextField("Justificativa (ex: local fora da jurisdição, duplicado)", text: $notaDigitada, axis: .vertical)
                            .lineLimit(3...4)
                    }
                }
            }
            .navigationTitle(tituloModal(acao))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        acaoMunicipal = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirmar") {
                        executarAcao(item: item, acao: acao)
                        acaoMunicipal = nil
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func tituloModal(_ acao: AcaoMunicipal) -> String {
        switch acao {
        case .aceitar: return "Aceitar & Atribuir"
        case .iniciar: return "Iniciar Trabalhos"
        case .concluir: return "Concluir Alerta"
        case .rejeitar: return "Arquivar Alerta"
        }
    }

    private func executarAcao(item: Alerta, acao: AcaoMunicipal) {
        withAnimation {
            switch acao {
            case .aceitar:
                store.aceitarAlerta(
                    id: item.id,
                    equipa: equipaSelecionada,
                    nota: notaDigitada,
                    prazo: prazoDigitado
                )
            case .iniciar:
                store.iniciarIntervencao(id: item.id, nota: notaDigitada)
            case .concluir:
                store.concluirAlerta(id: item.id, nota: notaDigitada)
            case .rejeitar:
                store.rejeitarAlerta(id: item.id, motivo: notaDigitada.isEmpty ? "Não especificado" : notaDigitada)
            }
        }
        notaDigitada = ""
    }
}

// Extensao auxiliar para suportar uso no modificador sheet
extension DetalheAlertaView.AcaoMunicipal: Identifiable {
    var id: Int {
        switch self {
        case .aceitar: return 1
        case .iniciar: return 2
        case .concluir: return 3
        case .rejeitar: return 4
        }
    }
}
