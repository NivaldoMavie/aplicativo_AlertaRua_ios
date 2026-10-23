import SwiftUI

// Modelo de enumeracao para os papeis no aplicativo (Visao do Municipe vs Gestao Municipal)
enum PerfilUtilizador: String, CaseIterable, Identifiable {
    case cidadao = "Cidadão"
    case municipio = "Município (CMB)"

    var id: String { rawValue }

    var icone: String {
        switch self {
        case .cidadao: return "person.fill"
        case .municipio: return "building.columns.fill"
        }
    }
}

// Modelo de enumeracao para as categorias de problemas urbanos
enum Categoria: String, CaseIterable, Identifiable, Codable {
    case buraco = "Buraco na Via"
    case lixo = "Lixo Acumulado"
    case candeeiro = "Iluminação Pública"
    case esgoto = "Esgoto a Céu Aberto"

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

// Modelo de prioridade do problema relatado
enum Prioridade: String, CaseIterable, Identifiable, Codable {
    case baixa = "Baixa"
    case media = "Média"
    case alta = "Alta"
    case critica = "Crítica"

    var id: String { rawValue }

    var cor: Color {
        switch self {
        case .baixa: return .blue
        case .media: return .yellow
        case .alta: return .orange
        case .critica: return .red
        }
    }

    var icone: String {
        switch self {
        case .baixa: return "arrow.down.circle"
        case .media: return "minus.circle"
        case .alta: return "arrow.up.circle.fill"
        case .critica: return "flame.fill"
        }
    }
}

// Modelo de enumeracao para os estados do ciclo de vida da ocorrencia
enum Estado: String, CaseIterable, Codable {
    case pendente = "Pendente"
    case aceite = "Aceite"
    case emResolucao = "Em resolução"
    case resolvido = "Resolvido"
    case rejeitado = "Rejeitado"

    // Cor correspondente ao estado atual
    var cor: Color {
        switch self {
        case .pendente: return .red
        case .aceite: return .purple
        case .emResolucao: return .orange
        case .resolvido: return .green
        case .rejeitado: return .secondary
        }
    }

    var icone: String {
        switch self {
        case .pendente: return "hourglass"
        case .aceite: return "checkmark.seal.fill"
        case .emResolucao: return "wrench.and.screwdriver.fill"
        case .resolvido: return "checkmark.circle.fill"
        case .rejeitado: return "xmark.circle.fill"
        }
    }

    // Logica de transicao sequencial basica
    var proximo: Estado {
        switch self {
        case .pendente: return .aceite
        case .aceite: return .emResolucao
        case .emResolucao: return .resolvido
        case .resolvido: return .resolvido
        case .rejeitado: return .pendente
        }
    }
}

// Modelo de enumeracao para os filtros da listagem de ocorrencias
enum Filtro: String, CaseIterable, Identifiable {
    case todas = "Todas"
    case pendentes = "Pendentes"
    case aceites = "Aceites"
    case emCurso = "Em curso"
    case resolvidas = "Resolvidas"

    var id: String { rawValue }

