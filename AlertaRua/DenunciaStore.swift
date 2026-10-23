import SwiftUI

// Classe observavel central para gerenciamento do estado dos alertas urbanos
// Suporta operacoes tanto do Municipe (reportar, apoiar) quanto do Municipio (triagem, atribuir equipa, resolver)
final class DenunciaStore: ObservableObject {
    // Chave unica para persistencia local dos dados no UserDefaults
    private let chaveArmazenamento = "alertarua_ocorrencias_v2"

    // Lista publicada de alertas que atualiza automaticamente todas as telas do aplicativo
    @Published var alertas: [Alerta] = [] {
        didSet {
            salvarDados()
        }
    }

    // Propriedade computada para compatibilidade reversa com o nome anterior
    var denuncias: [Alerta] {
        get { alertas }
        set { alertas = newValue }
    }

    // Inicializador que carrega os dados locais do UserDefaults ou os exemplos padrao
    init() {
        carregarDados()
    }

    // Carrega a colecao de dados persistida em formato JSON
    func carregarDados() {
        if let dados = UserDefaults.standard.data(forKey: chaveArmazenamento) {
            do {
                let decodificados = try JSONDecoder().decode([Alerta].self, from: dados)
                self.alertas = decodificados
                return
            } catch {
                print("Aviso ao carregar dados locais: \(error.localizedDescription)")
            }
        }

        // Caso seja a primeira inicializacao, popula com os exemplos realistas da Beira
        self.alertas = Alerta.exemplos
        salvarDados()
    }

    // Serializa todos os alertas para JSON e guarda no armazenamento local do dispositivo
    func salvarDados() {
        do {
            let dados = try JSONEncoder().encode(alertas)
            UserDefaults.standard.set(dados, forKey: chaveArmazenamento)
        } catch {
            print("Erro ao serializar dados: \(error.localizedDescription)")
        }
    }

    // Adiciona um novo alerta no topo da lista
    func adicionar(_ alerta: Alerta) {
        alertas.insert(alerta, at: 0)
    }

    // Incrementa o contador de apoios Eu tambem vi
    func apoiar(_ alerta: Alerta) {
        guard let index = alertas.firstIndex(where: { $0.id == alerta.id }) else { return }
        alertas[index].apoios += 1
    }

    // Remove um alerta especifico pelo seu identificador
    func remover(id: UUID) {
        alertas.removeAll { $0.id == id }
    }

    // Remove multiplos alertas por lista de identificadores
    func remover(ids: [UUID]) {
        alertas.removeAll { ids.contains($0.id) }
    }

    // Avanca o estado do alerta de maneira sequencial (usado no gesto de deslizar)
    func avancarEstado(_ alerta: Alerta) {
        guard let index = alertas.firstIndex(where: { $0.id == alerta.id }) else { return }
        let estadoAntigo = alertas[index].estado
        let novoEstado = estadoAntigo.proximo

        if novoEstado != estadoAntigo {
            alertas[index].estado = novoEstado
            let evento = EventoHistorico(
                titulo: "Estado atualizado para \(novoEstado.rawValue)",
                descricao: "Progresso operacional registado na ocorrência.",
                autor: "Conselho Municipal",
                icone: novoEstado.icone
            )
            alertas[index].historico.append(evento)
        }
    }

    // MARK: - Acoes Exclusivas do Conselho Municipal da Beira (CMB)

    // Aceita um alerta pendente, atribui a brigada tecnica municipal e define o prazo previsto
    func aceitarAlerta(id: UUID, equipa: String, nota: String, prazo: String) {
        guard let index = alertas.firstIndex(where: { $0.id == id }) else { return }
        alertas[index].estado = .aceite
        alertas[index].equipaAtribuida = equipa
        alertas[index].notaMunicipio = nota.isEmpty ? "Alerta aceite e integrado no cronograma de operações municipais." : nota
        alertas[index].prazoEstimado = prazo.isEmpty ? "Em avaliação" : prazo

        let evento = EventoHistorico(
            titulo: "Alerta Aceite pelo Município",
            descricao: "Atribuído a: \(equipa). Prazo previsto: \(alertas[index].prazoEstimado ?? "N/A").",
            autor: "Conselho Municipal",
            icone: "checkmark.seal.fill"
        )
        alertas[index].historico.append(evento)
    }

    // Altera o estado do alerta para Em resolucao quando a equipa inicia a intervencao fisica
    func iniciarIntervencao(id: UUID, nota: String) {
        guard let index = alertas.firstIndex(where: { $0.id == id }) else { return }
        alertas[index].estado = .emResolucao
        if !nota.isEmpty {
            alertas[index].notaMunicipio = nota
        }

        let evento = EventoHistorico(
            titulo: "Intervenção Técnica Iniciada",
            descricao: nota.isEmpty ? "A equipa técnica iniciou os trabalhos de reparação no local indicado." : nota,
            autor: alertas[index].equipaAtribuida ?? "Conselho Municipal",
            icone: "wrench.and.screwdriver.fill"
        )
        alertas[index].historico.append(evento)
    }

    // Marca o alerta como concluido e resolvido apos inspecao do municipio
    func concluirAlerta(id: UUID, nota: String) {
        guard let index = alertas.firstIndex(where: { $0.id == id }) else { return }
        alertas[index].estado = .resolvido
        alertas[index].prazoEstimado = "Concluído"
        if !nota.isEmpty {
            alertas[index].notaMunicipio = nota
        }

        let evento = EventoHistorico(
            titulo: "Alerta Resolvido",
            descricao: nota.isEmpty ? "Trabalhos concluídos com sucesso pela equipa do Conselho Municipal." : nota,
            autor: "Conselho Municipal",
            icone: "checkmark.circle.fill"
        )
        alertas[index].historico.append(evento)
    }

    // Rejeita ou arquiva um alerta com justificativa formal
    func rejeitarAlerta(id: UUID, motivo: String) {
        guard let index = alertas.firstIndex(where: { $0.id == id }) else { return }
        alertas[index].estado = .rejeitado
        alertas[index].notaMunicipio = "Arquivado: \(motivo)"

        let evento = EventoHistorico(
            titulo: "Alerta Arquivado",
            descricao: "Motivo: \(motivo)",
            autor: "Fiscalização CMB",
            icone: "xmark.circle.fill"
        )
        alertas[index].historico.append(evento)
    }
}
