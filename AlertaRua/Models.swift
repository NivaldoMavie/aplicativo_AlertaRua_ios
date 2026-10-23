import SwiftUI

enum Categoria: String, CaseIterable, Identifiable {
    case buraco = "Buraco"
    case lixo = "Lixo acumulado"
    case candeeiro = "Candeeiro avariado"
    case esgoto = "Esgoto a céu aberto"

    var id: String { rawValue }

    var icone: String {
        switch self {
        case .buraco: return "exclamationmark.triangle.fill"
        case .lixo: return "trash.fill"
        case .candeeiro: return "lightbulb.slash.fill"
        case .esgoto: return "drop.triangle.fill"
        }
    }

    var cor: Color {
        switch self {
        case .buraco: return .orange
        case .lixo: return .green
        case .candeeiro: return .yellow
        case .esgoto: return .brown
        }
    }
}

enum Estado: String, CaseIterable {
    case pendente = "Pendente"
    case emResolucao = "Em resolução"
    case resolvido = "Resolvido"

    var cor: Color {
        switch self {
        case .pendente: return .red
        case .emResolucao: return .orange
        case .resolvido: return .green
        }
    }

    var proximo: Estado {
        switch self {
        case .pendente: return .emResolucao
        case .emResolucao: return .resolvido
        case .resolvido: return .resolvido
        }
    }
}

enum Filtro: String, CaseIterable, Identifiable {
    case todas = "Todas"
    case pendentes = "Pendentes"
    case emCurso = "Em curso"
    case resolvidas = "Resolvidas"

    var id: String { rawValue }

    func aceita(_ estado: Estado) -> Bool {
        switch self {
        case .todas: return true
        case .pendentes: return estado == .pendente
        case .emCurso: return estado == .emResolucao
        case .resolvidas: return estado == .resolvido
        }
    }
}

let bairros = [
    "Macuti", "Munhava", "Manga", "Ponta-Gêa",
    "Chaimite", "Esturro", "Matacuane", "Chipangara"
]

struct Denuncia: Identifiable {
    let id = UUID()
    var categoria: Categoria
    var descricao: String
    var bairro: String
    var data: Date = Date()
    var estado: Estado = .pendente
    var apoios: Int = 0

    static let exemplos: [Denuncia] = [
        Denuncia(categoria: .buraco,
                 descricao: "Buraco grande no meio da estrada, perigoso para motas.",
                 bairro: "Munhava",
                 data: Date().addingTimeInterval(-86_400 * 3),
                 estado: .emResolucao, apoios: 14),
        Denuncia(categoria: .lixo,
                 descricao: "Lixo acumulado há uma semana junto ao mercado.",
                 bairro: "Manga",
                 data: Date().addingTimeInterval(-86_400 * 2),
                 estado: .pendente, apoios: 23),
        Denuncia(categoria: .candeeiro,
                 descricao: "Rua sem iluminação à noite, a zona fica insegura.",
                 bairro: "Macuti",
                 data: Date().addingTimeInterval(-86_400),
                 estado: .pendente, apoios: 9),
        Denuncia(categoria: .esgoto,
                 descricao: "Esgoto a correr na rua após a chuva.",
                 bairro: "Chaimite",
                 data: Date().addingTimeInterval(-86_400 * 6),
                 estado: .resolvido, apoios: 31)
    ]
}
