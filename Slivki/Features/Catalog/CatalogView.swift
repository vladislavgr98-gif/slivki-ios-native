import SwiftUI

public struct CatalogView: View {
    @EnvironmentObject private var router: AppRouter
    @State private var query = ""
    private let categories: [Category]

    public init(categories: [Category] = Fixtures.categories) {
        self.categories = categories
    }

    public var body: some View {
        ScrollView {
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
    }
}
