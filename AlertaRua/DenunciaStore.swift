import SwiftUI

final class DenunciaStore: ObservableObject {
    @Published var denuncias: [Denuncia] = Denuncia.exemplos

    func adicionar(_ denuncia: Denuncia) {
        denuncias.insert(denuncia, at: 0)
    }

    func avancarEstado(_ denuncia: Denuncia) {
        guard let i = denuncias.firstIndex(where: { $0.id == denuncia.id }) else { return }
        denuncias[i].estado = denuncias[i].estado.proximo
    }

    func apoiar(_ denuncia: Denuncia) {
        guard let i = denuncias.firstIndex(where: { $0.id == denuncia.id }) else { return }
        denuncias[i].apoios += 1
    }

    func remover(ids: [UUID]) {
        denuncias.removeAll { ids.contains($0.id) }
    }
}
