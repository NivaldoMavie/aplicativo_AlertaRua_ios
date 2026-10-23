import SwiftUI

// Classe observavel para gerenciar a fonte de dados das ocorrencias
// Integra persistencia local sem backend utilizando UserDefaults e serializacao JSON
final class DenunciaStore: ObservableObject {
    // Chave unica para gravar e recuperar os dados no UserDefaults
    private let chaveArmazenamento = "alertarua_denuncias_armazenadas"

    // Colecao de denuncias publicada para atualizacao reativa da interface
    @Published var denuncias: [Denuncia] = [] {
        didSet {
            salvarDados()
        }
    }

    // Inicializador que recupera os registros salvos ou popula com exemplos
    init() {
        carregarDados()
    }

    // Carrega as ocorrencias guardadas no UserDefaults ou restaura os exemplos
    func carregarDados() {
        if let dados = UserDefaults.standard.data(forKey: chaveArmazenamento) {
            do {
                let decodificadas = try JSONDecoder().decode([Denuncia].self, from: dados)
                self.denuncias = decodificadas
                return
            } catch {
                print("Aviso: Nao foi possivel decodificar os dados salvos: \(error.localizedDescription)")
            }
        }

        // Primeira execucao ou dados corrompidos: carrega os quatro dados de demonstracao
        self.denuncias = Denuncia.exemplos
        salvarDados()
    }

    // Serializa a lista atual em JSON e guarda no armazenamento local
    func salvarDados() {
        do {
            let dados = try JSONEncoder().encode(denuncias)
            UserDefaults.standard.set(dados, forKey: chaveArmazenamento)
        } catch {
            print("Erro ao codificar denuncias em JSON: \(error.localizedDescription)")
        }
    }

    // Insere uma nova ocorrencia exatamente no topo da lista (indice zero)
    func adicionar(_ denuncia: Denuncia) {
        denuncias.insert(denuncia, at: 0)
    }

    // Avanca o estado da ocorrencia: Pendente -> Em resolucao -> Resolvido
    func avancarEstado(_ denuncia: Denuncia) {
        guard let index = denuncias.firstIndex(where: { $0.id == denuncia.id }) else { return }
        denuncias[index].estado = denuncias[index].estado.proximo
    }

    // Incrementa o contador de apoios quando o cidadao clica em Eu tambem vi
    func apoiar(_ denuncia: Denuncia) {
        guard let index = denuncias.firstIndex(where: { $0.id == denuncia.id }) else { return }
        denuncias[index].apoios += 1
    }

    // Remove uma unica ocorrencia a partir do seu identificador
    func remover(id: UUID) {
        denuncias.removeAll { $0.id == id }
    }

    // Remove ocorrencias baseadas em uma lista de identificadores
    func remover(ids: [UUID]) {
        denuncias.removeAll { ids.contains($0.id) }
    }
}
