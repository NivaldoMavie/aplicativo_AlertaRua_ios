import SwiftUI

struct ContentView: View {
    @StateObject private var store = DenunciaStore()
    @State private var aba = 0

    var body: some View {
        TabView(selection: $aba) {
            ListaView()
                .tabItem { Label("Ocorrências", systemImage: "list.bullet") }
                .tag(0)

            NovaDenunciaView(aba: $aba)
                .tabItem { Label("Denunciar", systemImage: "plus.circle.fill") }
                .tag(1)

            ResumoView()
                .tabItem { Label("Resumo", systemImage: "chart.bar.fill") }
                .tag(2)
        }
        .environmentObject(store)
    }
}

// MARK: - Lista de ocorrências

struct ListaView: View {
    @EnvironmentObject var store: DenunciaStore
    @State private var filtro: Filtro = .todas
    @State private var pesquisa = ""

    private var filtradas: [Denuncia] {
        store.denuncias.filter { d in
            filtro.aceita(d.estado) &&
            (pesquisa.isEmpty || d.bairro.localizedCaseInsensitiveContains(pesquisa))
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Filtro", selection: $filtro) {
                        ForEach(Filtro.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    if filtradas.isEmpty {
                        Text("Sem ocorrências neste filtro.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(filtradas) { d in
                        LinhaDenuncia(denuncia: d)
                            .swipeActions(edge: .leading) {
                                if d.estado != .resolvido {
                                    Button("Avançar") { store.avancarEstado(d) }
                                        .tint(.blue)
                                }
                            }
                    }
                    .onDelete { indices in
                        store.remover(ids: indices.map { filtradas[$0].id })
                    }
                }
            }
            .navigationTitle("AlertaRua")
            .searchable(text: $pesquisa, prompt: "Pesquisar por bairro")
        }
    }
}

struct LinhaDenuncia: View {
    @EnvironmentObject var store: DenunciaStore
    let denuncia: Denuncia

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: denuncia.categoria.icone)
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(denuncia.categoria.cor, in: Circle())

                VStack(alignment: .leading) {
                    Text(denuncia.categoria.rawValue).font(.headline)
                    Text("\(denuncia.bairro) · \(denuncia.data.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(denuncia.estado.rawValue)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(denuncia.estado.cor.opacity(0.18), in: Capsule())
                    .foregroundStyle(denuncia.estado.cor)
            }

            Text(denuncia.descricao).font(.subheadline)

            Button {
                store.apoiar(denuncia)
            } label: {
                Label("Eu também vi (\(denuncia.apoios))", systemImage: "hand.thumbsup")
                    .font(.footnote)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Nova denúncia

struct NovaDenunciaView: View {
    @EnvironmentObject var store: DenunciaStore
    @Binding var aba: Int

    @State private var categoria: Categoria = .buraco
    @State private var bairro = bairros[0]
    @State private var descricao = ""

    private var valido: Bool {
        descricao.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tipo de problema") {
                    Picker("Categoria", selection: $categoria) {
                        ForEach(Categoria.allCases) { c in
                            Label(c.rawValue, systemImage: c.icone).tag(c)
                        }
                    }
                }

                Section("Localização") {
                    Picker("Bairro", selection: $bairro) {
                        ForEach(bairros, id: \.self) { Text($0) }
                    }
                }

                Section("Descrição") {
                    TextField("Descreve o problema (mín. 10 caracteres)",
                              text: $descricao, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button("Enviar denúncia") { enviar() }
                        .disabled(!valido)
                }
            }
            .navigationTitle("Nova denúncia")
        }
    }

    private func enviar() {
        let nova = Denuncia(categoria: categoria,
                            descricao: descricao.trimmingCharacters(in: .whitespacesAndNewlines),
                            bairro: bairro)
        store.adicionar(nova)
        descricao = ""
        aba = 0
    }
}

// MARK: - Resumo

struct ResumoView: View {
    @EnvironmentObject var store: DenunciaStore

    private var total: Int { store.denuncias.count }

    private func contar(_ estado: Estado) -> Int {
        store.denuncias.filter { $0.estado == estado }.count
    }

    private func contar(_ categoria: Categoria) -> Int {
        store.denuncias.filter { $0.categoria == categoria }.count
    }

    private var taxaResolucao: Double {
        total == 0 ? 0 : Double(contar(.resolvido)) / Double(total)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Por estado") {
                    ForEach(Estado.allCases, id: \.self) { e in
                        HStack {
                            Circle().fill(e.cor).frame(width: 10, height: 10)
                            Text(e.rawValue)
                            Spacer()
                            Text("\(contar(e))").bold()
                        }
                    }
                }

                Section("Taxa de resolução") {
                    ProgressView(value: taxaResolucao)
                        .tint(.green)
                    Text("\(Int(taxaResolucao * 100))% das ocorrências resolvidas")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Por categoria") {
                    ForEach(Categoria.allCases) { c in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Label(c.rawValue, systemImage: c.icone)
                                Spacer()
                                Text("\(contar(c))").bold()
                            }
                            ProgressView(value: total == 0 ? 0 : Double(contar(c)) / Double(total))
                                .tint(c.cor)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("Resumo")
        }
    }
}
