import SwiftUI

// Modelo de enumeracao para as categorias de problemas urbanos
enum Categoria: String, CaseIterable, Identifiable, Codable {
    case buraco = "Buraco"
    case lixo = "Lixo acumulado"
    case candeeiro = "Candeeiro avariado"
    case esgoto = "Esgoto a céu aberto"

    var id: String { rawValue }

    // Icone SF Symbol correspondente a cada categoria
    var icone: String {
        switch self {
        case .buraco: return "exclamationmark.triangle.fill"
        case .lixo: return "trash.fill"
        case .candeeiro: return "lightbulb.slash.fill"
        case .esgoto: return "drop.triangle.fill"
        }
    }

    // Cor tematica representativa de cada categoria
    var cor: Color {
        switch self {
        case .buraco: return .orange
        case .lixo: return .green
        case .candeeiro: return .yellow
        case .esgoto: return .brown
        }
    }
}

// Modelo de enumeracao para os estados do ciclo de vida da ocorrencia
enum Estado: String, CaseIterable, Codable {
    case pendente = "Pendente"
    case emResolucao = "Em resolução"
    case resolvido = "Resolvido"

    // Cor correspondente ao estado atual
    var cor: Color {
        switch self {
        case .pendente: return .red
        case .emResolucao: return .orange
        case .resolvido: return .green
        }
    }

    // Logica de transicao de estado sequencial: Pendente -> Em resolucao -> Resolvido
    var proximo: Estado {
        switch self {
        case .pendente: return .emResolucao
        case .emResolucao: return .resolvido
        case .resolvido: return .resolvido
        }
    }
}

// Modelo de enumeracao para os filtros da listagem de ocorrencias
enum Filtro: String, CaseIterable, Identifiable {
    case todas = "Todas"
    case pendentes = "Pendentes"
    case emCurso = "Em curso"
    case resolvidas = "Resolvidas"

    var id: String { rawValue }

    // Verifica se uma ocorrencia com determinado estado eh aceita pelo filtro
    func aceita(_ estado: Estado) -> Bool {
        switch self {
        case .todas: return true
        case .pendentes: return estado == .pendente
        case .emCurso: return estado == .emResolucao
        case .resolvidas: return estado == .resolvido
        }
    }
}

// Lista oficial dos oito bairros da Beira
let bairros = [
    "Macuti", "Munhava", "Manga", "Ponta-Gêa",
    "Chaimite", "Esturro", "Matacuane", "Chipangara"
]

// Estrutura de dados que representa uma ocorrencia registrada
// Conforma com Identifiable, Codable e Equatable para suportar persistencia e comparacao
struct Denuncia: Identifiable, Codable, Equatable {
    var id: UUID
    var categoria: Categoria
    var descricao: String
    var bairro: String
    var data: Date
    var estado: Estado
    var apoios: Int

    // Inicializador com valores padrao para criacao simplificada
    init(
        id: UUID = UUID(),
        categoria: Categoria,
        descricao: String,
        bairro: String,
        data: Date = Date(),
        estado: Estado = .pendente,
        apoios: Int = 0
    ) {
        self.id = id
        self.categoria = categoria
        self.descricao = descricao
        self.bairro = bairro
        self.data = data
        self.estado = estado
        self.apoios = apoios
    }

    // Quatro registros de demonstracao inicial cobrindo todas as categorias
    static let exemplos: [Denuncia] = [
        Denuncia(
            categoria: .buraco,
            descricao: "Buraco grande no meio da estrada, perigoso para motas.",
            bairro: "Munhava",
            data: Date().addingTimeInterval(-86_400 * 3),
            estado: .emResolucao,
            apoios: 14
        ),
        Denuncia(
            categoria: .lixo,
            descricao: "Lixo acumulado há uma semana junto ao mercado.",
            bairro: "Manga",
            data: Date().addingTimeInterval(-86_400 * 2),
            estado: .pendente,
            apoios: 23
        ),
        Denuncia(
            categoria: .candeeiro,
            descricao: "Rua sem iluminação à noite, a zona fica insegura.",
            bairro: "Macuti",
            data: Date().addingTimeInterval(-86_400),
            estado: .pendente,
            apoios: 9
        ),
        Denuncia(
            categoria: .esgoto,
            descricao: "Esgoto a correr na rua após a chuva.",
            bairro: "Chaimite",
            data: Date().addingTimeInterval(-86_400 * 6),
            estado: .resolvido,
            apoios: 31
        )
    ]
}
