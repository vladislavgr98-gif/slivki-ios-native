import SwiftUI

public struct CatalogView: View {
    @Environment(\.apiClient) private var apiClient
    @EnvironmentObject private var router: AppRouter
    @State private var query = ""
    @State private var state: LoadState<[Category]> = .idle

    private let fallbackCategories: [Category]

    public init(categories: [Category] = Fixtures.categories) {
        self.fallbackCategories = categories
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SlivkiSpacing.md) {
                statusBanner
                categoryGrid(categories)
            }
            .padding(SlivkiSpacing.md)
        }
        .background(SlivkiColor.groupedBackground)
        .navigationTitle("Каталог")
        .searchable(text: $query, prompt: "Поиск товаров")
        .onSubmit(of: .search) {
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                return
            }
            router.navigate(to: .search(query: trimmed), in: .catalog)
        }
        .task {
            await loadCatalog()
        }
    }

    private var categories: [Category] {
        if case .loaded(let loaded) = state, !loaded.isEmpty {
            return loaded
        }
        return fallbackCategories
    }

    @ViewBuilder
    private var statusBanner: some View {
        switch state {
        case .idle, .loading:
            HStack(spacing: SlivkiSpacing.sm) {
                ProgressView()
                Text("Загружаем категории")
                    .font(.subheadline)
                    .foregroundStyle(SlivkiColor.textSecondary)
            }
            .padding(SlivkiSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SlivkiColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        case .failed(let message):
            VStack(alignment: .leading, spacing: SlivkiSpacing.sm) {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(SlivkiColor.textSecondary)
                Button("Повторить") {
                    Task {
                        await loadCatalog()
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(SlivkiSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SlivkiColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        case .loaded:
            EmptyView()
        }
    }

    private func categoryGrid(_ categories: [Category]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: SlivkiSpacing.sm)], spacing: SlivkiSpacing.sm) {
            ForEach(categories) { category in
                Button {
                    router.navigate(to: .category(id: category.id, title: category.title), in: .catalog)
                } label: {
                    CategoryTileView(category: category)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func loadCatalog() async {
        state = .loading

        do {
            let response: CatalogResponse = try await apiClient.get(.catalog)
            guard !Task.isCancelled else {
                return
            }
            state = .loaded(response.categories)
        } catch is CancellationError {
            return
        } catch {
            state = .failed("Не удалось обновить категории. Показываем сохраненный каталог.")
        }
    }
}