    // Verifica se uma ocorrencia com determinado estado eh aceita pelo filtro
    func aceita(_ estado: Estado) -> Bool {
        switch self {
        case .todas: return true
        case .pendentes: return estado == .pendente
        case .aceites: return estado == .aceite
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

// Lista das brigadas operacionais do Conselho Municipal da Beira (CMB)
let equipasMunicipais = [
    "Brigada de Vias e Obras",
    "Serviços Municipais de Salubridade",
    "Piquete de Iluminação Pública",
    "Serviços de Drenagem e Saneamento",
    "Gabinete de Fiscalização Municipal"
]

// Registro historico de eventos para a linha do tempo (timeline)
struct EventoHistorico: Identifiable, Codable, Equatable {
    var id: UUID
    var data: Date
    var titulo: String
    var descricao: String
    var autor: String
    var icone: String

    init(
        id: UUID = UUID(),
        data: Date = Date(),
        titulo: String,
        descricao: String,
        autor: String,
        icone: String = "info.circle.fill"
    ) {
        self.id = id
        self.data = data
        self.titulo = titulo
        self.descricao = descricao
        self.autor = autor
        self.icone = icone
    }
}

// Estrutura de dados que representa um alerta urbano (ocorrencia)
// Conforma com Identifiable, Codable e Equatable para persistencia em JSON
struct Alerta: Identifiable, Codable, Equatable {
    var id: UUID
    var categoria: Categoria
    var descricao: String
    var bairro: String
    var pontoReferencia: String
    var prioridade: Prioridade
    var data: Date
    var estado: Estado
    var apoios: Int
    var equipaAtribuida: String?
    var notaMunicipio: String?
    var prazoEstimado: String?
    var historico: [EventoHistorico]

    // Inicializador completo com valores predefinidos
    init(
        id: UUID = UUID(),
        categoria: Categoria,
        descricao: String,
        bairro: String,
        pontoReferencia: String = "",
        prioridade: Prioridade = .media,
        data: Date = Date(),
        estado: Estado = .pendente,
        apoios: Int = 0,
        equipaAtribuida: String? = nil,
        notaMunicipio: String? = nil,
        prazoEstimado: String? = nil,
        historico: [EventoHistorico] = []
    ) {
        self.id = id
        self.categoria = categoria
        self.descricao = descricao
        self.bairro = bairro
        self.pontoReferencia = pontoReferencia
        self.prioridade = prioridade
        self.data = data
        self.estado = estado
        self.apoios = apoios
        self.equipaAtribuida = equipaAtribuida
        self.notaMunicipio = notaMunicipio
        self.prazoEstimado = prazoEstimado

        if historico.isEmpty {
            self.historico = [
                EventoHistorico(
                    data: data,
                    titulo: "Alerta Submetido",
                    descricao: "Ocorrência registada pelo munícipe no sistema AlertaRua.",
                    autor: "Munícipe",
                    icone: "person.crop.circle.badge.plus"
                )
            ]
        } else {
            self.historico = historico
        }
    }

    // Exemplos iniciais realistas cobrindo diferentes estados e fluxos do municipio
    static let exemplos: [Alerta] = [
        Alerta(
            categoria: .buraco,
            descricao: "Buraco de grande dimensão no meio da faixa de rodagem, com risco iminente de acidentes para viaturas e motociclos.",
            bairro: "Munhava",
            pontoReferencia: "Próximo à paragem de chapas da Munhava Central",
            prioridade: .critica,
            data: Date().addingTimeInterval(-86_400 * 3),
            estado: .emResolucao,
            apoios: 28,
            equipaAtribuida: "Brigada de Vias e Obras",
            notaMunicipio: "Equipa técnica no local com brita e asfalto frio para tapamento do buraco.",
            prazoEstimado: "Conclusão prevista em 24h",
            historico: [
                EventoHistorico(
                    data: Date().addingTimeInterval(-86_400 * 3),
                    titulo: "Alerta Registado",
                    descricao: "Registo inicial por munícipe com classificação prioritária.",
                    autor: "Munícipe",
                    icone: "person.crop.circle.badge.plus"
                ),
                EventoHistorico(
                    data: Date().addingTimeInterval(-86_400 * 2),
                    titulo: "Triagem Municipal Aprovada",
                    descricao: "Alerta aceite pelo CMB e atribuído à Brigada de Vias e Obras.",
                    autor: "Conselho Municipal",
                    icone: "checkmark.seal.fill"
                ),
                EventoHistorico(
                    data: Date().addingTimeInterval(-86_400 * 1),
                    titulo: "Início dos Trabalhos",
                    descricao: "Operação iniciada com sinalização de segurança na via.",
                    autor: "Brigada de Vias e Obras",
                    icone: "wrench.and.screwdriver.fill"
                )
            ]
        ),
        Alerta(
            categoria: .lixo,
            descricao: "Contentores a transbordar com resíduos espalhados na via pública há mais de uma semana.",
            bairro: "Manga",
            pontoReferencia: "Junto ao Mercado Central da Manga",
            prioridade: .alta,
            data: Date().addingTimeInterval(-86_400 * 2),
            estado: .aceite,
            apoios: 34,
            equipaAtribuida: "Serviços Municipais de Salubridade",
            notaMunicipio: "Camião compactador escalado para recolha noturna de reforço.",
            prazoEstimado: "Hoje até às 22h",
            historico: [
                EventoHistorico(
                    data: Date().addingTimeInterval(-86_400 * 2),
                    titulo: "Alerta Registado",
                    descricao: "Relato de acumulação de resíduos no mercado.",
                    autor: "Munícipe",
                    icone: "person.crop.circle.badge.plus"
                ),
                EventoHistorico(
                    data: Date().addingTimeInterval(-86_400 * 1),
                    titulo: "Validado pelo Município",
                    descricao: "Equipa de Salubridade alocou viatura de recolha pesada.",
                    autor: "Conselho Municipal",
                    icone: "checkmark.seal.fill"
                )
            ]
        ),
        Alerta(
            categoria: .candeeiro,
            descricao: "Poste com iluminação desligada há vários dias. A escuridão total causa insegurança aos pedestres.",
            bairro: "Macuti",
            pontoReferencia: "Rua do Farol, junto à rotunda",
            prioridade: .media,
            data: Date().addingTimeInterval(-86_400),
            estado: .pendente,
            apoios: 12,
            historico: [
                EventoHistorico(
                    data: Date().addingTimeInterval(-86_400),
                    titulo: "Alerta Registado",
                    descricao: "Aguardando triagem pelo Piquete de Iluminação do CMB.",
                    autor: "Munícipe",
                    icone: "hourglass"
                )
            ]
        ),
        Alerta(
            categoria: .esgoto,
            descricao: "Esgoto entupido com águas paradas a transbordar para as habitações vizinhas.",
            bairro: "Chaimite",
            pontoReferencia: "Avenida Eduardo Mondlane, esquina da farmácia",
            prioridade: .critica,
            data: Date().addingTimeInterval(-86_400 * 6),
            estado: .resolvido,
            apoios: 45,
            equipaAtribuida: "Serviços de Drenagem e Saneamento",
            notaMunicipio: "Desobstrução do coletor concluída e aplicação de desinfetante no local.",
            prazoEstimado: "Concluído",
            historico: [
                EventoHistorico(
                    data: Date().addingTimeInterval(-86_400 * 6),
                    titulo: "Alerta Submetido",
                    descricao: "Munícipe reportou esgoto a céu aberto com mau cheiro.",
                    autor: "Munícipe",
                    icone: "person.crop.circle.badge.plus"
                ),
                EventoHistorico(
                    data: Date().addingTimeInterval(-86_400 * 4),
                    titulo: "Aceite pelo Município",
                    descricao: "Urgência classificada pelo piquete de saneamento.",
                    autor: "Conselho Municipal",
                    icone: "checkmark.seal.fill"
                ),
                EventoHistorico(
                    data: Date().addingTimeInterval(-86_400 * 2),
                    titulo: "Intervenção no Coletor",
                    descricao: "Desentupimento hidrojato efetuado com sucesso.",
                    autor: "Serviços de Drenagem",
                    icone: "wrench.and.screwdriver.fill"
                ),
                EventoHistorico(
                    data: Date().addingTimeInterval(-86_400 * 1),
                    titulo: "Caso Resolvido",
                    descricao: "Vistoria final confirmou escoamento normalizado.",
                    autor: "Conselho Municipal",
                    icone: "checkmark.circle.fill"
                )
            ]
        )
    ]
}

// Compatibilidade reversa com o nome anterior para evitar quebras em codigos legados
typealias Denuncia = Alerta
