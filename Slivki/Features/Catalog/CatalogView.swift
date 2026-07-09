import SwiftUI

public struct CatalogView: View {
    @Environment(\.apiClient) private var apiClient
    @EnvironmentObject private var bootstrapStore: BootstrapStore
    @EnvironmentObject private var router: AppRouter
    @State private var query = ""
    @State private var state: LoadState<[Category]> = .idle

    private let fallbackCategories: [Category]

    public init(categories: [Category] = Fixtures.categories) {
        self.fallbackCategories = categories
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SlivkiSpacing.lg) {
                StorefrontDeliveryStrip()
                quickFilters
                statusBanner
                SlivkiSectionTitle("Все категории", subtitle: "Выберите раздел и сразу переходите к товарам")
                categoryGrid(categories)
                StorefrontFooter(
                    site: bootstrapStore.site,
                    onFavorites: { router.navigate(to: .favorites, in: .catalog) },
                    onAbout: { router.navigate(to: .legal(path: "/pages/rules.html"), in: .catalog) },
                    onFeedback: { router.selectedTab = .profile },
                    onRules: { router.navigate(to: .legal(path: "/pages/rules.html"), in: .catalog) },
                    onAgreement: { router.navigate(to: .legal(path: "/pages/agreement.html"), in: .catalog) }
                )
            }
            .padding(SlivkiSpacing.md)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: SlivkiSpacing.sm) {
                StorefrontHeader(
                    variant: .standard,
                    siteName: bootstrapStore.site?.name ?? "Сливки"
                )
                SlivkiSearchBar(text: $query, placeholder: "Что вы хотите найти?") {
                    submitSearch()
                }
            }
            .padding(.horizontal, SlivkiSpacing.md)
            .padding(.top, SlivkiSpacing.md)
            .padding(.bottom, SlivkiSpacing.sm)
            .background(SlivkiColor.surface)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(SlivkiColor.border.opacity(0.8))
                    .frame(height: 1)
            }
        }
        .background(SlivkiColor.groupedBackground)
        .navigationTitle("Каталог")
        .slivkiHideNavigationBar()
        .task {
            await loadCatalogIfNeeded()
        }
        .onChange(of: bootstrapStore.categories) { categories in
            guard !categories.isEmpty else {
                return
            }
            state = .loaded(categories)
        }
    }

    private var categories: [Category] {
        let bootstrapCategories = bootstrapStore.categories
        if !bootstrapCategories.isEmpty {
            return bootstrapCategories
        }
        if case .loaded(let loaded) = state, !loaded.isEmpty {
            return loaded
        }
        return fallbackCategories
    }

    private var quickFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SlivkiSpacing.xs) {
                SlivkiChip("Каталог", systemImage: "square.grid.2x2.fill", isSelected: true)

                Button {
                    router.navigate(to: .search(query: "акции"), in: .catalog)
                } label: {
                    SlivkiChip("Акции", systemImage: "percent")
                }
                .buttonStyle(.plain)

                Button {
                    if let readyFood = bootstrapStore.category(matchingTitle: "готов") {
                        router.navigate(to: .category(id: readyFood.id, title: readyFood.title), in: .catalog)
                    } else {
                        router.navigate(to: .search(query: "готовая еда"), in: .catalog)
                    }
                } label: {
                    SlivkiChip("Готовая еда", systemImage: "fork.knife")
                }
                .buttonStyle(.plain)
            }
        }
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
                        await loadCatalogIfNeeded()
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
        LazyVGrid(columns: [GridItem(.flexible(), spacing: SlivkiSpacing.sm), GridItem(.flexible(), spacing: SlivkiSpacing.sm)], spacing: SlivkiSpacing.sm) {
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

    private func submitSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }
        router.navigate(to: .search(query: trimmed), in: .catalog)
    }

    private func loadCatalogIfNeeded() async {
        if !bootstrapStore.categories.isEmpty {
            state = .loaded(bootstrapStore.categories)
            return
        }

        state = .loading

        do {
            let response: CatalogResponse = try await apiClient.get(.catalog)
            guard !Task.isCancelled else {
                return
            }
            state = .loaded(response.categories)
        } catch is CancellationError {
            if !bootstrapStore.categories.isEmpty {
                state = .loaded(bootstrapStore.categories)
            }
        } catch {
            if !bootstrapStore.categories.isEmpty {
                state = .loaded(bootstrapStore.categories)
                return
            }
            state = .failed("Не удалось обновить категории. Показываем сохраненный каталог.")
        }
    }
}
